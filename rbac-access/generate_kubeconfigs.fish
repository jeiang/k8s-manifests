#!/usr/bin/env fish

function usage
    set script_name (basename (status --current-filename))
    echo "Usage: $script_name [options]"
    echo
    echo "Generate client-certificate kubeconfigs for User subjects rendered by this chart."
    echo
    echo "Options:"
    echo "  -o, --output-dir DIR       Directory for kubeconfigs, keys, and certificates"
    echo "                            Default: ./kubeconfigs under this chart"
    echo "  -r, --release NAME         Helm release name used for rendering"
    echo "                            Default: rbac-access"
    echo "  -n, --namespace NAME       Helm release namespace used for rendering"
    echo "                            Default: kube-system"
    echo "  -f, --values FILE          Extra Helm values file; may be repeated"
    echo "      --context NAME         kubectl context to use"
    echo "      --expiration-days N    Requested certificate lifetime in days"
    echo "                            Default: 365"
    echo "      --csr-prefix NAME      Prefix for temporary CertificateSigningRequests"
    echo "                            Default: rbac-access"
    echo "  -h, --help                 Show this help"
end

function fail --argument-names message
    echo "error: $message" >&2
    exit 1
end

function require_command --argument-names command_name
    command -q "$command_name"; or fail "missing required command: $command_name"
end

function sanitize_name --argument-names raw_name
    set safe_name (string lower -- "$raw_name" | string replace -ra '[^a-z0-9.-]+' '-' | string replace -ra '(^[.-]+|[.-]+$)' '')

    if test -z "$safe_name"
        fail "cannot convert '$raw_name' to a valid file/CSR name"
    end

    string sub --length 180 -- "$safe_name"
end

function subject_to_openssl_cn --argument-names subject_name
    if string match -q '*/*' -- "$subject_name"
        fail "username '$subject_name' contains '/', which this script cannot safely encode as an OpenSSL subject"
    end

    set escaped_subject (string replace -a "\\" "\\\\" -- "$subject_name")
    set escaped_subject (string replace -a "," "\\," -- "$escaped_subject")
    set escaped_subject (string replace -a "+" "\\+" -- "$escaped_subject")
    set escaped_subject (string replace -a '"' '\"' -- "$escaped_subject")
    set escaped_subject (string replace -a "<" "\\<" -- "$escaped_subject")
    set escaped_subject (string replace -a ">" "\\>" -- "$escaped_subject")
    set escaped_subject (string replace -a ";" "\\;" -- "$escaped_subject")
    set escaped_subject (string replace -a "=" "\\=" -- "$escaped_subject")

    printf '%s\n' "$escaped_subject"
end

argparse h/help 'o/output-dir=' 'r/release=' 'n/namespace=' 'f/values=' 'context=' 'expiration-days=' 'csr-prefix=' -- $argv
or begin
    usage
    exit 2
end

if set -q _flag_help
    usage
    exit 0
end

for required_command in helm kubectl openssl awk sort cut base64 date mktemp
    require_command "$required_command"
end

set script_dir (cd (dirname (status --current-filename)); and pwd)
set chart_dir "$script_dir"

set output_dir "$chart_dir/kubeconfigs"
if set -q _flag_output_dir
    set output_dir $_flag_output_dir[1]
end

set release_name rbac-access
if set -q _flag_release
    set release_name $_flag_release[1]
end

set release_namespace kube-system
if set -q _flag_namespace
    set release_namespace $_flag_namespace[1]
end

set expiration_days 365
if set -q _flag_expiration_days
    set expiration_days $_flag_expiration_days[1]
end

if not string match -qr '^[1-9][0-9]*$' -- "$expiration_days"
    fail "--expiration-days must be a positive integer"
end

set expiration_seconds (math --scale=0 "$expiration_days * 86400")

set csr_prefix rbac-access
if set -q _flag_csr_prefix
    set csr_prefix $_flag_csr_prefix[1]
end

set kubectl_args
if set -q _flag_context
    set kubectl_args --context $_flag_context[1]
end

set temp_dir (mktemp -d)
or fail "failed to create temporary directory"

function cleanup --on-event fish_exit
    if set -q temp_dir; and test -d "$temp_dir"
        rm -rf "$temp_dir"
    end
end

mkdir -p "$output_dir"
or fail "failed to create output directory: $output_dir"

set rendered_file "$temp_dir/rendered.yaml"
set users_file "$temp_dir/users.tsv"

set helm_args template "$release_name" "$chart_dir" --namespace "$release_namespace"
if set -q _flag_values
    for values_file in $_flag_values
        set -a helm_args --values "$values_file"
    end
end

helm $helm_args >"$rendered_file"
or fail "helm template failed"

awk '
function clean(value) {
  sub(/^[[:space:]]+/, "", value)
  sub(/[[:space:]]+$/, "", value)
  sub(/^"/, "", value)
  sub(/"$/, "", value)
  return value
}
function value_after_colon(line) {
  return clean(substr(line, index(line, ":") + 1))
}
function reset_doc() {
  kind = ""
  namespace = ""
  in_subjects = 0
  subject_kind = ""
  subject_name = ""
}
function maybe_print_subject() {
  if (subject_kind == "User" && subject_name != "") {
    print subject_name "\t" namespace
    subject_name = ""
  }
}
BEGIN {
  reset_doc()
}
/^---[[:space:]]*$/ {
  reset_doc()
  next
}
/^kind:[[:space:]]*/ {
  kind = value_after_colon($0)
  next
}
kind == "RoleBinding" && /^  namespace:[[:space:]]*/ {
  namespace = value_after_colon($0)
  next
}
/^subjects:[[:space:]]*$/ {
  in_subjects = 1
  subject_kind = ""
  next
}
in_subjects && /^[^[:space:]-]/ {
  maybe_print_subject()
  in_subjects = 0
  subject_kind = ""
  subject_name = ""
}
in_subjects && /^  -[[:space:]]*/ {
  maybe_print_subject()
  subject_kind = ""
  subject_name = ""

  if ($0 ~ /kind:[[:space:]]*/) {
    subject_kind = value_after_colon($0)
  }

  if ($0 ~ /name:[[:space:]]*/) {
    subject_name = value_after_colon($0)
  }

  maybe_print_subject()
  next
}
in_subjects && /^    kind:[[:space:]]*/ {
  subject_kind = value_after_colon($0)
  maybe_print_subject()
  next
}
in_subjects && /^    name:[[:space:]]*/ {
  subject_name = value_after_colon($0)
  maybe_print_subject()
  next
}
' "$rendered_file" | sort -u >"$users_file"
or fail "failed to extract User subjects from rendered RBAC"

if not test -s "$users_file"
    fail "no User subjects were rendered by the chart"
end

set current_context (kubectl $kubectl_args config current-context)
or fail "failed to read current kubectl context"

set cluster_name (kubectl $kubectl_args config view --raw --minify -o 'jsonpath={.contexts[0].context.cluster}')
or fail "failed to read cluster name from kubeconfig"

set cluster_server (kubectl $kubectl_args config view --raw --minify -o 'jsonpath={.clusters[0].cluster.server}')
or fail "failed to read cluster server from kubeconfig"

set ca_data (kubectl $kubectl_args config view --raw --minify --flatten -o 'jsonpath={.clusters[0].cluster.certificate-authority-data}')
or fail "failed to read cluster certificate authority data from kubeconfig"

if test -z "$cluster_name"
    fail "current kubeconfig context does not include a cluster name"
end

if test -z "$cluster_server"
    fail "current kubeconfig context does not include a cluster server"
end

if test -z "$ca_data"
    fail "current kubeconfig context does not include certificate-authority-data"
end

set ca_file "$temp_dir/ca.crt"
printf '%s' "$ca_data" | base64 --decode >"$ca_file"
or fail "failed to decode cluster certificate authority data"

set users (cut -f 1 "$users_file" | sort -u)

echo "Using kubectl context: $current_context"
echo "Rendered chart: $chart_dir"
echo "Writing kubeconfigs to: $output_dir"
echo

for user_name in $users
    set safe_name (sanitize_name "$user_name")
    set key_file "$output_dir/$safe_name.key"
    set cert_file "$output_dir/$safe_name.crt"
    set kubeconfig_file "$output_dir/$safe_name.kubeconfig"
    set csr_file "$temp_dir/$safe_name.csr"
    set csr_manifest "$temp_dir/$safe_name-csr.yaml"
    set csr_name (string sub --length 253 -- "$csr_prefix-$safe_name-"(date +%Y%m%d%H%M%S))
    set openssl_cn (subject_to_openssl_cn "$user_name")

    echo "Generating kubeconfig for $user_name"

    openssl genrsa -out "$key_file" 4096 >/dev/null 2>&1
    or fail "failed to generate private key for $user_name"

    chmod 0600 "$key_file"
    or fail "failed to secure private key permissions for $user_name"

    openssl req -new -key "$key_file" -out "$csr_file" -subj "/CN=$openssl_cn" >/dev/null 2>&1
    or fail "failed to generate CSR for $user_name"

    set csr_request (base64 --wrap=0 "$csr_file")
    or fail "failed to encode CSR for $user_name"

    printf '%s\n' \
        'apiVersion: certificates.k8s.io/v1' \
        'kind: CertificateSigningRequest' \
        'metadata:' \
        "  name: $csr_name" \
        'spec:' \
        "  expirationSeconds: $expiration_seconds" \
        "  request: $csr_request" \
        '  signerName: kubernetes.io/kube-apiserver-client' \
        '  usages:' \
        '    - client auth' >"$csr_manifest"

    kubectl $kubectl_args apply -f "$csr_manifest" >/dev/null
    or fail "failed to create CertificateSigningRequest $csr_name"

    kubectl $kubectl_args certificate approve "$csr_name" >/dev/null
    or fail "failed to approve CertificateSigningRequest $csr_name"

    set cert_data
    for attempt in (seq 1 30)
        set cert_data (kubectl $kubectl_args get csr "$csr_name" -o 'jsonpath={.status.certificate}' 2>/dev/null)
        if test -n "$cert_data"
            break
        end

        sleep 1
    end

    if test -z "$cert_data"
        kubectl $kubectl_args describe csr "$csr_name" >&2
        kubectl $kubectl_args delete csr "$csr_name" --ignore-not-found >/dev/null 2>&1
        fail "timed out waiting for signed certificate on CSR $csr_name"
    end

    printf '%s' "$cert_data" | base64 --decode >"$cert_file"
    or fail "failed to decode signed certificate for $user_name"

    kubectl $kubectl_args delete csr "$csr_name" --ignore-not-found >/dev/null
    or fail "failed to delete temporary CertificateSigningRequest $csr_name"

    kubectl config --kubeconfig "$kubeconfig_file" set-cluster "$cluster_name" --server "$cluster_server" --certificate-authority "$ca_file" --embed-certs=true >/dev/null
    or fail "failed to write cluster config for $user_name"

    kubectl config --kubeconfig "$kubeconfig_file" set-credentials "$user_name" --client-certificate "$cert_file" --client-key "$key_file" --embed-certs=true >/dev/null
    or fail "failed to write user credentials for $user_name"

    set namespaces (awk -F '\t' -v user="$user_name" '$1 == user && $2 != "" { print $2 }' "$users_file" | sort -u)

    if test (count $namespaces) -gt 0
        set first_context ""

        for namespace_name in $namespaces
            set context_name "$user_name@$cluster_name:$namespace_name"
            kubectl config --kubeconfig "$kubeconfig_file" set-context "$context_name" --cluster "$cluster_name" --user "$user_name" --namespace "$namespace_name" >/dev/null
            or fail "failed to write namespace context $context_name"

            if test -z "$first_context"
                set first_context "$context_name"
            end
        end

        kubectl config --kubeconfig "$kubeconfig_file" use-context "$first_context" >/dev/null
        or fail "failed to select default context for $user_name"
    else
        set context_name "$user_name@$cluster_name"
        kubectl config --kubeconfig "$kubeconfig_file" set-context "$context_name" --cluster "$cluster_name" --user "$user_name" >/dev/null
        or fail "failed to write context $context_name"

        kubectl config --kubeconfig "$kubeconfig_file" use-context "$context_name" >/dev/null
        or fail "failed to select default context for $user_name"
    end

    chmod 0600 "$kubeconfig_file"
    or fail "failed to secure kubeconfig permissions for $user_name"

    echo "  $kubeconfig_file"
end

echo
echo "Done. Install or upgrade the rbac-access chart before using these kubeconfigs."

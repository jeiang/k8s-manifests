{{- define "attic.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "attic.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{- define "attic.labels" -}}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name (.Chart.Version | replace "+" "_") }}
app.kubernetes.io/name: {{ include "attic.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- define "attic.selectorLabels" -}}
app.kubernetes.io/name: {{ include "attic.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{- define "attic.secretName" -}}
{{- required "secrets.existingSecret is required" .Values.secrets.existingSecret -}}
{{- end }}

{{- define "attic.permissionTable" -}}
{{- $p := . -}}
{ r = {{ ternary 1 0 (default false $p.pull) }}, w = {{ ternary 1 0 (default false $p.push) }}, d = {{ ternary 1 0 (default false $p.delete) }}, cc = {{ ternary 1 0 (default false $p.create) }}, cr = {{ ternary 1 0 (default false $p.configure) }}, cq = {{ ternary 1 0 (default false $p.configureRetention) }}, cd = {{ ternary 1 0 (default false $p.destroy) }} }
{{- end }}

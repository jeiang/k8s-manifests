# Documentation Guidelines

## Scope

This folder contains root-level repository and cluster documentation for humans, operators, and external agents.

## Shared Agent Guide

[`AGENT_INSTRUCTIONS.md`](./AGENT_INSTRUCTIONS.md) is the minimal shareable guide for cloud agents or other users creating namespace-scoped Helm charts for this cluster. Prefer sending that file instead of the full repository context when someone only needs to build or review a namespaced workload chart.

## Maintenance

Update [`AGENT_INSTRUCTIONS.md`](./AGENT_INSTRUCTIONS.md) whenever cluster behavior changes in a way that another user or agent would reasonably need to know. This includes:

- Authentication, namespace ownership, RBAC, or Kyverno policy changes.
- New, removed, or changed CRDs that workload charts may use.
- Changes to ingress, TLS, DNS, storage classes, secret handling, or private service access.
- New restrictions on cluster-scoped resources, public exposure, persistent storage, or privileged workloads.

Keep root-level operational docs in this folder. Leave only the root `README.md` and root `AGENTS.md` at the repository root.

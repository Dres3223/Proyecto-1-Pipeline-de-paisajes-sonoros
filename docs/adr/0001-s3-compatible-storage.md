# ADR 0001: S3-compatible object storage for local development

- **Status:** Accepted
- **Date:** 2026-10-30
- **Task:** P1PDPS-10

## Context
The pipeline stores raw audio files in object storage and their metadata in PostgreSQL.
Locally we need a service that speaks the S3 API, so the same code can later run
against AWS S3 by changing configuration only (epic E6).

The original plan was MinIO, the usual choice for this. However, MinIO stopped
publishing community Docker images in October 2025, archived its GitHub repository
in April 2026, and the `minio/minio` images were removed from Docker Hub in
September 2026. Using it today would mean an unmaintained image that people cloning
this repository cannot pull.

## Options considered
| Option | Pros | Cons |
|---|---|---|
| **RustFS** (`rustfs/rustfs`) | S3-compatible, Apache 2.0, actively maintained, web console, closest day-to-day experience to MinIO | Young project, less battle-tested |
| SILO (`pgsty/silo`) | Community continuation of MinIO, versioned tags | Small community, few maintainers |
| Chainguard MinIO (`cgr.dev/chainguard/minio`) | Free, patched | Only the `latest` tag is free: versions cannot be pinned |
| Old local MinIO image | Works today | No security fixes, cannot be pulled by others |

## Decision
Use **RustFS**, pinned to an exact version (`rustfs/rustfs:1.0.4`).

## Consequences
- Application code talks only to the S3 API (endpoint, access key and secret key
  from environment variables named `S3_*`), never to RustFS-specific features.
  Switching to another S3-compatible service or to AWS S3 is a configuration change.
- RustFS only supports path-style addressing unless `RUSTFS_SERVER_DOMAINS` is set,
  so S3 clients must be configured with path-style access.
- The exact version pin protects us from breaking changes in a young project;
  upgrades are deliberate.

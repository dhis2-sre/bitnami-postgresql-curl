# PostgreSQL with curl

This image adds curl and CA certificates to Bitnami PostgreSQL so database
initialization scripts can download and restore dumps. It preserves the Bitnami
entrypoint, environment variables and non-root UID 1001. The DHIS2 CloudNativePG
chart also uses it for its separate seed job and wait container.

## Current build

The single Dockerfile pins the multiarchitecture manifest for
`bitnamilegacy/postgresql:17`. `dhis2/postgresql-curl:17-legacy-r1` is built for
Linux AMD64 and ARM64. The pinned base contains PostgreSQL 17.5. Existing numeric tags (`13` through `17`) are left untouched;
the former numeric-tag version matrix is retired. Older deployments
can retain their existing tags while version 3.0 adopts the new chart/image.

Bitnami Legacy receives no upstream updates. This is a compatibility bridge;
replacing Bitnami is a separate migration, not part of the test-performance work.

## Build and test

```sh
make build-all                     # load the host architecture locally
make test                          # build and validate AMD64 and ARM64
make test PLATFORMS=linux/arm64     # validate one architecture
```

Tests exercise the Bitnami server startup, HTTPS downloads, PostgreSQL tools,
and custom-format and gzipped SQL restores from separate client containers.
Each test removes its server container and anonymous volumes on exit. Cross-platform
local runs require Docker emulation; CI installs QEMU before running both platforms.

## Publish

PRs only build and test. A push to master, a manual workflow on master, or the
daily schedule (00:00 UTC) publishes the multiarchitecture `17-legacy-r1` tag
after both platform tests pass.
Scheduled runs disable the build cache while building and testing each platform,
so the curl/CA certificate installation picks up available Debian package updates.
Publication reuses those tested layers. This does not update the pinned PostgreSQL
17.5 binaries inherited from Bitnami Legacy. Run `make test TEST_BUILD_FLAGS=--no-cache`
to perform the same package refresh locally.

For an intentional local release, `make all` tests first and then publishes;
`make push-all` publishes without repeating tests. Registry credentials are required.
The workflow never publishes the old numeric tags.

The existing `.github/workflows/build.yml` workflow is currently disabled in GitHub.
After this PR merges, re-enable it and dispatch it on master for the initial
publication; its daily schedule then resumes. Keep it disabled until merge so
the old master workflow cannot resume publishing numeric tags.

Release order: merge/publish this image, release the chart that references
`17-legacy-r1`, then update im-manager version 3.0 to that chart release.

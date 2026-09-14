# Description

Bitnami have removed curl from their postgresql container as mentioned [here](https://github.com/bitnami/containers/issues/13637).

Since we're using curl to download data this project has been created.

# Build and release

Please see the `Makefile` for details about how we're building.

## Build all versions

All versions found in `versions.yaml` can be build and pushed using the following make command

```sh
make all
```

## CloudNativePG seed client

`Dockerfile.seed` builds `dhis2/postgresql-curl:17-bookworm` for Linux AMD64 and ARM64
from the official PostgreSQL 17 Debian image. It supplies bash, curl, gzip, psql,
pg_restore and pg_isready for the DHIS2 chart seed job and wait container, running
as the postgres user. It is a client image, not a drop-in replacement for a
Bitnami PostgreSQL server. Existing numeric tags retain their old build path.

The seed workflow builds and smoke tests both architectures on pull requests;
publication happens only from master after those checks pass.

```sh
docker build -f Dockerfile.seed -t dhis2/postgresql-curl:17-bookworm .
```

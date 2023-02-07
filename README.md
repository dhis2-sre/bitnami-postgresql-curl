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

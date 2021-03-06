#! /usr/bin/env nix-shell
#! nix-shell ../shell.nix -i bash

set -eu

OCI_ARCHIVE=$(nix-build --no-out-link -A packages.x86_64-linux.ociImage)
DOCKER_REPOSITORY="docker://$DOCKER_USERNAME/template-nix-notebooks"

if [ -z ${DOCKER_ACCESS_TOKEN+x} ]; then
    skopeo copy "docker-archive:${OCI_ARCHIVE}" "$DOCKER_REPOSITORY"
else
    skopeo copy --dest-creds="$DOCKER_USERNAME:$DOCKER_ACCESS_TOKEN" "docker-archive:${OCI_ARCHIVE}" "$DOCKER_REPOSITORY"
fi

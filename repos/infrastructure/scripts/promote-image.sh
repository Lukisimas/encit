#!/usr/bin/env bash
set -euo pipefail
IMAGE="${1:?imagen origen}"
TARGET="${2:?imagen destino}"
docker pull "$IMAGE"
SRC_DIGEST="$(docker inspect --format='{{index .RepoDigests 0}}' "$IMAGE")"
docker tag "$IMAGE" "$TARGET"
docker push "$TARGET"
echo "Promovida: $SRC_DIGEST -> $TARGET"

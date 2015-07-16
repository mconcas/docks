#!/bin/bash
if [ -f .dockerhub_token ]; then
  TOKEN_CONTENT=$(cat .dockerhub_token)
else
  echo "Not a valid token provided, exiting."
  exit 1
fi

# Trigger all tags/branchs for this automated build.
curl -H "Content-Type: application/json" --data '{"build": true}' -X POST https://registry.hub.docker.com/u/mconcas/parrotcvmfs-autobuild/trigger/$TOKEN_CONTENT/

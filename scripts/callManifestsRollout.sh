#!/bin/bash

# Parameters that need to be passed in:
RELEASE_TAG=$1

if [ -z "$RELEASE_TAG" ]; then
  echo "ERROR: RELEASE_TAG is not set"
  exit 1
fi

PAYLOAD="{\"ref\":\"main\",\"inputs\":{\"release_tag\":\"$RELEASE_TAG\"}}"

RESPONSE=$(curl -w '%{http_code}\n' \
  -o /dev/null -s \
  -L -X POST -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer $WORKFLOW_PAT" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  https://api.github.com/repos/cds-snc/notification-manifests/actions/workflows/ipv4-geolocate-webservice-staging.yaml/dispatches \
  -d "$PAYLOAD")

if [ "$RESPONSE" != 204 ]; then
  echo "ERROR CALLING MANIFESTS ROLLOUT: HTTP RESPONSE: $RESPONSE"
  exit 1
fi
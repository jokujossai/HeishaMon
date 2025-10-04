#!/bin/bash

set -euo pipefail

REPO="${1:-}"
DATE="${2:-}"
ALLOW_PRERELEASE="${3:-}"

if [ -z "$REPO" ] || [ -z "$DATE" ]; then
    echo "Usage: $0 <repo> <date> [allow-prerelease]"
    exit 1
fi

gh version >/dev/null 2>&1 || {
    echo "gh is not installed"
    exit 1
}

JQ_FILTER="[.[] | select(.prerelease == false and .created_at < \"${DATE}\")][0]"
if [ "$ALLOW_PRERELEASE" = "true" ]; then
  JQ_FILTER="[.[] | select(.created_at < \"${DATE}\")][0]"
fi

RELEASE="$(
  gh api \
    -H "Accept: application/vnd.github+json" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    /repos/${REPO}/releases \
    | jq -r "${JQ_FILTER}"
)"

if [ -z "$RELEASE" ] || [ "$RELEASE" == "null" ]; then
  RELEASE="$(
    gh api \
      -H "Accept: application/vnd.github+json" \
      -H "X-GitHub-Api-Version: 2022-11-28" \
      /repos/${REPO}/releases \
      --paginate \
      | jq -r "${JQ_FILTER}"
  )"
fi

if [ -z "$RELEASE" ] || [ "$RELEASE" == "null" ]; then
  echo "No release found for date: $DATE"
  exit 1
fi

VERSION="$(echo "$RELEASE" | jq -r '.tag_name')"

VERSION="${VERSION//v}"

if [ "$(echo $VERSION | cut -d. -f3)" == "" ]; then
  VERSION="${VERSION}.0"
fi

echo "$VERSION"
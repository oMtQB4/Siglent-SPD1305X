#!/bin/bash

# Script to set the version in pubspec.yaml
# Usage: ./scripts/set_version.sh <version>
# Example: ./scripts/set_version.sh 1.2.3

set -e

if [ -z "$1" ]; then
    echo "Usage: $0 <version>"
    echo "Example: $0 1.2.3"
    exit 1
fi

VERSION="$1"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PUBSPEC_PATH="$SCRIPT_DIR/pubspec.yaml"

if [ ! -f "$PUBSPEC_PATH" ]; then
    echo "Error: pubspec.yaml not found at $PUBSPEC_PATH"
    exit 1
fi

# Update the version line in pubspec.yaml
sed -i'' "s/^version: .*/version: $VERSION/" "$PUBSPEC_PATH"

echo "Version updated to $VERSION in pubspec.yaml"

#!/bin/sh

# Create one single manifest file
target="./manifests-all.yaml"
rm -f "$target"
echo "# Derived from ./yaml" >> "$target"
for file in $(find ./yaml -type f -name "*.yaml" | sort) ; do
  echo "---" >> "$target"
  cat "$file" >> "$target"
done

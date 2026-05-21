#!/bin/bash

# Exit immediately if any command fails
set -e

# 1. Update pubspec.yaml
echo "🔧 Updating pubspec.yaml..."

if [[ ! -f pubspec.yaml ]]; then
  echo "❌ pubspec.yaml not found!"
  exit 1
fi

# Extract current version (format: 1.0.0+9)
current_version=$(grep '^version:' pubspec.yaml | awk '{print $2}')
version_number=$(echo "$current_version" | cut -d+ -f1)
build_number=$(echo "$current_version" | cut -d+ -f2)

if [[ -z "$build_number" ]]; then
  echo "❌ Invalid version format in pubspec.yaml"
  exit 1
fi

new_build_number=$((build_number + 1))
new_version="$version_number+$new_build_number"

# Replace in file
sed -i '' "s/^version: .*/version: $new_version/" pubspec.yaml

echo "✅ pubspec.yaml updated to $new_version"

# 2. Update project.pbxproj (CURRENT_PROJECT_VERSION)
echo "🔧 Searching for project.pbxproj..."

pbxproj_files=$(find ios -name "project.pbxproj")

if [[ -z "$pbxproj_files" ]]; then
  echo "❌ project.pbxproj not found!"
  exit 1
fi

for file in $pbxproj_files; do
  echo "🔧 Updating $file..."

  # Loop through each CURRENT_PROJECT_VERSION line
  while read -r line; do
    if [[ "$line" =~ CURRENT_PROJECT_VERSION[[:space:]]*=[[:space:]]*([0-9]+) ]]; then
      old_version="${BASH_REMATCH[1]}"
      new_version=$((old_version + 1))
      sed -i '' "s/CURRENT_PROJECT_VERSION = $old_version;/CURRENT_PROJECT_VERSION = $new_version;/g" "$file"
      echo "✅ Updated CURRENT_PROJECT_VERSION from $old_version to $new_version in $file"
    fi
  done < <(grep 'CURRENT_PROJECT_VERSION' "$file")
done

# 3. Clean and reinstall dependencies
echo "🧹 Running flutter clean..."
flutter clean

echo "📦 Running flutter pub get..."
flutter pub get

echo "📦 Running pod install..."
cd ios && pod install && cd ..

echo "🎉 Version bump complete!"
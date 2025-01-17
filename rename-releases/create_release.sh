#!/bin/bash

# Get the root directory of the repository
REPO_ROOT=$(git rev-parse --show-toplevel)
REPO_NAME=$(basename "$REPO_ROOT") # Repository name

# Get the most recent tag
TAG_NAME=$(git describe --tags --exact-match 2>/dev/null)
if [ -z "$TAG_NAME" ]; then
  echo "No tag found for the current commit. Please create a tag first."
  exit 1
fi

# Get the Git user name
GIT_USER=$(git config user.name)
TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S") # Current timestamp

# Define the output ZIP files
OUTPUT_DIR=$(pwd) # Current working directory where the script is executed
FULL_ARCHIVE="${OUTPUT_DIR}/${REPO_NAME}_${TAG_NAME}.zip"
DEPLOY_ARCHIVE="${OUTPUT_DIR}/${REPO_NAME}_${TAG_NAME}_deploy.zip"
TEMP_LOG_FILE="release_${REPO_NAME}_${TAG_NAME}.txt"

# Flag to control embedding the log into .lpz and .vtz files
EMBED_LOG=false
if [[ "$1" == "--embed-log-lpz-vtz" ]]; then
  EMBED_LOG=true
fi

# Navigate to the repository root
cd "$REPO_ROOT" || exit 1

# Create the full archive, excluding .git and releases directories
echo "Creating full ZIP archive..."
zip -r "$FULL_ARCHIVE" . -x "*.git*" "./releases/*"

if [ $? -eq 0 ]; then
  echo "Full archive created: $FULL_ARCHIVE"
else
  echo "Failed to create the full archive."
  exit 1
fi

# Generate the release log file
echo "Generating release log..."
{
  echo "Repository: $REPO_NAME"
  echo "Path: $REPO_ROOT"
  echo "Timestamp: $TIMESTAMP"
  echo "User: $GIT_USER"
  echo ""
  git log --tags --simplify-by-decoration --oneline --pretty=format:"%h %ad %d %s" --date=short --decorate --all
} > "$TEMP_LOG_FILE"

# Create the deploy archive
echo "Creating deploy ZIP archive..."
DEPLOY_ITEMS=$(find . \( -type f \( -name "*.lpz" -o -name "*.vtz" -o -name "*.ch5z" -o -name "*.sig" \) -o -type d -name "*.Core3" \) -print)

if [ -z "$DEPLOY_ITEMS" ]; then
  echo "No .lpz, .vtz, .ch5z, .sig files, or *.Core3 folders found. Adding only release log."
  zip "$DEPLOY_ARCHIVE" "$TEMP_LOG_FILE"
else
  while IFS= read -r ITEM; do
    if [[ "$EMBED_LOG" == true && ("$ITEM" == *.lpz || "$ITEM" == *.vtz) ]]; then
      # Special treatment for .lpz and .vtz files
      TEMP_DIR=$(mktemp -d) # Create a temporary directory
      SUB_DIR="$TEMP_DIR/extracted" # Subdirectory for extracted files
      mkdir -p "$SUB_DIR"

      ORIGINAL_NAME=$(basename "$ITEM")
      MODIFIED_FILE="$TEMP_DIR/$ORIGINAL_NAME"

      # Copy and treat the file as .zip
      cp "$ITEM" "$TEMP_DIR/original.zip"
      cd "$SUB_DIR" || exit 1

      # Extract and enforce cleanup
      unzip -qq "$TEMP_DIR/original.zip"
      rm -f "$TEMP_DIR/original.zip" # Remove immediately after extraction
      rm -f "original.zip" # Extra cleanup in case it's accidentally extracted

      # Add the release log
      cp "$REPO_ROOT/$TEMP_LOG_FILE" .

      # Recreate the archive while excluding any `original.zip`
      zip -rq "$MODIFIED_FILE" . -x "original.zip"

      cd "$REPO_ROOT" || exit 1
      mv "$MODIFIED_FILE" "$ITEM" # Move the modified file back to its original path
      rm -rf "$TEMP_DIR" # Clean up the temporary directory
    fi
    zip -r "$DEPLOY_ARCHIVE" "$ITEM"
  done <<< "$DEPLOY_ITEMS"
  # Add the release log itself to the deploy archive
  zip -r "$DEPLOY_ARCHIVE" "$TEMP_LOG_FILE"
fi

# Remove the temporary release log file
rm -f "$TEMP_LOG_FILE"

# Print a message about whether the release log was added to .lpz and .vtz files
if [[ "$EMBED_LOG" == true ]]; then
  echo "**Added release log to .lpz and/or .vtz files in deploy archive**"
else
  echo "**Did not add release log to .lpz/.vtz - to change this invoke with --embed-log-lpz-vtz**"
fi

if [ $? -eq 0 ]; then
  echo "Deploy archive created: $DEPLOY_ARCHIVE"
else
  echo "Failed to create the deploy archive."
  exit 1
fi

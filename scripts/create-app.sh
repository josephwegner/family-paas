#!/bin/bash
set -e

if [ -z "$1" ] || [ -z "$2" ]; then
  echo "Usage: ./scripts/create-app.sh <app-name> <destination-path>"
  echo "After scaffolding, replace the tenant placeholders in app.config.json."
  exit 1
fi

APP_NAME="$1"
DEST="$2"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TEMPLATE_DIR="$SCRIPT_DIR/../templates/new-app"

if [ -d "$DEST" ]; then
  echo "Error: $DEST already exists"
  exit 1
fi

echo "Creating new app: $APP_NAME"
echo "Destination: $DEST"
echo ""

cp -r "$TEMPLATE_DIR" "$DEST"

# Replace APP_NAME placeholder in all files
if [[ "$(uname)" == "Darwin" ]]; then
  find "$DEST" -type f -exec sed -i '' "s/APP_NAME/$APP_NAME/g" {} +
else
  find "$DEST" -type f -exec sed -i "s/APP_NAME/$APP_NAME/g" {} +
fi

echo "App scaffolded at $DEST"
echo ""
echo "Next steps:"
echo "  cd $DEST"
echo "  git init"
echo "  npm install"
echo "  npm run dev"
echo ""
echo "Configure app.config.json from the platform tenant registry, then run:"
echo "  aws sso login --profile <tenant-profile>"
echo "  AWS_PROFILE=<tenant-profile> npm run terraform:init"
echo "  cd terraform && terraform plan && terraform apply"

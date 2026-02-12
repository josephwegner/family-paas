#!/bin/bash
set -e

if [ -z "$1" ] || [ -z "$2" ]; then
  echo "Usage: ./scripts/create-app.sh <app-name> <destination-path>"
  echo "Example: ./scripts/create-app.sh my-cool-app ~/Code/my-cool-app"
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
echo "Don't forget to set GitHub secrets for Terraform CI:"
echo "  gh secret set AWS_ACCESS_KEY_ID --repo josephwegner/$APP_NAME"
echo "  gh secret set AWS_SECRET_ACCESS_KEY --repo josephwegner/$APP_NAME"

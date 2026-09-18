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
FAMILY_PAAS_REF="$(git -C "$SCRIPT_DIR/.." rev-parse HEAD)"

if [ -n "$(git -C "$SCRIPT_DIR/.." status --porcelain -- templates/new-app packages terraform/modules)" ]; then
  echo "Error: platform template or module changes are uncommitted. Commit them before scaffolding so the generated app can pin a valid revision."
  exit 1
fi

if [ -d "$DEST" ]; then
  echo "Error: $DEST already exists"
  exit 1
fi

echo "Creating new app: $APP_NAME"
echo "Destination: $DEST"
echo ""

mkdir -p "$DEST"
rsync -a \
  --exclude '.terraform/' \
  --exclude '*.tfstate' \
  --exclude '*.tfstate.backup' \
  --exclude '*.tfplan' \
  --exclude 'node_modules/' \
  --exclude 'dist/' \
  "$TEMPLATE_DIR/" "$DEST/"

# Pin generated consumers to the exact platform revision used for scaffolding.
if [[ "$(uname)" == "Darwin" ]]; then
  find "$DEST" -type f -exec sed -i '' \
    -e "s/APP_NAME/$APP_NAME/g" \
    -e "s/FAMILY_PAAS_REF/$FAMILY_PAAS_REF/g" {} +
else
  find "$DEST" -type f -exec sed -i \
    -e "s/APP_NAME/$APP_NAME/g" \
    -e "s/FAMILY_PAAS_REF/$FAMILY_PAAS_REF/g" {} +
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

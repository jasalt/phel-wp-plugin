#!/bin/bash

PLUGIN_DIR="/bitnami/phel-wp-plugin"
LOCAL_PHEL_LANG="/bitnami/phel-lang"
VENDOR_PHEL_LANG="vendor/phel-lang"

cd "$PLUGIN_DIR" || { echo "Failed to navigate to $PLUGIN_DIR. Exiting."; exit 1; }

composer install --no-cache

# Check if "local phel-lang" directory exists
if [ -f "${LOCAL_PHEL_LANG}/bin/phel" ]; then
  # Remove existing vendor phel-lang and create a symlink to local src
  rm -rf "${VENDOR_PHEL_LANG}/phel-lang"
  ln -s "$LOCAL_PHEL_LANG" "$VENDOR_PHEL_LANG"
else
  echo "No local phel found, keeping original from composer"
fi

echo "Phel version: " "$($PLUGIN_DIR/vendor/bin/phel -V)"

cd /bitnami/wordpress/wp-content/plugins/phel-wp-plugin || exit
composer install --no-cache

# if "local phel-lang" is not empty
if [ -d "/bitnami/phel-lang" ] && [ "$(ls -A /bitnami/phel-lang 2>/dev/null)" ]; then
  # override vendor phel-lang with symlink pointing to "local phel-lang"
  rm -rf /bitnami/wordpress/wp-content/plugins/phel-wp-plugin/vendor/phel-lang/phel-lang
  ln -s /bitnami/phel-lang /bitnami/wordpress/wp-content/plugins/phel-wp-plugin/vendor/phel-lang/phel-lang
fi

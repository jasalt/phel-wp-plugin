echo "Duplicating the phel-wp-plugin to introduce the bug"

DUPE_PLUGIN_PATH=/bitnami/wordpress/wp-content/plugins/phel-wp-plugin-dupe

cp -rL /bitnami/phel-wp-plugin $DUPE_PLUGIN_PATH

echo "Renaming phel-wp-plugin.php to phel-wp-plugin-dupe.php"
mv $DUPE_PLUGIN_PATH/phel-wp-plugin.php $DUPE_PLUGIN_PATH/phel-wp-plugin-dupe.php

echo "Renaming plugin name in meta data"
sed -i 's/Plugin Name: Phel Demo Plugin/Plugin Name: Phel Demo Plugin DUPE/' \
	$DUPE_PLUGIN_PATH/phel-wp-plugin-dupe.php


# Following results in fatal error

# echo "Activating phel-wp-plugin-dupe"
# wp plugin activate phel-wp-plugin-dupe

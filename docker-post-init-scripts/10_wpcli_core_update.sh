# Updates WP Core, may give some warnings because of current way permissions are set

echo "Checking for WP Core updates"
echo "Don't mind possible warnings regarding to chmod(): Operation not permitted"

wp core update

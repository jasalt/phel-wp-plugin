This folder is mounted inside container at `/docker-entrypoint-init.d` and after container creation all `.sh`, `.sql` and `.php` files here are evaluated.

Docs: https://github.com/bitnami/containers/blob/d8b2e6ce7af0d6f957f98377c08445dd075344c2/bitnami/wordpress/6/debian-12/rootfs/post-init.sh

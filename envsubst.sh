#!/bin/sh
# Entrypoint script for nginx that substitutes environment variables in config template

set -e

# Get LAB_HOST from environment or use default
LAB_HOST="${LAB_HOST:-130.117.95.60}"

# Export for envsubst
export LAB_HOST

# Substitute variables in template and generate nginx.conf
envsubst '${LAB_HOST}' < /etc/nginx/nginx.conf.template > /etc/nginx/nginx.conf

# Execute nginx
exec nginx -g 'daemon off;'
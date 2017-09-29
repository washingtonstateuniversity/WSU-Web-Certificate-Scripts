#!/bin/bash

if [[ ! -z "$1" && "deploy" = $1 ]]; then
  force=0
  if [[ ! -z "$2" && "force" = $2 ]]; then
    force=1
  fi

  # Test the nginx configuration before deploying so that we don't
  # muddy up any existing issues with new config files.
  pre_deploy="$(sudo nginx -t 2>&1 > /dev/null)"

  # A successful nginx test will result in a 131 character long STDERR message.
  if [[ 131 != ${#pre_deploy} ]]; then
    echo $pre_deploy
    echo ""
    echo "Existing nginx configuration has errors. Please correct these or add 'force' to the end of the last command."
    exit 1
  fi

  mv nginx-config/*.conf /etc/nginx/sites-generated/

  # Test the nginx configuration with the new files in place.
  post_deploy="$(sudo nginx -t 2>&1 > /dev/null)"

  # A successful nginx test will result in a 131 character long STDERR message.
  if [[ 131 != ${#post_deploy} ]]; then
    echo $post_deploy
    echo ""
    echo "Post-deploy nginx configuration has errors. Please correct these and reload nginx manually."
    exit 1
  fi

  deploy="$(sudo service nginx reload)"

  echo "Configuration deployed and nginx reloaded."
  exit 0
fi

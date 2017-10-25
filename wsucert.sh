#!/bin/bash
#
# Request certificates through Let's Encrypt:
#   wsucert request domain.wsu.edu
#   wsucert request domain.wsu.edu no-www
#
# Deploy nginx configurations after successful request(s):
#   wsucert deploy
#   wsucert deploy force
#
# Revert nginx configuration after a failed deployment:
#   wsucert revert [backup-filename]
#
# Check an existing certificate's expiration date and issuer:
#   wsucert check web.wsu.edu
#
# Generate a text file containing a list of current domains:
#   wsucert generate domains

if [[ ! -z "$1" && "request" = $1 ]]; then
  domain=$2

  dns=$(dig @8.8.8.8 +short "$domain")
  dns=(${dns[@]})
  dns="${dns[0]}"

  generated=$(date)
  generator=$(whoami)

  if [[ "wsuwp-prod-01.web.wsu.edu." = $dns || "134.121.140.68" = $dns ]]; then
    if [[ ! -z "$3" && "no-www" = "$3" ]]; then
      certbot-auto certonly --webroot -w /var/www/wordpress/ -d $domain
      template="le-cert-no-www.template.conf"
    else
      certbot-auto certonly --webroot -w /var/www/wordpress/ -d $domain -d www.$domain
      template="le-cert.template.conf"
    fi

    mkdir ~/wsucert-nginx-config
    cp /opt/wsucert/templates/$template ~/wsucert-nginx-config/$domain.conf

    sed -i -e "s/WWWDOMAIN/www.$domain/g" ~/wsucert-nginx-config/$domain.conf
    sed -i -e "s/DOMAINS/$domain www.$domain/g" ~/wsucert-nginx-config/$domain.conf

    sed -i -e "s/DOMAIN/$domain/g" ~/wsucert-nginx-config/$domain.conf

    sed -i -e "s/GENERATED/$generated/g" ~/wsucert-nginx-config/$domain.conf
    sed -i -e "s/GENERATOR/$generator/g" ~/wsucert-nginx-config/$domain.conf
  else
    echo "Public DNS records are not ready for certificate authorization."
  fi
elif [[ ! -z "$1" && "deploy" = $1 ]]; then
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

  # Create a backup of the existing nginx configuration for easy reversal.
  timestamp=$(date +%Y%m%d-%H%M)
  sudo tar cpzf ~/nginx-config-back-$timestamp.tar --exclude="cache*" --exclude="ssl*" -C /etc/nginx/ .

  chmod 664 ~/wsucert-nginx-config/*.conf
  sudo chown root:ucadmin ~/wsucert-nginx-config/*.conf
  sudo mv ~/wsucert-nginx-config/*.conf /etc/nginx/sites-generated/

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
elif [[ ! -z "$1" && "revert" = $1 ]]; then
  backup=$2

  sudo rm -rf ~/revert-temp
  mkdir ~/revert-temp
  if [[ ! -z $backup && -f $backup ]]; then
    sudo tar xpf $backup -C ~/revert-temp

    if [[ ! -d "~/revert-temp/sites-generated" || ! -d "~/revert-temp/sites-manual" ]]; then
      echo "Backup file did not contain necessary directories."
      exit 1
    fi
    sudo rm -rf /etc/nginx/sites-generated
    sudo rm -rf /etc/nginx/sites-manual
    sudo cp -fr ~/revert-temp/sites-manual /etc/nginx/
    sudo cp -fr ~/revert-temp/sites-generated /etc/nginx/

    # Test the nginx configuration with the new files in place.
    post_deploy="$(sudo nginx -t 2>&1 > /dev/null)"

    # A successful nginx test will result in a 131 character long STDERR message.
    if [[ 131 != ${#post_deploy} ]]; then
      echo $post_deploy
      echo ""
      echo "Post-revert nginx configuration has errors. Please correct these and reload nginx manually."
      exit 1
    fi

    deploy="$(sudo service nginx reload)"

    echo "Configuration deployed and nginx reloaded."
    exit 0
  else
    echo "Please provide the filename for an existing backup."
    exit 1
  fi
elif [[ ! -z "$1" && "check" = $1 ]]; then
  domain=$2

  if [[ -z "$3" || "date" = $3 ]]; then
    result=$(echo | openssl s_client -showcerts -servername $domain -connect $domain:443 2>/dev/null | openssl x509 -inform pem -noout -dates | grep notAfter)
    result=${result:9}

    echo $domain $result
    exit 0
  elif [[ ! -z "$3" && "issuer" = $3 ]]; then
    result=$(echo | openssl s_client -showcerts -servername $domain -connect $domain:443 2>/dev/null | openssl x509 -inform pem -noout -issuer )
    str=${result/CN*/}
    strpos=${#str}
    strpos=$(( $strpos + 3 ));

    echo $domain ${result:$strpos}
    exit 0
  fi
elif [[ ! -z "$1" && "generate" = $1 ]]; then
    if [[ ! -z "$2" && "domains" = $2 ]]; then
        wp --path=/var/www/wordpress site list --fields=domain --format=csv | sort | uniq -c | awk '{print $2}' > ~/domains.txt
        echo "List of unique domains generated in domains.txt"
        exit 0
    else
        echo "Only domains can be generated at this time."
        exit 1
    fi
else
  echo "This script supports the request, deploy, revert, check, and domains commands."
  exit 1
fi

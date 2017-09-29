domain=$1

dns=$(dig @8.8.8.8 +short "$domain")
dns=(${dns[@]})
dns="${dns[0]}"

if [[ "wsuwp-prod-01.web.wsu.edu." = $dns || "134.121.140.68" = $dns ]]; then
  if [[ ! -z "$2" && "no-www" = "$2" ]]; then
    certbot-auto certonly --webroot -w /var/www/wordpress/ -d $domain
    template="le-cert-no-www.template.conf"
  else
    certbot-auto certonly --webroot -w /var/www/wordpress/ -d $domain -d www.$domain
    template="le-cert.template.conf"
  fi

  cp $template nginx-config/$domain.conf

  sed -i '' -e "s/WWWDOMAIN/www.$domain/g" nginx-config/$domain.conf
  sed -i '' -e "s/DOMAINS/$domain www.$domain/g" nginx-config/$domain.conf

  sed -i '' -e "s/DOMAIN/$domain/g" nginx-config/$domain.conf
else
  echo "Domain not ready"
fi

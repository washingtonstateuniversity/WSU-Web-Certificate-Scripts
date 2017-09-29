domain=$1

if [[ $(dig cname @8.8.8.8 +short "$domain" | grep wsuwp-prod-01 ) ]]; then
  if [[ $(curl -Ls http://"$domain"/cert_status.txt | grep https) ]]; then
    echo "Already configured for HTTPS"
  else
    echo "Certificate required"
    certbot-auto certonly --webroot -w /var/www/wordpress/ -d $domain -d www.$domain
    #certbot-auto certonly --webroot -w /var/www/wordpress/ -d $domain
    cp le-cert.template /home/ucadmin/nginx-deploy/$domain.conf
    sed -i -e "s/WWWDOMAIN/www.$domain/g" /home/ucadmin/nginx-deploy/$domain.conf
    sed -i -e "s/DOMAINS/$domain www.$domain/g" /home/ucadmin/nginx-deploy/$domain.conf
    sed -i -e "s/DOMAIN/$domain/g" /home/ucadmin/nginx-deploy/$domain.conf
  fi
else
  echo "Domain not ready"
fi

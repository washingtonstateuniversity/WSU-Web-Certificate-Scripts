# WSU Web Certificate Scripts

A collection of scripts used to manage HTTPS certificates on WSU servers.

## Request a certificate through Let's Encrypt

The `wsucert request` command will request the required certificates and create a file containing the site's nginx configuration in the `nginx-config/` directory.

* `wsucert request domain.wsu.edu` will request a certificate for `domain.wsu.edu` and `www.domain.wsu.edu`
* `wsucert request domain.wsu.edu no-www` will request a certificate for `domain.wsu.edu` only.

If DNS for the domain is not public, the request to Let's Encrypt will not be made. This decision is made by checking Google's `8.8.8.8` DNS server for current status using `dig`. When DNS is not public, you'll need to re-issue the command to continue checking until the request is successful.

## Deploy new nginx configurations after successful request

Configurations can be deployed with `wsucert deploy` once a Let's Encrypt certificate has been obtained.

This deployment will:

* Test the existing nginx configuration for current errors.
* Make a backup of the full nginx configuration.
* Move the waiting configuration(s) to production.
* Test the new nginx configuration for errors.
* Reload nginx with the new configuration.

If an error is found after deployment, you'll need to make the necessary changes to the configuration manually or revert to the pre-deployment state using `wsucert revert`.

## Revert nginx configuration after a failed deployment:

When `wsucert deploy` is used, a backup of the server's nginx configuration is made in `nginx-config-back-YYYYMMDD-HHMM.tar`. Use `ls` to find the name of this file and then `wsucert revert nginx-config-back-YYYYMMDD-HHMM.tar` to revert to the previous nginx configuration.

This command will test the reverted configuration of nginx before reloading it into production.

## Check a domain's existing certificate expiration date and issuer

This command is purely informative. Typing `wsucert check domain.wsu.edu` or `wsucert check domain.wsu.edu date` will return the domain and the date of its certificate expiration. Typing `wsucert check domain.wsu.edu issuer` will return the issuer of the certificate.

## Generate a text file containing a list of current domains in WordPress

`wsucert generate domains` will create a file `domains.txt` containing a list of unique domains currently configured in WSUWP. This can be used in combination with something like `wsucert check` to check the certificate status of many domains at once.

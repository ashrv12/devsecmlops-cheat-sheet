docker run -it --rm --name certbot \
  -v "$(pwd)/letsencrypt:/etc/letsencrypt" \
  -v "$(pwd)/letsencrypt-lib:/var/lib/letsencrypt" \
  certbot/certbot certonly \
  --manual \
  --preferred-challenges dns \
  -d oktagon.mn
FROM nginx:1.23.4-alpine3.17-slim

COPY settings/default.conf /etc/nginx/conf.d/
WORKDIR /usr/share/nginx/public/
RUN touch /usr/share/nginx/public/index.php

FROM composer:2 AS vendor
WORKDIR /app
COPY . .
RUN composer install --no-dev --no-interaction --optimize-autoloader --ignore-platform-reqs --no-scripts

FROM php:8.2-fpm-alpine
LABEL org.opencontainers.image.source="https://github.com/XYW110/chamilo-lms"
ENV APP_ENV=prod APP_DEBUG=0
RUN apk add --no-cache nginx libzip-dev icu-dev libxml2-dev openldap-dev freetype-dev libjpeg-turbo-dev libpng-dev && mkdir -p /run/nginx
COPY --from=vendor /app /var/www/chamilo
RUN docker-php-ext-configure gd --with-freetype --with-jpeg && docker-php-ext-install -j$(nproc) intl gd pdo_mysql zip bcmath exif pcntl ldap
RUN cp -r /var/www/chamilo/config /var/www/chamilo/config.default && cp -r /var/www/chamilo/var /var/www/chamilo/var.default
RUN mkdir -p /var/www/chamilo/public/uploads /var/log/nginx && touch /var/www/chamilo/.env && chmod -R 777 /var/www/chamilo/var /var/www/chamilo/config /var/www/chamilo/.env /var/www/chamilo/public/uploads /var/www/chamilo/public/build /var/www/chamilo/vendor
RUN rm -f /etc/nginx/conf.d/default.conf /etc/nginx/http.d/default.conf
COPY nginx.conf /etc/nginx/nginx.conf
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
RUN echo "upload_max_filesize=64M" >> /usr/local/etc/php/conf.d/docker-php-ext-chamilo.ini \
 && echo "post_max_size=64M" >> /usr/local/etc/php/conf.d/docker-php-ext-chamilo.ini \
 && echo "memory_limit=256M" >> /usr/local/etc/php/conf.d/docker-php-ext-chamilo.ini \
 && echo "session.auto_start=Off" >> /usr/local/etc/php/conf.d/docker-php-ext-chamilo.ini \
 && echo "short_open_tag=Off" >> /usr/local/etc/php/conf.d/docker-php-ext-chamilo.ini \
 && echo "session.cookie_httponly=On" >> /usr/local/etc/php/conf.d/docker-php-ext-chamilo.ini \
 && echo "display_errors=Off" >> /usr/local/etc/php/conf.d/docker-php-ext-chamilo.ini
WORKDIR /var/www/chamilo
EXPOSE 80
ENTRYPOINT ["/entrypoint.sh"]

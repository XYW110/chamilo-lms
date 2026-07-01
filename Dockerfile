FROM php:8.2-fpm-alpine AS vendor
WORKDIR /tmp
ADD https://getcomposer.org/download/latest-2.x/composer.phar /usr/local/bin/composer
RUN chmod +x /usr/local/bin/composer
WORKDIR /app
COPY . .
RUN composer install --no-dev --no-scripts --no-interaction --optimize-autoloader --ignore-platform-reqs 2>&1 | tail -3

FROM php:8.2-fpm-alpine
LABEL org.opencontainers.image.source="https://github.com/XYW110/chamilo-lms"
RUN apk add --no-cache nginx && mkdir -p /run/nginx
COPY --from=vendor /usr/local/etc/php/ /usr/local/etc/php/
COPY --from=vendor /app /var/www/chamilo
RUN docker-php-ext-install -j$(nproc) pdo_mysql
RUN mkdir -p /var/www/chamilo/var /var/www/chamilo/config /var/www/chamilo/public/uploads /var/log/nginx  && chown -R www-data:www-data /var/www/chamilo/var /var/www/chamilo/config /var/www/chamilo/public/build /var/www/chamilo/vendor /var/www/chamilo/public/uploads  && chmod -R 775 /var/www/chamilo/var /var/www/chamilo/config /var/www/chamilo/public/uploads
RUN rm -f /etc/nginx/conf.d/default.conf /etc/nginx/http.d/default.conf
COPY nginx.conf /etc/nginx/nginx.conf
WORKDIR /var/www/chamilo
EXPOSE 80
CMD ["sh", "-c", "php-fpm -D && nginx -g 'daemon off;'"]

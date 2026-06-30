FROM php:8.2-fpm-alpine AS vendor
WORKDIR /tmp
ADD https://getcomposer.org/download/latest-2.x/composer.phar /usr/local/bin/composer
RUN chmod +x /usr/local/bin/composer
WORKDIR /app
COPY . .
RUN composer install --no-dev --no-scripts --no-interaction --optimize-autoloader --ignore-platform-reqs 2>&1

FROM php:8.2-fpm-alpine
COPY --from=vendor /usr/local/etc/php/ /usr/local/etc/php/
RUN apk add --no-cache libzip-dev icu-dev libxml2-dev openldap-dev freetype-dev libjpeg-turbo-dev libpng-dev autoconf g++ make && docker-php-ext-configure gd --with-freetype --with-jpeg && docker-php-ext-install -j$(nproc) intl gd pdo_mysql zip bcmath exif pcntl opcache xml ldap && pecl install apcu && docker-php-ext-enable apcu && apk del autoconf g++ make && rm -rf /tmp/pear
RUN echo "opcache.memory_consumption=64" >> /usr/local/etc/php/conf.d/chamilo.ini && echo "opcache.max_accelerated_files=10000" >> /usr/local/etc/php/conf.d/chamilo.ini && echo "memory_limit=128M" >> /usr/local/etc/php/conf.d/chamilo.ini && echo "upload_max_filesize=64M" >> /usr/local/etc/php/conf.d/chamilo.ini && echo "post_max_size=64M" >> /usr/local/etc/php/conf.d/chamilo.ini && echo "date.timezone=Asia/Shanghai" >> /usr/local/etc/php/conf.d/chamilo.ini
COPY --from=vendor /app /var/www/chamilo
RUN mkdir -p /var/www/chamilo/var /var/www/chamilo/config /var/www/chamilo/public/uploads && chown -R www-data:www-data /var/www/chamilo/var /var/www/chamilo/config /var/www/chamilo/public/build /var/www/chamilo/vendor /var/www/chamilo/public/uploads && chmod -R 775 /var/www/chamilo/var /var/www/chamilo/config /var/www/chamilo/public/uploads
WORKDIR /var/www/chamilo
EXPOSE 9000
CMD ["php-fpm"]

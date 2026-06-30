FROM composer:2 AS vendor
WORKDIR /app
COPY . .
RUN composer install --no-dev --no-scripts --no-interaction --optimize-autoloader --ignore-platform-reqs

FROM php:8.2-fpm-alpine
LABEL description="Chamilo LMS"
RUN apk add --no-cache libzip-dev icu-dev libxml2-dev openldap-dev freetype-dev libjpeg-turbo-dev libpng-dev autoconf g++ make
RUN docker-php-ext-configure gd --with-freetype --with-jpeg && docker-php-ext-install -j$(nproc) intl gd pdo_mysql zip bcmath exif pcntl opcache xml ldap
RUN pecl install apcu && docker-php-ext-enable apcu && apk del autoconf g++ make && rm -rf /tmp/pear
RUN echo "opcache.memory_consumption=64" > /usr/local/etc/php/conf.d/chamilo.ini && echo "opcache.max_accelerated_files=10000" >> /usr/local/etc/php/conf.d/chamilo.ini && echo "memory_limit=128M" >> /usr/local/etc/php/conf.d/chamilo.ini && echo "upload_max_filesize=64M" >> /usr/local/etc/php/conf.d/chamilo.ini && echo "post_max_size=64M" >> /usr/local/etc/php/conf.d/chamilo.ini && echo "date.timezone=Asia/Shanghai" >> /usr/local/etc/php/conf.d/chamilo.ini
WORKDIR /var/www/chamilo
COPY --from=vendor /app/vendor/ vendor/
COPY --from=vendor /app/src/ src/
COPY --from=vendor /app/public/ public/
COPY --from=vendor /app/config/ config/
COPY --from=vendor /app/bin/ bin/
COPY --from=vendor /app/var/ var/
COPY --from=vendor /app/assets/ assets/
COPY --from=vendor /app/translations/ translations/
COPY --from=vendor /app/composer.json composer.lock ./
COPY --from=vendor /app/.env.dist ./
COPY public/build/ public/build/
RUN mkdir -p var/ config/ public/uploads/ && chown -R www-data:www-data var/ config/ public/build/ vendor/ public/uploads/ && chmod -R 775 var/ config/ public/uploads/
EXPOSE 9000
CMD ["php-fpm"]

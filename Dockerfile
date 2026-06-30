# =============================================================================
# Chamilo LMS - Alpine PHP-FPM 镜像
# 依赖外部：MariaDB / OpenResty / Redis
# =============================================================================

# Stage 1: 前端构建
FROM node:20-alpine AS frontend
WORKDIR /app
COPY package.json yarn.lock .yarnrc.yml ./
RUN yarn install --immutable
COPY assets/ assets/
COPY webpack.config.js vite.config.js ./
RUN yarn build

# Stage 2: Composer 依赖
FROM composer:2 AS vendor
WORKDIR /app
COPY composer.json composer.lock symfony.lock ./
COPY src/ src/
RUN composer install --no-dev --no-scripts --no-interaction --optimize-autoloader

# Stage 3: 运行时 - 仅 ~80MB
FROM php:8.2-fpm-alpine
LABEL description="Chamilo LMS - Alpine PHP-FPM"

RUN set -eux; \
    apk add --no-cache \
        icu-dev gd-dev curl-dev zip-dev \
        libxml2-dev openldap-dev \
        freetype-dev libjpeg-turbo-dev libpng-dev \
        $PHPIZE_DEPS; \
    docker-php-ext-configure gd --with-freetype --with-jpeg; \
    docker-php-ext-install -j$(nproc) \
        intl gd curl zip mbstring xml pdo_mysql ldap exif bcmath opcache; \
    pecl install apcu; \
    docker-php-ext-enable apcu; \
    apk del $PHPIZE_DEPS; \
    rm -rf /tmp/pear

RUN { \
    echo 'opcache.memory_consumption=64'; \
    echo 'opcache.max_accelerated_files=10000'; \
    echo 'opcache.revalidate_freq=2'; \
    echo 'opcache.validate_timestamps=0'; \
    echo 'memory_limit=128M'; \
    echo 'max_execution_time=300'; \
    echo 'upload_max_filesize=64M'; \
    echo 'post_max_size=64M'; \
    echo 'max_input_vars=10000'; \
    echo 'date.timezone=Asia/Shanghai'; \
    echo 'realpath_cache_size=2048K'; \
    echo 'realpath_cache_ttl=600'; \
} > /usr/local/etc/php/conf.d/chamilo.ini

WORKDIR /var/www/chamilo

COPY --from=vendor /app/vendor/ vendor/
COPY --from=frontend /app/public/build/ public/build/
COPY . .

RUN set -eux; \
    mkdir -p var/ config/ public/uploads/; \
    chown -R www-data:www-data var/ config/ public/build/ vendor/ public/uploads/; \
    chmod -R 775 var/ config/ public/uploads/

HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 \
    CMD nc -z 127.0.0.1 9000 || exit 1

EXPOSE 9000
CMD ["php-fpm"]

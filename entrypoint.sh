#!/bin/sh
# 初始化挂载卷：如果配置目录为空，从默认模板复制
if [ -d /var/www/chamilo/config.default ] && [ ! -f /var/www/chamilo/config/bundles.php ]; then
    cp -r /var/www/chamilo/config.default/. /var/www/chamilo/config/
    chmod -R 777 /var/www/chamilo/config/
fi
if [ -d /var/www/chamilo/var.default ] && [ ! -f /var/www/chamilo/var/cache/.gitkeep ]; then
    cp -r /var/www/chamilo/var.default/. /var/www/chamilo/var/
    chmod -R 777 /var/www/chamilo/var/
fi
if [ ! -f /var/www/chamilo/.env ]; then
    cp /var/www/chamilo/.env.dist /var/www/chamilo/.env 2>/dev/null || true
    chmod 777 /var/www/chamilo/.env 2>/dev/null || true
fi
# 启动 PHP-FPM + Nginx
php-fpm -D
nginx -g 'daemon off;'

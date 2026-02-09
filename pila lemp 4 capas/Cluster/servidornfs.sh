#!/bin/bash

apt-get update -qq
apt-get install -y git mariadb-client

#INSTALAR NFS
apt-get install -y nfs-kernel-server

#INSTALAR PHP-FPM + EXTENSIONES
apt-get install -y php-fpm php-mysql php-curl php-gd php-mbstring \
    php-xml php-xmlrpc php-soap php-intl php-zip netcat-openbsd

#CREAR DIRECTORIO COMPARTIDO PARA LA WEB
mkdir -p /var/www/html/webapp
chown -R www-data:www-data /var/www/html/webapp
chmod -R 755 /var/www/html/webapp

#EXPORTS NFS
cat > /etc/exports << 'EOF'
/var/www/html/webapp 192.168.20.11(rw,sync,no_subtree_check,no_root_squash)
/var/www/html/webapp 192.168.20.12(rw,sync,no_subtree_check,no_root_squash)
EOF

exportfs -a
systemctl restart nfs-kernel-server
systemctl enable nfs-kernel-server

#CONFIGURAR PHP-FPM PARA ESCUCHAR EN PUERTO 9000
PHP_VERSION=$(php -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;')
PHP_FPM_CONF="/etc/php/${PHP_VERSION}/fpm/pool.d/www.conf"

sed -i 's|listen = /run/php/php.*-fpm.sock|listen = 9000|' "$PHP_FPM_CONF"
sed -i 's|;listen.allowed_clients.*|listen.allowed_clients = 192.168.20.11,192.168.20.12|' "$PHP_FPM_CONF"

systemctl restart php${PHP_VERSION}-fpm
systemctl enable php${PHP_VERSION}-fpm

sleep 3
echo "PHP-FPM escuchando en:"
netstat -tlnp | grep 9000

#DESCARGAR LA WEB DE LA PRACTICA LAMP
rm -rf /var/www/html/webapp/*
rm -rf /tmp/lamp

echo "Descargando aplicación web..."
git clone https://github.com/josejuansanchez/iaw-practica-lamp.git /tmp/lamp

#Copiar contenido de la app PHP
cp -r /tmp/lamp/src/* /var/www/html/webapp/

#CONFIGURAR CONFIG.PHP CON LAS CREDENCIALES CORRECTAS
cat > /var/www/html/webapp/config.php << 'EOF'
<?php
// Credenciales de base de datos
define('DB_HOST', '192.168.30.10');
define('DB_NAME', 'lamp_db');
define('DB_USER', 'antonio');
define('DB_PASS', '1234');

$mysqli = new mysqli(DB_HOST, DB_USER, DB_PASS, DB_NAME);
$mysqli->set_charset("utf8mb4");
?>
EOF

#Crear info.php para diagnostico
cat > /var/www/html/webapp/info.php << 'EOF'
<?php
phpinfo();
?>
EOF

#AJUSTAR PERMISOS
chown -R www-data:www-data /var/www/html/webapp
chmod -R 755 /var/www/html/webapp

# IMPORTAR LA BASE DE DATOS
echo "Importando estructura de base de datos..."
if [ -f /tmp/lamp/db/database.sql ]; then
    mysql -h 192.168.30.10 -u antonio -p1234 lamp_db < /tmp/lamp/db/database.sql
    echo "Base de datos importada correctamente"
    
    # Verificar que se crearon las tablas
    echo "Tablas creadas:"
    mysql -h 192.168.30.10 -u antonio -p1234 lamp_db -e "SHOW TABLES;"
else
    echo "ERROR: No se encontró el archivo database.sql"
fi

#Limpiar temporales
rm -rf /tmp/lamp

echo "Contenido del directorio webapp:"
ls -lh /var/www/html/webapp/

echo "Configuración de NFS completada correctamente"


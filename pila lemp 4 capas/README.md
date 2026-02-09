# PILA LEMP DE 4 CAPAS

<img width="811" height="510" alt="clienteservidor" src="https://github.com/user-attachments/assets/4ac200dd-ba55-42ff-8f05-b0082488c84a" />

## ÍNDICE
1. INTRODUCCIÓN
2. ARQUITECTURA DE LA INFRAESTRUCTURA
3. CONFIGURACIÓN DE LAS MÁQUINAS
   1. BALANCEADOR
   2. SERVIDORES BACKEND Y NFS
   3. HAPROXY
   4. SERVIDORES MARIADB

## 1. INTRODUCCIÓN 
En esta práctica, se tendrá como objetivo la configuración total de una pila de arquitectura LEMP de 4 capas, con el uso de 1 balanceador de carga con acceso a internet, 2 servidores backend, 1 servidor NFS, un balanceador HaProxy y 2 servidores de Base de Datos con MariaDB. Teniendo en cuenta de que el balanceador es el único que tiene que tener acceso a internet.

## 2. ARQUITECTURA DE LA INFRAESTRUCTURA
La estructura del CMS de 4 capas es el siguiente, 1 balanceador de carga de con acceso a internet utilizando nginx, 2 servidores backend donde hostearan la página web de este trabajo, un servidor NFS el cual sincronizará los 2 servidores backend, un balanceador HaProxy el cual hará que se tengan acceso a los dos servidores de base de datos, y 2 servidores de base de datos con MariaDB donde se almacenaran los datos de la página que se está creando.

<img width="445" height="494" alt="imagen" src="https://github.com/user-attachments/assets/c1072fd9-8ac0-4d25-8255-c47b5e4299e3" />

## 3. CONFIGURACIÓN DE LAS MÁQUINAS

### 3.1. BALANCEADOR

Para la configuración del balanceador, primero hay que actualizar el repositorio de paquetes de Linux, para ello hay que usar el comando ```sudo apt update```, luego se instala el servicio de nginx con el comando ```sudo apt install -y nginx```.
Para entrar en los archivos de configuración, hay que entrar en la ruta ```/etc/nginx/sites-avalibles``` y desde ahí hacer una copia de la configuración por defecto (archivo default) con el comando ```sudo cp default cluster```. Ahora se entra en el archivo nuevo creado, y poner lo mismo de la imagen:
<img width="801" height="814" alt="imagen" src="https://github.com/user-attachments/assets/e76195d8-84d4-4a46-a233-49f8432b13c1" />

Con los comandos ```ln -sf /etc/nginx/sites-available/webapp /etc/nginx/sites-enabled/```y ```rm -f /etc/nginx/sites-enabled/default```se selecciona la configuración que se quiere enseñar y borrar la que está por defecto.

### 3.2. SERVIDORES BACKEND
Para la configuación de los servidores backend se hacen primero hay que actualizar el repositorio de paquetes de Linux, para ello hay que usar el comando ```sudo apt update```, luego se instala el servicio de nginx y la aplicación cliente del servidor nfs con el comando ```sudo apt install -y nginx nfs-common```.
Primero se configurará la aplicación cliente del servicio NFS, donde se creará primero una carpeta en donde se encontrará nuestra aplicación web. Para ello, se hará con el comando ```mkdir -p /var/www/html/webapp```. Luego se montará la carpeta con el comando ```mount -t nfs 192.168.20.10:/var/www/html/webapp /var/www/html/webapp```siendo la dirección IP del servidor NFS.
Para entrar en los archivos de configuración, hay que entrar en la ruta ```/etc/nginx/sites-avalibles``` y desde ahí hacer una copia de la configuración por defecto (archivo default) con el comando ```sudo cp default cluster```. Ahora se entra en el archivo nuevo creado, y poner lo mismo de la imagen:
<img width="929" height="637" alt="imagen" src="https://github.com/user-attachments/assets/d47456a7-c3f5-4a2f-ae64-c907820013d8" />
Con los comandos ```ln -sf /etc/nginx/sites-available/webapp /etc/nginx/sites-enabled/```y ```rm -f /etc/nginx/sites-enabled/default```se selecciona la configuración que se quiere enseñar y borrar la que está por defecto y se reinicia con el comando ```sudo systemctl restart nginx```y se verifica que funciona bien con ```sudo systemctl status nginx```
Esto se repetirá 2 veces ya que la idea es que los servidores hagan lo mismo.

### 3.3. SERVIDOR NFS
Para el servidor NFS, se hará primero el comando ```sudo apt update```para actualizar el repositorio de paquetes de Linux. Luego con el comando ```sudo apt install git mariadb-client nfs-kernel-server``` se instalará un cliente de MariaDB, el servicio de NFS y una conexión con git hub para la descarga de un archivo php. Luego, con el comando ```sudo apt install php-fpm php-mysql php-curl php-gd php-mbstring php-xml php-xmlrpc php-soap php-intl php-zip netcat-openbsd```se instalará todas las herramientas para el interprete de php.
A continuación, se creará la carpeta compartida con las máquinas backend para subir la aplicación web a la vez. Con los comandos ```sudo mkdir -p /var/www/html/webapp```, ```chown -R www-data:www-data /var/www/html/webapp```y ```chmod -R 755 /var/www/html/webapp```para la creación, asignar dueño y grupo y asignar permisos a la carpeta que se va a tener sincronizada con los servidores backend.

Por último, para acabar con el servicio de NFS, se tiene que entrar en el archivo de configuración con ```sudo nano /etc/exports/``` y aplicar el siguiente código:
```
/var/www/html/webapp 192.168.20.11(rw,sync,no_subtree_check,no_root_squash)
/var/www/html/webapp 192.168.20.12(rw,sync,no_subtree_check,no_root_squash)

```
Siendo las direcciones IP las de los servidores Backend.

Por último, con este script, se configurará el PHP para la página web:

```
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
```
### 3.4. HAPROXY

Para la configuración del balanceador HaProxy, primero se tiene usar el comando ```sudo apt update```para actualizar el repositorio de paquetes de Linux. Luego con el comando ```sudo apt install haproxy -y``` para la instalación del servicio.
Luego hay que acceder al directorio ```/etc/haproxy/``` donde se encontrará el archivo de configuración del balanceador. Para entrar, solo hay que escribir el comando ```sudo nano haproxy.cfg```y escribir lo siguiente:

```
    log global
    mode tcp
    option tcplog
    option dontlognull
    timeout connect 10s
    timeout client 1h
    timeout server 1h

# Frontend para MariaDB (puerto 3306)
# Escucha en TODAS las interfaces para recibir conexiones desde cualquier red
frontend mariadb_frontend
    bind *:3306
    mode tcp
    default_backend mariadb_backend

# Backend con los nodos del cluster Galera
backend mariadb_backend
    mode tcp
    balance roundrobin
    option tcp-check

    # Health check mas permisivo
    tcp-check connect

    server database1antonio 192.168.40.11:3306 check inter 5s rise 2 fall 3
    server database2antonio 192.168.40.12:3306 check inter 5s rise 2 fall 3

# Estadisticas de HAProxy
listen stats
    bind *:8080
    mode http
    stats enable
    stats uri /stats
    stats refresh 10s
    stats admin if TRUE
    stats auth admin:admin
```

Luego se usa el comando ```systemctl enable haproxy```, ```systemctl restart haproxy``` para iniciar el servicio, y luego ```systemctl status haproxy```para verificar que funciona correctamente.

### 3.5. SERVIDORES MARIADB
Para la configuración las máquinas de MariaDB, primero se tiene usar el comando ```sudo apt update```para actualizar el repositorio de paquetes de Linux. Luego con el comando ```sudo apt install mariadb-server mariadb-client galera-4 rsync -y``` para la instalación del servicio. Una vez echo esto hay que parar el servicio de MariaDB con el comando ```sudo systemctl stop mariadb.services```.
Luego hay que entrar en el directorio ```/etc/mysql/mariadb.conf.d/``` y en el archivo 60-galera.cnf, se escribe lo siguiente:

<img width="753" height="478" alt="imagen" src="https://github.com/user-attachments/assets/cb30978b-38ba-4857-bb2e-5749877a760f" />

Luego con el comando ```sudo galera_new_cluster``` se crea el cluster nuevo, y se arrancan los servicio de MariaDB con ```sudo systemctl start mariadb.services```. Esta configuración hay que repetirla en el otro servidor de MariaDB.

Al final, con este script se creará una base de datos para verificar que el cluster funciona correctamente:

```
mysql << 'EOSQL'
-- Crear base de datos
CREATE DATABASE IF NOT EXISTS lamp_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- Crear usuario para la aplicacion
CREATE USER IF NOT EXISTS 'antonio'@'%' IDENTIFIED BY '1234';
GRANT ALL PRIVILEGES ON lamp_db.* TO 'antonio'@'%';

-- Usuario para health checks de HAProxy 
CREATE USER IF NOT EXISTS 'haproxy'@'%' IDENTIFIED BY '';
GRANT USAGE ON *.* TO 'haproxy'@'%';

-- Crear usuario root remoto para administracion
CREATE USER IF NOT EXISTS 'root'@'%' IDENTIFIED BY 'root';
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION;

FLUSH PRIVILEGES;

-- Verificar usuarios creados
SELECT User, Host FROM mysql.user WHERE User IN ('antonio', 'haproxy', 'root');
EOSQL

```


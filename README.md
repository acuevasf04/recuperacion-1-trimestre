# PILA LEMP DE 4 CAPAS

<img width=800 height=800 src=https://github.com/user-attachments/assets/a05195ea-a5bf-4ba9-81a2-32b3757cef2d/>

## ÍNDICE

1. INTRODUCCIÓN
2. ARQUITECTURA DE LA INFRAESTRUCTURA
3. CONFIGURACIÓN DE LAS MÁQUINAS
   1. BALANCEADOR
   2. SERVIDORES BACKEND Y NFS
   3. HAPROXY
   4. SERVIDORES MARIADB

## 1. INTRODUCCIÓN

El presente proyecto detalla el diseño, despliegue y configuración de una infraestructura web de alta disponibilidad basada en una pila LEMP (Linux, Nginx, MariaDB, PHP) distribuida en cuatro capas diferenciadas. El objetivo principal es implementar un entorno robusto y escalable que elimine puntos únicos de fallo y segmente las responsabilidades del sistema para mejorar tanto el rendimiento como la seguridad.

## 2. ARQUITECTURA DE LA INFRAESTRUCTURA. 

En la arquitectura de la red de este proyecto, conformará de 7 servidores que abastecerán nuestro servicio.

1. Balanceador

El balanceador usando el software de Nginx, "repartirá" las solicitudes que llegan a la infraestructura y las distribuye a los servidores backend a los que está conectado. El balanceador de cargas distribuirá las solicitudes usando el algoritmo de Round Robin.

2. Servidores Backend

Los servidores backend de la infraestructura es donde se alojará la aplicación web que se va a lanzar.

3. Servidor NFS

El servidor NFS (Network File System) es un servidor el cual compartirá los archivos a los servidores web de manera sincronizada. A parte, aquí se alojará nuestro interprete de PHP para la ejecución de los programas PHP.

4. Servidor HaProxy

El servidor HaProxy es un balanceador de carga el cual redistribuye las solicitudes entre los servidores de base de datos, en este caso son 2 servidores.

5. Servidores MariaDB

Los servidores MariaDB sirven para alojar todos los datos que se van a generar en nuestra página web.

<img width="545" height="732" alt="arquitectura" src="https://github.com/user-attachments/assets/3def6543-99a0-4334-b133-635158af90ce" />

## 3. CONFIGURACIÓN DE LAS MÁQUINAS
En este apartado se explicará como se configuran las máquinas de la red.

#### 1. BALANCEADOR

Para la configuración del balanceador, hay que seguir los siguientes pasos:

1. Instalación del servicio: Para instalar el servicio, primero hay que egecutar el comando ```sudo apt update && sudo apt upgrade -y```esto hará que los repositorios de la distrubición que se haya instalado, en este caso Debian, se actualicen y luego se actualicen los programas que estén instalados.
2. Con el comando ```sudo apt install nginx -y``` haciendo que se instale nginx en el sistema.
3. Luego hay que acceder a los archivos de nginx que se encuentran en el directorio ```/etc/nginx/sites-avalibles```. Este es donde se encuentran los archivos de configuración de Nginx.
4. Con el comando ```sudo cp default balancer``` creamos un archivo de configuración Nginx para el balanceador.
5. Con la copia se configura el balanceador, asignando las direcciones IP de cada servidor backend.
6. Una vez configurado el archivo de configuración de Nginx se ejecutarán los comandos ```sudo ln -sf /etc/nginx/sites-available/balancer /etc/nginx/sites-enabled/``` que habilita la configuración que se acaba de hacer, y el comando ```sudo rm -f /etc/nginx/sites-enabled/default``` que elimina el archivo de configuración de Nginx por defecto.
7. Para terminar, se ejecutan los comandos ```sudo systemctl restart nginx``` para reiniciar el servicio, y el comando ```sudo systemctl status nginx``` para berificar que el servicio Nginx funciona correctamente.
### Explicación de la configuración.

En este apartado se explicará como fuciona el archivo de configuración.

En el primer apartado, en esta sección:

```
upstream backend_servers {
    server 192.168.20.11:80 max_fails=3 fail_timeout=30s;
    server 192.168.20.12:80 max_fails=3 fail_timeout=30s;
}
```
Se está proporcionando los servidores backend de la red con su dirección IP de cada uno, el puerto por donde escucha las peticiones, y la cantidad de fallos que permite el balanceador para poder entrar en el servidor backend y el tiempo de espera que le da.

El apartado:

```
    location / {
        proxy_pass http://backend_servers;
        
        # Headers para mantener informacion del cliente
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
```
Este bloque de código es el "cerebro" del Balanceador de Carga. Su función es gestionar cómo se reenvían las peticiones de los usuarios hacia los servidores backend y asegurar que la comunicación no se pierda.
```
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
```
En la parte de la "Información del Cliente", $host Le dice al backend qué dominio está visitando el usuario (útil si tienes varias webs), $remote_addr le entrega al backend la dirección IP real de la persona que está navegando, X-Forwarded-For mantiene un historial de todas las IPs por las que ha pasado la conexión y X-Forwarded-Proto le avisa al backend si el usuario entró por http o https.

```
proxy_connect_timeout 60s;
proxy_send_timeout 60s;
proxy_read_timeout 60s;
```
Establecen un límite de 60 segundos para conectar, enviar o leer datos de los servidores backend. Si el backend tarda más de un minuto en responder, el balanceador cortará la conexión y dará un error al usuario.

Por último:

```
    # Health check endpoint (opcional)
    location /nginx-health {
        access_log off;
        return 200 "healthy\n";
        add_header Content-Type text/plain;
    }
```
Este bloque de configuración es un punto de verificación de salud. Su propósito es ofrecer una forma rápida y automática de saber si el servidor Nginx está vivo y respondiendo correctamente, sin interferir con el tráfico normal de la web.

<img width="801" height="814" alt="imagen" src="https://github.com/user-attachments/assets/e76195d8-84d4-4a46-a233-49f8432b13c1" />


#### 2. SERVIDORES BACKEND

Para la instalación de los Servidores Backend se seguirán los siguientes pasos:
1. Instalación del servicio: Para instalar el servicio, primero hay que egecutar el comando ```sudo apt update && sudo apt upgrade -y```esto hará que los repositorios de la distrubición que se haya instalado, en este caso Debian, se actualicen y luego se actualicen los programas que estén instalados.
2. Con el comando ```sudo apt install nginx nfs-commons -y``` haciendo que se instale nginx en el sistema.
3. Luego hay que acceder a los archivos de nginx que se encuentran en el directorio ```/etc/nginx/sites-avalibles```. Este es donde se encuentran los archivos de configuración de Nginx.
4. Con el comando ```sudo cp default balancer``` creamos un archivo de configuración Nginx para el balanceador.
5. Con la copia se configura el balanceador, asignando las direcciones IP de cada servidor backend.
6. Una vez configurado el archivo de configuración de Nginx se ejecutarán los comandos ```sudo ln -sf /etc/nginx/sites-available/balancer /etc/nginx/sites-enabled/``` que habilita la configuración que se acaba de hacer, y el comando ```sudo rm -f /etc/nginx/sites-enabled/default``` que elimina el archivo de configuración de Nginx por defecto.
7. Para terminar, se ejecutan los comandos ```sudo systemctl restart nginx``` para reiniciar el servicio, y el comando ```sudo systemctl status nginx``` para berificar que el servicio Nginx funciona correctamente.
8. Para el montaje del servicio NFS, se tiene que ejecutar el comando ```sudo mount -t nfs 192.168.20.10:/var/www/html/webapp /var/www/html/webapp```, que monta la carpeta compartida con el servidor NFS.
### Explicacion de la configuración.

En este apartado se explicará como fuciona el archivo de configuración.
```
    listen 80;
    server_name _;
    
    root /var/www/html/webapp;
    index index.php index.html index.htm;
```
En esta parte del archivo de configuración de Nginx hace que el servidor escuche a través del puerto 80 por el protocolo HTTP. El ```server_name``` indica que este bloque de configuración responderá a cualquier nombre de dominio o dirección IP que llegue al servidor. ```root /var/www/html/webapp;``` indica a Nginx la carpeta física en el disco duro donde están guardados los archivos de tu sitio web. 

```
    access_log /var/log/nginx/access.log;
    error_log /var/log/nginx/error.log;
    
    location / {
        try_files $uri $uri/ /index.php?$args;
    }
```
En este archivo la sección ```access_log /var/log/nginx/access.log``` registra cada visita, guarda la IP del usuario, qué página pidió, a qué hora y si la carga fue exitosa o no. <br>
La línea de ```error_log /var/log/nginx/error.log``` registra solo los fallos. Si un archivo no existe, si hay un problema de permisos o si el servidor PHP está caído, los detalles aparecerán aquí para que puedas arreglarlo. <br>
El bloque de ```location /``` define qué debe hacer Nginx con cualquier petición que llegue a la raíz del sitio. ```try_files``` funciona como un sistema de "último recurso" que intenta tres cosas en este orden exacto, ```$uri``` primero busca si existe un archivo real con ese nombre, ```$uri /```si no es un archivo, busca si existe una carpeta con ese nombre y ```/index.php?$args;``` si no encontró ni un archivo ni una carpeta, se rinde y le pasa la bola a PHP.

```
    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass 192.168.20.10:9000;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include fastcgi_params;
    }
    
    location ~ /\.ht {
        deny all;
    }
```
En el bloque de ```location ~ \.php$``` Esta línea usa una expresión regular (el símbolo ~) para decirle a Nginx: "cualquier archivo que termine en .php, trátalo con estas reglas". <br>
La línea de ```include snippets/fastcgi-php.conf``` hace que cargue una configuración estándar que ayuda a Nginx a entender cómo pasar archivos PHP de forma segura. <br>
La línea de ```fastcgi_pass 192.168.20.10:9000;``` le dice a Nginx que el interprete de PHP no se encuentra en un servidor externo, en este caso en el servidor NFS y PHP, proporcionando la dirección IP y el puerto por donde escucha las peticiones y ```fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name``` es una etiqueta de envío la cual le dice a Nginx en que carpeta se encuentra los programas de PHP. <br>
En la línea de ``` include fastcgi_params``` incluye una lista de variables necesarias para que PHP entienda cosas como la dirección IP del visitante.

Por último, en el bloque de ```location ~ /\.ht``` una medida de protección para servidores que vienen de entornos Apache o que tienen archivos de configuración sensibles y hace que no permita el acceso a archivos que no sean ```.ht```.

<img width="929" height="637" alt="imagen" src="https://github.com/user-attachments/assets/d47456a7-c3f5-4a2f-ae64-c907820013d8" />

#### 3. SERVIDOR NFS Y PHP

Para la instalación y configuración de los servicios NFS y PHP con los siguientes pasos.

1.  Instalación del servicio: Para instalar el servicio, primero hay que egecutar el comando ```sudo apt update && sudo apt upgrade -y```esto hará que los repositorios de la distrubición que se haya instalado, en este caso Debian, se actualicen y luego se actualicen los programas que estén instalados.
2.  Con el comando ```sudo apt install nfsnfs-kernel-server php-fpm php-mysql php-curl php-gd php-mbstring \ php-xml php-xmlrpc php-soap php-intl php-zip netcat-openbsd -y``` para la instalación de los servicios de NFS y el interprete de PHP.
3.  Ahora se tiene que crear la carpeta con el comando ```sudo mkdir -p /var/www/html/webapp``` y se le cambia de dueño con el comando ```sudo chown -R www-data:www-data /var/www/html/webapp``` y cambia los permisos con el comando ```sudo chmod -R 755 /var/www/html/webapp``` haciendo que el dueño de la carpeta tenga control absoluto y el grupo y los usuarios ajenos a la carpeta tengan permisos de lectura y ejecución.
4.  Una vez realizado esto, añades en el archivo ```/etc/exports``` las siguientes líneas: ```/var/www/html/webapp 192.168.20.11(rw,sync,no_subtree_check,no_root_squash)``` y ```/var/www/html/webapp 192.168.20.12(rw,sync,no_subtree_check,no_root_squash)``` para decir que servidores son a los que tienen que ir asociados.
5.  Se reiniciará el servidor con el comando ```systemctl restart nfs-kernel-server``` y se verá el estado del servicio con el comando ```systemctl status nfs-kernel-server``` para comprobar el estado del servicio.
6.  Para que el servicio PHP-FPM pueda escuchar por el puerto 9000, el cual tienes que ejcutar el siguiente comando para que se pueda escuchar por ese puerto.
```
PHP_VERSION=$(php -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;')
PHP_FPM_CONF="/etc/php/${PHP_VERSION}/fpm/pool.d/www.conf"

sed -i 's|listen = /run/php/php.*-fpm.sock|listen = 9000|' "$PHP_FPM_CONF"
sed -i 's|;listen.allowed_clients.*|listen.allowed_clients = 192.168.20.11,192.168.20.12|' "$PHP_FPM_CONF"
```
Este fragmento de script hace que se configure el puerto 9000. Definiendo la versión del interprete de PHP. También se define una ruta para la configuración del servicio FPM de PHP. Y permite solo a los dos servidores backend de la red. <br>
Por último, con el siguiente código de PHP, se conectará a la base de datos:
```
<?php
define('DB_HOST', '192.168.30.10');
define('DB_NAME', 'lamp_db');
define('DB_USER', 'antonio');
define('DB_PASS', '1234');
```
En este código se define el servidor host para proporcionarnos los datos ```define('DB_HOST', '192.168.30.10');``` en este caso es el balanceador haproxy, la base de datos que va a usar ```define('DB_NAME', 'lamp_db');``` y el usuario y contraseña de quien administra esa base de datos. ```define('DB_USER', 'antonio');``` ```define('DB_PASS', '1234');```.
#### 4. SERVIDOR HAPROXY

Para la instalación y configuración del servicio de Haproxy con los siguientes pasos:
1. Instalación del servicio: Para instalar el servicio, primero hay que egecutar el comando ```sudo apt update && sudo apt upgrade -y```esto hará que los repositorios de la distrubición que se haya instalado, en este caso Debian, se actualicen y luego se actualicen los programas que estén instalados.
2. Con el comando ```sudo apt install haproxy -y``` se instala el servicio de Haproxy.
3. Para la configuración del servicio hay que usar el comando ```sudo nano /etc/haproxy/haproxy.cfg``` el cual es el archivo de configuración del servicio.


#### 5. SERVIDORES MARIADB
1. Instalación del servicio: Para instalar el servicio, primero hay que egecutar el comando ```sudo apt update && sudo apt upgrade -y```esto hará que los repositorios de la distrubición que se haya instalado, en este caso Debian, se actualicen y luego se actualicen los programas que estén instalados.
2. Con el comando ```sudo apt install mariadb-server mariadb-client galera-4 rsync -y``` para la instalación de la base de datos, y el software para la configuración del cluster.
3. Se le quitará la conexión a internet con el comando ```sudo ip route del default```. Esto es una solución temporal para quitar la conextión a internet, si quiere quitar el internet a una máquina permanentemente se tiene que comentar la linea del Gateway en el archivo ```/etc/network/interfaces```.
4. Ahora se para el servicio de MariaDB con el comando ```sudo systemctl stop mariadb```, y se accede al archivo de configuración del cluster con el comando ```sudo nano /etc/mysql/mariadb.conf.d/60-galera.cnf```
5. Y se configura con la siguiente disposición de la captura que sale a continuación:
<img width="753" height="478" alt="imagen" src="https://github.com/user-attachments/assets/cb30978b-38ba-4857-bb2e-5749877a760f" />

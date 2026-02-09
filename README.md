# PILA LEMP DE 4 CAPAS

<img width=800 height=800 src=https://github.com/user-attachments/assets/a05195ea-a5bf-4ba9-81a2-32b3757cef2d />

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

1. BALANCEADOR

Para la configuración del balanceador, hay que seguir los siguientes pasos:

1. Instalación del servicio: Para instalar el servicio, primero hay que egecutar el comando ```sudo apt update && sudo apt upgrade -y```esto hará que los repositorios de la distrubición que se haya instalado, en este caso Debian, se actualicen y luego se actualicen los programas que estén instalados.
2. Con el comando ```sudo apt install nginx -y``` haciendo que se instale nginx en el sistema.
3. Luego hay que acceder a los archivos de nginx que se encuentran en el directorio ```/etc/nginx/sites-avalibles```. Este es donde se encuentran los archivos de configuración de Nginx.
4. Con el comando ```sudo cp default balancer``` creamos un archivo de configuración Nginx para el balanceador.
5. Con la copia se configura el balanceador, asignando las direcciones IP de cada servidor backend.
6. Una vez configurado el archivo de configuración de Nginx se ejecutarán los comandos ```sudo ln -sf /etc/nginx/sites-available/balancer /etc/nginx/sites-enabled/``` que habilita la configuración que se acaba de hacer, y el comando ```sudo rm -f /etc/nginx/sites-enabled/default``` que elimina el archivo de configuración de Nginx por defecto.
7. Para terminar, se ejecutan los comandos ```sudo systemctl restart nginx``` para reiniciar el servicio, y el comando ```sudo systemctl status nginx``` para berificar que el servicio Nginx funciona correctamente.
8. Explicacion de la configuración.

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

La sección:

```
proxy_connect_timeout 60s;
proxy_send_timeout 60s;
proxy_read_timeout 60s;
```
Establecen un límite de 60 segundos para conectar, enviar o leer datos de los servidores backend. Si el backend tarda más de un minuto en responder, el balanceador cortará la conexión y dará un error al usuario.

<img width="801" height="814" alt="imagen" src="https://github.com/user-attachments/assets/e76195d8-84d4-4a46-a233-49f8432b13c1" />






2. SERVIDORES BACKEND

3. SERVIDOR NFS Y PHP

4. SERVIDOR HAPROXY

5. SERVIDORES MARIADB

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



2. SERVIDORES BACKEND

3. SERVIDOR NFS Y PHP

4. SERVIDOR HAPROXY

5. SERVIDORES MARIADB

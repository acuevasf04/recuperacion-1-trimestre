#!/bin/bash
set -e

#Actualizar sistema
apt-get update -qq

#Instalar MariaDB Server y Galera
DEBIAN_FRONTEND=noninteractive apt-get install -y mariadb-server mariadb-client galera-4 rsync

#Detener MariaDB para configurar Galera
systemctl stop mariadb

#Configurar Galera Cluster
cat > /etc/mysql/mariadb.conf.d/60-galera.cnf << 'EOF'
[mysqld]
binlog_format=ROW
default-storage-engine=innodb
innodb_autoinc_lock_mode=2
bind-address=0.0.0.0

# Galera Provider Configuration
wsrep_on=ON
wsrep_provider=/usr/lib/galera/libgalera_smm.so

# Galera Cluster Configuration
wsrep_cluster_name="galera_cluster"
wsrep_cluster_address="gcomm://192.168.40.11,192.168.40.12"

# Galera Synchronization Configuration
wsrep_sst_method=rsync

# Galera Node Configuration
wsrep_node_address="192.168.40.12"
wsrep_node_name="database2antonio"
EOF

#Iniciar MariaDB 
systemctl start mariadb

# Verificar estado
systemctl status mariadb --no-pager

#Habilitar MariaDB en el arranque
systemctl enable mariadb

# Mostrar estado del cluster
mysql -e "SHOW STATUS LIKE 'wsrep_%';" 2>/dev/null | grep -E "(wsrep_cluster_size|wsrep_cluster_status|wsrep_ready|wsrep_connected)"

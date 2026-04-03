#!/bin/bash
set -e

echo "Waiting for master to be ready..."
until mysql -h"${MYSQL_MASTER_HOST}" -P"${MYSQL_MASTER_PORT}" -u"${MYSQL_REPLICATION_USER}" -p"${MYSQL_REPLICATION_PASSWORD}" -e "SELECT 1" >/dev/null 2>&1; do
  sleep 2
done

echo "Configuring replica to connect to master..."

# Get master log file and position
MASTER_STATUS=$(mysql -h"${MYSQL_MASTER_HOST}" -P"${MYSQL_MASTER_PORT}" -u"${MYSQL_REPLICATION_USER}" -p"${MYSQL_REPLICATION_PASSWORD}" -e "SHOW MASTER STATUS\G")
MASTER_LOG_FILE=$(echo "${MASTER_STATUS}" | grep "File:" | awk '{print $2}')
MASTER_LOG_POS=$(echo "${MASTER_STATUS}" | grep "Position:" | awk '{print $2}')

echo "Master log file: ${MASTER_LOG_FILE}, position: ${MASTER_LOG_POS}"

# Configure replication
mysql -u root -p"${MYSQL_ROOT_PASSWORD}" <<-EOSQL
    STOP SLAVE;
    CHANGE MASTER TO
        MASTER_HOST='${MYSQL_MASTER_HOST}',
        MASTER_PORT=${MYSQL_MASTER_PORT},
        MASTER_USER='${MYSQL_REPLICATION_USER}',
        MASTER_PASSWORD='${MYSQL_REPLICATION_PASSWORD}',
        MASTER_LOG_FILE='${MASTER_LOG_FILE}',
        MASTER_LOG_POS=${MASTER_LOG_POS};
    START SLAVE;
EOSQL

echo "Replica initialization complete."

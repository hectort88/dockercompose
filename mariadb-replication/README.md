# MariaDB Replication Setup

This Docker Compose configuration sets up MariaDB with one master and two read replicas.

## Architecture

- **mariadb-master**: Master database (port 3306)
- **mariadb-replica1**: First read replica (port 3307)
- **mariadb-replica2**: Second read replica (port 3308)

## Configuration

All configuration is managed through environment variables in the `.env` file.

### Environment Variables

Copy `.env.example` to `.env` and customize as needed:

```bash
cp .env.example .env
```

**Available variables:**

- `MYSQL_ROOT_PASSWORD` - Root password for all MariaDB instances
- `MYSQL_DATABASE` - Default database to create
- `MYSQL_USER` - Application user username
- `MYSQL_PASSWORD` - Application user password
- `MYSQL_REPLICATION_USER` - Replication user username
- `MYSQL_REPLICATION_PASSWORD` - Replication user password
- `MARIADB_MASTER_PORT` - Host port for master (default: 3306)
- `MARIADB_REPLICA1_PORT` - Host port for replica1 (default: 3307)
- `MARIADB_REPLICA2_PORT` - Host port for replica2 (default: 3308)
- `MARIADB_MASTER_SERVER_ID` - Unique server ID for master (default: 1)
- `MARIADB_REPLICA1_SERVER_ID` - Unique server ID for replica1 (default: 2)
- `MARIADB_REPLICA2_SERVER_ID` - Unique server ID for replica2 (default: 3)

**Default credentials:**
- Root Password: `rootpassword`
- Database: `mydb`
- User: `user` / Password: `userpassword`
- Replication User: `repl_user` / Password: `repl_password`

## Usage

### Start the cluster

```bash
docker-compose up -d
```

### Check service status

```bash
docker-compose ps
```

### View logs

```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f mariadb-master
docker-compose logs -f mariadb-replica1
docker-compose logs -f mariadb-replica2
```

### Verify replication status

Check replica status on replica1:
```bash
docker exec -it mariadb-replica1 mysql -uroot -p${MYSQL_ROOT_PASSWORD} -e "SHOW SLAVE STATUS\G"
```

Check replica status on replica2:
```bash
docker exec -it mariadb-replica2 mysql -uroot -p${MYSQL_ROOT_PASSWORD} -e "SHOW SLAVE STATUS\G"
```

Look for:
- `Slave_IO_Running: Yes`
- `Slave_SQL_Running: Yes`
- `Seconds_Behind_Master: 0` (or small number)

### Test replication

1. Connect to master and create a test table:
```bash
docker exec -it mariadb-master mysql -uroot -p${MYSQL_ROOT_PASSWORD} -e "
USE ${MYSQL_DATABASE};
CREATE TABLE IF NOT EXISTS test (id INT PRIMARY KEY, name VARCHAR(50));
INSERT INTO test VALUES (1, 'test from master');
SELECT * FROM test;
"
```

2. Check if data replicated to replica1:
```bash
docker exec -it mariadb-replica1 mysql -uroot -p${MYSQL_ROOT_PASSWORD} -e "
USE ${MYSQL_DATABASE};
SELECT * FROM test;
"
```

3. Check if data replicated to replica2:
```bash
docker exec -it mariadb-replica2 mysql -uroot -p${MYSQL_ROOT_PASSWORD} -e "
USE ${MYSQL_DATABASE};
SELECT * FROM test;
"
```

### Connect to databases

**Master (read/write):**
```bash
# From host
mysql -h127.0.0.1 -P${MARIADB_MASTER_PORT} -u${MYSQL_USER} -p${MYSQL_PASSWORD} ${MYSQL_DATABASE}

# Using Docker
docker exec -it mariadb-master mysql -u${MYSQL_USER} -p${MYSQL_PASSWORD} ${MYSQL_DATABASE}
```

**Replica 1 (read-only):**
```bash
# From host
mysql -h127.0.0.1 -P${MARIADB_REPLICA1_PORT} -u${MYSQL_USER} -p${MYSQL_PASSWORD} ${MYSQL_DATABASE}

# Using Docker
docker exec -it mariadb-replica1 mysql -u${MYSQL_USER} -p${MYSQL_PASSWORD} ${MYSQL_DATABASE}
```

**Replica 2 (read-only):**
```bash
# From host
mysql -h127.0.0.1 -P${MARIADB_REPLICA2_PORT} -u${MYSQL_USER} -p${MYSQL_PASSWORD} ${MYSQL_DATABASE}

# Using Docker
docker exec -it mariadb-replica2 mysql -u${MYSQL_USER} -p${MYSQL_PASSWORD} ${MYSQL_DATABASE}
```

### Stop the cluster

```bash
docker-compose down
```

### Stop and remove volumes (WARNING: deletes all data)

```bash
docker-compose down -v
```

## Notes

- Replicas are configured with `read-only=1`, preventing direct writes
- All write operations should be performed on the master
- Replication uses binary log format ROW for better consistency
- Each server has a unique server-id (master=1, replica1=2, replica2=3)
- Persistent data is stored in Docker volumes
- The replicas wait for the master to be healthy before starting

## Troubleshooting

If replication is not working:

1. Check if all containers are running:
```bash
docker-compose ps
```

2. Check logs for errors:
```bash
docker-compose logs
```

3. Verify replication user exists on master:
```bash
docker exec -it mariadb-master mysql -uroot -p${MYSQL_ROOT_PASSWORD} -e "SELECT User, Host FROM mysql.user WHERE User='${MYSQL_REPLICATION_USER}';"
```

4. Check master status:
```bash
docker exec -it mariadb-master mysql -uroot -p${MYSQL_ROOT_PASSWORD} -e "SHOW MASTER STATUS;"
```

5. Reset replication (if needed):
```bash
docker-compose down -v
docker-compose up -d
```

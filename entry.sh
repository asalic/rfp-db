#!/bin/sh

PG_MAJOR="${1}"
POSTGRES_DIR="${2}"

if test -e "${POSTGRES_DIR}/initial_load"; then
  sudo  pg_ctlcluster ${PG_MAJOR} main start
  sudo service postgresql restart
else
  sudo pg_createcluster ${PG_MAJOR} main --start
  echo "host\tall\tall\t0.0.0.0/0\tmd5" >> /etc/postgresql/${PG_MAJOR}/main/pg_hba.conf
  echo "listen_addresses='*'" >> /etc/postgresql/${PG_MAJOR}/main/postgresql.conf
  sudo service postgresql restart
  ${POSTGRES_DIR}/gtfs_SQL_importer/src/import-gtfs-data.sh
  psql -U postgres -c "ALTER USER postgres WITH PASSWORD '${POSTGRES_PASSW}';"
  touch "${POSTGRES_DIR}/initial_load"
fi

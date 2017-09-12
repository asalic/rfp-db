#!/bin/bash

USR_PSQL=`env | grep ^USER=`

echo "executing user is: ${USR_PSQL}"

if [[ ! $USR_PSQL == *"postgres"* ]]; then
  echo "Error executing script! Please use sudo -u postgres <script name>"
  exit 1
else
  echo "Running the importer, please wait"
fi

#if [ $# -ne 2 ]; then
#  echo "Incorrect number of arguments; Please specify: "
#  echo "1. the full address and path to the root ftp with the countries and cities"
#  echo "2. the postgres DB user password"
#  exit 1
#fi

#GTFS_DATA_FTP_FPATH=$1
#POSTGRES_PASSW=$2
#echo "FTP with data: ${GTFS_DATA_FTP_FPATH}"
if [ "${POSTGRES_PASSW}" = 'default' ]; then
  echo "WARNING: It seems that the password for the posgres DB user is the default! Are you sure you want this behaviour?"
fi

echo "updating postgres DB user password"
psql -U postgres -c "ALTER USER postgres WITH PASSWORD '${POSTGRES_PASSW}';"

# Full al  path (including de root directory) to the gtfs sql importer git
SQL_IMPORTER_SRC_FPATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"


GTFS_LCL_DIR=${SQL_IMPORTER_SRC_FPATH}/../ftp
#mkdir -p ${GTFS_LCL_DIR}
#FTP_LOG=`curlftpfs -o nonempty ${GTFS_DATA_FTP_FPATH} ${GTFS_LCL_DIR}
mkdir -p ${GTFS_LCL_DIR}
echo "Download ftp data"
exec 5>&1
lftpRes=$(lftp -e "mirror --only-newer --verbose ${GTFS_DATA_FTP_FPATH} ${GTFS_LCL_DIR};quit" | tee >(cat - >&5))
echo ${lftpRes}
if [[ $lftpRes == *"error detected"* ]]
then
  echo "Error connecting to the ftp ${GTFS_DATA_FTP_FPATH} to get the static data"
  exit 1
fi
set -e
for country in ${GTFS_LCL_DIR}/* ; do
  countryShort="$(basename $country)"
  for city in ${GTFS_LCL_DIR}/${countryShort}/* ; do
    cityShort="$(basename $city)"

    DB_NM=${countryShort}_${cityShort}
    echo "Extract data"
    mkdir -p ${GTFS_LCL_DIR}/${countryShort}/${cityShort}/gtfs || true
    ZIP_NM=`cd ${GTFS_LCL_DIR}/${countryShort}/${cityShort}/ && ls *.zip | sort -rn | head -1`
    echo "Latest zip name is ${ZIP_NM}"
    unzip ${GTFS_LCL_DIR}/${countryShort}/${cityShort}/${ZIP_NM} -d ${GTFS_LCL_DIR}/${countryShort}/${cityShort}/gtfs || true
    echo "Import ${DB_NM}"
    dropdb --if-exists ${DB_NM}
    createdb ${DB_NM}
    cat ${SQL_IMPORTER_SRC_FPATH}/gtfs_tables.sql <(python3 ${SQL_IMPORTER_SRC_FPATH}/import_gtfs_to_sql.py ${GTFS_LCL_DIR}/${countryShort}/${cityShort}/gtfs/) ${SQL_IMPORTER_SRC_FPATH}/gtfs_tables_makeindexes.sql ${SQL_IMPORTER_SRC_FPATH}/vacuumer.sql ${SQL_IMPORTER_SRC_FPATH}/gtfs_create_materialized_views.sql | psql ${DB_NM}
  done
done

#echo "clean the ftp downloaded files"
#rm -R ${GTFS_LCL_DIR}
#usermount -u ${GTFS_LCL_DIR}
echo "Done!"

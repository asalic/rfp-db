# rfp-db
Docker ready to be built repo containing the PostgreSQL static data

The following ENV variables can be set when running the container:

1. Set the path to the ftp server with the static data
GTFS_DATA_FTP_FPATH='ftp://ftpgrycap.i3m.upv.es/public/eubrabigsea/data/'

2. In order to keep the container running, a process must run in the foreground; You can set whatever you like to keep the loop open; The container can then run using the "-d" flag for docker; You can then use "docker exec" to attach a pseudo-TTY to a running instance
CMD_KEEP_ALIVE='tail -f /dev/null'

3. Set the password for the postgres DB user
POSTGRES_PASSW='default'



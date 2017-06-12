FROM postgres:9.5

MAINTAINER Andy S Alic (asalic@upv.es) Universitat Politecnica de Valencia


RUN apt-get update && apt-get -y install vim bash apt-utils sudo git lftp python3 tar zip unzip

ENV PG_MAJOR 9.5
# You can set the following variables as you wish
ENV GTFS_DATA_FTP_FPATH ftp://ftpgrycap.i3m.upv.es/public/eubrabigsea/compressed-data/
ENV CMD_KEEP_ALIVE tail -f /dev/null
ENV POSTGRES_PASSW default


# Prepare directory for postgres
RUN usermod -m -d /home/postgres postgres
RUN mkdir -p /home/postgres
RUN chown -R postgres:postgres /home/postgres

# Adjust PostgreSQL configuration so that remote connections to the
# database are possible.
#RUN echo "host all  all    0.0.0.0/0  md5" >> /etc/postgresql/${PG_MAJOR}/main/pg_hba.conf

# And add ``listen_addresses``
#RUN echo "listen_addresses='*'" >> /etc/postgresql/${PG_MAJOR}/main/postgresql.conf
ENV USER postgres
# Allow user to start stop the DB server
RUN echo "Cmnd_Alias POSTGRES_CMD = /usr/sbin/service postgresql *, /usr/bin/pg_createcluster *, /usr/bin/psql*, /usr/lib/postgresql/${PG_MAJOR}/bin/pg_ctl*" >> /etc/sudoers.d/postgres
RUN echo "postgres ALL = NOPASSWD: POSTGRES_CMD" >> /etc/sudoers.d/postgres

# Run everything as user postgres
USER postgres

# Switch to user's home
WORKDIR /home/postgres

#RUN sudo service postgresql restart

# Get the git repo with the maintainer's version of gtfs importer
RUN git clone https://github.com/eubr-bigsea/gtfs_SQL_importer
RUN chmod +x gtfs_SQL_importer/src/import-gtfs-data.sh

EXPOSE 5432

# Set the default command to run when starting the container
ENTRYPOINT sudo pg_createcluster ${PG_MAJOR} main --start && echo "host\tall\tall\t0.0.0.0/0\tmd5" >> /etc/postgresql/${PG_MAJOR}/main/pg_hba.conf && echo "listen_addresses='*'" >> /etc/postgresql/${PG_MAJOR}/main/postgresql.conf && sudo service postgresql restart && /home/postgres/gtfs_SQL_importer/src/import-gtfs-data.sh && eval ${CMD_KEEP_ALIVE}

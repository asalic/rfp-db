FROM postgres:9.5

MAINTAINER Andy S Alic (asalic@upv.es) Universitat Politecnica de Valencia


RUN apt-get update && apt-get -y install vim bash apt-utils sudo git lftp python3 tar zip unzip

ENV PG_MAJOR 9.5
ENV POSTGRES_DIR /home/postgres
# You can set the following variables as you wish
ENV GTFS_DATA_FTP_FPATH ftp://ftpgrycap.i3m.upv.es/public/eubrabigsea/compressed-data/
ENV CMD_KEEP_ALIVE tail -f /dev/null
ENV POSTGRES_PASSW default


# Prepare directory for postgres
RUN usermod -m -d ${POSTGRES_DIR} postgres
RUN mkdir -p /home/postgres
COPY ./entry.sh ${POSTGRES_DIR}/
RUN chmod +x ${POSTGRES_DIR}/entry.sh
RUN chown -R postgres:postgres ${POSTGRES_DIR}


# Adjust PostgreSQL configuration so that remote connections to the
# database are possible.
#RUN echo "host all  all    0.0.0.0/0  md5" >> /etc/postgresql/${PG_MAJOR}/main/pg_hba.conf

# And add ``listen_addresses``
#RUN echo "listen_addresses='*'" >> /etc/postgresql/${PG_MAJOR}/main/postgresql.conf

#COPY ./importer ${POSTGRES_DIR}/gtfs_SQL_importer
#RUN chown -R postgres:postgres ${POSTGRES_DIR}/gtfs_SQL_importer

ENV USER postgres
# Allow user to start stop the DB server
RUN echo "Cmnd_Alias POSTGRES_CMD = /usr/sbin/service postgresql *, /usr/bin/pg_ctlcluster *, /usr/bin/pg_createcluster *, /usr/bin/psql*, /usr/lib/postgresql/${PG_MAJOR}/bin/pg_ctl*" >> /etc/sudoers.d/postgres
RUN echo "postgres ALL = NOPASSWD: POSTGRES_CMD" >> /etc/sudoers.d/postgres

# Run everything as user postgres
USER postgres

# Switch to user's home
WORKDIR ${POSTGRES_DIR}

# Get the git repo with the maintainer's version of gtfs importer
RUN git clone https://github.com/eubr-bigsea/gtfs_SQL_importer
RUN chmod +x gtfs_SQL_importer/src/import-gtfs-data.sh

EXPOSE 5432

# Set the default command to run when starting the container
ENTRYPOINT  ${POSTGRES_DIR}/entry.sh ${PG_MAJOR} ${POSTGRES_DIR} && eval ${CMD_KEEP_ALIVE}

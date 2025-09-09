#!/bin/bash

# set patroni.yml
if [ ! -f $PATRONICONF/patroni.yml ]; then
cat > $PATRONICONF/patroni.yml <<__EOF__
bootstrap:
  dcs:
    postgresql:
      use_pg_rewind: true
  initdb:
    - encoding: 'UTF8'
    - locale: 'C'
    - auth: '${IVORYSQL_HOST_AUTH_METHOD}'
    - dbmode: '${IVORYSQL_COMPATIBLE_MODE}'
#restapi:
  #connect_address: '${PATRONI_KUBERNETES_POD_IP}:8008'
postgresql:
  #connect_address: '${PATRONI_KUBERNETES_POD_IP}:5432'
  database: ivorysql
  listen: 0.0.0.0:5432
  port: 5432
  authentication:
    replication:
      username: '${PATRONI_REPLICATOR_USERNAME}'
      password: '${PATRONI_REPLICATOR_PASSWORD}'
    rewind:
      username: '${PATRONI_REWIND_USERNAME}'
      password: '${PATRONI_REWIND_PASSWORD}'
    superuser:
      username: ivorysql
      password: '${IVORYSQL_PASSWORD}'

  parameters:
    ssl: 'off'
    logging_collector: on
    log_directory: 'log'
    ivorysql.listen_addresses: '*'

__EOF__
fi
# edit patroni.yml
FILE="$PATRONICONF/patroni.yml"
if ! grep -q "pg_hba:" "$FILE"; then
    cat $PATRONICONF/pg_hba.txt | sed 's/^/  /' >> $PATRONICONF/patroni.yml
    echo "pg_hba.txt added."
fi
if ! grep -q "tags:" "$FILE"; then
    cat $PATRONICONF/tags.txt >> $PATRONICONF/patroni.yml
    echo "tags.txt added."
fi
if ! grep -q "log:" "$FILE"; then
    cat $PATRONICONF/log.txt >> $PATRONICONF/patroni.yml
    echo "log.txt added."
fi

echo "patroni start."
patroni $PATRONICONF/patroni.yml

if [ ! -f $PATRONICONF/patroni.yml ]; then
echo "there is no patroni.yml, will generate patroni.yml "
cat > $PATRONICONF/patroni.yml <<__EOF__
scope: ${PATRONI_SCOPE}
name: ${PATRONI_SERVICE_NAME}
namespace: /service/

restapi:
  listen: 0.0.0.0:8008
  connect_address: ${IVORYSQL_HOST}:8008

etcd3:
  hosts: ${ETCD_HOSTS}
bootstrap:
  dcs:
    ttl: 30
    loop_wait: 10
    retry_timeout: 10
    maximum_lag_on_failover: 1048576
    master_start_timeout: 300
    synchronous_mode: false
    postgresql:
      use_pg_rewind: true
      parameters:
        wal_level: replica
        hot_standby: "on"
        wal_keep_size: 100
        max_wal_senders: 10
        max_replication_slots: 10
        wal_log_hints: "on"
        archive_mode: "off"
        archive_timeout: 1800s
        logging_collector: "on" 
  initdb:
    - encoding: 'UTF8'
    - locale: 'C'
    - auth: '${IVORYSQL_HOST_AUTH_METHOD}'

postgresql:  
  database: ivorysql
  listen: 0.0.0.0:5432
  connect_address: ${IVORYSQL_HOST}:5432
  bin_dir: /var/local/ivorysql/ivorysql-$IVORY_MAJOR/bin
  data_dir: $PGDATA
  config_dir: $PGDATA
  pgpass: /tmp/.pgpass


  authentication:
    replication:
      username: ivorysql
      password: '${IVORYSQL_PASSWORD}'
    rewind:
      username: ivorysql
      password: '${IVORYSQL_PASSWORD}'
    superuser:
      username: ivorysql
      password: '${IVORYSQL_PASSWORD}'

  parameters:
    ssl: 'off'
    logging_collector: on
    log_directory: 'log'
    ivorysql.listen_addresses: '*'
  
  pg_hba:
    - local   all             all                                     peer
    - host    all             all             0.0.0.0/0               ${IVORYSQL_HOST_AUTH_METHOD}
    - host    all             all             ::1/128                 ${IVORYSQL_HOST_AUTH_METHOD}
    - local   replication     all                                     peer
    - host    replication     all             0.0.0.0/0               ${IVORYSQL_HOST_AUTH_METHOD}
    - host    replication     all             ::1/128                 ${IVORYSQL_HOST_AUTH_METHOD}

tags:
    nofailover: false
    noloadbalance: false
    clonefrom: false
    nosync: false

log:
  level: INFO
  traceback_level: INFO
  dir: $PATRONICONF
__EOF__
   
else
   echo "will substitute patroni.yml with real value"
fi


echo "will start patroni......"
patroni $PATRONICONF/patroni.yml
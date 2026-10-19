#!/usr/bin/env bash
# Run from the repository root: bash tests/entrypoint-pgdata.sh
set -Eeuo pipefail
test_root=$(mktemp -d)
trap 'rm -rf "$test_root"' EXIT
for script in docker-entrypoint.sh [0-9]*/*/docker-entrypoint.sh; do
  for directory in 'plain' 'data with spaces' 'data[1]'; do
    for oracle_config in yes no; do
      (
        source "$script"
        export PGDATA="$test_root/$directory" IVORYSQL_USER=test IVORYSQL_PASSWORD=test
        POSTGRES_INITDB_ARGS=''
        # Do not require a real initdb or an NSS entry for the test UID.
        getent() { return 0; }
        initdb() {
          mkdir -p "$PGDATA"
          printf "#listen_addresses = 'localhost'\n" > "$PGDATA/postgresql.conf"
          rm -f "$PGDATA/ivorysql.conf"
          if [[ $oracle_config == yes ]]; then
            printf "#ivorysql.listen_addresses = 'localhost'\n" > "$PGDATA/ivorysql.conf"
          fi
        }
        docker_init_database_dir
        grep -Fx "listen_addresses = '*'" "$PGDATA/postgresql.conf" >/dev/null
        if [[ $oracle_config == yes ]]; then
          grep -Fx "ivorysql.listen_addresses = '*'" "$PGDATA/ivorysql.conf" >/dev/null
        fi
      )
    done
  done
done
echo 'All entrypoint PGDATA path checks passed'

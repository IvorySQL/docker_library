#!/usr/bin/env bash
# Run from the repository root: bash tests/entrypoint-port.sh
# Stub only database commands; exercise every shipped entrypoint function.
set -Eeuo pipefail
for script in docker-entrypoint.sh [0-9]*/*/docker-entrypoint.sh; do
  for port in '' 6543; do
    (
      source "$script"
      export PGPORT="$port" IVORYSQL_USER=test IVORYSQL_DB=test PGDATA=/tmp/test
      expected_port=${PGPORT:-5866}
      psql() {
        while (( $# )); do
          if [[ $1 == -p ]]; then
            [[ $2 == "$expected_port" ]] || {
              echo "$script: SQL client uses $2 instead of $expected_port" >&2
              return 1
            }
            return
          fi
          shift
        done
        echo 'SQL client port missing' >&2
        return 1
      }
      pg_ctl() {
        while (( $# )); do
          if [[ $1 == -o ]]; then
            [[ " $2 " == *" -p $expected_port "* ]]
            return
          fi
          shift
        done
        return 1
      }
      docker_temp_server_start postgres
      docker_process_sql --command 'SELECT 1'
    )
  done
done
echo 'All entrypoint client/server port checks passed'

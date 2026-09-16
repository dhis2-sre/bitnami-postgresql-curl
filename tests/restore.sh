#!/usr/bin/env bash
set -euo pipefail

image=${1:?image required}
platform=${2:?platform required}
container=""
cleanup() {
  if [[ -n "$container" ]]; then
    docker rm -fv "$container" >/dev/null
  fi
}
trap cleanup EXIT

# Exercise the inherited Bitnami entrypoint and its PostgreSQL server contract.
container=$(docker run -d --platform "$platform" \
  -e POSTGRESQL_PASSWORD=test-password -e POSTGRESQL_DATABASE=source "$image")
ready=false
for ((attempt=0; attempt<90; attempt++)); do
  # Bitnami starts a temporary server during initialization. Wait for the final
  # PostgreSQL process to replace PID 1 before accepting a successful query.
  if docker exec -e PGPASSWORD=test-password "$container" bash -ec '
    test "$(cat /proc/1/comm)" = postgres
    psql -h 127.0.0.1 -U postgres -d source -Atc "SELECT 1"
  ' >/dev/null 2>&1; then
    ready=true
    break
  fi
  sleep 2
done
if [[ "$ready" != true ]]; then
  docker logs "$container"
  exit 1
fi

docker exec -e PGPASSWORD=test-password "$container" bash -euo pipefail -c '
  test "$(id -u)" = 1001
  psql --version
  pg_restore --version
  curl --version
  test -s /etc/ssl/certs/ca-certificates.crt
  curl --fail --silent --show-error --location --max-time 60 \
    https://www.postgresql.org/ -o /tmp/https-download.html
  test -s /tmp/https-download.html
  psql -h 127.0.0.1 -U postgres -d source -v ON_ERROR_STOP=1 \
    -c "CREATE TABLE fixture (id integer PRIMARY KEY, value integer); INSERT INTO fixture VALUES (1, 42);"
  pg_dump -h 127.0.0.1 -U postgres -d source -Fc -f /tmp/fixture.pgc
  pg_dump -h 127.0.0.1 -U postgres -d source | gzip > /tmp/fixture.sql.gz
  createdb -h 127.0.0.1 -U postgres restored_archive
  createdb -h 127.0.0.1 -U postgres restored_sql
'

# A separate client container matches the chart seed job: explicit Bash command,
# PG* connection settings, temporary downloads, and no server entrypoint.
# Transfer the dumps through stdin to avoid host-mounted permission differences.
docker exec "$container" cat /tmp/fixture.pgc | \
  docker run --rm -i --platform "$platform" --network "container:$container" \
    -e PGHOST=127.0.0.1 -e PGUSER=postgres -e PGPASSWORD=test-password \
    -e PGDATABASE=restored_archive --entrypoint bash "$image" -euo pipefail -c '
      pg_isready
      dump=$(mktemp)
      cat > "$dump"
      pg_restore --exit-on-error -d "$PGDATABASE" "$dump"
      rm "$dump"
    '
docker exec "$container" cat /tmp/fixture.sql.gz | \
  docker run --rm -i --platform "$platform" --network "container:$container" \
    -e PGHOST=127.0.0.1 -e PGUSER=postgres -e PGPASSWORD=test-password \
    -e PGDATABASE=restored_sql --entrypoint bash "$image" -euo pipefail -c 'gunzip -c | psql -v ON_ERROR_STOP=1'
for database in restored_archive restored_sql; do
  result=$(docker exec -e PGPASSWORD=test-password "$container" \
    psql -h 127.0.0.1 -U postgres -d "$database" -Atc "SELECT value FROM fixture WHERE id=1")
  test "$result" = 42
done
echo "$platform: server startup, HTTPS download, custom archive and gzipped SQL restores passed"

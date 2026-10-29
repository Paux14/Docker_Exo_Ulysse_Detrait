export MSYS_NO_PATHCONV=1
cd "$(dirname "${BASH_SOURCE[0]}")"
BACKUP_DIR="${BACKUP_DIR:-$PWD/backups}"
VOLUME="${VOLUME:-shopdata_pgdata}"
SUM_SQL="SELECT count(*) || ' ' || md5(string_agg(id::text || status, ',' ORDER BY id)) FROM orders"

checksum() {
  docker compose "$@" exec -T db psql -U shop -d shop -tAc "$SUM_SQL"
}

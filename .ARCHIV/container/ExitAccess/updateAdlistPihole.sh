#!/bin/bash

create_sql_dump() {
    local list_url="$1"
    local sql_dump="$2"
    cat >"$sql_dump" <<EOF
BEGIN TRANSACTION;
DELETE FROM 'adlist_by_group';
DELETE FROM 'adlist';
# Reset autoincrement
DELETE FROM 'sqlite_sequence' WHERE name='adlist';
EOF
    cat $list_url | while read url; do
        echo "INSERT INTO 'adlist' (address, enabled, comment) VALUES('$url', 1, 'Added by script');"
    done >>"$sql_dump"
    echo 'COMMIT;' >>"$sql_dump"

    # Check if curl failed or the adlist is empty
    [ -n "$(grep 'INSERT INTO' $sql_dump)" ] || return 1
}

# Update adlists
TMP_SQL="$(mktemp --tmpdir adlist.XXXXXX.sql)"

# Create firebog tick and nocross list
list="/root/list.txt"
nlist="/root/nlist.txt"
curl -s "https://v.firebog.net/hosts/lists.php?type=tick" >> $list
curl -s "https://v.firebog.net/hosts/lists.php?type=nocross" >> $list
sort $list | uniq -u >> $nlist
sort $list | uniq -d >> $nlist

create_sql_dump "$nlist" "$TMP_SQL"
if [ ! $? -eq 0 ]; then
    echo "ERROR: Unable to fetch adlist" >> $workDir/log.txt
    rm $TMP_SQL
    exit 1
fi
sqlite3 /etc/pihole/gravity.db < $TMP_SQL
rm $TMP_SQL

# Update gravity
/usr/local/bin/pihole updateGravity >/var/log/pihole_updateGravity.log || cat /var/log/pihole_updateGravity.log
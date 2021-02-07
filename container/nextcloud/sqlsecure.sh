#!/bin/bash

SECURE_MYSQL=$(expect -c "
set timeout 3
spawn mysql_secure_installation
expect \"Press y|Y for Yes, any other key for No:\"
send \"n\r\"
expect \"New password:\"
send \"ROOTPASSWORDTOCHANGE\r\"
expect \"Re-enter new password:\"
send \"ROOTPASSWORDTOCHANGE\r\"
expect \"Remove anonymous users?\"
send \"y\r\"
expect \"Disallow root login remotely?\"
send \"y\r\"
expect \"Remove test database and access to it?\"
send \"y\r\"
expect \"Reload privilege tables now?\"
send \"y\r\"
expect eof
")

if [ $(dpkg-query -W -f='${Status}' expect 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
  apt-get install -y expect 2>&1 >/dev/null
  echo "${SECURE_MYSQL}"
  apt-get purge -y expect 2>&1 >/dev/null
else
  echo "${SECURE_MYSQL}"
fi

exit 0
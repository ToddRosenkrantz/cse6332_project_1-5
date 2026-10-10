#!/bin/bash
# First start: seed /data (the host folder), initialise MySQL, load and date-shift the classicmodels database.
set -e
D=/data
mkdir -p $D/www $D/flask $D/node $D/nginx $D/mysql $D/redis /var/run/mysqld

for d in www flask node nginx; do
  if [ -z "$(ls -A $D/$d 2>/dev/null)" ]; then cp -r /opt/seed/$d/. $D/$d/; fi
done
ln -sf $D/nginx/default.conf /etc/nginx/conf.d/default.conf

chown -R mysql:mysql $D/mysql /var/run/mysqld || true
chown -R redis:redis $D/redis || true

if [ ! -f $D/mysql/.course_initialized ]; then
  echo "=== First start: initialising MySQL and loading the classicmodels database ==="
  if [ ! -d $D/mysql/mysql ]; then
    runuser -u mysql -- mysqld --initialize-insecure --datadir=$D/mysql --log-error=/tmp/mysql-init.log
  fi
  runuser -u mysql -- mysqld --skip-networking --mysqlx=OFF --socket=/var/run/mysqld/init.sock &
  INIT_PID=$!
  for i in $(seq 1 60); do
    mysqladmin --socket=/var/run/mysqld/init.sock -uroot ping >/dev/null 2>&1 && break
    sleep 1
  done
  M="mysql --socket=/var/run/mysqld/init.sock -uroot"
  $M -e "CREATE USER IF NOT EXISTS 'student'@'%' IDENTIFIED BY '${STUDENT_PASSWORD}';
         CREATE USER IF NOT EXISTS 'student'@'localhost' IDENTIFIED BY '${STUDENT_PASSWORD}';"
  $M < /opt/sample/classicmodels.sql
  { echo "SET @semester_start_text='${SEMESTER_START}';"; cat /opt/scripts/shift_dates.sql; } | $M
  $M -e "GRANT ALL ON classicmodels.* TO 'student'@'%'; GRANT ALL ON \`student\\_%\`.* TO 'student'@'%';
         GRANT ALL ON classicmodels.* TO 'student'@'localhost'; GRANT ALL ON \`student\\_%\`.* TO 'student'@'localhost';"
  mysqladmin --socket=/var/run/mysqld/init.sock -uroot shutdown
  wait $INIT_PID || true
  echo "loaded $(date -u +%FT%TZ); latest date shifted to ${SEMESTER_START}" > $D/mysql/.course_initialized
  echo "=== classicmodels database ready ==="
fi
exec "$@"

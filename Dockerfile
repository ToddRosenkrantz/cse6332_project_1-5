# CSE 6332 course container: nginx + Flask + Node.js + Redis + MySQL in one image.
# Used for Projects 1-5. Everything students change lives in the host folder mounted at /data.
#
# Kept small on purpose: official Node.js binary instead of Ubuntu's node/npm packages (which pull in
# hundreds of build-tool packages), only MySQL's core server and client packages (the full mysql-server
# package needs all of Perl), no unused MySQL tools, no docs/man pages, and no default MySQL data directory.

# ---- stage 1: fetch Node.js (curl and xz stay in this stage and never reach the final image) ----
FROM ubuntu:24.04 AS node
ARG NODE_VERSION=24.21.0
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates curl xz-utils \
 && arch="$(dpkg --print-architecture)" \
 && case "$arch" in amd64) n=x64 ;; arm64) n=arm64 ;; *) echo "unsupported CPU: $arch" >&2; exit 1 ;; esac \
 && f="node-v${NODE_VERSION}-linux-${n}.tar.xz" \
 && curl -fsSLO "https://nodejs.org/dist/v${NODE_VERSION}/${f}" \
 && curl -fsSLO "https://nodejs.org/dist/v${NODE_VERSION}/SHASUMS256.txt" \
 && grep " ${f}\$" SHASUMS256.txt | sha256sum -c - \
 && mkdir /opt/node && tar -xJf "$f" -C /opt/node --strip-components=1 \
 && cd /opt/node && rm -rf include share CHANGELOG.md README.md \
      lib/node_modules/npm/docs lib/node_modules/npm/man lib/node_modules/corepack

# Database client libraries for Node (MySQL and Redis), installed globally so require('mysql2') works
# from any folder without an internet connection.
RUN PATH=/opt/node/bin:$PATH npm install -g --omit=dev --no-audit --no-fund mysql2 redis \
 && rm -rf /root/.npm

# ---- stage 2: the course image ----
FROM ubuntu:24.04
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
      nginx supervisor redis-server \
      mysql-server-core-8.0 mysql-client-core-8.0 \
      python3 python3-pip python3-flask gunicorn \
      python3-redis python3-pymysql \
      ca-certificates \
 && groupadd -r mysql && useradd -r -g mysql -d /nonexistent -s /usr/sbin/nologin mysql \
 && mkdir -p /etc/mysql /var/run/mysqld \
 && cd /usr/bin \
 && rm -f myisamchk myisampack ibd2sdi innochecksum lz4_decompress zlib_decompress perror \
          mysqlpump mysqlslap mysqlcheck mysqlimport mysqlshow mysqlbinlog mysql_config_editor \
          mysql_migrate_keyring mysql_secure_installation mysql_ssl_rsa_setup mysql_tzinfo_to_sql mysql_upgrade \
 && rm -rf /var/lib/apt/lists/* /var/cache/apt/* /var/log/apt/* /var/log/dpkg.log \
           /usr/share/doc/* /usr/share/man/* /usr/share/info/* /usr/share/lintian/* \
           /usr/share/locale/* /root/.cache

# Oracle's official MySQL connector (pure-Python wheel, about 0.5 MB; Ubuntu's packaged version is too old for Python 3.12).
RUN pip3 download -q --no-deps --only-binary=:all: --platform any --python-version 3.12 -d /tmp/w mysql-connector-python==26.7.0 && pip3 install -q --break-system-packages --no-deps --no-cache-dir /tmp/w/*.whl && rm -rf /tmp/w /root/.cache

COPY --from=node /opt/node /opt/node
RUN ln -s /opt/node/bin/node /usr/local/bin/node \
 && ln -s /opt/node/bin/npm  /usr/local/bin/npm \
 && ln -s /opt/node/bin/npx  /usr/local/bin/npx

COPY seed/    /opt/seed/
COPY scripts/ /opt/scripts/
# MySQL "classicmodels" sample database (mysqltutorial.org), loaded on first start.
COPY sample/  /opt/sample/
COPY supervisord.conf /etc/supervisor/conf.d/course.conf
COPY mysql-course.cnf /etc/mysql/my.cnf
RUN chmod +x /opt/scripts/*.sh && rm -f /etc/nginx/sites-enabled/default

ENV SEMESTER_START=2026-10-12 \
    STUDENT_PASSWORD=student \
    NODE_PATH=/opt/node/lib/node_modules
EXPOSE 80 3306 6379
VOLUME /data
ENTRYPOINT ["/opt/scripts/entrypoint.sh"]
CMD ["/usr/bin/supervisord", "-n", "-c", "/etc/supervisor/supervisord.conf"]

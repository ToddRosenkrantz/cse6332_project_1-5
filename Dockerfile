# CSE 6332 course container: nginx + Flask + Node.js + Redis + MySQL in one image.
# Used for Projects 1-5. Everything students change lives in the host folder mounted at /data.
FROM ubuntu:24.04
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
      nginx supervisor redis-server mysql-server \
      nodejs npm \
      python3 python3-pip python3-flask gunicorn python3-redis python3-pymysql \
      ca-certificates curl tzdata \
 && rm -rf /var/lib/apt/lists/*

COPY seed/    /opt/seed/
COPY scripts/ /opt/scripts/
# MySQL "classicmodels" sample database (mysqltutorial.org), loaded on first start.
COPY sample/  /opt/sample/
COPY supervisord.conf /etc/supervisor/conf.d/course.conf
COPY mysql-course.cnf /etc/mysql/mysql.conf.d/zz-course.cnf
RUN chmod +x /opt/scripts/*.sh && rm -f /etc/nginx/sites-enabled/default

ENV SEMESTER_START=2026-10-12 \
    STUDENT_PASSWORD=student
EXPOSE 80 3306 6379
VOLUME /data
ENTRYPOINT ["/opt/scripts/entrypoint.sh"]
CMD ["/usr/bin/supervisord", "-n", "-c", "/etc/supervisor/supervisord.conf"]

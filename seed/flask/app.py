import os
import pymysql
import redis
from flask import Flask, jsonify

app = Flask(__name__)


@app.route("/")
def status():
    out = {"service": "flask"}
    try:
        db = pymysql.connect(user="student", password=os.environ.get("STUDENT_PASSWORD", "student"),
                             database="classicmodels", unix_socket="/var/run/mysqld/mysqld.sock")
        with db.cursor() as cur:
            cur.execute("SELECT COUNT(*), MAX(orderDate) FROM orders")
            count, latest = cur.fetchone()
            out["orders"] = count
            out["latest_order_date"] = str(latest)
    except Exception as e:
        out["mysql_error"] = str(e)
    try:
        out["redis_hits"] = redis.Redis().incr("hits")
    except Exception as e:
        out["redis_error"] = str(e)
    return jsonify(out)

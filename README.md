# CSE 6332 Course Container: Student Guide (Projects 1-5)

One container gives you everything for Projects 1-5: **nginx**, **Flask** (Python), **Node.js 24**, **Redis 7** and
**MySQL 8** with the **classicmodels** sample database. Everything you create lives in a folder on your own
computer (`data/`), so it survives stopping, rebuilding or deleting the container.

Project 6 uses a separate stack (Kafka, Spark, SeaweedFS and so on) with its own instructions.

## 1. What you get

| Service | How to reach it from your computer | Where its files are (`data/` folder) |
|---|---|---|
| Web site (nginx) | http://localhost:8080 | `data/www/` |
| Flask (Python) | http://localhost:8080/flask/ | `data/flask/app.py` |
| Node.js | http://localhost:8080/node/ | `data/node/app.js` |
| MySQL | host `127.0.0.1`, port `3306`, user `student`, password `student`, database `classicmodels` | `data/mysql/` (do not edit) |
| Redis | host `127.0.0.1`, port `6379`, no password | `data/redis/` (do not edit) |
| Your own apps | http://localhost:9000 to 9009 (see section 5) | anywhere under `data/` |
| nginx settings | | `data/nginx/default.conf` |

You may also create your own databases in MySQL if their names start with `student_` (for example
`student_project3`).

## 2. Before you start

1. Install **Docker Desktop** (Windows or macOS) or Docker Engine with the Compose plugin (Linux).
   - Windows: use the **WSL 2** backend and make sure virtualization is enabled in your BIOS/UEFI.
   - Allow Docker at least **4 GB of memory** (Docker Desktop > Settings > Resources). The container itself
     uses about 0.6 GB once running.
   - You need about **2 GB of free disk** (the image is about 0.7 GB, with roughly 160 MB to download, and the
     database about 0.2 GB).
2. Check that Docker works: open a terminal and run `docker run hello-world`. If it prints a welcome message
   you are ready.
3. Put this folder (`course-container`) somewhere that is **not** synced by OneDrive, Dropbox or Google Drive.
   The database files in `data/mysql` change constantly and will upset sync clients.

### Supported computers

The image is built for both **x86-64 (amd64)** and **ARM64 (aarch64)**; Docker picks the right one automatically.

| Your computer | Notes |
|---|---|
| Windows 10/11 with Docker Desktop (WSL 2 backend) | Works. Keep the folder on your normal drive, not a network or synced folder. |
| Windows with WSL 2 (Docker Engine or Docker Desktop integration) | Works. For the best speed and fewest file-permission problems, keep the folder **inside the Linux filesystem** (for example `~/course-container`), not under `/mnt/c`. |
| macOS, Intel or Apple Silicon (M1 and later) | Works with Docker Desktop. Apple Silicon runs the ARM64 image natively. In Docker Desktop, use the default VirtioFS file sharing. |
| Linux, x86-64 or ARM64 (including Raspberry Pi 4/5 with a 64-bit OS) | Works with Docker Engine and the Compose plugin. Add yourself to the `docker` group, or put `sudo` in front of the commands. On Fedora, RHEL and other SELinux systems the `:z` in `docker-compose.yaml` is required; leave it in. |

Not supported: 32-bit systems, Podman without a Docker-compatible Compose, and Windows containers (Docker must be in
Linux-container mode).

## 3. Start, stop and daily use

Open a terminal **in the course-container folder** and run:

    docker compose up -d --build

- The first time, Docker downloads and builds the image (a few minutes), then the container loads the sample
  database (under a minute). Watch it with `docker compose logs -f` and wait for the line
  `=== classicmodels database ready ===`. Press Ctrl+C to stop watching; the container keeps running.
- Open http://localhost:8080. You should see the course page. http://localhost:8080/flask/ should show JSON
  with an order count, and http://localhost:8080/node/ should show JSON with the Node version.

Daily use:

| Task | Command |
|---|---|
| Stop (keeps all your data) | `docker compose stop` |
| Start again | `docker compose start` |
| Stop and remove the container (data in `data/` is kept) | `docker compose down` |
| See logs from all services | `docker compose logs -f` |
| Is everything running? | `docker exec cse6332-course supervisorctl status` |
| Open a shell inside the container | `docker exec -it cse6332-course bash` |
| MySQL command line | `docker exec -it cse6332-course mysql -ustudent -pstudent classicmodels` |
| Redis command line | `docker exec -it cse6332-course redis-cli` |

The container restarts automatically when Docker starts, unless you stopped it yourself.

## 4. Where your work lives and how changes take effect

Edit files in the `data/` folder with your normal editor on your own computer. The container sees the same files.

| What you change | What to do |
|---|---|
| Files in `data/www/` (HTML, CSS, images) | Nothing. Refresh the browser. |
| `data/flask/app.py` (or other Python files there) | Nothing. Flask reloads automatically. If you get an error page, check the logs for a typo. |
| `data/node/app.js` | Restart it: `docker exec cse6332-course supervisorctl restart node` |
| `data/nginx/default.conf` | Test, then reload: `docker exec cse6332-course nginx -t` then `docker exec cse6332-course nginx -s reload` |
| MySQL or Redis data | Changed through SQL or Redis commands. It is stored in `data/mysql` and `data/redis`. |

The first time the container starts, it copies starter files into `data/www`, `data/flask`, `data/node` and
`data/nginx`. It only does that when those folders are empty, so your edits are never overwritten.

Installing extra packages: run `docker exec -it cse6332-course bash`, then for example `pip3 install --break-system-packages <package>`
or `npm install <package>` inside `/data/node`. Packages installed with `npm` inside `data/node` are kept in your
folder. Python packages installed with `pip` live inside the container and are lost if you recreate it
(`docker compose down` then `up`), so list them in a `requirements.txt` in `data/flask` and reinstall when needed.

## 5. Running your own applications and opening ports

Your app runs **inside** the container. To reach it from your browser, one of these routes must lead to it.

**Route A: use the Flask or Node folders (easiest).** Put your code in `data/flask/app.py` or `data/node/app.js`.
They are already served at `/flask/` and `/node/`.

**Route B: use a student port (9000 to 9009).** These ports are already open on your computer. Start your app
inside the container and make it listen on **`0.0.0.0`** (not `localhost` or `127.0.0.1`, which only works inside
the container) on one of those ports:

    docker exec -d cse6332-course python3 /data/myapp/server.py

For a quick test (serves the folder `/data/www` on port 9001):

    docker exec -d cse6332-course python3 -m http.server 9001 --bind 0.0.0.0 --directory /data/www

Then open http://localhost:9001. Examples of listening on all addresses:
- Flask: `app.run(host="0.0.0.0", port=9001)`
- Node (Express or `http`): `app.listen(9001, "0.0.0.0")`

Apps you start this way stop when the container restarts. Start them again with the same command.

**Route C: put your app behind nginx.** Add a block to `data/nginx/default.conf`:

    location /myapp/ { proxy_pass http://127.0.0.1:9001/; }

Then `docker exec cse6332-course nginx -t` and `docker exec cse6332-course nginx -s reload`. Your app is now at
http://localhost:8080/myapp/ .

**Route D: you need a port outside 9000 to 9009.** Edit `docker-compose.yaml` and add a line under `ports:`, for example:

    - "127.0.0.1:9100:9100"

Then run `docker compose up -d`. The container is recreated and your `data/` folder is untouched. The format is
`computer-port:container-port`. If a port is "already in use" on your computer, change only the left number.

Reaching your computer from another device (a phone, a classmate) is **off by default** because every port is bound to
`127.0.0.1`. MySQL and Redis have no real security, so only change this on a network you trust.

## 6. The sample database (classicmodels)

`classicmodels` is the retailer of scale models of cars, planes, ships and trains that appears in many SQL tutorials.
Tables: `customers`, `employees`, `offices`, `orderdetails`, `orders`, `payments`, `productlines`, `products`
(about 326 orders, 122 customers, 110 products).

The data originally covers 2003-2005. When it is first loaded, every date (order, required, shipped and payment date)
is moved forward by the same number of days so that the **latest date in the data is the start of the semester,
2026-10-12**. An order that has not shipped keeps an empty (NULL) shipped date. The setting is `SEMESTER_START` in
`docker-compose.yaml`; the script is `scripts/shift_dates.sql`.

You can connect with any MySQL tool (MySQL Workbench, DBeaver, VS Code extensions, or your own code). Use host
`127.0.0.1`, port `3306`, user `student`, password `student`. Code running **inside** the container can also use the
socket `/var/run/mysqld/mysqld.sock`. The sample database is a starting point; the `student` user can change it, so
make a copy (or a `student_` database) for experiments.

**Database libraries already installed in the container** (no download needed):

| Language | MySQL | Redis |
|---|---|---|
| Python 3.12 | `pymysql`, and `mysql.connector` (Oracle's official MySQL Connector/Python) | `redis` |
| Node.js 24 | `mysql2` (supports promises) | `redis` |

Examples (run inside the container, so the host is `127.0.0.1`):

    # Python
    import mysql.connector
    db = mysql.connector.connect(host="127.0.0.1", user="student", password="student", database="classicmodels")

    // Node.js (works from any folder; no npm install needed)
    const mysql = require('mysql2/promise');
    const db = await mysql.createConnection({host: '127.0.0.1', user: 'student', password: 'student', database: 'classicmodels'});

The `student` account uses MySQL's `mysql_native_password` login so that older drivers and tutorials work too.
Need another library? See "Installing extra packages" in section 4.

## 7. Start over

- **Reset only the database:** `docker compose down`, delete the folder `data/mysql`, then `docker compose up -d`.
  The sample data is loaded again.
- **Reset everything:** `docker compose down`, delete the entire `data/` folder, then `docker compose up -d --build`.
  Your own files in `data/www`, `data/flask` and `data/node` are deleted too, so copy them first.
- **Rebuild the image** after changing the `Dockerfile` or downloading a new version of this folder:
  `docker compose up -d --build`.
- **Change the shifted date:** edit `SEMESTER_START` in `docker-compose.yaml`, delete `data/mysql` and start again.

## 8. Troubleshooting

| Symptom | Likely cause and fix |
|---|---|
| `docker: command not found`, or "Cannot connect to the Docker daemon" | Docker Desktop is not installed or not running. Start it and wait for "Docker Desktop is running". On Windows also check WSL 2 is installed (`wsl --status`) and virtualization is enabled. |
| `port is already allocated` or `address already in use` (8080, 3306, 6379) | Another program uses it, for example a MySQL or Redis installed on your computer. Stop that program, or change the left-hand number in `docker-compose.yaml` (for example `"127.0.0.1:8081:80"`) and use the new number in the URL. |
| Browser cannot reach http://localhost:8080 | Check `docker compose ps` shows the container as running, and read `docker compose logs`. On the very first start wait until you see `classicmodels database ready`. |
| `/flask/` shows "502 Bad Gateway" | Flask failed to start, usually from a typo in `data/flask/app.py`. Run `docker compose logs --tail 50`, fix the error and save the file. Flask reloads by itself. |
| Changes to `app.js` do not show | Node does not reload. Run `docker exec cse6332-course supervisorctl restart node`. |
| Changes to HTML or images do not show | Hard-refresh the browser (Ctrl+F5), and check you edited `data/www/` in the right course-container folder. |
| "Can't connect to MySQL" or "Access denied" | Wait for `classicmodels database ready` in the logs on the first start. User is `student`, password `student`. Use `127.0.0.1`, not `localhost`, in tools that try a socket by default. Use `docker exec cse6332-course supervisorctl status`; `mysql` must be RUNNING. |
| MySQL keeps restarting or the first start never finishes | Almost always low disk space, low Docker memory (raise to 4 GB), or a sync client (OneDrive) locking `data/mysql`. Fix that, then `docker compose down`, delete `data/mysql`, and `docker compose up -d`. |
| `docker compose logs` is hard to read | Show one service with `docker compose logs --tail 100`, or check state with `docker exec cse6332-course supervisorctl status`. Restart one service with `docker exec cse6332-course supervisorctl restart flask` (also `node`, `nginx`, `mysql`, `redis`). |
| My app on port 9001 shows "connection refused" or "empty reply" | The app is not running, or it listens on `127.0.0.1`. Start it again inside the container and make it listen on `0.0.0.0`. Use ports 9000 to 9009. |
| Permission denied when editing files in `data/` (Linux) | Files created by the container are owned by root. Run `sudo chown -R $USER data/www data/flask data/node data/nginx`. |
| The container starts but MySQL or nginx report "Permission denied" on `/data` (Fedora, RHEL, other SELinux Linux) | The `:z` after `./data:/data` in `docker-compose.yaml` relabels the folder for SELinux. Make sure it is still there, then `docker compose up -d`. |
| `exec format error`, or Redis exits with an ARM64 kernel warning | The image was built for a different CPU type. Rebuild on your own computer with `docker compose build --no-cache`. If an old kernel makes Redis refuse to start, the repo already passes `--ignore-warnings ARM64-COW-BUG` to Redis; update the repo and rebuild. |
| The container is slow on Windows | Keep the course-container folder on your normal drive (not a network or synced folder). For the best speed, put it inside your WSL 2 Linux filesystem (for example `~/course-container`). |
| Something is badly broken | Section 7: reset the database, or reset everything. Copy your own files first. |

If you are still stuck, send your instructor: the exact command you ran, the output of
`docker compose logs --tail 80`, and the output of `docker exec cse6332-course supervisorctl status`.

## 9. Security notes

- All ports are published on `127.0.0.1` only, so other computers cannot connect.
- MySQL (`student` / `student`) and Redis (no password) are for learning only. Never put real data in them and never
  expose them to the internet.
- Do not commit passwords to a public repository.

## 10. What is in this folder

| Path | Purpose |
|---|---|
| `Dockerfile`, `supervisord.conf`, `mysql-course.cnf` | How the image is built and how its services run |
| `docker-compose.yaml` | Ports, settings and the `data/` folder mapping (edit this to change ports) |
| `scripts/` | First-start setup (`entrypoint.sh`) and the date-shift script (`shift_dates.sql`) |
| `sample/classicmodels.sql` | The sample database (from mysqltutorial.org) |
| `seed/` | Starter files copied into `data/` the first time |
| `data/` | **Your work.** Created on first start. Back it up; it is not in the image. |

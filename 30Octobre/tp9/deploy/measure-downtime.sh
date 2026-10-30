#!/usr/bin/env bash
DURATION="${1:-30}"
URL="${URL:-http://127.0.0.1/health}"
HOST_HEADER="${HOST_HEADER:-api.localhost}"
RATE="${RATE:-100}"

PY=python
command -v python >/dev/null 2>&1 || PY=python3

exec $PY - "$DURATION" "$URL" "$HOST_HEADER" "$RATE" <<'PYEOF'
import sys, time, threading, urllib.request

duration = float(sys.argv[1])
url, host, rate = sys.argv[2], sys.argv[3], int(sys.argv[4])

lock = threading.Lock()
stats = {"ok": 0, "ko": 0}
fails = []
t0 = time.time()
errors = {}

def hit():
    req = urllib.request.Request(url, headers={"Host": host})
    try:
        with urllib.request.urlopen(req, timeout=2) as r:
            code = r.status
    except urllib.error.HTTPError as e:
        code = e.code
    except Exception as e:
        code = type(e).__name__
    with lock:
        if code == 200:
            stats["ok"] += 1
        else:
            stats["ko"] += 1
            errors[code] = errors.get(code, 0) + 1
            fails.append(round(time.time() - t0))

end = time.time() + duration
threads = []
n = 0
start = time.time()
while time.time() < end:
    t = threading.Thread(target=hit)
    t.start()
    threads.append(t)
    n += 1
    delay = start + n / rate - time.time()
    if delay > 0:
        time.sleep(delay)

for t in threads:
    t.join()

total = stats["ok"] + stats["ko"]
print(f"requetes={total} ok={stats['ok']} echecs={stats['ko']} detail={errors}")
if fails:
    print('echecs aux secondes:', sorted(set(fails)))
sys.exit(1 if stats["ko"] else 0)
PYEOF

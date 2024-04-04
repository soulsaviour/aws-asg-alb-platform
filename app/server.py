#!/usr/bin/env python3
"""Small HTTP service used to exercise the ALB, health checks and deployments.

Standard library only, so it runs on a stock Amazon Linux 2023 instance.

  GET /        -> version, host and uptime
  GET /health  -> 200 while the process is serving
"""

import json
import logging
import os
import signal
import socket
import sys
import threading
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

PORT = int(os.environ.get("APP_PORT", "8080"))
VERSION = os.environ.get("APP_VERSION", "dev")
HOSTNAME = socket.gethostname()
STARTED_AT = time.time()

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(levelname)s %(message)s",
    stream=sys.stdout,
)
log = logging.getLogger("app")


class Handler(BaseHTTPRequestHandler):
    server_version = "demo-app"

    def _send_json(self, status, payload):
        body = json.dumps(payload).encode()
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):
        if self.path == "/health":
            self._send_json(200, {"status": "ok"})
        elif self.path == "/":
            self._send_json(
                200,
                {
                    "version": VERSION,
                    "host": HOSTNAME,
                    "uptime_seconds": int(time.time() - STARTED_AT),
                },
            )
        else:
            self._send_json(404, {"error": "not found"})

    def log_message(self, fmt, *args):
        log.info("%s %s", self.address_string(), fmt % args)


def main():
    server = ThreadingHTTPServer(("0.0.0.0", PORT), Handler)

    def stop(signum, _frame):
        log.info("received signal %s, shutting down", signum)
        # shutdown() waits for serve_forever() to return, so it can't be
        # called from the thread that is running it.
        threading.Thread(target=server.shutdown, daemon=True).start()

    signal.signal(signal.SIGTERM, stop)
    signal.signal(signal.SIGINT, stop)

    log.info("starting version %s on port %d", VERSION, PORT)
    server.serve_forever()
    server.server_close()


if __name__ == "__main__":
    main()

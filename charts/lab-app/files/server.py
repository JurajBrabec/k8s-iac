from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
import os
import threading
import time

counts = {"200": 0, "500": 0, "404": 0}
lock = threading.Lock()
started = time.time()


class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/metrics":
            with lock:
                lines = [f'lab_http_requests_total{{status="{k}"}} {v}' for k, v in counts.items()]
            lines.insert(0, "# TYPE lab_http_requests_total counter")
            lines += ["# TYPE lab_uptime_seconds gauge", f"lab_uptime_seconds {time.time() - started:.0f}"]
            self.respond(200, "\n".join(lines) + "\n", "text/plain; version=0.0.4")
            return
        if self.path == "/healthz":
            self.respond(200, "ok\n")
            return
        status = 200 if self.path == "/" else 500 if self.path == "/fail" else 404
        with lock:
            counts[str(status)] += 1
        self.respond(status, os.environ.get("MESSAGE", "hello") + "\n" if status == 200 else "error\n")

    def respond(self, status, body, content_type="text/plain"):
        data = body.encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", content_type)
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)


ThreadingHTTPServer(("0.0.0.0", int(os.environ.get("PORT", "8080"))), Handler).serve_forever()

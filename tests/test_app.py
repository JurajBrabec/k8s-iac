"""Local smoke test for the example app; does not require Kubernetes."""

import os
from pathlib import Path
import socket
import subprocess
import sys
import time
import unittest
from urllib.error import HTTPError, URLError
from urllib.request import urlopen


class AppTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        with socket.socket() as sock:
            sock.bind(("127.0.0.1", 0))
            port = sock.getsockname()[1]
        cls.url = f"http://127.0.0.1:{port}"
        server = Path(__file__).resolve().parents[1] / "charts/lab-app/files/server.py"
        cls.process = subprocess.Popen(
            [sys.executable, str(server)],
            env={**os.environ, "PORT": str(port), "MESSAGE": "lab-test"},
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
        for _ in range(50):
            try:
                with urlopen(cls.url + "/healthz", timeout=1) as response:
                    if response.read() == b"ok\n":
                        return
            except (OSError, URLError):
                time.sleep(0.1)
        cls.process.terminate()
        cls.process.wait(timeout=5)
        raise RuntimeError("app did not become ready")

    @classmethod
    def tearDownClass(cls):
        cls.process.terminate()
        cls.process.wait(timeout=5)

    def test_requests_and_metrics(self):
        with urlopen(self.url + "/") as response:
            self.assertEqual(response.status, 200)
            self.assertEqual(response.read(), b"lab-test\n")
        with self.assertRaises(HTTPError) as error:
            urlopen(self.url + "/fail")
        self.assertEqual(error.exception.code, 500)
        with urlopen(self.url + "/metrics") as response:
            metrics = response.read().decode()
        self.assertIn('lab_http_requests_total{status="200"} 1', metrics)
        self.assertIn('lab_http_requests_total{status="500"} 1', metrics)
        self.assertIn("lab_uptime_seconds", metrics)


if __name__ == "__main__":
    unittest.main()

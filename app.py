#!/usr/bin/env python3
"""
Servidor HTTP simple que responde Hola Mundo
Incluye consumo del microservicio cu-ms-payments
"""

import http.server
import socketserver
import sys
from datetime import datetime
import requests
import os

PORT = 3000

# URL del microservicio cu-ms-payments (puedes sobrescribirla con variable de entorno)
PAYMENTS_URL = os.getenv(
    "PAYMENTS_URL",
    "http://cu-ms-payments.hoverdev-dev.svc.cluster.local:3000/users"
)

class HolaMundoHandler(http.server.SimpleHTTPRequestHandler):

    def do_GET(self):
        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        print(f"[{timestamp}] Solicitud GET recibida", file=sys.stdout)
        print(f"[{timestamp}] Path: {self.path}", file=sys.stdout)

        # ---- ENDPOINT STARTUP ----
        if self.path == '/startup':
            self._send_ok(timestamp, "/startup")

        # ---- ENDPOINT LIVENESS ----
        elif self.path == '/liveness':
            self._send_ok(timestamp, "/liveness")

        # ---- ENDPOINT READINESS ----
        elif self.path == '/readiness':
            self._send_ok(timestamp, "/readiness")

        # ---- NUEVO ENDPOINT PARA CONSUMIR OTRO MICROSERVICIO ----
        elif self.path == "/users":
            print(f"[{timestamp}] llamando al microservicio cu-ms-payments...", file=sys.stdout)
            sys.stdout.flush()

            try:
                response = requests.get(PAYMENTS_URL, timeout=5)
                response.raise_for_status()

                data = response.json()
                print(f"[{timestamp}] respuesta recibida desde cu-ms-payments", file=sys.stdout)

                self.send_response(200)
                self.send_header("Content-type", "application/json; charset=utf-8")
                self.end_headers()
                self.wfile.write(response.content)

            except requests.exceptions.RequestException as e:
                error_msg = f"Error llamando a cu-ms-payments: {e}"
                print(f"[{timestamp}] {error_msg}", file=sys.stdout)
                
                self.send_response(500)
                self.send_header("Content-type", "application/json; charset=utf-8")
                self.end_headers()
                self.wfile.write(bytes(f'{{"error": "{error_msg}"}}', "utf-8"))

        # ---- ENDPOINT RAÍZ ----
        else:
            print(f"[{timestamp}] se llamó al endpoint raíz", file=sys.stdout)
            sys.stdout.flush()
            self.send_response(200)
            self.send_header('Content-type', 'text/html; charset=utf-8')
            self.end_headers()
            self.wfile.write(b'<h1>Hola Mundo</h1>')


    # ---- Método auxiliar para probes ----
    def _send_ok(self, timestamp, name):
        print(f"[{timestamp}] se llamo al endpoint {name}", file=sys.stdout)
        sys.stdout.flush()
        self.send_response(200)
        self.send_header('Content-type', 'text/html; charset=utf-8')
        self.end_headers()
        self.wfile.write(b'OK')

    # ---- Logs formateados ----
    def log_message(self, format, *args):
        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        print(f"[{timestamp}] {self.address_string()} - {format%args}", file=sys.stdout)
        sys.stdout.flush()


if __name__ == "__main__":
    with socketserver.TCPServer(("", PORT), HolaMundoHandler) as httpd:
        print(f"Servidor corriendo en puerto {PORT}")
        print("Presiona Ctrl+C para detener")
        httpd.serve_forever()

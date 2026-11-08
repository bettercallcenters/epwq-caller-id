#!/usr/bin/env python3
"""Página de un solo uso, en la red local, que conecta un teléfono con el CRM.

Vive en su propio archivo a propósito. Estuvo metido dentro de `python3 -c '...'` en
conectar.sh y fue un error: cualquier comilla simple del HTML —la del `viewport`, la del
`href`— cerraba la cadena del shell y el código salía partido a la mitad. La página llegaba
rota y nadie se enteraba hasta que el teléfono no conectaba.

Qué hace: sirve UNA página en una dirección al azar de tu WiFi. Esa página rebota al enlace
real de la app con la clave en el fragmento (#t=). Se apaga en cuanto alguien entra, o a los
3 minutos.

El rebote lo hace el NAVEGADOR (location.replace), no un 302 del servidor: un redirect del
servidor no tiene obligación de arrastrar el fragmento, y Safari del iPhone efectivamente lo
tira — el teléfono llegaba a la app sin la clave y el aviso rojo seguía ahí.

La clave entra por el entorno (LINK) y nunca por argv: lo de argv lo ve cualquiera con `ps`.
"""
import http.server
import json
import os
import socketserver
import threading

LINK = os.environ["LINK"]
RUTA = os.environ["RUTA"]
PUERTO = int(os.environ.get("PUERTO", "8765"))
VIDA_SEG = int(os.environ.get("VIDA_SEG", "180"))

PAGINA = (
    '<!doctype html><meta charset="utf-8">'
    '<meta name="viewport" content="width=device-width,initial-scale=1">'
    "<title>Conectando…</title>"
    "<style>body{font:17px -apple-system,system-ui,sans-serif;padding:28px;text-align:center;color:#0f172a}"
    "a{display:inline-block;margin-top:22px;padding:15px 26px;background:#1d4ed8;color:#fff;"
    "text-decoration:none;border-radius:11px;font-weight:700}</style>"
    "<p>Conectando este equipo con el CRM…</p>"
    # El enlace visible es la red por si el JavaScript está apagado: se toca y ya.
    "<a href=" + json.dumps(LINK) + ">Si no avanza solo, toca aquí</a>"
    "<script>location.replace(" + json.dumps(LINK) + ")</script>"
).encode("utf-8")


class Mano(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path.strip("/") != RUTA:
            self.send_response(404)
            self.end_headers()
            self.wfile.write(b"no")
            return
        self.send_response(200)
        self.send_header("Content-Type", "text/html; charset=utf-8")
        self.send_header("Content-Length", str(len(PAGINA)))
        self.send_header("Cache-Control", "no-store")
        self.end_headers()
        self.wfile.write(PAGINA)
        # flush: redirigido a un archivo, python guarda en búfer y el aviso se perdía.
        print("   El telefono entro — ya quedo conectado.", flush=True)
        threading.Thread(target=srv.shutdown, daemon=True).start()

    def log_message(self, *a):
        pass  # sin logs: ahí iría la ruta


socketserver.TCPServer.allow_reuse_address = True
srv = socketserver.TCPServer(("0.0.0.0", PUERTO), Mano)
threading.Timer(VIDA_SEG, lambda: threading.Thread(target=srv.shutdown, daemon=True).start()).start()
srv.serve_forever()

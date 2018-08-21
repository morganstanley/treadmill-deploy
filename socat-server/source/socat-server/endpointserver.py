#!/usr/bin/python

import os
import SimpleHTTPServer
import BaseHTTPServer
import SocketServer
import subprocess
from subprocess import CalledProcessError
import sys

FETCH_COMMAND = "/opt/socat-server/fetch_endpoints.sh"

PORT = os.environ.get('SOCAT_PORT')


class requestHandler(BaseHTTPServer.BaseHTTPRequestHandler):

    def do_GET(self):
        try:
            response_data = subprocess.check_output([FETCH_COMMAND])
            self.send_response(200)
            self.send_header("Content-type", "text/plain")
            self.end_headers()
            self.wfile.write(response_data)
            self.wfile.close()
        except CalledProcessError as e:
            self.send_response(500)
            self.send_header("Content-type", "text/plain")
            self.end_headers()
            self.wfile.write(e.output.decode())
            self.wfile.close()


Handler = requestHandler

httpd = SocketServer.TCPServer(("", int(PORT)), Handler)

print("serving at port", PORT)
httpd.serve_forever()

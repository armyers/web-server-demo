#!/usr/bin/env python3
"""
Very simple HTTP server in python for logging requests
Usage::
    ./server.py [<port>]
"""
from http.server import BaseHTTPRequestHandler, HTTPServer, ThreadingHTTPServer
import socket
import logging

SERVER_PORT = 40080

# XXXX this seems to be about the only way to get your own primary IP address using python
# (one other way would be to call a shell script, I suppose)
def get_server_ip():
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        # doesn't even have to be reachable
        s.connect(('10.255.255.255', 1))
        IP = s.getsockname()[0]
    except Exception:
        IP = '127.0.0.1'
    finally:
        s.close()
    return IP

class S(BaseHTTPRequestHandler):
    def _set_response(self):
        self.send_response(200)
        self.send_header('Content-type', 'text/html')
        self.end_headers()

    def do_GET(self):
        self._set_response()
        self.wfile.write(bytes("<body>", "utf-8"))
        self.wfile.write(bytes("<p>Request: %s</p>" % self.path, "utf-8"))
        # XXXX using a global function and global var -- probably not cool!
        self.wfile.write(bytes("<p>web server: %s:%s</p>" % (get_server_ip(), SERVER_PORT), "utf-8"))
        self.wfile.write(bytes("<p>Host header: %s</p>" % (self.headers['Host']), "utf-8"))
        self.wfile.write(bytes("<p>client address: %s:%s</p>" % (self.client_address[0], self.client_address[1]), "utf-8"))
        self.wfile.write(bytes("<p>X-Forwarded-For header: %s</p>" % (self.headers['X-Forwarded-For']), "utf-8"))
        self.wfile.write(bytes("<p>X-Forwarded-Proto header: %s</p>" % (self.headers['X-Forwarded-Proto']), "utf-8"))
        self.wfile.write(bytes("<p>The time is now: %s</p>" % self.date_time_string(), "utf-8"))
        self.wfile.write(bytes("</body></html>", "utf-8"))
        logging.info("GET request:\nPath: %s\nHeaders:\n%s\n", str(self.path), str(self.headers))

    def do_POST(self):
        content_length = int(self.headers['Content-Length']) # <--- Gets the size of data
        post_data = self.rfile.read(content_length) # <--- Gets the data itself
        logging.info("POST request,\nPath: %s\nHeaders:\n%s\n\nBody:\n%s\n",
                str(self.path), str(self.headers), post_data.decode('utf-8'))

        self._set_response()
        self.wfile.write("POST request for {}".format(self.path).encode('utf-8'))

def run(server_class=ThreadingHTTPServer, handler_class=S, port=SERVER_PORT):
    logging.basicConfig(level=logging.INFO)
    server_address = ('', port)
    httpd = server_class(server_address, handler_class)
    logging.info('Starting httpd...\n')
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        pass
    httpd.server_close()
    logging.info('Stopping httpd...\n')

if __name__ == '__main__':
    run()

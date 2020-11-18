#!/usr/bin/env python3

from http.server import HTTPServer, BaseHTTPRequestHandler
from socketserver import ThreadingMixIn
import threading
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

class Handler(BaseHTTPRequestHandler):

    def _concentric_array(self, A):
        # either terminate recursion, or recurse
        if A == 1:
            return [1]
        else:
            inner_pp_A = _concentric_array(self, A - 1)
        # only get here if A > 1
        # size of one dimension of the array
        side = 2*A - 1
        # create the array size (2*A -1) square initialized to A
        pp_A = [x[:] for x in [[A] * side] * side]
        # set the inner array to values returned via recursion
        # FYI: short circuit for the innermost array when it's just going to be [1]
        if A == 2:
            pp_A[1][1] = 1
        else:
            for row in range(1, side - 1):
                for col in range(1, side - 1):
                    pp_A[row][col] = inner_pp_A[row - 1][col - 1]
        return pp_A

    def do_GET(self):
        self.send_response(200)
        self.end_headers()
        self.wfile.write(bytes("<body>", "utf-8"))
        self.wfile.write(bytes("<p>Request: %s</p>" % self.path, "utf-8"))
        # XXXX using a global function and global var -- probably not cool!
        self.wfile.write(bytes("<p>web server: %s:%s</p>" % (get_server_ip(), SERVER_PORT), "utf-8"))
        self.wfile.write(bytes("<p>Server Threads: %s, %s total threads</p>" % (threading.currentThread().getName(), str(threading.active_count())), "utf-8"))
        self.wfile.write(bytes("<p>Host header: %s</p>" % (self.headers['Host']), "utf-8"))
        self.wfile.write(bytes("<p>client address: %s:%s</p>" % (self.client_address[0], self.client_address[1]), "utf-8"))
        self.wfile.write(bytes("<p>X-Forwarded-For header: %s</p>" % (self.headers['X-Forwarded-For']), "utf-8"))
        self.wfile.write(bytes("<p>X-Forwarded-Proto header: %s</p>" % (self.headers['X-Forwarded-Proto']), "utf-8"))
        self.wfile.write(bytes("<p>The time is now: %s</p>" % self.date_time_string(), "utf-8"))
        self.wfile.write(bytes("</body></html>", "utf-8"))

class ThreadingSimpleServer(ThreadingMixIn, HTTPServer):
    pass

def run():
    server = ThreadingSimpleServer(('', SERVER_PORT), Handler)
    logging.info('Starting web-server...\n')
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    server.server_close()
    logging.info('Stopping web-server...\n')

if __name__ == '__main__':
    run()


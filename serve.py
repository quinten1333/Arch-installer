#
# Small python script which will output the correct IP as host variable in a download script.
#
# Usage:
# Run this script with path to the config as second argument
# In the arch iso run:
# $ curl http://ip:port/dl.sh | sh
# $ ./install.sh
# The installation is done using the supplied config file

import argparse
import pathlib
import http.server

config_path = ""
script_dir = pathlib.Path(__file__).parent.resolve().joinpath('./src')

class Server(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == '/':
            self.send_response(200)
            self.end_headers()
            connInfo = self.connection.getsockname()
            usage = f"""
Usage:

curl http://{connInfo[0]}:{connInfo[1]}/dl.sh | sh
./install.sh
            """
            self.wfile.write(bytes(usage, 'utf-8'))
        elif self.path == "/dl.sh":
            self.sendDownloadScript()
        elif self.path == "/config.sh":
            try:
                print(f"Reading config from: {config_path}")
                with open(config_path, 'rb') as file:
                    self.send_response(200)
                    self.end_headers()
                    self.wfile.write(file.read())
            except:
                self.send_response(404)
                self.end_headers()
                self.wfile.write("Invalid config path given on the server")
                print("Invalid config path!")
        else:
            if '..' in self.path:
                self.unauthorized()
                return

            path = script_dir.joinpath('./' + self.path.strip('/'))
            try:
                print(f"Reading: {path}")
                with open(path, 'rb') as file:
                    self.send_response(200)
                    self.end_headers()
                    self.wfile.write(file.read())
            except:
                self.send_response(404)
                self.end_headers()

    def sendDownloadScript(self):
        self.send_response(200)
        self.end_headers()
        connInfo = self.connection.getsockname()
        file = f"""
host="http://{connInfo[0]}:{connInfo[1]}"
curl $host/install.sh > install.sh
curl $host/config.sh > config.sh
curl $host/systeminit.sh > systeminit.sh
curl $host/fdisk_partitioning > fdisk_partitioning
chmod +x *.sh
echo "Now run './install.sh'"
        """
        self.wfile.write(bytes(file, "utf-8"))

    def unauthorized(self):
        self.send_response(403)
        self.end_headers()
        self.wfile.write(bytes("Unauthorized. You shall not pass!", "utf-8"))
        self.wfile.close()

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Over engineered server to serve install shell scripts for installing arch linux.")
    parser.add_argument('config', help="Path to the config shell script", nargs="?", type=str, default="./src/config.sh")
    args = parser.parse_args()

    config_path = args.config

    server_address = ('', 8000)
    httpd = http.server.HTTPServer(server_address, Server)
    print(f"Started: http://{server_address[0]}:{server_address[1]}")
    httpd.serve_forever()

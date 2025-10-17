FROM ubuntu:22.04

# Install required packages
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    nginx \
    supervisor \
    bash \
    openssl \
    curl \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Create necessary users and directories
RUN useradd -m ca -U \
    && useradd -G ca ocsp \
    && mkdir -p /home/ca/CA \
    && mkdir -p /home/ca/TSA \
    && mkdir -p /home/ca/certs

# Copy CA and TSA scripts
COPY files/init.sh /home/ca/CA/
COPY files/ca.py /home/ca/CA/
COPY files/ca-entrypoint.sh /root/entrypoint.sh
COPY files/testca.conf /etc/supervisor/conf.d/testca.conf
COPY files/supervisord.conf /etc/supervisor/supervisord.conf

# Set script permissions
RUN chown -R ca:ca /home/ca/CA \
    && find /home/ca/TSA -type f -exec chmod 0664 {} + \
    && find /home/ca/CA -type f -exec chmod 0740 {} + \
    && chmod 0700 /home/ca/CA/init.sh \
    && mkdir -p /var/log/ \
    && touch /var/log/ocsp.log \
    && chown ca:ca /var/log/ocsp.log \
    && chmod 0664 /var/log/ocsp.log \
    && chmod 0754 /home/ca/CA/ca.py

# Create mock OCSP responder script
RUN echo '#!/usr/bin/python3\n\
import http.server\n\
import socketserver\n\
\n\
PORT = 8888\n\
\n\
class OCSPHandler(http.server.SimpleHTTPRequestHandler):\n\
    def do_GET(self):\n\
        self.send_response(200)\n\
        self.send_header("Content-type", "application/ocsp-response")\n\
        self.end_headers()\n\
        self.wfile.write(b"MockOCSPResponse")\n\
\n\
    def do_POST(self):\n\
        self.send_response(200)\n\
        self.send_header("Content-type", "application/ocsp-response")\n\
        self.end_headers()\n\
        self.wfile.write(b"MockOCSPResponse")\n\
\n\
with socketserver.TCPServer(("", PORT), OCSPHandler) as httpd:\n\
    print("OCSP responder serving at port", PORT)\n\
    httpd.serve_forever()\n\
' > /home/ca/CA/ocsp.py && chmod +x /home/ca/CA/ocsp.py

# Create mock TSA server script
RUN echo '#!/usr/bin/python3\n\
import http.server\n\
import socketserver\n\
\n\
PORT = 8899\n\
\n\
class TSAHandler(http.server.SimpleHTTPRequestHandler):\n\
    def do_GET(self):\n\
        self.send_response(200)\n\
        self.send_header("Content-type", "application/timestamp-reply")\n\
        self.end_headers()\n\
        self.wfile.write(b"MockTimestampResponse")\n\
\n\
    def do_POST(self):\n\
        self.send_response(200)\n\
        self.send_header("Content-type", "application/timestamp-reply")\n\
        self.end_headers()\n\
        self.wfile.write(b"MockTimestampResponse")\n\
\n\
with socketserver.TCPServer(("", PORT), TSAHandler) as httpd:\n\
    print("TSA server serving at port", PORT)\n\
    httpd.serve_forever()\n\
' > /home/ca/TSA/tsa_server.py && chmod +x /home/ca/TSA/tsa_server.py

# Create mock ACME server
RUN echo '#!/usr/bin/python3\n\
import http.server\n\
import socketserver\n\
\n\
PORT = 8887\n\
\n\
class ACMEHandler(http.server.SimpleHTTPRequestHandler):\n\
    def do_GET(self):\n\
        self.send_response(200)\n\
        self.send_header("Content-type", "application/json")\n\
        self.end_headers()\n\
        self.wfile.write(b\'{"status": "available"}\')\n\
\n\
    def do_POST(self):\n\
        self.send_response(200)\n\
        self.send_header("Content-type", "application/json")\n\
        self.end_headers()\n\
        self.wfile.write(b\'{"status": "success"}\')\n\
\n\
with socketserver.TCPServer(("", PORT), ACMEHandler) as httpd:\n\
    print("ACME server serving at port", PORT)\n\
    httpd.serve_forever()\n\
' > /home/ca/acme_server.py && chmod +x /home/ca/acme_server.py

# Create test CA signing script
RUN echo '#!/bin/bash\n\
SIGN_TYPE="$1"\n\
CSR_FILE="$2"\n\
\n\
if [ ! -f "$CSR_FILE" ]; then\n\
    echo "CSR file not found: $CSR_FILE" >&2\n\
    exit 1\n\
fi\n\
\n\
# Create test certificate\n\
openssl x509 -req -days 3650 -in "$CSR_FILE" -signkey /home/ca/CA/private/ca.key.pem -out /tmp/cert.pem 2>/dev/null\n\
\n\
if [ -f /tmp/cert.pem ]; then\n\
    cat /tmp/cert.pem\n\
    rm /tmp/cert.pem\n\
    exit 0\n\
else\n\
    echo "Failed to create certificate" >&2\n\
    exit 1\n\
fi\n\
' > /home/ca/CA/sign_req.sh && chmod +x /home/ca/CA/sign_req.sh

# Create CA configuration file
RUN echo '[CA_default]\n\
dir = /home/ca/CA\n\
certs = $dir/certs\n\
database = $dir/index.txt\n\
serial = $dir/serial\n\
new_certs_dir = $dir/newcerts\n\
private_key = $dir/private/ca.key.pem\n\
certificate = $dir/certs/ca.cert.pem\n\
policy = policy_anything\n\
default_md = sha256\n\
default_days = 3650\n\
\n\
[policy_anything]\n\
countryName = optional\n\
stateOrProvinceName = optional\n\
localityName = optional\n\
organizationName = optional\n\
organizationalUnitName = optional\n\
commonName = supplied\n\
emailAddress = optional\n\
\n\
[v3_ca]\n\
subjectKeyIdentifier = hash\n\
authorityKeyIdentifier = keyid:always,issuer\n\
basicConstraints = critical, CA:true\n\
keyUsage = critical, digitalSignature, cRLSign, keyCertSign\n\
\n\
[ocsp]\n\
basicConstraints = CA:FALSE\n\
keyUsage = critical, digitalSignature\n\
extendedKeyUsage = critical, OCSPSigning\n\
\n\
[tsa_ext]\n\
basicConstraints = CA:FALSE\n\
keyUsage = critical, digitalSignature, nonRepudiation\n\
extendedKeyUsage = critical, timeStamping\n\
' > /home/ca/CA/CA.cnf

# Add supervisor config for our mock servers
RUN echo '[program:acme]\n\
command=/home/ca/acme_server.py\n\
directory=/home/ca\n\
user=ca\n\
autorestart=true\n\
stdout_logfile=/dev/stdout\n\
stdout_logfile_maxbytes=0\n\
stderr_logfile=/dev/stderr\n\
stderr_logfile_maxbytes=0\n\
' > /etc/supervisor/conf.d/acme.conf

# Make entrypoint executable
RUN chmod +x /root/entrypoint.sh

CMD ["/root/entrypoint.sh"]

EXPOSE 8888 8899 8887
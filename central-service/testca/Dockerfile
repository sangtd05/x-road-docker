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
RUN cat <<'EOF' > /home/ca/CA/ocsp.py
#!/usr/bin/python3
import http.server
import socketserver

PORT = 8888

class OCSPHandler(http.server.SimpleHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200)
        self.send_header("Content-type", "application/ocsp-response")
        self.end_headers()
        self.wfile.write(b"MockOCSPResponse")

    def do_POST(self):
        self.send_response(200)
        self.send_header("Content-type", "application/ocsp-response")
        self.end_headers()
        self.wfile.write(b"MockOCSPResponse")

with socketserver.TCPServer(("", PORT), OCSPHandler) as httpd:
    print("OCSP responder serving at port", PORT)
    httpd.serve_forever()
EOF

RUN chmod +x /home/ca/CA/ocsp.py

# Create mock TSA server script
RUN cat <<'EOF' > /home/ca/TSA/tsa_server.py
#!/usr/bin/python3
import http.server
import socketserver

PORT = 8899

class TSAHandler(http.server.SimpleHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200)
        self.send_header("Content-type", "application/timestamp-reply")
        self.end_headers()
        self.wfile.write(b"MockTimestampResponse")

    def do_POST(self):
        self.send_response(200)
        self.send_header("Content-type", "application/timestamp-reply")
        self.end_headers()
        self.wfile.write(b"MockTimestampResponse")

with socketserver.TCPServer(("", PORT), TSAHandler) as httpd:
    print("TSA server serving at port", PORT)
    httpd.serve_forever()
EOF

RUN chmod +x /home/ca/TSA/tsa_server.py

# Create mock ACME server
RUN cat <<'EOF' > /home/ca/acme_server.py
#!/usr/bin/python3
import http.server
import socketserver

PORT = 8887

class ACMEHandler(http.server.SimpleHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200)
        self.send_header("Content-type", "application/json")
        self.end_headers()
        self.wfile.write(b'{"status": "available"}')

    def do_POST(self):
        self.send_response(200)
        self.send_header("Content-type", "application/json")
        self.end_headers()
        self.wfile.write(b'{"status": "success"}')

with socketserver.TCPServer(("", PORT), ACMEHandler) as httpd:
    print("ACME server serving at port", PORT)
    httpd.serve_forever()
EOF

RUN chmod +x /home/ca/acme_server.py

# Create test CA signing script
RUN cat <<'EOF' > /home/ca/CA/sign_req.sh
#!/bin/bash
SIGN_TYPE="$1"
CSR_FILE="$2"

if [ ! -f "$CSR_FILE" ]; then
    echo "CSR file not found: $CSR_FILE" >&2
    exit 1
fi

# Create test certificate
openssl x509 -req -days 3650 -in "$CSR_FILE" -signkey /home/ca/CA/private/ca.key.pem -out /tmp/cert.pem 2>/dev/null

if [ -f /tmp/cert.pem ]; then
    cat /tmp/cert.pem
    rm /tmp/cert.pem
    exit 0
else
    echo "Failed to create certificate" >&2
    exit 1
fi
EOF

RUN chmod +x /home/ca/CA/sign_req.sh

# Create CA configuration file
RUN cat <<'EOF' > /home/ca/CA/CA.cnf
[CA_default]
dir = /home/ca/CA
certs = $dir/certs
database = $dir/index.txt
serial = $dir/serial
new_certs_dir = $dir/newcerts
private_key = $dir/private/ca.key.pem
certificate = $dir/certs/ca.cert.pem
policy = policy_anything
default_md = sha256
default_days = 3650

[policy_anything]
countryName = optional
stateOrProvinceName = optional
localityName = optional
organizationName = optional
organizationalUnitName = optional
commonName = supplied
emailAddress = optional

[v3_ca]
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always,issuer
basicConstraints = critical, CA:true
keyUsage = critical, digitalSignature, cRLSign, keyCertSign

[ocsp]
basicConstraints = CA:FALSE
keyUsage = critical, digitalSignature
extendedKeyUsage = critical, OCSPSigning

[tsa_ext]
basicConstraints = CA:FALSE
keyUsage = critical, digitalSignature, nonRepudiation
extendedKeyUsage = critical, timeStamping
EOF

# Add supervisor config for our mock servers
RUN cat <<'EOF' > /etc/supervisor/conf.d/acme.conf
[program:acme]
command=/home/ca/acme_server.py
directory=/home/ca
user=ca
autorestart=true
stdout_logfile=/dev/stdout
stdout_logfile_maxbytes=0
stderr_logfile=/dev/stderr
stderr_logfile_maxbytes=0
EOF

# Make entrypoint executable
RUN chmod +x /root/entrypoint.sh

CMD ["/root/entrypoint.sh"]

EXPOSE 8888 8899 8887
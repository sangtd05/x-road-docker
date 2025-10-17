#!/usr/bin/python3
import http.server
import socketserver
import json

PORT = 8888

# Sample WSDL content
EXAMPLE_WSDL = """<?xml version="1.0" encoding="UTF-8"?>
<wsdl:definitions xmlns:wsdl="http://schemas.xmlsoap.org/wsdl/" 
                  xmlns:soap="http://schemas.xmlsoap.org/wsdl/soap/"
                  xmlns:tns="http://example.org/services"
                  targetNamespace="http://example.org/services">
    <wsdl:message name="GetRandomRequest"/>
    <wsdl:message name="GetRandomResponse">
        <wsdl:part name="result" type="xsd:int"/>
    </wsdl:message>
    
    <wsdl:message name="HelloServiceRequest">
        <wsdl:part name="name" type="xsd:string"/>
    </wsdl:message>
    <wsdl:message name="HelloServiceResponse">
        <wsdl:part name="greeting" type="xsd:string"/>
    </wsdl:message>
    
    <wsdl:message name="ListPeopleRequest"/>
    <wsdl:message name="ListPeopleResponse">
        <wsdl:part name="people" type="xsd:string"/>
    </wsdl:message>
    
    <wsdl:message name="PersonDetailsRequest">
        <wsdl:part name="id" type="xsd:string"/>
    </wsdl:message>
    <wsdl:message name="PersonDetailsResponse">
        <wsdl:part name="details" type="xsd:string"/>
    </wsdl:message>
    
    <wsdl:portType name="ExampleService">
        <wsdl:operation name="getRandom">
            <wsdl:input message="tns:GetRandomRequest"/>
            <wsdl:output message="tns:GetRandomResponse"/>
        </wsdl:operation>
        <wsdl:operation name="helloService">
            <wsdl:input message="tns:HelloServiceRequest"/>
            <wsdl:output message="tns:HelloServiceResponse"/>
        </wsdl:operation>
        <wsdl:operation name="listPeople">
            <wsdl:input message="tns:ListPeopleRequest"/>
            <wsdl:output message="tns:ListPeopleResponse"/>
        </wsdl:operation>
        <wsdl:operation name="personDetails">
            <wsdl:input message="tns:PersonDetailsRequest"/>
            <wsdl:output message="tns:PersonDetailsResponse"/>
        </wsdl:operation>
    </wsdl:portType>
    
    <wsdl:binding name="ExampleServiceSOAP" type="tns:ExampleService">
        <soap:binding style="document" transport="http://schemas.xmlsoap.org/soap/http"/>
        <wsdl:operation name="getRandom">
            <soap:operation soapAction="http://example.org/getRandom"/>
            <wsdl:input><soap:body use="literal"/></wsdl:input>
            <wsdl:output><soap:body use="literal"/></wsdl:output>
        </wsdl:operation>
        <wsdl:operation name="helloService">
            <soap:operation soapAction="http://example.org/helloService"/>
            <wsdl:input><soap:body use="literal"/></wsdl:input>
            <wsdl:output><soap:body use="literal"/></wsdl:output>
        </wsdl:operation>
        <wsdl:operation name="listPeople">
            <soap:operation soapAction="http://example.org/listPeople"/>
            <wsdl:input><soap:body use="literal"/></wsdl:input>
            <wsdl:output><soap:body use="literal"/></wsdl:output>
        </wsdl:operation>
        <wsdl:operation name="personDetails">
            <soap:operation soapAction="http://example.org/personDetails"/>
            <wsdl:input><soap:body use="literal"/></wsdl:input>
            <wsdl:output><soap:body use="literal"/></wsdl:output>
        </wsdl:operation>
    </wsdl:binding>
    
    <wsdl:service name="ExampleService">
        <wsdl:port binding="tns:ExampleServiceSOAP" name="ExampleServiceSOAP">
            <soap:address location="http://example.org/exampleService"/>
        </wsdl:port>
    </wsdl:service>
</wsdl:definitions>"""

# Sample OpenAPI specification
OPENAPI_SPEC = {
    "openapi": "3.0.0",
    "info": {
        "title": "Example API",
        "version": "1.0.0"
    },
    "paths": {
        "/api/members": {
            "get": {
                "summary": "Get all members",
                "responses": {
                    "200": {
                        "description": "A list of members",
                        "content": {
                            "application/json": {
                                "schema": {
                                    "type": "array",
                                    "items": {
                                        "type": "object",
                                        "properties": {
                                            "id": {"type": "string"},
                                            "name": {"type": "string"}
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

class TestServiceHandler(http.server.BaseHTTPRequestHandler):
    def _set_headers(self, content_type="text/xml"):
        self.send_response(200)
        self.send_header('Content-type', content_type)
        self.end_headers()

    def do_GET(self):
        if self.path == "/exampleService.wsdl":
            self._set_headers("text/xml")
            self.wfile.write(EXAMPLE_WSDL.encode())
        elif self.path == "/openapi.json":
            self._set_headers("application/json")
            self.wfile.write(json.dumps(OPENAPI_SPEC).encode())
        elif self.path.startswith("/api/members"):
            self._set_headers("application/json")
            members = [
                {"id": "1", "name": "John Doe"},
                {"id": "2", "name": "Jane Smith"}
            ]
            self.wfile.write(json.dumps(members).encode())
        elif self.path == "/rest":
            self._set_headers("application/json")
            self.wfile.write(json.dumps({"status": "ok"}).encode())
        elif self.path == "/exampleService":
            self._set_headers()
            response = "<soap:Envelope xmlns:soap='http://schemas.xmlsoap.org/soap/envelope/'><soap:Body><response>Success</response></soap:Body></soap:Envelope>"
            self.wfile.write(response.encode())
        elif self.path.startswith("/testca/sign"):
            # This is a special case - sending back a mock certificate
            self._set_headers()
            mock_cert = """-----BEGIN CERTIFICATE-----
MIIDazCCAlOgAwIBAgIUEKGGtw+oeQ2OYiNHs8YEvTTWH3owDQYJKoZIhvcNAQEL
BQAwRTELMAkGA1UEBhMCRkkxDTALBgNVBAgMBFRlc3QxDTALBgNVBAoMBFRlc3Qx
GDAWBgNVBAMMD1Rlc3QgQ2VydGlmaWNhdGUwHhcNMjQwNDExMTIwMDAwWhcNMjUw
NDExMTIwMDAwWjBFMQswCQYDVQQGEwJGSTENMAsGA1UECAwEVGVzdDENMAsGA1UE
CgwEVGVzdDEYMBYGA1UEAwwPVGVzdCBDZXJ0aWZpY2F0ZTCCASIwDQYJKoZIhvcN
AQEBBQADggEPADCCAQoCggEBAKxN1EqF2HD8MGfr1RgwOsFmNrKlY9FjXtWXlE0E
7jULHJwJ9Fk1qBxJCgYCbLyutFJiQZ1DDlJ6dzGVVGIQn9mxGXbRqc8YD8OtyX7E
hOeGmPLHrCTNhuhDXt8ckSfOzUsJi5wUV/1h48XlCkO9aOT4BBwEjzKR8i/C5CT9
S9mj6JRrYKgVvDGDzj8r3/XdaNJAEbRXbCWfGHps/aMPQXv2LnCOZkLV+jIwgjJw
c2RP2bVbhNMj5ScU1PfHQBFJ9QcBJRJC8UUCVFmYOySNY5PYBrsh4MuxeAcLXwT8
RhKp9aYJYEFUSCLdCpJxR+0xVYA1UNpL7w6jnRwIoqZK0VcCAwEAAaNTMFEwHQYD
VR0OBBYEFPvz2xT5ygCMb1Qtb0vE/ZJL5dYvMB8GA1UdIwQYMBaAFPvz2xT5ygCM
b1Qtb0vE/ZJL5dYvMA8GA1UdEwEB/wQFMAMBAf8wDQYJKoZIhvcNAQELBQADggEB
ACTVlxwqTwvhlQQpCVgteXD6mIPaAKAQNE5z3nXtSaiYFqyNisHAd5eBRGkQVJYp
VJxgLcJhgZbA5adRWzg1CZCCQnw3kM84v9TpWmhBXh+umfdAGZzKQIMUe9MWRRQx
D5AlU8Hy9voLuFNZ4e+Q9NK5VBdPCu+JPMbjHn8RYKp0FjWtU7mQg3GY2DNBxiMe
AAhsIweKbFJfHoGfS8zKnPnz3RBk5Q6pUUJK+JzqCCiYO7xEzwXQeNRwPRp5rEUk
BGBOkXKqzLroRYvksdS4aQJHXqPtOgDM5o+AGq9OLQ8t6WYzkcYMwDSZuPTGUgEc
TEDzqgw7i+hP1YSg9YUHw3E=
-----END CERTIFICATE-----"""
            self.wfile.write(mock_cert.encode())
        else:
            self._set_headers("text/plain")
            self.wfile.write(b"Mock service endpoint")

    def do_POST(self):
        content_length = int(self.headers['Content-Length'])
        post_data = self.rfile.read(content_length)
        
        if self.path.startswith("/testca/sign"):
            # Return a mock certificate
            self._set_headers()
            mock_cert = """-----BEGIN CERTIFICATE-----
MIIDazCCAlOgAwIBAgIUEKGGtw+oeQ2OYiNHs8YEvTTWH3owDQYJKoZIhvcNAQEL
BQAwRTELMAkGA1UEBhMCRkkxDTALBgNVBAgMBFRlc3QxDTALBgNVBAoMBFRlc3Qx
GDAWBgNVBAMMD1Rlc3QgQ2VydGlmaWNhdGUwHhcNMjQwNDExMTIwMDAwWhcNMjUw
NDExMTIwMDAwWjBFMQswCQYDVQQGEwJGSTENMAsGA1UECAwEVGVzdDENMAsGA1UE
CgwEVGVzdDEYMBYGA1UEAwwPVGVzdCBDZXJ0aWZpY2F0ZTCCASIwDQYJKoZIhvcN
AQEBBQADggEPADCCAQoCggEBAKxN1EqF2HD8MGfr1RgwOsFmNrKlY9FjXtWXlE0E
7jULHJwJ9Fk1qBxJCgYCbLyutFJiQZ1DDlJ6dzGVVGIQn9mxGXbRqc8YD8OtyX7E
hOeGmPLHrCTNhuhDXt8ckSfOzUsJi5wUV/1h48XlCkO9aOT4BBwEjzKR8i/C5CT9
S9mj6JRrYKgVvDGDzj8r3/XdaNJAEbRXbCWfGHps/aMPQXv2LnCOZkLV+jIwgjJw
c2RP2bVbhNMj5ScU1PfHQBFJ9QcBJRJC8UUCVFmYOySNY5PYBrsh4MuxeAcLXwT8
RhKp9aYJYEFUSCLdCpJxR+0xVYA1UNpL7w6jnRwIoqZK0VcCAwEAAaNTMFEwHQYD
VR0OBBYEFPvz2xT5ygCMb1Qtb0vE/ZJL5dYvMB8GA1UdIwQYMBaAFPvz2xT5ygCM
b1Qtb0vE/ZJL5dYvMA8GA1UdEwEB/wQFMAMBAf8wDQYJKoZIhvcNAQELBQADggEB
ACTVlxwqTwvhlQQpCVgteXD6mIPaAKAQNE5z3nXtSaiYFqyNisHAd5eBRGkQVJYp
VJxgLcJhgZbA5adRWzg1CZCCQnw3kM84v9TpWmhBXh+umfdAGZzKQIMUe9MWRRQx
D5AlU8Hy9voLuFNZ4e+Q9NK5VBdPCu+JPMbjHn8RYKp0FjWtU7mQg3GY2DNBxiMe
AAhsIweKbFJfHoGfS8zKnPnz3RBk5Q6pUUJK+JzqCCiYO7xEzwXQeNRwPRp5rEUk
BGBOkXKqzLroRYvksdS4aQJHXqPtOgDM5o+AGq9OLQ8t6WYzkcYMwDSZuPTGUgEc
TEDzqgw7i+hP1YSg9YUHw3E=
-----END CERTIFICATE-----"""
            self.wfile.write(mock_cert.encode())
        elif self.path == "/exampleService":
            self._set_headers()
            response = "<soap:Envelope xmlns:soap='http://schemas.xmlsoap.org/soap/envelope/'><soap:Body><response>Success</response></soap:Body></soap:Envelope>"
            self.wfile.write(response.encode())
        elif self.path == "/rest":
            self._set_headers("application/json")
            self.wfile.write(json.dumps({"status": "ok"}).encode())
        else:
            self._set_headers("application/json")
            self.wfile.write(json.dumps({"status": "ok"}).encode())

# Add to the testca.conf file to start this service
print("""
[program:test-services]
command=python3 /home/ca/test_services.py
directory=/home/ca
user=ca
autorestart=true
stdout_logfile=/dev/stdout
stdout_logfile_maxbytes=0
stderr_logfile=/dev/stderr
stderr_logfile_maxbytes=0
""")

if __name__ == "__main__":
    with socketserver.TCPServer(("", PORT), TestServiceHandler) as httpd:
        print(f"Mock test services running at port {PORT}")
        httpd.serve_forever()
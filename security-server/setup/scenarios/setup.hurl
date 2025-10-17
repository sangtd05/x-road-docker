# Check that the Security Server UI is up and running
GET https://{{ss_host}}:4000
HTTP 200

# Create Security Server API-Key
POST https://{{ss_host}}:4000/api/v1/api-keys
[BasicAuth]
{{ss_admin_user}}: {{ss_admin_user_password}}
[
    "XROAD_SECURITY_OFFICER",
    "XROAD_REGISTRATION_OFFICER",
    "XROAD_SERVICE_ADMINISTRATOR",
    "XROAD_SYSTEM_ADMINISTRATOR",
    "XROAD_SECURITYSERVER_OBSERVER",
    "XROAD_MANAGEMENT_SERVICE"
]

HTTP 200

[Captures]
ss_api_key: jsonpath "$['key']"

# Download global configuration anchor from Central Server
GET https://{{cs_host}}:4000/api/v1/configuration-sources/INTERNAL/anchor/download
Authorization: X-Road-ApiKey token={{cs_api_key}}

HTTP 200

[Captures]
gconf_anchor: body

# Add configuration anchor
POST https://{{ss_host}}:4000/api/v1/system/anchor
Authorization: X-Road-ApiKey token={{ss_api_key}}
Content-Type: application/octet-stream
```
{{gconf_anchor}}
```

HTTP 201

# Initialize Security Server
POST https://{{ss_host}}:4000/api/v1/initialization
Authorization: X-Road-ApiKey token={{ss_api_key}}
Content-Type: application/json
{
    "owner_member_class": "{{ss_member_class}}",
    "owner_member_code": "{{ss_member_code}}",
    "security_server_code": "{{ss_security_server_code}}",
    "software_token_pin": "{{ss_token_pin}}",
    "ignore_warnings": true
}

HTTP 201

# Log in to the Security Server token
PUT https://{{ss_host}}:4000/api/v1/tokens/0/login
Authorization: X-Road-ApiKey token={{ss_api_key}}
Content-Type: application/json
{
    "password": "{{ss_token_pin}}"
}

HTTP *

# Get the CA name
GET https://{{ss_host}}:4000/api/v1/certificate-authorities
Authorization: X-Road-ApiKey token={{ss_api_key}}

HTTP 200

[Captures]
ca_name: jsonpath "$[0].name"

# Add auth key to the Security Server token
POST https://{{ss_host}}:4000/api/v1/tokens/0/keys-with-csrs
Authorization: X-Road-ApiKey token={{ss_api_key}}
Content-Type: application/json
{
    "key_label": "Auth key",
    "csr_generate_request": {
        "key_usage_type": "AUTHENTICATION",
        "ca_name": "{{ca_name}}",
        "csr_format": "DER",
        "subject_field_values": {
            "CN": "{{ss_host}}",
            "C": "VN",
            "O": "{{ss_member_name}}",
            "subjectAltName": "{{ss_host}}",
            "serialNumber": "{{cs_instance_identifier}}/{{ss_security_server_code}}/{{ss_member_class}}"
        }
    }
}

HTTP 200

[Captures]
ss_auth_key_id: jsonpath "$.key.id"
ss_auth_key_csr_id: jsonpath "$.csr_id"

# Get the auth key CSR
GET https://{{ss_host}}:4000/api/v1/keys/{{ss_auth_key_id}}/csrs/{{ss_auth_key_csr_id}}?csr_format=PEM
Authorization: X-Road-ApiKey token={{ss_api_key}}

HTTP 200

[Captures]
ss_auth_key_csr: body

# Sign the auth key CSR
POST http://{{ca_host}}:8888/testca/sign
Content-Type: multipart/form-data; boundary=certboundary
```
--certboundary
Content-Disposition: form-data; name="type"

auth
--certboundary
Content-Disposition: form-data; name="certreq"; filename="auth.csr.pem"

{{ss_auth_key_csr}}
--certboundary--
```

HTTP 200

[Captures]
ss_auth_key_cert: body

# Import auth certificate
POST https://{{ss_host}}:4000/api/v1/token-certificates
Authorization: X-Road-ApiKey token={{ss_api_key}}
Content-Type: application/octet-stream
```
{{ss_auth_key_cert}}
```

HTTP 201

[Captures]
ss_auth_key_cert_hash: jsonpath "$.certificate_details.hash"

# Add sign key to the Security Server token
POST https://{{ss_host}}:4000/api/v1/tokens/0/keys-with-csrs
Authorization: X-Road-ApiKey token={{ss_api_key}}
Content-Type: application/json
{
    "key_label": "Sign key",
    "csr_generate_request": {
        "key_usage_type": "SIGNING",
        "ca_name": "{{ca_name}}",
        "csr_format": "DER",
        "member_id": "{{cs_instance_identifier}}:{{ss_member_class}}:{{ss_member_code}}",
        "subject_field_values": {
            "CN": "{{ss_member_code}}",
            "C": "VN",
            "O": "{{ss_member_name}}",
            "subjectAltName": "{{ss_host}}",
            "serialNumber": "{{cs_instance_identifier}}/{{ss_security_server_code}}/{{ss_member_class}}"
        }
    }
}

HTTP 200

[Captures]
ss_sign_key_id: jsonpath "$.key.id"
ss_sign_key_csr_id: jsonpath "$.csr_id"

# Get the sign key CSR
GET https://{{ss_host}}:4000/api/v1/keys/{{ss_sign_key_id}}/csrs/{{ss_sign_key_csr_id}}?csr_format=PEM
Authorization: X-Road-ApiKey token={{ss_api_key}}

HTTP 200

[Captures]
ss_sign_key_csr: body

# Sign the sign key CSR
POST http://{{ca_host}}:8888/testca/sign
Content-Type: multipart/form-data; boundary=certboundary
```
--certboundary
Content-Disposition: form-data; name="type"

sign
--certboundary
Content-Disposition: form-data; name="certreq"; filename="sign.csr.pem"

{{ss_sign_key_csr}}
--certboundary--
```

HTTP 200

[Captures]
ss_sign_key_cert: body

# Import sign certificate
POST https://{{ss_host}}:4000/api/v1/token-certificates
Authorization: X-Road-ApiKey token={{ss_api_key}}
Content-Type: application/octet-stream
```
{{ss_sign_key_cert}}
```

HTTP 201

[Captures]
ss_sign_key_cert_hash: jsonpath "$.certificate_details.hash"

# Register auth certificate
PUT https://{{ss_host}}:4000/api/v1/token-certificates/{{ss_auth_key_cert_hash}}/register
Authorization: X-Road-ApiKey token={{ss_api_key}}
{
    "address": "{{ss_host}}"
}

HTTP 204

# Accept Security Server auth certificate registration
GET https://{{cs_host}}:4000/api/v1/management-requests?sort=id&desc=true&status=WAITING
Authorization: X-Road-ApiKey token={{cs_api_key}}

HTTP 200

[Captures]
ss_auth_cert_reg_req_id: jsonpath "$.items[0].id"

POST https://{{cs_host}}:4000/api/v1/management-requests/{{ss_auth_cert_reg_req_id}}/approval
Authorization: X-Road-ApiKey token={{cs_api_key}}

HTTP 200

# Activate auth certificate on Security Server
PUT https://{{ss_host}}:4000/api/v1/token-certificates/{{ss_auth_key_cert_hash}}/activate
Authorization: X-Road-ApiKey token={{ss_api_key}}

HTTP 204

# Set timestamping service on Security Server
GET https://{{ss_host}}:4000/api/v1/timestamping-services
Authorization: X-Road-ApiKey token={{ss_api_key}}

HTTP 200

[Captures]
tsa_name: jsonpath "$[0].name"
tsa_url: jsonpath "$[0].url"

POST https://{{ss_host}}:4000/api/v1/system/timestamping-services
Authorization: X-Road-ApiKey token={{ss_api_key}}
{
    "name": "{{tsa_name}}",
    "url": "{{tsa_url}}"
}

HTTP 201

# Add subsystem to Security Server
POST https://{{ss_host}}:4000/api/v1/clients
Authorization: X-Road-ApiKey token={{ss_api_key}}
{
    "ignore_warnings": true,
    "client": {
        "member_class": "{{ss_member_class}}",
        "member_code": "{{ss_member_code}}",
        "subsystem_code": "{{ss_subsystem_code}}",
        "connection_type": "HTTP"
    }
}

HTTP 201

[Captures]
ss_subsystem_id: jsonpath "$.id"

# Register subsystem to Security Server
PUT https://{{ss_host}}:4000/api/v1/clients/{{ss_subsystem_id}}/register
Authorization: X-Road-ApiKey token={{ss_api_key}}

HTTP 204

# Accept Security Server subsystem registration
GET https://{{cs_host}}:4000/api/v1/management-requests?sort=id&desc=true&status=WAITING
Authorization: X-Road-ApiKey token={{cs_api_key}}

HTTP 200

[Captures]
ss_subsystem_reg_req_id: jsonpath "$.items[0].id"

POST https://{{cs_host}}:4000/api/v1/management-requests/{{ss_subsystem_reg_req_id}}/approval
Authorization: X-Road-ApiKey token={{cs_api_key}}

HTTP 200

# Add TestService to Security Server
POST https://{{ss_host}}:4000/api/v1/clients
Authorization: X-Road-ApiKey token={{ss_api_key}}
{
    "ignore_warnings": true,
    "client": {
        "member_class": "{{ss_member_class}}",
        "member_code": "{{ss_member_code}}",
        "subsystem_code": "TestService",
        "connection_type": "HTTP"
    }
}

HTTP 201

[Captures]
ss_test_service_id: jsonpath "$.id"

# Register TestService to Security Server
PUT https://{{ss_host}}:4000/api/v1/clients/{{ss_test_service_id}}/register
Authorization: X-Road-ApiKey token={{ss_api_key}}

HTTP 204

# Accept Security Server TestService registration
GET https://{{cs_host}}:4000/api/v1/management-requests?sort=id&desc=true&status=WAITING
Authorization: X-Road-ApiKey token={{cs_api_key}}

HTTP 200

[Captures]
ss_test_service_req_id: jsonpath "$.items[0].id"

POST https://{{cs_host}}:4000/api/v1/management-requests/{{ss_test_service_req_id}}/approval
Authorization: X-Road-ApiKey token={{cs_api_key}}

HTTP 200

# Add example service to Security Server
POST https://{{ss_host}}:4000/api/v1/clients/{{ss_test_service_id}}/service-descriptions
Authorization: X-Road-ApiKey token={{ss_api_key}}
{
    "url": "{{example_service_wsdl}}",
    "type": "WSDL",
    "ignore_warnings": true
}

HTTP 201

[Captures]
ss_test_service_service_id: jsonpath "$.id"
ss_test_service_service_service_id: jsonpath "$.services[0].id"

# Add test service URL
PATCH https://{{ss_host}}:4000/api/v1/services/{{ss_test_service_service_service_id}}
Authorization: X-Road-ApiKey token={{ss_api_key}}
{
    "ignore_warnings": true,
    "ssl_auth": false,
    "ssl_auth_all": true,
    "timeout": 60,
    "timeout_all": true,
    "url": "{{example_service_address}}",
    "url_all": true
}

HTTP 200

# Enable soap service on Security Server
PUT https://{{ss_host}}:4000/api/v1/service-descriptions/{{ss_test_service_service_id}}/enable
Authorization: X-Road-ApiKey token={{ss_api_key}}

HTTP 200

# Register REST service
POST https://{{ss_host}}:4000/api/v1/clients/{{ss_test_service_id}}/service-descriptions
Authorization: X-Road-ApiKey token={{ss_api_key}}
{
    "url": "{{is_rest_url}}",
    "type": "REST",
    "rest_service_code": "{{is_rest_service_code}}"
}

HTTP 201

[Captures]
ss_test_rest_service_service_id: jsonpath "$.id"

# Enable REST service
PUT https://{{ss_host}}:4000/api/v1/service-descriptions/{{ss_test_rest_service_service_id}}/enable
Authorization: X-Road-ApiKey token={{ss_api_key}}

HTTP 200

# Register OpenAPI REST service
POST https://{{ss_host}}:4000/api/v1/clients/{{ss_test_service_id}}/service-descriptions
Authorization: X-Road-ApiKey token={{ss_api_key}}
{
    "url": "{{is_openapi_url}}",
    "type": "OPENAPI3",
    "rest_service_code": "{{is_openapi_service_code}}"
}

HTTP 201

[Captures]
ss_test_rest_openapi_service_service_id: jsonpath "$.id"

# Add TestClient access to OpenAPI REST service's "GET members" endpoint
GET https://{{ss_host}}:4000/api/v1/services/{{ss_test_service_id}}%3A{{is_openapi_service_code}}
Authorization: X-Road-ApiKey token={{ss_api_key}}

HTTP 200

[Captures]
# Until Hurl supports combining multiple filters in JSONPath, we need to use this approach:
# Ideal would be: "$.endpoints[?(@.path == '/api/members' && @.method == 'GET')].id" nth 0
ss_test_rest_openapi_service_get_members_endpoint_id: jsonpath "$.endpoints[?(@.path == '/api/members')].id" nth 0

# Enable OpenAPI REST service
PUT https://{{ss_host}}:4000/api/v1/service-descriptions/{{ss_test_rest_openapi_service_service_id}}/enable
Authorization: X-Road-ApiKey token={{ss_api_key}}

HTTP 200
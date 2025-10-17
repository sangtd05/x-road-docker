# Check that the Central Server UI is up and running
GET https://{{cs_host}}:4000

HTTP 200

# Create Central Server API-Key
POST https://{{cs_host}}:4000/api/v1/api-keys
[BasicAuth]
{{cs_admin_user}}: {{cs_admin_user_password}}
[
    "XROAD_REGISTRATION_OFFICER",
    "XROAD_SECURITY_OFFICER",
    "XROAD_SYSTEM_ADMINISTRATOR",
    "XROAD_MANAGEMENT_SERVICE"
]

HTTP 200

[Captures]
cs_api_key: jsonpath "$['key']"

# Initialize Central Server
POST https://{{cs_host}}:4000/api/v1/initialization
Authorization: X-Road-ApiKey token={{cs_api_key}}
Content-Type: application/json
{
    "software_token_pin": "{{cs_token_pin}}",
    "instance_identifier": "{{cs_instance_identifier}}",
    "central_server_address": "{{cs_host}}"
}

# FIXME: The Central Server currently returns 200 but documentation says it should be 201
# https://github.com/nordic-institute/X-Road/blob/6ef2d9e83287ccb281b0cc27ba663a5ae8c4aa16/src/central-server/openapi-model/src/main/resources/openapi-definition.yaml#L1344
HTTP 200

# Add member classes to Central Server
POST https://{{cs_host}}:4000/api/v1/member-classes
Authorization: X-Road-ApiKey token={{cs_api_key}}
Content-Type: application/json
{
    "code": "GOV",
    "description": "Governmental organizations"
}

POST https://{{cs_host}}:4000/api/v1/member-classes
Authorization: X-Road-ApiKey token={{cs_api_key}}
Content-Type: application/json
{
    "code": "EDU",
    "description": "Educational organizations"
}

POST https://{{cs_host}}:4000/api/v1/member-classes
Authorization: X-Road-ApiKey token={{cs_api_key}}
Content-Type: application/json
{
    "code": "ORG",
    "description": "Non-profit organizations"
}

POST https://{{cs_host}}:4000/api/v1/member-classes
Authorization: X-Road-ApiKey token={{cs_api_key}}
Content-Type: application/json
{
    "code": "COM",
    "description": "Commercial organizations"
}

HTTP 201

# Log in Central Server token
PUT https://{{cs_host}}:4000/api/v1/tokens/0/login
Authorization: X-Road-ApiKey token={{cs_api_key}}
Content-Type: application/json
{
    "password": "{{cs_token_pin}}"
}

HTTP *

# Add internal signing key to Central Server
POST https://{{cs_host}}:4000/api/v1/configuration-sources/INTERNAL/signing-keys
Authorization: X-Road-ApiKey token={{cs_api_key}}
Content-Type: application/json
{
    "key_label": "Internal signing key",
    "token_id": 0
}

# FIXME: The Central Server currently returns 200 but documentation says it should be 201
# https://github.com/nordic-institute/X-Road/blob/6ef2d9e83287ccb281b0cc27ba663a5ae8c4aa16/src/central-server/openapi-model/src/main/resources/openapi-definition.yaml#L1051
HTTP 200

# Add external signing key to Central Server
POST https://{{cs_host}}:4000/api/v1/configuration-sources/EXTERNAL/signing-keys
Authorization: X-Road-ApiKey token={{cs_api_key}}
Content-Type: application/json
{
    "key_label": "External signing key",
    "token_id": 0
}

# FIXME: The Central Server currently returns 200 but documentation says it should be 201
# https://github.com/nordic-institute/X-Road/blob/6ef2d9e83287ccb281b0cc27ba663a5ae8c4aa16/src/central-server/openapi-model/src/main/resources/openapi-definition.yaml#L1051
HTTP 200

# Add member to Central Server
POST https://{{cs_host}}:4000/api/v1/members
Authorization: X-Road-ApiKey token={{cs_api_key}}
Content-Type: application/json
{
    "member_id": {
        "member_class": "{{ssm_member_class}}",
        "member_code": "{{ssm_member_code}}"
    },
    "member_name": "{{ssm_member_name}}"
}

HTTP 201

# Add management subsystem for member to Central Server
POST https://{{cs_host}}:4000/api/v1/subsystems
Authorization: X-Road-ApiKey token={{cs_api_key}}
Content-Type: application/json
{
    "subsystem_id": {
        "member_class": "{{ssm_member_class}}",
        "member_code": "{{ssm_member_code}}",
        "subsystem_code": "{{ssm_subsystem_code}}"
    }
}

HTTP 201

# Set management subsystem for member as the management service for the Central Server
PATCH https://{{cs_host}}:4000/api/v1/management-services-configuration
Authorization: X-Road-ApiKey token={{cs_api_key}}
Content-Type: application/json
{
    "service_provider_id": "{{cs_instance_identifier}}:{{ssm_member_class}}:{{ssm_member_code}}:{{ssm_subsystem_code}}"
}

HTTP 200

# Add test CA to Central Server configuration
POST https://{{cs_host}}:4000/api/v1/certification-services
Authorization: X-Road-ApiKey token={{cs_api_key}}
[MultipartFormData]
certificate_profile_info: ee.ria.xroad.common.certificateprofile.impl.FiVRKCertificateProfileInfoProvider
tls_auth: false
acme_server_directory_url: http://{{ca_host}}:8887
certificate: file,ca/ca.pem;

HTTP 201

[Captures]
ca_id: jsonpath "$.id"

# Add OCSP to test CA in the Central Server configuration
POST https://{{cs_host}}:4000/api/v1/certification-services/{{ca_id}}/ocsp-responders
Authorization: X-Road-ApiKey token={{cs_api_key}}
[MultipartFormData]
url: http://{{ca_host}}:8888
certificate: file,ca/ocsp.pem;

HTTP 201

# Add TSA to the Central Server
POST https://{{cs_host}}:4000/api/v1/timestamping-services
Authorization: X-Road-ApiKey token={{cs_api_key}}
[MultipartFormData]
url: http://{{ca_host}}:8899
certificate: file,ca/tsa.pem;

HTTP 201

# Download global configuration anchor from Central Server
GET https://{{cs_host}}:4000/api/v1/configuration-sources/INTERNAL/anchor/download
Authorization: X-Road-ApiKey token={{cs_api_key}}

HTTP 200

[Captures]
gconf_anchor: body

# Initialize management Security Server

# Check that the Security Server UI is up and running
GET https://{{ss0_host}}:4000
HTTP 200

# Create management Security Server API-Key
POST https://{{ss0_host}}:4000/api/v1/api-keys
[BasicAuth]
{{ss0_admin_user}}: {{ss0_admin_user_password}}
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
ss0_api_key: jsonpath "$['key']"

# Add configuration anchor
POST https://{{ss0_host}}:4000/api/v1/system/anchor
Authorization: X-Road-ApiKey token={{ss0_api_key}}
Content-Type: application/octet-stream
```
{{gconf_anchor}}
```

HTTP 201

# Initialize management Security Server
POST https://{{ss0_host}}:4000/api/v1/initialization
Authorization: X-Road-ApiKey token={{ss0_api_key}}
Content-Type: application/json
{
    "owner_member_class": "{{ssm_member_class}}",
    "owner_member_code": "{{ssm_member_code}}",
    "security_server_code": "{{ssm_security_server_code}}",
    "software_token_pin": "{{ssm_token_pin}}",
    "ignore_warnings": true
}

HTTP 201

# Log in to the Security Servers token
PUT https://{{ss0_host}}:4000/api/v1/tokens/0/login
Authorization: X-Road-ApiKey token={{ss0_api_key}}
Content-Type: application/json
{
    "password": "{{ssm_token_pin}}"
}

HTTP *

# Get the CA name
GET https://{{ss0_host}}:4000/api/v1/certificate-authorities
Authorization: X-Road-ApiKey token={{ss0_api_key}}

HTTP 200

[Captures]
ca_name: jsonpath "$[0].name"

# Add auth key to the Security Server token
POST https://{{ss0_host}}:4000/api/v1/tokens/0/keys-with-csrs
Authorization: X-Road-ApiKey token={{ss0_api_key}}
Content-Type: application/json
{
    "key_label": "Auth key",
    "csr_generate_request": {
        "key_usage_type": "AUTHENTICATION",
        "ca_name": "{{ca_name}}",
        "csr_format": "DER",
        "subject_field_values": {
            "CN": "{{ss0_host}}",
            "C": "FI",
            "O": "{{ssm_member_name}}",
            "subjectAltName": "{{ss0_host}}",
            "serialNumber": "{{cs_instance_identifier}}/{{ssm_security_server_code}}/{{ssm_member_class}}"
        }
    }
}
# FIXME: This should return 201 according to the definition:
# https://github.com/nordic-institute/X-Road/blob/e14d198f704b34b4d1789c2972e816152b6a35f8/src/security-server/openapi-model/src/main/resources/META-INF/openapi-definition.yaml#L4846
HTTP 200

[Captures]
ss0_auth_key_id: jsonpath "$.key.id"
ss0_auth_key_csr_id: jsonpath "$.csr_id"

# Get the auth key CSR
GET https://{{ss0_host}}:4000/api/v1/keys/{{ss0_auth_key_id}}/csrs/{{ss0_auth_key_csr_id}}?csr_format=PEM
Authorization: X-Road-ApiKey token={{ss0_api_key}}

HTTP 200

[Captures]
ss0_auth_key_csr: body

# Sign the auth key CSR (note that the test CA needs filename so we can't just send it under
# [FormMultiPart] as we do with the other requests)
POST http://{{ca_host}}:8888/testca/sign
Content-Type: multipart/form-data; boundary=certboundary
```
--certboundary
Content-Disposition: form-data; name="type"

auth
--certboundary
Content-Disposition: form-data; name="certreq"; filename="auth.csr.pem"

{{ss0_auth_key_csr}}
--certboundary--
```

HTTP 200

[Captures]
ss0_auth_key_cert: body

# Import auth certificate
POST https://{{ss0_host}}:4000/api/v1/token-certificates
Authorization: X-Road-ApiKey token={{ss0_api_key}}
Content-Type: application/octet-stream
```
{{ss0_auth_key_cert}}
```

HTTP 201

[Captures]
ss0_auth_key_cert_hash: jsonpath "$.certificate_details.hash"

# Add sign key to the Security Server token
POST https://{{ss0_host}}:4000/api/v1/tokens/0/keys-with-csrs
Authorization: X-Road-ApiKey token={{ss0_api_key}}
Content-Type: application/json
{
    "key_label": "Sign key",
    "csr_generate_request": {
        "key_usage_type": "SIGNING",
        "ca_name": "{{ca_name}}",
        "csr_format": "DER",
        "member_id": "{{cs_instance_identifier}}:{{ssm_member_class}}:{{ssm_member_code}}",
        "subject_field_values": {
            "CN": "{{ssm_member_code}}",
            "C": "FI",
            "O": "{{ssm_member_name}}",
            "subjectAltName": "{{ss0_host}}",
            "serialNumber": "{{cs_instance_identifier}}/{{ssm_security_server_code}}/{{ssm_member_class}}"
        }
    }
}

# FIXME: This should return 201 according to the definition (same as for auth key above)
HTTP 200

[Captures]
ss0_sign_key_id: jsonpath "$.key.id"
ss0_sign_key_csr_id: jsonpath "$.csr_id"

# Get the sign key CSR
GET https://{{ss0_host}}:4000/api/v1/keys/{{ss0_sign_key_id}}/csrs/{{ss0_sign_key_csr_id}}?csr_format=PEM
Authorization: X-Road-ApiKey token={{ss0_api_key}}

HTTP 200

[Captures]
ss0_sign_key_csr: body

# Sign the sign key CSR (note that the test CA needs filename so we can't just send it under
# [FormMultiPart] as we do with the other requests)
POST http://{{ca_host}}:8888/testca/sign
Content-Type: multipart/form-data; boundary=certboundary
```
--certboundary
Content-Disposition: form-data; name="type"

sign
--certboundary
Content-Disposition: form-data; name="certreq"; filename="sign.csr.pem"

{{ss0_sign_key_csr}}
--certboundary--
```

HTTP 200

[Captures]
ss0_sign_key_cert: body

# Import sign certificate
POST https://{{ss0_host}}:4000/api/v1/token-certificates
Authorization: X-Road-ApiKey token={{ss0_api_key}}
Content-Type: application/octet-stream
```
{{ss0_sign_key_cert}}
```

HTTP 201

[Captures]
ss0_sign_key_cert_hash: jsonpath "$.certificate_details.hash"

# Register auth certificate
PUT https://{{ss0_host}}:4000/api/v1/token-certificates/{{ss0_auth_key_cert_hash}}/register
Authorization: X-Road-ApiKey token={{ss0_api_key}}
{
    "address": "{{ss0_host}}"
}

# FIXME: This should be 200 according to the OpenAPI description but is 204:
# https://github.com/nordic-institute/X-Road/blob/e14d198f704b34b4d1789c2972e816152b6a35f8/src/security-server/openapi-model/src/main/resources/META-INF/openapi-definition.yaml#L640
HTTP 204

# Accept Security Server auth certificate registration
GET https://{{cs_host}}:4000/api/v1/management-requests?sort=id&desc=true&status=WAITING
Authorization: X-Road-ApiKey token={{cs_api_key}}

HTTP 200

[Captures]
ss0_auth_cert_reg_req_id: jsonpath "$.items[0].id"

POST https://{{cs_host}}:4000/api/v1/management-requests/{{ss0_auth_cert_reg_req_id}}/approval
Authorization: X-Road-ApiKey token={{cs_api_key}}

HTTP 200

# Register management subsystem to Security Server
POST https://{{cs_host}}:4000/api/v1/management-services-configuration/register-provider
Authorization: X-Road-ApiKey token={{cs_api_key}}
{
    "security_server_id": "{{cs_instance_identifier}}:{{ssm_member_class}}:{{ssm_member_code}}:{{ssm_security_server_code}}"
}

HTTP 200

# Add MANAGEMENT to management Security Server
POST https://{{ss0_host}}:4000/api/v1/clients
Authorization: X-Road-ApiKey token={{ss0_api_key}}
{
    "ignore_warnings": true,
    "client": {
        "member_class": "{{ssm_member_class}}",
        "member_code": "{{ssm_member_code}}",
        "subsystem_code": "{{ssm_subsystem_code}}",
        "connection_type": "HTTP"
    }
}

HTTP 201

[Captures]
ss0_management_client_id: jsonpath "$.id"

# Get Central Server management services settings
GET https://{{cs_host}}:4000/api/v1/management-services-configuration
Authorization: X-Road-ApiKey token={{cs_api_key}}

HTTP 200

[Captures]
cs_management_service_address: jsonpath "$.services_address"
cs_management_service_wsdl: jsonpath "$.wsdl_address"

# Add Central Server management service to SS0 Security Server
POST https://{{ss0_host}}:4000/api/v1/clients/{{ss0_management_client_id}}/service-descriptions
Authorization: X-Road-ApiKey token={{ss0_api_key}}
{
    "url": "{{cs_management_service_wsdl}}",
    "type": "WSDL",
    "ignore_warnings": true
}

HTTP 201

[Captures]
ss0_management_service_id: jsonpath "$.id"
ss0_auth_cert_deletion_service_id: jsonpath "$.services[0].id"

# Add security server owners group access to management services
PATCH https://{{ss0_host}}:4000/api/v1/services/{{ss0_auth_cert_deletion_service_id}}
Authorization: X-Road-ApiKey token={{ss0_api_key}}
{
    "ignore_warnings": true,
    "ssl_auth": false,
    "ssl_auth_all": true,
    "timeout": 60,
    "timeout_all": true,
    "url": "{{cs_management_service_address}}",
    "url_all": true
}

HTTP 200

# Add security server owners group access to management services
POST https://{{ss0_host}}:4000/api/v1/clients/{{ss0_management_client_id}}/service-clients/{{cs_instance_identifier}}:security-server-owners/access-rights
Authorization: X-Road-ApiKey token={{ss0_api_key}}
{
    "items": [
        {
            "service_code": "authCertDeletion"
        },
        {
            "service_code": "clientDeletion"
        },
        {
            "service_code": "clientReg"
        },
        {
            "service_code": "ownerChange"
        },
        {
            "service_code": "clientEnable"
        },
        {
            "service_code": "clientDisable"
        },
        {
            "service_code": "addressChange"
        },
        {
            "service_code": "clientRename"
        }
    ]
}

HTTP 201

# Enable management subsystem on management Security Server
PUT https://{{ss0_host}}:4000/api/v1/service-descriptions/{{ss0_management_service_id}}/enable
Authorization: X-Road-ApiKey token={{ss0_api_key}}

# FIXME: This should be 204 according to the OpenAPI description but is 200:
# https://github.com/nordic-institute/X-Road/blob/e14d198f704b34b4d1789c2972e816152b6a35f8/src/security-server/openapi-model/src/main/resources/META-INF/openapi-definition.yaml#L3908
HTTP 200

# Activate auth certificate on Security Server
PUT https://{{ss0_host}}:4000/api/v1/token-certificates/{{ss0_auth_key_cert_hash}}/activate
Authorization: X-Road-ApiKey token={{ss0_api_key}}

HTTP 204

# Set timestamping service on Security Server
GET https://{{ss0_host}}:4000/api/v1/timestamping-services
Authorization: X-Road-ApiKey token={{ss0_api_key}}

HTTP 200

[Captures]
tsa_name: jsonpath "$[0].name"
tsa_url: jsonpath "$[0].url"

POST https://{{ss0_host}}:4000/api/v1/system/timestamping-services
Authorization: X-Road-ApiKey token={{ss0_api_key}}
{
    "name": "{{tsa_name}}",
    "url": "{{tsa_url}}"
}

HTTP 201

# Initialize Security Server 1 (SS1)

# Check that the Security Server UI is up and running
GET https://{{ss1_host}}:4000
HTTP 200

# Create SS1 Security Server API-Key
POST https://{{ss1_host}}:4000/api/v1/api-keys
[BasicAuth]
{{ss1_admin_user}}: {{ss1_admin_user_password}}
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
ss1_api_key: jsonpath "$['key']"

# Add configuration anchor
POST https://{{ss1_host}}:4000/api/v1/system/anchor
Authorization: X-Road-ApiKey token={{ss1_api_key}}
Content-Type: application/octet-stream
```
{{gconf_anchor}}
```

HTTP 201

# Initialize SS1 Security Server
POST https://{{ss1_host}}:4000/api/v1/initialization
Authorization: X-Road-ApiKey token={{ss1_api_key}}
Content-Type: application/json
{
    "owner_member_class": "COM",
    "owner_member_code": "4321",
    "security_server_code": "SS1",
    "software_token_pin": "Secret1234",
    "ignore_warnings": true
}

HTTP 201

# Log in to the Security Servers token
PUT https://{{ss1_host}}:4000/api/v1/tokens/0/login
Authorization: X-Road-ApiKey token={{ss1_api_key}}
Content-Type: application/json
{
    "password": "Secret1234"
}

HTTP *

# Add auth key to the SS1 Security Server token
POST https://{{ss1_host}}:4000/api/v1/tokens/0/keys-with-csrs
Authorization: X-Road-ApiKey token={{ss1_api_key}}
Content-Type: application/json
{
    "key_label": "Auth key",
    "csr_generate_request": {
        "key_usage_type": "AUTHENTICATION",
        "ca_name": "{{ca_name}}",
        "csr_format": "DER",
        "subject_field_values": {
            "CN": "{{ss1_host}}",
            "C": "FI",
            "O": "Test client",
            "subjectAltName": "{{ss1_host}}",
            "serialNumber": "{{cs_instance_identifier}}/SS1/COM"
        }
    }
}

HTTP 200

[Captures]
ss1_auth_key_id: jsonpath "$.key.id"
ss1_auth_key_csr_id: jsonpath "$.csr_id"

# Get the auth key CSR
GET https://{{ss1_host}}:4000/api/v1/keys/{{ss1_auth_key_id}}/csrs/{{ss1_auth_key_csr_id}}?csr_format=PEM
Authorization: X-Road-ApiKey token={{ss1_api_key}}

HTTP 200

[Captures]
ss1_auth_key_csr: body

# Sign the auth key CSR
POST http://{{ca_host}}:8888/testca/sign
Content-Type: multipart/form-data; boundary=certboundary
```
--certboundary
Content-Disposition: form-data; name="type"

auth
--certboundary
Content-Disposition: form-data; name="certreq"; filename="auth.csr.pem"

{{ss1_auth_key_csr}}
--certboundary--
```

HTTP 200

[Captures]
ss1_auth_key_cert: body

# Import auth certificate
POST https://{{ss1_host}}:4000/api/v1/token-certificates
Authorization: X-Road-ApiKey token={{ss1_api_key}}
Content-Type: application/octet-stream
```
{{ss1_auth_key_cert}}
```

HTTP 201

[Captures]
ss1_auth_key_cert_hash: jsonpath "$.certificate_details.hash"

# Add sign key to the Security Server token
POST https://{{ss1_host}}:4000/api/v1/tokens/0/keys-with-csrs
Authorization: X-Road-ApiKey token={{ss1_api_key}}
Content-Type: application/json
{
    "key_label": "Sign key",
    "csr_generate_request": {
        "key_usage_type": "SIGNING",
        "ca_name": "{{ca_name}}",
        "csr_format": "DER",
        "member_id": "{{cs_instance_identifier}}:COM:4321",
        "subject_field_values": {
            "CN": "4321",
            "C": "FI",
            "O": "Test client",
            "subjectAltName": "{{ss1_host}}",
            "serialNumber": "{{cs_instance_identifier}}/SS1/COM"
        }
    }
}

HTTP 200

[Captures]
ss1_sign_key_id: jsonpath "$.key.id"
ss1_sign_key_csr_id: jsonpath "$.csr_id"

# Get the sign key CSR
GET https://{{ss1_host}}:4000/api/v1/keys/{{ss1_sign_key_id}}/csrs/{{ss1_sign_key_csr_id}}?csr_format=PEM
Authorization: X-Road-ApiKey token={{ss1_api_key}}

HTTP 200

[Captures]
ss1_sign_key_csr: body

# Sign the sign key CSR
POST http://{{ca_host}}:8888/testca/sign
Content-Type: multipart/form-data; boundary=certboundary
```
--certboundary
Content-Disposition: form-data; name="type"

sign
--certboundary
Content-Disposition: form-data; name="certreq"; filename="sign.csr.pem"

{{ss1_sign_key_csr}}
--certboundary--
```

HTTP 200

[Captures]
ss1_sign_key_cert: body

# Import sign certificate
POST https://{{ss1_host}}:4000/api/v1/token-certificates
Authorization: X-Road-ApiKey token={{ss1_api_key}}
Content-Type: application/octet-stream
```
{{ss1_sign_key_cert}}
```

HTTP 201

[Captures]
ss1_sign_key_cert_hash: jsonpath "$.certificate_details.hash"

# Register auth certificate
PUT https://{{ss1_host}}:4000/api/v1/token-certificates/{{ss1_auth_key_cert_hash}}/register
Authorization: X-Road-ApiKey token={{ss1_api_key}}
{
    "address": "{{ss1_host}}"
}

HTTP 204

# Accept Security Server auth certificate registration
GET https://{{cs_host}}:4000/api/v1/management-requests?sort=id&desc=true&status=WAITING
Authorization: X-Road-ApiKey token={{cs_api_key}}

HTTP 200

[Captures]
ss1_auth_cert_reg_req_id: jsonpath "$.items[0].id"

POST https://{{cs_host}}:4000/api/v1/management-requests/{{ss1_auth_cert_reg_req_id}}/approval
Authorization: X-Road-ApiKey token={{cs_api_key}}

HTTP 200

# Activate auth certificate on SS1 Security Server
PUT https://{{ss1_host}}:4000/api/v1/token-certificates/{{ss1_auth_key_cert_hash}}/activate
Authorization: X-Road-ApiKey token={{ss1_api_key}}

HTTP 204

# Set timestamping service on SS1 Security Server
POST https://{{ss1_host}}:4000/api/v1/system/timestamping-services
Authorization: X-Road-ApiKey token={{ss1_api_key}}
{
    "name": "{{tsa_name}}",
    "url": "{{tsa_url}}"
}

HTTP 201

# Add TestClient to SS1 Security Server
POST https://{{ss1_host}}:4000/api/v1/clients
Authorization: X-Road-ApiKey token={{ss1_api_key}}
{
    "ignore_warnings": true,
    "client": {
        "member_class": "COM",
        "member_code": "4321",
        "subsystem_code": "TestClient",
        "connection_type": "HTTP"
    }
}

HTTP 201

[Captures]
ss1_test_client_id: jsonpath "$.id"

# Register TestClient to SS1 Security Server
PUT https://{{ss1_host}}:4000/api/v1/clients/{{ss1_test_client_id}}/register
Authorization: X-Road-ApiKey token={{ss1_api_key}}

HTTP 204

# Accept Security Server TestClient registration
GET https://{{cs_host}}:4000/api/v1/management-requests?sort=id&desc=true&status=WAITING
Authorization: X-Road-ApiKey token={{cs_api_key}}

HTTP 200

[Captures]
ss1_test_client_req_id: jsonpath "$.items[0].id"

POST https://{{cs_host}}:4000/api/v1/management-requests/{{ss1_test_client_req_id}}/approval
Authorization: X-Road-ApiKey token={{cs_api_key}}

HTTP 200

# Add TestService to Management Security Server
POST https://{{ss0_host}}:4000/api/v1/clients
Authorization: X-Road-ApiKey token={{ss0_api_key}}
{
    "ignore_warnings": true,
    "client": {
        "member_class": "{{ssm_member_class}}",
        "member_code": "{{ssm_member_code}}",
        "subsystem_code": "TestService",
        "connection_type": "HTTP"
    }
}

HTTP 201

[Captures]
ss0_test_service_id: jsonpath "$.id"

# Register TestService to management Security Server
PUT https://{{ss0_host}}:4000/api/v1/clients/{{ss0_test_service_id}}/register
Authorization: X-Road-ApiKey token={{ss0_api_key}}

HTTP 204

# Accept Security Server TestService registration
GET https://{{cs_host}}:4000/api/v1/management-requests?sort=id&desc=true&status=WAITING
Authorization: X-Road-ApiKey token={{cs_api_key}}

HTTP 200

[Captures]
ss0_test_service_req_id: jsonpath "$.items[0].id"

POST https://{{cs_host}}:4000/api/v1/management-requests/{{ss0_test_service_req_id}}/approval
Authorization: X-Road-ApiKey token={{cs_api_key}}

HTTP 200

# Add TestSaved to SS0
POST https://{{ss0_host}}:4000/api/v1/clients
Authorization: X-Road-ApiKey token={{ss0_api_key}}
{
    "ignore_warnings": true,
    "client": {
        "member_class": "{{ssm_member_class}}",
        "member_code": "{{ssm_member_code}}",
        "subsystem_code": "TestSaved",
        "connection_type": "HTTP"
    }
}

HTTP 201

[Captures]
ss0_test_saved_id: jsonpath "$.id"

# Register TestSaved to SS0
PUT https://{{ss0_host}}:4000/api/v1/clients/{{ss0_test_saved_id}}/register
Authorization: X-Road-ApiKey token={{ss0_api_key}}

HTTP 204

# Accept SS0 TestSaved registration
GET https://{{cs_host}}:4000/api/v1/management-requests?sort=id&desc=true&status=WAITING
Authorization: X-Road-ApiKey token={{cs_api_key}}

HTTP 200

[Captures]
ss0_test_saved_req_id: jsonpath "$.items[0].id"

POST https://{{cs_host}}:4000/api/v1/management-requests/{{ss0_test_saved_req_id}}/approval
Authorization: X-Road-ApiKey token={{cs_api_key}}

HTTP 200

# Add test-consumer to SS1 Security Server
POST https://{{ss1_host}}:4000/api/v1/clients
Authorization: X-Road-ApiKey token={{ss1_api_key}}
{
    "ignore_warnings": true,
    "client": {
        "member_class": "{{ssm_member_class}}",
        "member_code": "{{ssm_member_code}}",
        "subsystem_code": "test-consumer",
        "connection_type": "HTTP"
    }
}

HTTP 201

[Captures]
ss1_test_consumer_id: jsonpath "$.id"

# Add test-consumer sign key to the SS1 Security Server token
POST https://{{ss1_host}}:4000/api/v1/tokens/0/keys-with-csrs
Authorization: X-Road-ApiKey token={{ss1_api_key}}
Content-Type: application/json
{
    "key_label": "test-consumer sign key",
    "csr_generate_request": {
        "key_usage_type": "SIGNING",
        "ca_name": "{{ca_name}}",
        "csr_format": "DER",
        "member_id": "{{cs_instance_identifier}}:{{ssm_member_class}}:{{ssm_member_code}}",
        "subject_field_values": {
            "CN": "{{ssm_member_code}}",
            "C": "FI",
            "O": "Test Consumer",
            "subjectAltName": "{{ss1_host}}",
            "serialNumber": "{{cs_instance_identifier}}/SS1/{{ssm_member_class}}"
        }
    }
}

HTTP 200

[Captures]
test_consumer_sign_key_id: jsonpath "$.key.id"
test_consumer_sign_key_csr_id: jsonpath "$.csr_id"

# Get the sign key CSR
GET https://{{ss1_host}}:4000/api/v1/keys/{{test_consumer_sign_key_id}}/csrs/{{test_consumer_sign_key_csr_id}}?csr_format=PEM
Authorization: X-Road-ApiKey token={{ss1_api_key}}

HTTP 200

[Captures]
test_consumer_sign_key_csr: body

# Sign the sign key CSR (note that the test CA needs filename so we can't just send it under
# [FormMultiPart] as we do with the other requests)
POST http://{{ca_host}}:8888/testca/sign
Content-Type: multipart/form-data; boundary=certboundary
```
--certboundary
Content-Disposition: form-data; name="type"

sign
--certboundary
Content-Disposition: form-data; name="certreq"; filename="sign.csr.pem"

{{test_consumer_sign_key_csr}}
--certboundary--
```

HTTP 200

[Captures]
test_consumer_sign_key_cert: body

# Import sign certificate
POST https://{{ss1_host}}:4000/api/v1/token-certificates
Authorization: X-Road-ApiKey token={{ss1_api_key}}
Content-Type: application/octet-stream
```
{{test_consumer_sign_key_cert}}
```

HTTP 201

# Register test-consumer to SS1 Security Server
PUT https://{{ss1_host}}:4000/api/v1/clients/{{ss1_test_consumer_id}}/register
Authorization: X-Road-ApiKey token={{ss1_api_key}}

HTTP 204

# Accept SS1 test-consumer registration
GET https://{{cs_host}}:4000/api/v1/management-requests?sort=id&desc=true&status=WAITING
Authorization: X-Road-ApiKey token={{cs_api_key}}

HTTP 200

[Captures]
ss1_test_consumer_req_id: jsonpath "$.items[0].id"

POST https://{{cs_host}}:4000/api/v1/management-requests/{{ss1_test_consumer_req_id}}/approval
Authorization: X-Road-ApiKey token={{cs_api_key}}

HTTP 200

# Add example service to management Security Server
POST https://{{ss0_host}}:4000/api/v1/clients/{{ss0_test_service_id}}/service-descriptions
Authorization: X-Road-ApiKey token={{ss0_api_key}}
{
    "url": "{{example_service_wsdl}}",
    "type": "WSDL",
    "ignore_warnings": true
}

HTTP 201

[Captures]
ss0_test_service_service_id: jsonpath "$.id"
ss0_test_service_service_service_id: jsonpath "$.services[0].id"

# Add test service URL
PATCH https://{{ss0_host}}:4000/api/v1/services/{{ss0_test_service_service_service_id}}
Authorization: X-Road-ApiKey token={{ss0_api_key}}
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

# Add TestClient access to TestService
POST https://{{ss0_host}}:4000/api/v1/clients/{{ss0_test_service_id}}/service-clients/{{ss1_test_client_id}}/access-rights
Authorization: X-Road-ApiKey token={{ss0_api_key}}
{
    "items": [
        {
            "service_code": "getRandom"
        },
        {
            "service_code": "helloService"
        },
        {
            "service_code": "listPeople"
        },
        {
            "service_code": "personDetails"
        }
    ]
}

HTTP 201

# Enable soap service on SS0
PUT https://{{ss0_host}}:4000/api/v1/service-descriptions/{{ss0_test_service_service_id}}/enable
Authorization: X-Road-ApiKey token={{ss0_api_key}}

HTTP 200

# Register REST service
POST https://{{ss0_host}}:4000/api/v1/clients/{{ss0_test_service_id}}/service-descriptions
Authorization: X-Road-ApiKey token={{ss0_api_key}}
{
    "url": "{{is_rest_url}}",
    "type": "REST",
    "rest_service_code": "{{is_rest_service_code}}"
}

HTTP 201

[Captures]
ss0_test_rest_service_service_id: jsonpath "$.id"

# Enable REST service
PUT https://{{ss0_host}}:4000/api/v1/service-descriptions/{{ss0_test_rest_service_service_id}}/enable
Authorization: X-Road-ApiKey token={{ss0_api_key}}

HTTP 200

# Grant access to REST service
POST https://{{ss0_host}}:4000/api/v1/clients/{{ss0_test_service_id}}/service-clients/{{ss1_test_client_id}}/access-rights
Authorization: X-Road-ApiKey token={{ss0_api_key}}
{
    "items": [
        {
            "service_code": "{{is_rest_service_code}}"
        }
    ]
}

HTTP 201

# Register OpenAPI REST service
POST https://{{ss0_host}}:4000/api/v1/clients/{{ss0_test_service_id}}/service-descriptions
Authorization: X-Road-ApiKey token={{ss0_api_key}}
{
    "url": "{{is_openapi_url}}",
    "type": "OPENAPI3",
    "rest_service_code": "{{is_openapi_service_code}}"
}

HTTP 201

[Captures]
ss0_test_rest_openapi_service_service_id: jsonpath "$.id"

# Add TestClient access to OpenAPI REST service's "GET members" endpoint
GET https://{{ss0_host}}:4000/api/v1/services/{{ss0_test_service_id}}%3A{{is_openapi_service_code}}
Authorization: X-Road-ApiKey token={{ss0_api_key}}

HTTP 200

[Captures]
# Until Hurl supports combining multiple filters in JSONPath, we need to use this approach:
# Ideal would be: "$.endpoints[?(@.path == '/api/members' && @.method == 'GET')].id" nth 0
ss0_test_rest_openapi_service_get_members_endpoint_id: jsonpath "$.endpoints[?(@.path == '/api/members')].id" nth 0

POST https://{{ss0_host}}:4000/api/v1/endpoints/{{ss0_test_rest_openapi_service_get_members_endpoint_id}}/service-clients
Authorization: X-Road-ApiKey token={{ss0_api_key}}
{
    "items": [
        {
            "id": "{{cs_instance_identifier}}:COM:4321:TestClient",
            "name": "Test client",
            "service_client_type": "SUBSYSTEM"
        }
    ]
}

HTTP 201

# Enable OpenAPI REST service
PUT https://{{ss0_host}}:4000/api/v1/service-descriptions/{{ss0_test_rest_openapi_service_service_id}}/enable
Authorization: X-Road-ApiKey token={{ss0_api_key}}

HTTP 200
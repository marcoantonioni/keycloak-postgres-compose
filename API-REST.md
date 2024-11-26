# API REST

```
KEYCLOAK_HOST=https://localhost:8443

#--------------------------------------------------------
# token admin realm master, admin-cli
KC_CLIENT_ID=admin-cli
KC_REALM=master
KC_USER_NAME=admin
KC_USER_PWD=admin
KC_TOKEN=$(curl -k -s --data "username=${KC_USER_NAME}&password=${KC_USER_PWD}&grant_type=password&client_id=${KC_CLIENT_ID}" "${KEYCLOAK_HOST}/realms/${KC_REALM}/protocol/openid-connect/token" | jq .access_token | sed 's/"//g')
echo $KC_TOKEN

#--------------------------------------------------------
# info realm
curl -v -k -H "Accept: application/json" -H "Authorization: Bearer ${KC_TOKEN}" -X GET "${KEYCLOAK_HOST}/realms/${KC_REALM}" | jq .

#--------------------------------------------------------
# elenco dei clients
curl -v -k -H "Accept: application/json" -H "Authorization: Bearer ${KC_TOKEN}" -X GET "${KEYCLOAK_HOST}/admin/realms/master/clients" | jq .

#--------------------------------------------------------
# numero utenti (token admin)
KC_REALM=master
KC_REALM_USERS=$(curl -s -k -H "Accept: application/json" -H "Authorization: Bearer ${KC_TOKEN}" -X GET "${KEYCLOAK_HOST}/admin/realms/${KC_REALM}/users/count")
echo "[${KC_REALM}] users: "${KC_REALM_USERS}

KC_REALM=quarkus
KC_REALM_USERS=$(curl -s -k -H "Accept: application/json" -H "Authorization: Bearer ${KC_TOKEN}" -X GET "${KEYCLOAK_HOST}/admin/realms/${KC_REALM}/users/count")
echo "[${KC_REALM}] users: "${KC_REALM_USERS}

#--------------------------------------------------------
# lista utenti (token admin)

KC_REALM=master
curl -s -k -H "Accept: application/json" -H "Authorization: Bearer ${KC_TOKEN}" -X GET "${KEYCLOAK_HOST}/admin/realms/${KC_REALM}/users" | jq .

KC_REALM=quarkus
curl -s -k -H "Accept: application/json" -H "Authorization: Bearer ${KC_TOKEN}" -X GET "${KEYCLOAK_HOST}/admin/realms/${KC_REALM}/users" | jq .


#--------------------------------------------------------
# crea realm

????
curl -k -v -X POST "${KEYCLOAK_HOST}/realms" \
  -H "Authorization: Bearer ${KC_TOKEN}" -H "Accept: application/json" -H "Content-Type: application/json" \
  -d '{
    "id": "mynewrealm",
    "realm": "my-new-realm",
    "displayName": "My New Realm",
    "enabled": true,
    "sslRequired": "external",
    "registrationAllowed": false,
    "loginWithEmailAllowed": true,
    "duplicateEmailsAllowed": false,
    "resetPasswordAllowed": false,
    "editUsernameAllowed": false,
    "bruteForceProtected": true
  }'


#--------------------------------------------------------
# token utente realm quarkus, account
KC_CLIENT_ID=admin-cli
KC_REALM=quarkus
KC_USER_NAME=user1
KC_USER_PWD=password
KC_TOKEN=$(curl -k -s --data "username=${KC_USER_NAME}&password=${KC_USER_PWD}&grant_type=password&client_id=${KC_CLIENT_ID}" "${KEYCLOAK_HOST}/realms/${KC_REALM}/protocol/openid-connect/token" | jq .access_token | sed 's/"//g')
echo $KC_TOKEN


```

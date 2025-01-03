# API REST

https://www.keycloak.org/docs-api/latest/rest-api/index.html

```
KEYCLOAK_HOST=https://localhost:7433

#--------------------------------------------------------
# token admin realm master, admin-cli
KC_CLIENT_ID=admin-cli
KC_REALM=master
KC_USER_NAME=admin
KC_USER_PWD=admin

# default Access Token Lifespan = 1 minute

KC_LOGIN_DATA=$(curl -k -s --data "username=${KC_USER_NAME}&password=${KC_USER_PWD}&grant_type=password&client_id=${KC_CLIENT_ID}" "${KEYCLOAK_HOST}/realms/${KC_REALM}/protocol/openid-connect/token")

echo $KC_LOGIN_DATA | jq .

KC_TOKEN=$(echo "${KC_LOGIN_DATA}" | jq .access_token | sed 's/"//g')

echo $KC_TOKEN


# Token expiration
# Modificare 'Access Token Lifespan'
# https://localhost:8443/admin/master/console/#/master/realm-settings/tokens

KC_REALM=master
KC_TK_EXP_SECS=14400
curl -s -k -H "Content-Type: application/json" -H "Accept: application/json" -H "Authorization: Bearer ${KC_TOKEN}" -X PUT "${KEYCLOAK_HOST}/admin/realms/${KC_REALM}/ui-ext" -d '{"accessTokenLifespan": '${KC_TK_EXP_SECS}' }' | jq .

#--------------------------------------------------------
# info realm
curl -v -k -H "Accept: application/json" -H "Authorization: Bearer ${KC_TOKEN}" -X GET "${KEYCLOAK_HOST}/realms/${KC_REALM}" | jq .

#--------------------------------------------------------
# elenco dei clients
curl -v -k -H "Accept: application/json" -H "Authorization: Bearer ${KC_TOKEN}" -X GET "${KEYCLOAK_HOST}/admin/realms/master/clients" | jq .

#--------------------------------------------------------
# numero gruppi (token admin)
KC_REALM=master
KC_REALM_GROUPS=$(curl -s -k -H "Accept: application/json" -H "Authorization: Bearer ${KC_TOKEN}" -X GET "${KEYCLOAK_HOST}/admin/realms/${KC_REALM}/groups/count" | jq .count)
echo "[${KC_REALM}] groups: "${KC_REALM_GROUPS}

KC_REALM=quarkus
KC_REALM_GROUPS=$(curl -s -k -H "Accept: application/json" -H "Authorization: Bearer ${KC_TOKEN}" -X GET "${KEYCLOAK_HOST}/admin/realms/${KC_REALM}/groups/count" | jq .count)
echo "[${KC_REALM}] groups: "${KC_REALM_GROUPS}

#--------------------------------------------------------
# lista gruppi (token admin)

KC_REALM=master
curl -s -k -H "Accept: application/json" -H "Authorization: Bearer ${KC_TOKEN}" -X GET "${KEYCLOAK_HOST}/admin/realms/${KC_REALM}/groups" | jq .

KC_REALM=quarkus
curl -s -k -H "Accept: application/json" -H "Authorization: Bearer ${KC_TOKEN}" -X GET "${KEYCLOAK_HOST}/admin/realms/${KC_REALM}/groups" | jq .

#--------------------------------------------------------
# crea gruppo (token admin)

KC_REALM=quarkus
KC_GROUP_NAME=groupBeta
curl -s -k -H "Content-Type: application/json" -H "Accept: application/json" -H "Authorization: Bearer ${KC_TOKEN}" -X POST "${KEYCLOAK_HOST}/admin/realms/${KC_REALM}/groups" \
    -d '{ "name": "'${KC_GROUP_NAME}'" }' | jq .

#--------------------------------------------------------
# lista ruoli
KC_REALM=my-realm-1
curl -k -s -H "Accept: application/json" -H "Authorization: Bearer ${KC_TOKEN}" -X GET "${KEYCLOAK_HOST}/admin/realms/${KC_REALM}/roles?first=0&max=100" | jq .

#--------------------------------------------------------
# crea ruolo realm
KC_REALM=my-realm-1
KC_ROLE_NAME="AlfaRole"

curl -s -k -H "Accept: application/json" -H "Authorization: Bearer ${KC_TOKEN}" -H "Content-Type: application/json" \
  -X POST "${KEYCLOAK_HOST}/admin/realms/${KC_REALM}/roles" \
  -d '{ "name": "'${KC_ROLE_NAME}'", "description": "", "attributes": {} }'


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
# crea utente (token admin)
KC_REALM=quarkus
KC_USER=user5
curl -s -k -H "Content-Type: application/json" -H "Accept: application/json" -H "Authorization: Bearer ${KC_TOKEN}" \
    -X POST "${KEYCLOAK_HOST}/admin/realms/${KC_REALM}/users" \
    -d '{ "username": "'${KC_USER}'", "firstName":"'${KC_USER}'","lastName":"'${KC_USER}'", "email":"'${KC_USER}'@home.net", "enabled":"true", "groups": ["groupAlfa"] }'

#--------------------------------------------------------
# reset password utente (token admin)
KC_REALM=my-realm-1
KC_USER=requestor4
KC_PWD=requestor4

KC_USER_ID=$(curl -s -k -H "Accept: application/json" -H "Authorization: Bearer ${KC_TOKEN}" -X GET "${KEYCLOAK_HOST}/admin/realms/${KC_REALM}/users" | jq '.[] | select(.username == "'${KC_USER}'")' | jq .id | sed 's/"//g')

echo $KC_USER_ID

curl -s -k -H "Content-Type: application/json" -H "Accept: application/json" -H "Authorization: Bearer ${KC_TOKEN}" \
    -X PUT "${KEYCLOAK_HOST}/admin/realms/${KC_REALM}/users/${KC_USER_ID}/reset-password" \
    -d '{ "value": "'${KC_PWD}'", "type": "password", "temporary": false }'



#--------------------------------------------------------
# associa utente a gruppo
KC_USER=user2
KC_GROUP_NAME=groupBeta
KC_REALM=quarkus

KC_USER_ID=$(curl -s -k -H "Accept: application/json" -H "Authorization: Bearer ${KC_TOKEN}" -X GET "${KEYCLOAK_HOST}/admin/realms/${KC_REALM}/users" | jq '.[] | select(.username == "'${KC_USER}'")' | jq .id | sed 's/"//g')

KC_GROUP_ID=$(curl -s -k -H "Accept: application/json" -H "Authorization: Bearer ${KC_TOKEN}" -X GET "${KEYCLOAK_HOST}/admin/realms/${KC_REALM}/groups" | jq '.[] | select(.name == "'${KC_GROUP_NAME}'")' | jq .id | sed 's/"//g')

[[ ! -z "${KC_GROUP_ID}" ]] && [[ ! -z "${KC_GROUP_ID}" ]] && curl -s -k -H "Content-Type: application/json" -H "Accept: application/json" -H "Authorization: Bearer ${KC_TOKEN}" -X PUT "${KEYCLOAK_HOST}/admin/realms/${KC_REALM}/users/${KC_USER_ID}/groups/${KC_GROUP_ID}"

#--------------------------------------------------------
# associa utente a ruolo 
KC_REALM=my-realm-1
KC_USER="mary"
KC_ROLE_NAME="MyRole1"

KC_USER_ID=$(curl -s -k -H "Accept: application/json" -H "Authorization: Bearer ${KC_TOKEN}" \
  -X GET "${KEYCLOAK_HOST}/admin/realms/${KC_REALM}/users" \
  | jq '.[] | select(.username == "'${KC_USER}'")' | jq .id | sed 's/"//g')

KC_ROLE_DATA=$(curl -k -s -H "Accept: application/json" -H "Authorization: Bearer ${KC_TOKEN}" -X GET "${KEYCLOAK_HOST}/admin/realms/${KC_REALM}/roles" | jq '.[] | select(.name=="'${KC_ROLE_NAME}'")')

echo $KC_ROLE_DATA 

curl -s -k -H "Accept: application/json" -H "Authorization: Bearer ${KC_TOKEN}" -H "Content-Type: application/json" \
  -X POST "${KEYCLOAK_HOST}/admin/realms/${KC_REALM}/users/${KC_USER_ID}/role-mappings/realm" \
  -d "[${KC_ROLE_DATA}]"

#--------------------------------------------------------
# associa gruppo a ruolo

KC_REALM=my-realm-1
KC_ROLE_NAME="MyRole1"
KC_GROUP_NAME="Requestors"

KC_GROUP_ID=$(curl -s -k -H "Accept: application/json" -H "Authorization: Bearer ${KC_TOKEN}" -X GET "${KEYCLOAK_HOST}/admin/realms/${KC_REALM}/groups" | jq '.[] | select(.name == "'${KC_GROUP_NAME}'")' | jq .id | sed 's/"//g')

KC_ROLE_DATA=$(curl -k -s -H "Accept: application/json" -H "Authorization: Bearer ${KC_TOKEN}" -X GET "${KEYCLOAK_HOST}/admin/realms/${KC_REALM}/roles" | jq '.[] | select(.name=="'${KC_ROLE_NAME}'")')

curl -s -k -H "Accept: application/json" -H "Authorization: Bearer ${KC_TOKEN}" -H "Content-Type: application/json" \
  -X POST "${KEYCLOAK_HOST}/admin/realms/${KC_REALM}/groups/${KC_GROUP_ID}/role-mappings/realm" \
  -d "[${KC_ROLE_DATA}]"

#--------------------------------------------------------
# crea realm
KC_REALM=pluto
curl -k -s -X POST "${KEYCLOAK_HOST}/admin/realms" \
  -H "Authorization: Bearer ${KC_TOKEN}" -H "Accept: application/json" -H "Content-Type: application/json" \
  -d '{
    "realm": "'${KC_REALM}'",
    "displayName": "'${KC_REALM}'",
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


KC_CLIENT_ID=my-client-bpm
KC_CLIENT_SECRET=my-secret-bpm
KC_REALM=my-realm-1
KC_USER_NAME=requestor1
KC_USER_PWD=requestor1
KC_TOKEN=$(curl -k -s --data "username=${KC_USER_NAME}&password=${KC_USER_PWD}&grant_type=password&client_id=${KC_CLIENT_ID}&client_secret=${KC_CLIENT_SECRET}" "${KEYCLOAK_HOST}/realms/${KC_REALM}/protocol/openid-connect/token" | jq .access_token | sed 's/"//g')
echo $KC_TOKEN


#--------------------------------------------------------
# lista dei clients
KC_REALM=my-realm-1
curl -k -s -H "Accept: application/json" -H "Authorization: Bearer ${KC_TOKEN}" -X GET "${KEYCLOAK_HOST}/admin/realms/${KC_REALM}/clients" | jq .

# crea nuovo client
KC_REALM=my-realm-1
_NEW_CLIENT_NAME="my-client-bpm"
_NEW_CLIENT_SECRET="my-secret"
# , "defaultRoles": ["uma_authorization", "user"] ???
curl -k -s -H "Accept: application/json" -H "Authorization: Bearer ${KC_TOKEN}" -H "Content-Type: application/json" \
  -X POST "${KEYCLOAK_HOST}/admin/realms/${KC_REALM}/clients" \
  -d '{"name": "'${_NEW_CLIENT_NAME}'", "clientId": "'${_NEW_CLIENT_NAME}'", "enabled": true, "secret": "'${_NEW_CLIENT_SECRET}'", "directAccessGrantsEnabled": true, "serviceAccountsEnabled": true }' | jq .

# legge UUID di client
KC_CLIENT_UUID=$(curl -k -s -H "Accept: application/json" -H "Authorization: Bearer ${KC_TOKEN}" -X GET "${KEYCLOAK_HOST}/admin/realms/${KC_REALM}/clients" | jq '.[] | select(.clientId == "'${_NEW_CLIENT_NAME}'")' | jq .id | sed 's/"//g')
echo $KC_CLIENT_UUID

# crea ruolo del client
_NEW_ROLE_NAME="user_bpm"
curl -k -s -H "Accept: application/json" -H "Authorization: Bearer ${KC_TOKEN}" -H "Content-Type: application/json" \
  -X POST "${KEYCLOAK_HOST}/admin/realms/${KC_REALM}/clients/${KC_CLIENT_UUID}/roles" \
  -d '{"name": "'${_NEW_ROLE_NAME}'", "clientRole": true }' | jq .

# legge roles associati a client
curl -w '\n' -s -k -H "Accept: application/json" -H "Authorization: Bearer ${KC_TOKEN}" \
  -X GET "${KEYCLOAK_HOST}/admin/realms/${KC_REALM}/clients/${KC_CLIENT_UUID}/roles" | jq .

```

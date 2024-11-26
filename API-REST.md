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

# Token expiration
# Modificare 'Access Token Lifespan'
# https://localhost:8443/admin/master/console/#/master/realm-settings/tokens

KC_REALM=master
KC_TK_EXP_SECS=7200
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
# associa utente a gruppo
PUT /admin/realms/{realm}/users/{user-id}/groups/{groupId}




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

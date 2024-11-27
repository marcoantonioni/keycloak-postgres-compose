#!/bin/bash

declare -a _GROUPS=("Requestors" "Validators")
declare _USER_PREFIX="user"
declare _USER_MAX=10

declare KEYCLOAK_HOST=https://localhost:7433
declare KC_CLIENT_ID=admin-cli
declare KC_REALM=master
declare KC_USER_NAME=admin
declare KC_USER_PWD=admin
KC_TOKEN=""

function _getToken() {
  export KC_TOKEN=$(curl -sk --data "username=${KC_USER_NAME}&password=${KC_USER_PWD}&grant_type=password&client_id=${KC_CLIENT_ID}" \
    "${KEYCLOAK_HOST}/realms/${KC_REALM}/protocol/openid-connect/token" | jq .access_token | sed 's/"//g')
  echo "token: $KC_TOKEN"
}

function _createRealm() {
  KC_NEW_REALM=$1
  curl -k -s -X POST "${KEYCLOAK_HOST}/admin/realms" \
    -H "Authorization: Bearer ${KC_TOKEN}" -H "Accept: application/json" -H "Content-Type: application/json" \
    -d '{
      "realm": "'${KC_NEW_REALM}'",
      "displayName": "'${KC_NEW_REALM}'",
      "enabled": true,
      "sslRequired": "external",
      "registrationAllowed": false,
      "loginWithEmailAllowed": true,
      "duplicateEmailsAllowed": false,
      "resetPasswordAllowed": false,
      "editUsernameAllowed": false,
      "bruteForceProtected": true
    }'

}

function _createGroups() {
  _realmName=$1
  if [[ ! -z "${KC_TOKEN}" ]] && [[ ! -z "${_realmName}" ]]; then
    for _grpName in "${_GROUPS[@]}"
    do
      echo "Creating group: ${_grpName} in realm: ${_realmName}"
      curl -s -k -H "Content-Type: application/json" -H "Accept: application/json" -H "Authorization: Bearer ${KC_TOKEN}" \
        -X POST "${KEYCLOAK_HOST}/admin/realms/${_realmName}/groups" \
        -d '{ "name": "'${_grpName}'" }' | jq .
    done
  fi
}

function _createUsers() {
  _realmName=$1
  if [[ ! -z "${KC_TOKEN}" ]] && [[ ! -z "${_realmName}" ]]; then
    for (( _usrIdx=1; _usrIdx<=$_USER_MAX; _usrIdx++ ))
    do
      _usrName="${_USER_PREFIX}${_usrIdx}"
      echo "Creating user: ${_usrName} in realm: ${_realmName}"
      curl -s -k -H "Content-Type: application/json" -H "Accept: application/json" -H "Authorization: Bearer ${KC_TOKEN}" \
        -X POST "${KEYCLOAK_HOST}/admin/realms/${_realmName}/users" \
        -d '{ "username": "'${_usrName}'", "firstName":"'${_usrName}'","lastName":"'${_usrName}'", "email":"'${_usrName}'@home.net", "enabled":"true" }'
    done
  fi
}

#-------------------------------

_getToken
_NEW_REALM="myrealm1"
_createRealm "${_NEW_REALM}"
_createGroups "${_NEW_REALM}"
_createUsers "${_NEW_REALM}"

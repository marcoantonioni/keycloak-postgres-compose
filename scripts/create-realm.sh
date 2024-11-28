#!/bin/bash

# declare -a _GROUPS=("Requestors" "Validators")
declare -a _GROUPS=("Frontend" "Backend" "Managers")

declare -a _USERS=()
declare -a _USERS_IN_ROLE=()

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
  #echo "token: $KC_TOKEN"
  if [[ -z "${KC_TOKEN}" ]]; then
    echo "ERROR getting authentication token, exit."
    exit 1
  fi
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
  echo "#--- Creating groups"
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
  echo "#--- Creating users"
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
_createRoleUsersData() {
  
  _groupIdx=$1
  _range=$2

  _min=${_range%..*}
  _max=${_range#*..}

  _USERS[$_groupIdx]=""
  for ((_userSuffix = $_min ; _userSuffix <= $_max ; _userSuffix++)); do
    _comma=""
    if (( $_userSuffix != $_max )); then
      _comma=","
    fi
    _USERS[$_groupIdx]="${_USERS[$_groupIdx]}${_USER_PREFIX}$_userSuffix$_comma"
  done

  _USERS_IN_ROLE[$_groupIdx]=${_USERS[$_groupIdx]}
  #echo "_groupIdx=$_groupIdx - ${_GROUPS[$_groupIdx]}: ${_USERS_IN_ROLE[$_groupIdx]}"

}

function _mapUsersToRoles() {
  echo "#--- Mapping users to role"
  KC_NEW_REALM=$1
  _groupIdx=0
  for _grpName in "${_GROUPS[@]}"; do
    IFS=',' read -r -a _usersInRole <<< "${_USERS_IN_ROLE[$_groupIdx]}"

    for _userName in "${_usersInRole[@]}"; do
      echo "Adding user [${_userName}] to group [$_grpName]"

      KC_USER_ID=$(curl -s -k -H "Accept: application/json" -H "Authorization: Bearer ${KC_TOKEN}" \
        -X GET "${KEYCLOAK_HOST}/admin/realms/${KC_NEW_REALM}/users" \
        | jq '.[] | select(.username == "'${_userName}'")' | jq .id | sed 's/"//g')

      KC_GROUP_ID=$(curl -s -k -H "Accept: application/json" -H "Authorization: Bearer ${KC_TOKEN}" \
        -X GET "${KEYCLOAK_HOST}/admin/realms/${KC_NEW_REALM}/groups" \
        | jq '.[] | select(.name == "'${_grpName}'")' | jq .id | sed 's/"//g')

      if [[ ! -z "${KC_GROUP_ID}" ]] && [[ ! -z "${KC_GROUP_ID}" ]]; then 
        curl -s -k -H "Content-Type: application/json" -H "Accept: application/json" -H "Authorization: Bearer ${KC_TOKEN}" \
          -X PUT "${KEYCLOAK_HOST}/admin/realms/${KC_NEW_REALM}/users/${KC_USER_ID}/groups/${KC_GROUP_ID}"
      else
        echo "ERROR IDs not found for user [${_userName}] and/or group [$_grpName]"
      fi

    done

    _groupIdx=$((_groupIdx+1))
  done

}

#-------------------------------

_getToken
_NEW_REALM="$1"
_createRealm "${_NEW_REALM}"
_createGroups "${_NEW_REALM}"
_createUsers "${_NEW_REALM}"

_createRoleUsersData 0 "1..3"
_createRoleUsersData 1 "4..6"
_createRoleUsersData 2 "7..10"

_mapUsersToRoles "${_NEW_REALM}"

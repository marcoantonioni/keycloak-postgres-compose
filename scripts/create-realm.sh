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

#-------------------------------
function _getToken() {
  export KC_TOKEN=$(curl -sk --data "username=${KC_USER_NAME}&password=${KC_USER_PWD}&grant_type=password&client_id=${KC_CLIENT_ID}" \
    "${KEYCLOAK_HOST}/realms/${KC_REALM}/protocol/openid-connect/token" | jq .access_token | sed 's/"//g')
  #echo "token: $KC_TOKEN"
  if [[ -z "${KC_TOKEN}" ]]; then
    echo "ERROR getting authentication token, exit."
    exit 1
  fi
}

#-------------------------------
function _createRealm() {
  _newRealmName=$1
  curl -k -s -X POST "${KEYCLOAK_HOST}/admin/realms" \
    -H "Authorization: Bearer ${KC_TOKEN}" -H "Accept: application/json" -H "Content-Type: application/json" \
    -d '{
      "realm": "'${_newRealmName}'",
      "displayName": "'${_newRealmName}'",
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

#-------------------------------
function _createGroup() {
  #echo "#--- Creating group"
  _realmName=$1
  _grpName=$2
  echo "Creating group: ${_grpName} in realm: ${_realmName}"
  curl -s -k -H "Content-Type: application/json" -H "Accept: application/json" -H "Authorization: Bearer ${KC_TOKEN}" \
    -X POST "${KEYCLOAK_HOST}/admin/realms/${_realmName}/groups" \
    -d '{ "name": "'${_grpName}'" }' | jq .
}
#-------------------------------
function _createGroups() {
  echo "#--- Creating groups"
  _realmName=$1
  if [[ ! -z "${KC_TOKEN}" ]] && [[ ! -z "${_realmName}" ]]; then
    for _grpName in "${_GROUPS[@]}"
    do
      _createGroup "${_realmName}" "$_grpName"
    done
  fi
}

#-------------------------------
function _createUser() {
  #echo "#--- Creating user"
  _realmName=$1
  _usrName=$2
  echo "Creating user: ${_usrName} in realm: ${_realmName}"
  curl -s -k -H "Content-Type: application/json" -H "Accept: application/json" -H "Authorization: Bearer ${KC_TOKEN}" \
    -X POST "${KEYCLOAK_HOST}/admin/realms/${_realmName}/users" \
    -d '{ "username": "'${_usrName}'", "firstName":"'${_usrName}'","lastName":"'${_usrName}'", "email":"'${_usrName}'@home.net", "enabled":"true" }'
}

#-------------------------------
function _createUsers() {
  echo "#--- Creating users"
  _realmName=$1
  if [[ ! -z "${KC_TOKEN}" ]] && [[ ! -z "${_realmName}" ]]; then
    for (( _usrIdx=1; _usrIdx<=$_USER_MAX; _usrIdx++ ))
    do
      _usrName="${_USER_PREFIX}${_usrIdx}"
      _createUser "${_realmName}" "${_usrName}"
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

#-------------------------------
function _mapUsersToRoles() {
  echo "#--- Mapping users to role"
  _newRealmName=$1
  _groupIdx=0
  for _grpName in "${_GROUPS[@]}"; do
    IFS=',' read -r -a _usersInRole <<< "${_USERS_IN_ROLE[$_groupIdx]}"

    for _userName in "${_usersInRole[@]}"; do
      echo "Adding user [${_userName}] to group [$_grpName]"
#---
      KC_USER_ID=$(curl -s -k -H "Accept: application/json" -H "Authorization: Bearer ${KC_TOKEN}" \
        -X GET "${KEYCLOAK_HOST}/admin/realms/${_newRealmName}/users" \
        | jq '.[] | select(.username == "'${_userName}'")' | jq .id | sed 's/"//g')

      KC_GROUP_ID=$(curl -s -k -H "Accept: application/json" -H "Authorization: Bearer ${KC_TOKEN}" \
        -X GET "${KEYCLOAK_HOST}/admin/realms/${_newRealmName}/groups" \
        | jq '.[] | select(.name == "'${_grpName}'")' | jq .id | sed 's/"//g')

      if [[ ! -z "${KC_GROUP_ID}" ]] && [[ ! -z "${KC_GROUP_ID}" ]]; then 
        curl -s -k -H "Content-Type: application/json" -H "Accept: application/json" -H "Authorization: Bearer ${KC_TOKEN}" \
          -X PUT "${KEYCLOAK_HOST}/admin/realms/${_newRealmName}/users/${KC_USER_ID}/groups/${KC_GROUP_ID}"
      else
        echo "ERROR IDs not found for user [${_userName}] and/or group [$_grpName]"
      fi

    done

    _groupIdx=$((_groupIdx+1))
  done

}

_loadGroupAnfUsersFromFile() {
  _realmName="$1"
  _FILE_NAME="$2"

  while IFS="," read -r _GROUP_NAME _USERS
  do
    if [[ "${_GROUP_NAME}" != "GROUP_NAME" ]]; then
      # echo "Group name: ${_GROUP_NAME}"

      # crea gruppo
      _createGroup "${_realmName}" "${_GROUP_NAME}"

      # echo "Users: ${_USERS}"
      if [[ ${_USERS} = *..* ]]; then
        _trimmed="$(echo -e "${_USERS}" | tr -d '[:space:]')"
        _min=${_trimmed%..*}
        _max=${_trimmed#*..}
        # echo "  min=${_min}, max=${_max}"
        _USERS=""
        for ((_userSuffix = $_min ; _userSuffix <= $_max ; _userSuffix++)); do
          _sep=""
          if (( $_userSuffix != $_max )); then
            _sep=" "
          fi
          _USERS+="${_USER_PREFIX}$_userSuffix$_sep"
        done
      fi

      #_listOfUsers=()
      for _usr in ${_USERS}; do 
        #_listOfUsers+=($_usr)
        #echo "_user: ${_usr}"
        _createUser "${_realmName}" "${_usr}"

        # associa utente a gruppo
      done

    fi
  done < <(cat ${_FILE_NAME})
}


#-------------------------------
_test() {
  _createGroups "${_NEW_REALM}"
  _createUsers "${_NEW_REALM}"

  _createRoleUsersData 0 "1..3"
  _createRoleUsersData 1 "4..6"
  _createRoleUsersData 2 "7..10"

  _mapUsersToRoles "${_NEW_REALM}"

}

#-------------------------------

_NEW_REALM="$1"
_GROUP_USERS_FILE="$2"

if [[ ! -z "${_NEW_REALM}" ]]; then
  _getToken
  _createRealm "${_NEW_REALM}"

  if [[ ! -z "${_GROUP_USERS_FILE}" ]]; then
    if [ -f "$(pwd)/${_GROUP_USERS_FILE}" ]; then
      _loadGroupAnfUsersFromFile "${_NEW_REALM}" "$(pwd)/${_GROUP_USERS_FILE}"
    fi
  fi
fi



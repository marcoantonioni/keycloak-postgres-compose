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

_setAccessTokenLifespan() {
  _realmName=$1
  _timeOut=$2
  if [[ -z "${_timeOut}" ]]; then
    _timeOut=14400
  fi
  echo "Setting token lifespan [${_timeOut}] for realm [${_realmName}]"
  curl -s -k -H "Content-Type: application/json" -H "Accept: application/json" -H "Authorization: Bearer ${KC_TOKEN}" \
    -X PUT "${KEYCLOAK_HOST}/admin/realms/${_realmName}/ui-ext" -d '{"accessTokenLifespan": '${_timeOut}' }' | jq .
}

#-------------------------------
function _createRealm() {
  _newRealmName="$1"
  _timeOut="$2"
  if [[ ! -z "${KC_TOKEN}" ]] && [[ ! -z "${_newRealmName}" ]]; then
    echo "Creating realm [${_newRealmName}]"
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
    _setAccessTokenLifespan ${_newRealmName} ${_timeOut}
  fi
}

#-------------------------------
function _createGroup() {
  _realmName=$1
  _grpName=$2
  if [[ ! -z "${KC_TOKEN}" ]]&& [[ ! -z "${_newRealmName}" ]] && [[ ! -z "${_grpName}" ]]; then
    echo "Creating group [${_grpName}] in realm [${_realmName}]"
    curl -s -k -H "Content-Type: application/json" -H "Accept: application/json" -H "Authorization: Bearer ${KC_TOKEN}" \
      -X POST "${KEYCLOAK_HOST}/admin/realms/${_realmName}/groups" \
      -d '{ "name": "'${_grpName}'" }' | jq .
  fi
}

#-------------------------------
function _createGroups() {
  _realmName=$1
  if [[ ! -z "${KC_TOKEN}" ]] && [[ ! -z "${_realmName}" ]]; then
    for _grpName in "${_GROUPS[@]}"
    do
      _createGroup "${_realmName}" "$_grpName"
    done
  fi
}

#-------------------------------
_createPassword() {
  _realmName=$1
  _usrName=$2
  _userPasswd=$3

  _usrId=$(curl -s -k -H "Accept: application/json" -H "Authorization: Bearer ${KC_TOKEN}" \
    -X GET "${KEYCLOAK_HOST}/admin/realms/${_realmName}/users" | jq '.[] | select(.username == "'${_usrName}'")' | jq .id | sed 's/"//g')
  
  if [[ ! -z "${_usrId}" ]]; then
    echo "Setting password for user [${_usrName}] in realm [${_realmName}]"
    curl -s -k -H "Content-Type: application/json" -H "Accept: application/json" -H "Authorization: Bearer ${KC_TOKEN}" \
      -X PUT "${KEYCLOAK_HOST}/admin/realms/${KC_REALM}/users/${_usrId}/reset-password" \
      -d '{ "value": "'${_userPasswd}'", "type": "password", "temporary": false }'
  fi
}

#-------------------------------
function _createUser() {
  #echo "#--- Creating user"
  _realmName=$1
  _usrName=$2
  if [[ ! -z "${KC_TOKEN}" ]]&& [[ ! -z "${_realmName}" ]] && [[ ! -z "${_usrName}" ]]; then
    echo "Creating user [${_usrName}] in realm [${_realmName}]"
    curl -s -k -H "Content-Type: application/json" -H "Accept: application/json" -H "Authorization: Bearer ${KC_TOKEN}" \
      -X POST "${KEYCLOAK_HOST}/admin/realms/${_realmName}/users" \
      -d '{ "username": "'${_usrName}'", "firstName":"'${_usrName}'","lastName":"'${_usrName}'", "email":"'${_usrName}'@home.net", "enabled":"true" }'
  fi
}

#-------------------------------
function _createUsers() {
  #echo "#--- Creating users"
  _realmName=$1
  if [[ ! -z "${KC_TOKEN}" ]] && [[ ! -z "${_realmName}" ]]; then
    for (( _usrIdx=1; _usrIdx<=$_USER_MAX; _usrIdx++ ))
    do
      _usrName="${_USER_PREFIX}${_usrIdx}"
      _createUser "${_realmName}" "${_usrName}"
      _createPassword "${_realmName}" "${_usrName}" "${_usrName}"
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
function _associateUserToGroup() {
  # echo "#--- Mapping users to role"
  _realmName=$1
  _userName=$2
  _grpName=$3
  if [[ ! -z "${KC_TOKEN}" ]]&& [[ ! -z "${_realmName}" ]] && [[ ! -z "${_grpName}" ]] && [[ ! -z "${_usrName}" ]]; then
    echo "Associating user [${_usrName}] to group [${_grpName}] in realm [${_realmName}]"
    KC_USER_ID=$(curl -s -k -H "Accept: application/json" -H "Authorization: Bearer ${KC_TOKEN}" \
      -X GET "${KEYCLOAK_HOST}/admin/realms/${_realmName}/users" \
      | jq '.[] | select(.username == "'${_userName}'")' | jq .id | sed 's/"//g')

    KC_GROUP_ID=$(curl -s -k -H "Accept: application/json" -H "Authorization: Bearer ${KC_TOKEN}" \
      -X GET "${KEYCLOAK_HOST}/admin/realms/${_realmName}/groups" \
      | jq '.[] | select(.name == "'${_grpName}'")' | jq .id | sed 's/"//g')

    if [[ ! -z "${KC_GROUP_ID}" ]] && [[ ! -z "${KC_GROUP_ID}" ]]; then 
      curl -s -k -H "Content-Type: application/json" -H "Accept: application/json" -H "Authorization: Bearer ${KC_TOKEN}" \
        -X PUT "${KEYCLOAK_HOST}/admin/realms/${_realmName}/users/${KC_USER_ID}/groups/${KC_GROUP_ID}"
    else
      echo "ERROR IDs not found for user [${_userName}] and/or group [$_grpName]"
    fi
  fi
}

#-------------------------------
function _associateUsersToGroups() {
  # echo "#--- Mapping users to role"
  _newRealmName=$1
  _groupIdx=0
  for _grpName in "${_GROUPS[@]}"; do
    IFS=',' read -r -a _usersInRole <<< "${_USERS_IN_ROLE[$_groupIdx]}"

    for _userName in "${_usersInRole[@]}"; do
      echo "Adding user [${_userName}] to group [$_grpName]"
      _associateUserToGroup "${_newRealmName}" "${_userName}" "${_grpName}"
    done

    _groupIdx=$((_groupIdx+1))
  done

}

#-------------------------------
_createRole() {
  _realmName=$1 
  _roleName=$2

  if [[ ! -z "${_roleName}" ]]; then
    curl -s -k -H "Accept: application/json" -H "Authorization: Bearer ${KC_TOKEN}" -H "Content-Type: application/json" \
      -X POST "${KEYCLOAK_HOST}/admin/realms/${_realmName}/roles" \
      -d '{ "name": "'${_roleName}'", "description": "", "attributes": {} }'
  fi
}

#-------------------------------
_associateGroupToRole() {
  _realmName=$1 
  _grpName=$2 
  _roleName=$3

  if [[ ! -z "${_grpName}" ]] && [[ ! -z "${_roleName}" ]]; then
    KC_GROUP_ID=$(curl -s -k -H "Accept: application/json" -H "Authorization: Bearer ${KC_TOKEN}" \
      -X GET "${KEYCLOAK_HOST}/admin/realms/${_realmName}/groups" \
      | jq '.[] | select(.name == "'${_grpName}'")' | jq .id | sed 's/"//g')

    KC_ROLE_DATA=$(curl -k -s -H "Accept: application/json" -H "Authorization: Bearer ${KC_TOKEN}" \
      -X GET "${KEYCLOAK_HOST}/admin/realms/${_realmName}/roles" | jq '.[] | select(.name=="'${_roleName}'")')

    curl -s -k -H "Accept: application/json" -H "Authorization: Bearer ${KC_TOKEN}" -H "Content-Type: application/json" \
      -X POST "${KEYCLOAK_HOST}/admin/realms/${_realmName}/groups/${KC_GROUP_ID}/role-mappings/realm" \
      -d "[${KC_ROLE_DATA}]"
  fi
}

#-------------------------------
_loadGroupAnfUsersFromFile() {
  _realmName="$1"
  _fileName="$2"

  while IFS="," read -r _grpName _roleName _USERS _userPrefix
  do
    _grpName="$(echo -e "${_grpName}" | tr -d '[:space:]')"
    _roleName="$(echo -e "${_roleName}" | tr -d '[:space:]')"
    
    if [[ -z ${_userPrefix} ]]; then
      _userPrefix="${_USER_PREFIX}"
    else
      _userPrefix="$(echo -e "${_userPrefix}" | tr -d '[:space:]')"
    fi
    # if not titles
    if [[ "${_grpName}" != "GROUP_NAME" ]]; then
      # create goup
      _createGroup "${_realmName}" "${_grpName}"

      # user range ?
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
          _USERS+="${_userPrefix}$_userSuffix$_sep"
        done
      fi

      for _usrName in ${_USERS}; do 
        # create user
        _createUser "${_realmName}" "${_usrName}"
        _createPassword "${_realmName}" "${_usrName}" "${_usrName}"

        # associate user to group
        _associateUserToGroup "${_realmName}" "${_usrName}" "${_grpName}"
      done

      if [[ ! -z "${_roleName}" ]]; then
        _createRole "${_realmName}" "${_roleName}"
        _associateGroupToRole "${_realmName}" "${_grpName}" "${_roleName}"
      fi

    fi
  done < <(cat ${_fileName})
}

#-------------------------------
_createClient() {
    KC_REALM=$1
    _NEW_CLIENT_NAME=$2
    _NEW_CLIENT_SECRET=$3
    echo "Creating client [${_NEW_CLIENT_NAME}] in realm [${KC_REALM}]"
    curl -k -s -H "Accept: application/json" -H "Authorization: Bearer ${KC_TOKEN}" -H "Content-Type: application/json" \
      -X POST "${KEYCLOAK_HOST}/admin/realms/${KC_REALM}/clients" \
      -d '{"name": "'${_NEW_CLIENT_NAME}'", "clientId": "'${_NEW_CLIENT_NAME}'", "enabled": true, "secret": "'${_NEW_CLIENT_SECRET}'", "directAccessGrantsEnabled": true, "serviceAccountsEnabled": true }'
}

#-------------------------------
_createClientRole() {
  KC_REALM=$1
  _NEW_CLIENT_NAME=$2
  _NEW_ROLE_NAME=$3

  # legge client UUID
  KC_CLIENT_UUID=$(curl -k -s -H "Accept: application/json" -H "Authorization: Bearer ${KC_TOKEN}" \
    -X GET "${KEYCLOAK_HOST}/admin/realms/${KC_REALM}/clients" \
    | jq '.[] | select(.clientId == "'${_NEW_CLIENT_NAME}'")' | jq .id | sed 's/"//g')

  if [[ ! -z "${KC_CLIENT_UUID}" ]]; then
    # crea ruolo del client
    echo "Creating client role [${_NEW_ROLE_NAME}] for client [${_NEW_CLIENT_NAME}] in realm [${KC_REALM}]"
    curl -k -s -H "Accept: application/json" -H "Authorization: Bearer ${KC_TOKEN}" -H "Content-Type: application/json" \
      -X POST "${KEYCLOAK_HOST}/admin/realms/${KC_REALM}/clients/${KC_CLIENT_UUID}/roles" \
      -d '{"name": "'${_NEW_ROLE_NAME}'", "clientRole": true }' | jq .
  fi
}

#-------------------------------
_createClientAndRoles() {
  _realmName="$1"
  _fileName="$2"

  if [[ ! -z "${_realmName}" ]] && [[ ! -z "${_fileName}" ]]; then

    while IFS="," read -r _clientName _clientSecret _clientRoles
    do
      _clientName="$(echo -e "${_clientName}" | tr -d '[:space:]')"
      _clientSecret="$(echo -e "${_clientSecret}" | tr -d '[:space:]')"
      if [[ -z "${_clientSecret}" ]]; then
        _clientSecret="secret"
      fi

      # if not titles
      if [[ "${_clientName}" != "CLIENT_NAME" ]]; then
        # create client
        _createClient "${_realmName}" "${_clientName}" "${_clientSecret}"

        for _cRole in ${_clientRoles}; do 
          # create client roles
          _cRole="$(echo -e "${_cRole}" | tr -d '[:space:]')"
          _createClientRole "${_realmName}" "${_clientName}" "${_cRole}"
        done

      fi
    done < <(cat ${_fileName})  

  fi
}

#-------------------------------
_test() {
  _createGroups "${_NEW_REALM}"
  _createUsers "${_NEW_REALM}"

  _createRoleUsersData 0 "1..3"
  _createRoleUsersData 1 "4..6"
  _createRoleUsersData 2 "7..10"

  _associateUsersToGroups "${_NEW_REALM}"
}

#-------------------------------

_NEW_REALM="$1"
_GROUP_USERS_FILE="$2"
_GROUP_CLIENT_FILE="$3"
_TOKEN_LIFESPAN="$4"

if [[ ! -z "${_NEW_REALM}" ]]; then
  _getToken
  _createRealm "${_NEW_REALM}" "${_TOKEN_LIFESPAN}"

  # create Client and clientRoles
  if [[ ! -z "${_GROUP_CLIENT_FILE}" ]]; then
    if [ -f "$(pwd)/${_GROUP_CLIENT_FILE}" ]; then
      _createClientAndRoles "${_NEW_REALM}" "${_GROUP_CLIENT_FILE}"
    fi
  fi

  if [[ ! -z "${_GROUP_USERS_FILE}" ]]; then
    if [ -f "$(pwd)/${_GROUP_USERS_FILE}" ]; then
      _loadGroupAnfUsersFromFile "${_NEW_REALM}" "$(pwd)/${_GROUP_USERS_FILE}"

      # tbd: create realm roles

      # tbd: associate users to role

      # verificare differenze tra ruolo del realm e ruolo del client per annotazione @RolesAllow...
    fi
  fi
else
  echo "Usage: $0 'newRealmName' 'pathToGroupsUsersFile'"  
fi



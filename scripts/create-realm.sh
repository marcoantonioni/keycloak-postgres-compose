#!/bin/bash

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
# Login and export access token in var KC_TOKEN
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
# Set token lifespan, default to 14400 msec.
#-------------------------------
_setTokensLifespan() {
  _realmName=$1
  _timeOut=$2
  if [[ -z "${_timeOut}" ]]; then
    _timeOut=14400
  fi
  echo "Setting token lifespan [${_timeOut}] for realm [${_realmName}]"
  curl -s -k -H "Content-Type: application/json" -H "Accept: application/json" -H "Authorization: Bearer ${KC_TOKEN}" \
    -X PUT "${KEYCLOAK_HOST}/admin/realms/${_realmName}/ui-ext" \
    -d '{ "accessTokenLifespan": "'${_timeOut}'", "accessTokenLifespanForImplicitFlow": "'${_timeOut}'", "actionTokenGeneratedByAdminLifespan": "'${_timeOut}'", "actionTokenGeneratedByUserLifespan": "'${_timeOut}'", "oauth2DeviceCodeLifespan": "'${_timeOut}'" }' \
    | jq .
}

#-------------------------------
# create new realm
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
    _setTokensLifespan ${_newRealmName} ${_timeOut}
  fi
}

#-------------------------------
# Create Group
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
# Create user Password
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
# Create User
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
# Associate a User to a Group
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
# Create Role
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
# Associate a Group to a Role
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
# Create Groups and Users
#-------------------------------
_loadGroupAndUsersFromFile() {
  _realmName="$1"
  _fileName="$2"

  while IFS="," read -r _grpName _roleName _USERS _userPrefix
  do
    # skip empty or comment
    [[ -z "${_grpName}" ]] && continue
    [[ ${_grpName} =~ ^#.* ]] && continue

    _grpName="$(echo -e "${_grpName}" | tr -d '[:space:]')"
    _roleName="$(echo -e "${_roleName}" | tr -d '[:space:]')"
    
    if [[ -z ${_userPrefix} ]]; then
      _userPrefix="${_USER_PREFIX}"
    else
      _userPrefix="$(echo -e "${_userPrefix}" | tr -d '[:space:]')"
    fi

    # if not titles row
    if [[ "${_grpName}" != "GROUP_NAME" ]]; then
      # create goup
      _createGroup "${_realmName}" "${_grpName}"

      # is user range ?
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
# Create Client
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
# Create Scope
#-------------------------------
_createScope() {
  KC_REALM=$1
  _SCOPE_NAME=$2
  if [[ ! -z "${_SCOPE_NAME}" ]]; then
    echo "Creating default scope [${_SCOPE_NAME}] in realm [${KC_REALM}]"
    curl -k -s -H "Accept: application/json" -H "Authorization: Bearer ${KC_TOKEN}" -H "Content-Type: application/json" \
      -X POST "${KEYCLOAK_HOST}/admin/realms/${KC_REALM}/client-scopes" \
      -d '{"name": "'${_SCOPE_NAME}'","type": "default","protocol": "openid-connect","attributes": {"display.on.consent.screen": "true","include.in.token.scope": "true"}}'
  fi
}

#-------------------------------
# Associate a Scope to a Client
#-------------------------------
_associateClientScope() {
  KC_REALM=$1
  _CLIENT_NAME=$2
  _SCOPE_NAME=$3

  if [[ ! -z "${_SCOPE_NAME}" ]]; then
    # read client UUID
    KC_CLIENT_UUID=$(curl -k -s -H "Accept: application/json" -H "Authorization: Bearer ${KC_TOKEN}" \
      -X GET "${KEYCLOAK_HOST}/admin/realms/${KC_REALM}/clients" \
      | jq '.[] | select(.clientId == "'${_CLIENT_NAME}'")' | jq .id | sed 's/"//g')

    # read scope UUID
    KC_SCOPE_UUID=$(curl -k -s -H "Accept: application/json" -H "Authorization: Bearer ${KC_TOKEN}" \
      -X GET "${KEYCLOAK_HOST}/admin/realms/${KC_REALM}/client-scopes" \
      | jq '.[] | select(.name == "'${_SCOPE_NAME}'")' | jq .id | sed 's/"//g')

    if [[ ! -z "${KC_CLIENT_UUID}" ]] && [[ ! -z "${KC_SCOPE_UUID}" ]]; then
      # associate scope to client
      echo "Associating client scope [${_SCOPE_NAME}] for client [${_CLIENT_NAME}] in realm [${KC_REALM}]"
      curl -k -s -H "Accept: application/json" -H "Authorization: Bearer ${KC_TOKEN}" -H "Content-Type: application/json" \
        -X PUT "${KEYCLOAK_HOST}/admin/realms/${KC_REALM}/clients/${KC_CLIENT_UUID}/default-client-scopes/${KC_SCOPE_UUID}"
    fi
  fi
}

#-------------------------------
# Create a ClientRole
#-------------------------------
_createClientRole() {
  KC_REALM=$1
  _NEW_CLIENT_NAME=$2
  _NEW_ROLE_NAME=$3

  # read client UUID
  KC_CLIENT_UUID=$(curl -k -s -H "Accept: application/json" -H "Authorization: Bearer ${KC_TOKEN}" \
    -X GET "${KEYCLOAK_HOST}/admin/realms/${KC_REALM}/clients" \
    | jq '.[] | select(.clientId == "'${_NEW_CLIENT_NAME}'")' | jq .id | sed 's/"//g')

  if [[ ! -z "${KC_CLIENT_UUID}" ]]; then
    # create a role for client
    echo "Creating client role [${_NEW_ROLE_NAME}] for client [${_NEW_CLIENT_NAME}] in realm [${KC_REALM}]"
    curl -k -s -H "Accept: application/json" -H "Authorization: Bearer ${KC_TOKEN}" -H "Content-Type: application/json" \
      -X POST "${KEYCLOAK_HOST}/admin/realms/${KC_REALM}/clients/${KC_CLIENT_UUID}/roles" \
      -d '{"name": "'${_NEW_ROLE_NAME}'", "clientRole": true }' | jq .
  fi
}

#-------------------------------
# Create Client and ClientRoles
#-------------------------------
_createClientAndRoles() {
  _realmName="$1"
  _fileName="$2"

  if [[ ! -z "${_realmName}" ]] && [[ ! -z "${_fileName}" ]]; then

    while IFS="," read -r _clientName _clientSecret _clientScope _clientRoles
    do
      # skip empty or comment
      [[ -z "${_clientName}" ]] && continue
      [[ ${_clientName} =~ ^#.* ]] && continue

      _clientName="$(echo -e "${_clientName}" | tr -d '[:space:]')"
      _clientSecret="$(echo -e "${_clientSecret}" | tr -d '[:space:]')"
      _clientScope="$(echo -e "${_clientScope}" | tr -d '[:space:]')"

      if [[ -z "${_clientSecret}" ]]; then
        # if empty column in configuration set default password for client
        _clientSecret="secret"
      fi

      # if not titles row
      if [[ "${_clientName}" != "CLIENT_NAME" ]]; then
        # create client
        _createClient "${_realmName}" "${_clientName}" "${_clientSecret}"

        # create scope
        _createScope "${_realmName}" "${_clientScope}"

        # associate client scope
        _associateClientScope "${_realmName}" "${_clientName}" "${_clientScope}"

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
# MAIN section
#-------------------------------

_NEW_REALM="$1"
_GROUP_USERS_FILE="$2"
_GROUP_CLIENT_FILE="$3"
_TOKEN_LIFESPAN="$4"

if [[ ! -z "${_NEW_REALM}" ]]; then
  _getToken
  _createRealm "${_NEW_REALM}" "${_TOKEN_LIFESPAN}"

  # create Client and ClientRoles from configuration file
  if [[ ! -z "${_GROUP_CLIENT_FILE}" ]]; then
    if [ -f "$(pwd)/${_GROUP_CLIENT_FILE}" ]; then
      _createClientAndRoles "${_NEW_REALM}" "${_GROUP_CLIENT_FILE}"
    fi
  fi

  # create Groups and Users from configuration file
  if [[ ! -z "${_GROUP_USERS_FILE}" ]]; then
    if [ -f "$(pwd)/${_GROUP_USERS_FILE}" ]; then
      _loadGroupAndUsersFromFile "${_NEW_REALM}" "$(pwd)/${_GROUP_USERS_FILE}"
    fi
  fi
else
  echo "Usage: $0 'newRealmName' 'pathToGroupsUsersFile'"  
fi



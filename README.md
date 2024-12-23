# keycloak-postgres-compose


## Start containers
```
./scripts/clear.sh && podman compose up
```

## KeyCloak console
https://localhost:7433/admin/master/console


## Create new realm

Before creating a realm make sure that one of the examples 'my-realm-1' or 'my-realm-1' does not already exist. 

The script reports its presence in case of duplication of internal elements but does not stop.
```
# option 1, token lifespan default 14400 secs
_REALM_NAME=my-realm-1
_GROUPS_AND_USERS_FILE=./scripts/groups-users-1.csv
_CLIENT_ROLES_FILE=./scripts/client-roles.csv
./scripts/create-realm.sh ${_REALM_NAME} ${_GROUPS_AND_USERS_FILE} ${_CLIENT_ROLES_FILE}

# option 2, token lifespan set to 30 secs
_REALM_NAME=my-realm-2
_GROUPS_AND_USERS_FILE=./scripts/groups-users-1.csv
_CLIENT_ROLES_FILE=./scripts/client-roles.csv
_TOKEN_LIFESPAN=30
./scripts/create-realm.sh ${_REALM_NAME} ${_GROUPS_AND_USERS_FILE} ${_CLIENT_ROLES_FILE} ${_TOKEN_LIFESPAN}
```


## Export realm
```
# enter in container shell
kc_ctr=$(podman ps | grep keycloak | awk '{print $1}')
[[ ! -z "${kc_ctr}" ]] && podman exec -it ${kc_ctr} /bin/bash

# from inside container, export realm in file: quarkus-realm.json
ls -al /tmp

/opt/keycloak/bin/kc.sh export --dir /tmp --users realm_file --realm my-realm-1

/opt/keycloak/bin/kc.sh export --dir /tmp --users realm_file --realm my-realm-2

ls -al /tmp
exit
```

## From your shell, copy realm configuration to your local f.s.
```
kc_ctr=$(podman ps | grep keycloak | awk '{print $1}')
podman cp ${kc_ctr}:/tmp/my-realm-1-realm.json ./realms/my-realm-1-realm.json
podman cp ${kc_ctr}:/tmp/my-realm-2-realm.json ./realms/my-realm-2-realm.json
```

## Supporting commands
```
podman compose events
podman network prune -f
podman network inspect keycloak-postgres-compose_default

# create certificate
cd ./certs
keytool -genkeypair -alias keycloak-localhost -keyalg RSA -keysize 2048 -validity 3650 -keystore keycloak.keystore -dname "cn=keycloak,o=home,c=it" -keypass secret -storepass secret

# list certificate
keytool -list -keystore keycloak.keystore

```

# References

https://www.keycloak.org/server/all-config

https://www.keycloak.org/docs-api/latest/rest-api/index.html

https://www.mastertheboss.com/keycloak/getting-started-with-keycloak-powered-by-quarkus/

https://github.com/fmarchioni/mastertheboss/tree/master/bootable-jar/elytron-oidc-client-keycloak17

https://keycloak-managed-service.inteca.com/identity-access-management/harnessing-the-power-of-keycloak-and-quarkus-a-comprehensive-guide/


# keycloak-postgres-compose

## KeyCloak configuration parameters
https://www.keycloak.org/server/all-config
https://www.keycloak.org/docs-api/latest/rest-api/index.html

https://www.mastertheboss.com/keycloak/getting-started-with-keycloak-powered-by-quarkus/

https://github.com/fmarchioni/mastertheboss/tree/master/bootable-jar/elytron-oidc-client-keycloak17


https://keycloak-managed-service.inteca.com/identity-access-management/harnessing-the-power-of-keycloak-and-quarkus-a-comprehensive-guide/

## TBD
<pre>
- rivedere uso _GROUPS
- rivedere _test() e funzioni vecchie
</pre>

## Avvio containers
```
./clear.sh && podman compose up

podman compose events

podman network prune -f
podman network inspect keycloak-postgres-compose_default
```

## KeyCloak console
https://localhost:8443/admin/master/console/#/quarkus


## Export realm
```
kc_ctr=$(podman ps | grep keycloak | awk '{print $1}')
[[ ! -z "${kc_ctr}" ]] && podman exec -it ${kc_ctr} /bin/bash

# da container, export in unico file: quarkus-realm.json
ls -al /tmp
/opt/keycloak/bin/kc.sh export --dir /tmp --users realm_file --realm my-realm-1
ls -al /tmp
exit
```

## da shell host, copia configurazione del realm
```
kc_ctr=$(podman ps | grep keycloak | awk '{print $1}')
podman cp ${kc_ctr}:/tmp/my-realm-1-realm.json ./realms/my-realm-1-realm.json
```

## creazione utente via curl
```
KC_HOST=https://localhost:8443/auth/admin/realms/apiv2/users
curl -k -v ${KC_HOST} -H "Content-Type: application/json" -H "Authorization: bearer $TOKEN"   --data '{"firstName":"xyz","lastName":"xyz", "username":"xyz123","email":"demo2@gmail.com", "enabled":"true","credentials":[{"type":"password","value":"test123","temporary":false}]}'
```

## update repo
```
git add . && git commit -m "update" && git push origin main
```

## certificato
```
cd ./certs
keytool -genkeypair -alias keycloak-localhost -keyalg RSA -keysize 2048 -validity 3650 -keystore keycloak.keystore -dname "cn=keycloak,o=home,c=it" -keypass secret -storepass secret

# list
keytool -list -keystore keycloak.keystore
```

## creazione realm, gruppi+utenti, clienti+ruoli
```
# token lifespan default 14400 secs
./scripts/create-realm.sh my-realm-1 ./scripts/groups-users-1.csv ./scripts/client-roles.csv

# token lifespan 3600 secs
./scripts/create-realm.sh my-realm-1 ./scripts/groups-users-1.csv ./scripts/client-roles.csv 3600
```

# keycloak-postgres-compose

## KeyCloak configuration parameters
https://www.keycloak.org/server/all-config

## Avvio containers
```
./clear.sh && podman compose up
```

## KeyCloak console
https://localhost:8443/admin/master/console/#/quarkus


## Export realm
```
kc_ctr=$(podman ps | grep keycloak | awk '{print $1}')
[[ ! -z "${kc_ctr}" ]] && podman exec -it ${kc_ctr} /bin/bash

# da container, export in unico file: quarkus-realm.json
ls -al /tmp
/opt/keycloak/bin/kc.sh export --dir /tmp --users realm_file --realm quarkus
ls -al /tmp
exit
```

## da shell host, copia configurazione del realm
```
kc_ctr=$(podman ps | grep keycloak | awk '{print $1}')
podman cp ${kc_ctr}:/tmp/quarkus-realm.json ./realms/quarkus-realm.json
```

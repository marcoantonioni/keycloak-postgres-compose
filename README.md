# keycloak-postgres-compose

## KeyCloak configuration parameters
https://www.keycloak.org/server/all-config

## Export realm
kc_ctr=$(podman ps | grep keycloak | awk '{print $1}')
[[ ! -z "${kc_ctr}" ]] && podman exec -it ${kc_ctr} /bin/bash

# export in unico file: quarkus-realm.json
ls -al /tmp
/opt/keycloak/bin/kc.sh export --dir /tmp --users realm_file --realm quarkus
ls -al /tmp
exit

kc_ctr=$(podman ps | grep keycloak | awk '{print $1}')
podman cp ${kc_ctr}:/tmp/quarkus-realm.json ./quarkus-realm.json

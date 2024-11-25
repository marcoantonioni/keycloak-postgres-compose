#/bin/bash
podman ps --all | grep -v CONTAINER | awk '{print $1}' | xargs podman rm

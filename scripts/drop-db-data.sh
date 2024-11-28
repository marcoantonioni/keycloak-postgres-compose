#!/bin/bash

if [ -d "$(pwd)/pgdata" ]; then
  sudo rm -fr ./pgdata
  echo "./pgdata removed"
  exit 0
else
  echo "folder ./pgdata not found"
  exit 1
fi


#!/bin/bash

sh -c "nginx-reloader.sh &"
exec "$@"

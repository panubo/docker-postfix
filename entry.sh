#!/usr/bin/env bash

set -e
[ "${DEBUG:-false}" == 'true' ] && set -x

# Defaults
if [ -z "$MAILNAME" ]; then
    echo "smtp >> Error: MAILNAME not specified"
    exit 128
fi

if [ -z "$MYNETWORKS" ]; then
    export MYNETWORKS='127.0.0.0/8, 10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16'
    echo "smtp >> Warning: MYNETWORKS not specified, allowing all private IPs"
fi

echo "Running command $@"
exec "$@"

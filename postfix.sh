#!/usr/bin/env bash

# exit cleanly
trap "{ /usr/sbin/service postfix stop; }" EXIT

# start postfix
/usr/sbin/service postfix start

# don't exit
sleep infinity

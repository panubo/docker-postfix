#!/usr/bin/env bats

setup() {
  # The entrypoint script will configure and start all services via s6
  # We run it in the background to not block the test
  env MAILNAME='mail.example.com' SMTPD_USERS='user:password' MYNETWORKS='10.0.0.0/8' /entry.sh /usr/bin/s6-svscan /etc/s6 &
  # And give it some time to start up
  sleep 5
}

teardown() {
  # Stop the s6 supervisor and all its services
  s6-svscanctl -t /etc/s6
}

@test "Test SMTPD_USERS sasl authentication" {
  # Test auth on submission port
  run swaks --to "test@example.com" \
            --from "user@example.com" \
            --server "127.0.0.1:587" \
            --auth-user "user" \
            --auth-password "password"
  echo "status: ${status}"
  echo "output: ${output}"
  [ "${status}" -eq 0 ]
}

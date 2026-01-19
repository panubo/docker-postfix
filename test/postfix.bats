#!/usr/bin/env bats

# Test for /etc/s6/postfix/run

setup() {
    BATS_TMPDIR=$(mktemp -d -t bats-XXXXXXXX)
    export BATS_TMPDIR

    # Backup original files that the script might modify
    [ -f /etc/postfix/main.cf ] && cp /etc/postfix/main.cf "${BATS_TMPDIR}/main.cf.bak"
    [ -f /etc/sasldb2 ] && cp /etc/sasldb2 "${BATS_TMPDIR}/sasldb2.bak"
    cp /usr/lib/postfix/configure-instance.sh "${BATS_TMPDIR}/configure-instance.sh.bak"

    # Create a version of the run script without the final 'exec' to prevent blocking
    sed 's/exec \/usr\/sbin\/postfix start-fg//' /etc/s6/postfix/run > "${BATS_TMPDIR}/run"
    chmod +x "${BATS_TMPDIR}/run"

    # The script might create these files, so ensure the directory exists
    mkdir -p /etc/postfix/sasl
}

teardown() {
    # Restore original files
    [ -f "${BATS_TMPDIR}/main.cf.bak" ] && mv "${BATS_TMPDIR}/main.cf.bak" /etc/postfix/main.cf
    [ -f "${BATS_TMPDIR}/sasldb2.bak" ] && mv "${BATS_TMPDIR}/sasldb2.bak" /etc/sasldb2
    mv "${BATS_TMPDIR}/configure-instance.sh.bak" /usr/lib/postfix/configure-instance.sh
    rm -rf "${BATS_TMPDIR}"
}

@test "should configure main.cf with custom values from environment variables" {
    # Run the modified script in a subshell with custom environment variables
    (
        # Set env vars to test against
        export MAILNAME="test.example.com"
        export MYNETWORKS="10.0.0.0/8 127.0.0.0/8"
        export SIZELIMIT="20480000"
        export RELAYHOST="[mail.example.com]:587"
        export POSTFIX_ADD_MISSING_HEADERS="yes"
        export INET_PROTOCOLS="ipv4"
        export DISABLE_VRFY_COMMAND="no"
        export USE_TLS="no" # Disable TLS to avoid slow cert generation

        # Execute the setup script
        bash -x "${BATS_TMPDIR}/run"
    )

    # Use postconf to verify the settings in /etc/postfix/main.cf
    run postconf -h myhostname
    [ "$status" -eq 0 ]
    [ "$output" = "test.example.com" ]

    run postconf -h mynetworks
    [ "$status" -eq 0 ]
    [ "$output" = "10.0.0.0/8 127.0.0.0/8" ]

    run postconf -h message_size_limit
    [ "$status" -eq 0 ]
    [ "$output" = "20480000" ]

    run postconf -h relayhost
    [ "$status" -eq 0 ]
    [ "$output" = "[mail.example.com]:587" ]

    run postconf -h always_add_missing_headers
    [ "$status" -eq 0 ]
    [ "$output" = "yes" ]

    run postconf -h inet_protocols
    [ "$status" -eq 0 ]
    [ "$output" = "ipv4" ]

    run postconf -h disable_vrfy_command
    [ "$status" -eq 0 ]
    [ "$output" = "no" ]
}

@test "should enable DKIM milter when USE_DKIM is 'yes'" {
    (
        export MAILNAME="test.example.com"
        export USE_DKIM="yes"
        bash -x "${BATS_TMPDIR}/run"
    )

    run postconf -h smtpd_milters
    [ "$status" -eq 0 ]
    [ "$output" = "inet:localhost:8891" ]

    run postconf -h non_smtpd_milters
    [ "$status" -eq 0 ]
    [ "$output" = "inet:localhost:8891" ]
}

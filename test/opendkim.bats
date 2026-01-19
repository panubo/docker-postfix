#!/usr/bin/env bats

# This setup function runs before each test.
setup() {
    # Create a temporary directory for our test files.
    BATS_TMPDIR=$(mktemp -d -t bats-XXXXXXXX)
    export BATS_TMPDIR

    # Mock the s6-svscanctl command so the script doesn't fail if it's not installed.
    # We create a fake executable that does nothing and returns success.
    ln -s /usr/bin/true "${BATS_TMPDIR}/s6-svscanctl"
    export PATH="${BATS_TMPDIR}:${PATH}"
}

# This teardown function runs after each test to clean up.
teardown() {
    rm -rf "${BATS_TMPDIR}"
}

@test "should generate config with default values" {
    # Define test-specific variables
    local output_file="${BATS_TMPDIR}/opendkim.conf"
    local dkim_keyfile="${BATS_TMPDIR}/dkim.key"
    touch "${dkim_keyfile}" # Create the dummy key file

    # Run the script in a subshell with a clean environment and execution tracing (-x)
    (
        export MAILNAME="example.com"
        export MYNETWORKS="127.0.0.1"
        export DKIM_CONF="${output_file}"
        export DKIM_KEYFILE="${dkim_keyfile}"
        bash -x etc/opendkim.conf.sh
    )

    # Check that the generated file contains the expected lines.
    run grep "Domain    example.com" "${output_file}"
    [ "$status" -eq 0 ] # Succeeds if grep finds the line

    run grep "Selector  mail" "${output_file}"
    [ "$status" -eq 0 ]

    run grep "InternalHosts       127.0.0.1" "${output_file}"
    [ "$status" -eq 0 ]
}

@test "should use DKIM_DOMAINS and DKIM_SELECTOR from environment" {
    # Define test-specific variables
    local output_file="${BATS_TMPDIR}/opendkim.conf"
    local dkim_keyfile="${BATS_TMPDIR}/dkim.key"
    touch "${dkim_keyfile}"

    # Run the script in a subshell with a clean environment and execution tracing (-x)
    (
        export DKIM_DOMAINS="custom.net,another.org"
        export DKIM_SELECTOR="dkim2024"
        export DKIM_CONF="${output_file}"
        export DKIM_KEYFILE="${dkim_keyfile}"
        bash -x etc/opendkim.conf.sh
    )

    # Check for the custom values.
    run grep "Domain    custom.net,another.org" "${output_file}"
    [ "$status" -eq 0 ]

    run grep "Selector  dkim2024" "${output_file}"
    [ "$status" -eq 0 ]
}

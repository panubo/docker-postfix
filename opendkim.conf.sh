#!/usr/bin/env bash

set -e

OUTPUT='/etc/opendkim.conf'

# exit if config already exists
[ -f "${OUTPUT}" ] && exit 0

# defaults
: ${DKIM_KEYFILE:='/etc/opendkim/dkim.key'}
: ${DKIM_DOMAINS:="${MAILNAME}"}
: ${DKIM_SELECTOR:='mail'}
: ${DKIM_INTERNALHOSTS:="${MYNETWORKS}"}
: ${DKIM_EXTERNALIGNORE:="${MYNETWORKS}"}
: ${DKIM_OVERSIGN_HEADERS:='From'}
: ${DKIM_SENDER_HEADERS:='From'}
: ${DKIM_SIGN_HEADERS:='*'}
: ${DKIM_OMIT_HEADERS:='*'}

# Checks
if [ ! -f "${DKIM_KEYFILE}" ]; then
    echo "dkim >> Error: DKIM_KEYFILE ${DKIM_KEYFILE} not found"
    # shutdown everything
    s6-svscanctl -t /etc/s6
    exit 128
else
    echo "dkim >> Setting mode and owner on $DKIM_KEYFILE"
    chown root:root ${DKIM_KEYFILE}
    chmod 400 ${DKIM_KEYFILE}
fi

# Status Output
echo "dkim >> Setting DKIM_KEYFILE to $DKIM_KEYFILE"
echo "dkim >> Setting DKIM_DOMAINS to $DKIM_DOMAINS"
echo "dkim >> Setting DKIM_SELECTOR to $DKIM_SELECTOR"

# Render the dkim config
cat > ${OUTPUT} <<EOF
# This is a basic configuration that can easily be adapted to suit a standard
# installation. For more advanced options, see opendkim.conf(5) and/or
# /usr/share/doc/opendkim/examples/opendkim.conf.sample.

# Log to syslog
Syslog         yes
SyslogSuccess  yes

# Required to use local socket with MTAs that access the socket as a non-
# privileged user (e.g. Postfix)
UMask  002

##  Create a socket through which your MTA can communicate.
Socket  inet:8891@localhost

# Sign for example.com with key in /etc/mail/dkim.key using
# selector '2007' (e.g. 2007._domainkey.example.com)
Domain    ${DKIM_DOMAINS}
KeyFile   ${DKIM_KEYFILE}
Selector  ${DKIM_SELECTOR}

# Commonly-used options; the commented-out versions show the defaults.
Canonicalization  relaxed
Mode              s
#SubDomains       no
#ADSPAction       continue

InternalHosts       ${DKIM_INTERNALHOSTS}
ExternalIgnoreList  ${DKIM_EXTERNALIGNORE}

##  Specifies whether or not the filter should generate report mail back
##  to senders when verification fails and an address for such a purpose
##  is provided. See opendkim.conf(5) for details.
SendReports  yes

# Always oversign From (sign using actual From and a null From to prevent
# malicious signatures header fields (From and/or others) between the signer
# and the verifier.  From is oversigned by default in the Debian pacakge
# because it is often the identity key used by reputation systems and thus
# somewhat security sensitive.
OversignHeaders  ${DKIM_OVERSIGN_HEADERS}
SenderHeaders    ${DKIM_SENDER_HEADERS}
SignHeaders      ${DKIM_SIGN_HEADERS}
OmitHeaders      ${DKIM_OMIT_HEADERS}

# List domains to use for RFC 6541 DKIM Authorized Third-Party Signatures
# (ATPS) (experimental)

#ATPSDomains  example.com
EOF

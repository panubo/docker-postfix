# Postfix Docker Image

Postfix SMTP Relay.

Drop-in Docker image for SMTP relaying. Use wherever a connected service
requires SMTP sending capabilities. Supports TLS out of the box and DKIM
(if enabled and configured). Additionally offers support for Virtual
alias regex (useful for address rewriting) and maps.

## Environment Variables

- `MAILNAME` - set this to a legitimate FQDN hostname for this service (required).
- `MYNETWORKS` - comma separated list of IP subnets that are allowed to relay. Default `127.0.0.0/8, 10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16`
- `LOGOUTPUT` - Syslog log file location. eg `/var/log/maillog`. Default `/dev/stdout`.
- `TZ` - set timezone. This is used by Postfix to create `Received` headers. Default `UTC`.

General Postfix:

- `SIZELIMIT` - Postfix `message_size_limit`. Default `15728640`.
- `POSTFIX_ADD_MISSING_HEADERS` - add missing headers. Default `no`
- `INET_PROTOCOLS` - IP protocols, eg `ipv4` or `ipv6`. Default `all`
- `BOUNCE_ADDRESS` - Email address to receive delivery failure notifications. Default is to log the delivery failure.
- `HEADER_CHECKS` - If "true" activates a set of pre-configured header_checks.

Relay host parameters:

- `RELAYHOST` - Postfix `relayhost`. Default ''. (example `mail.example.com:25`)
- `RELAYHOST_AUTH` - Enable authentication for relayhost. Generally used with `RELAYHOST_PASSWORDMAP`. Default `no`.
- `RELAYHOST_PASSWORDMAP` - relayhost password map in format: `RELAYHOST_PASSWORDMAP=mail1.example.com:user1:pass2,mail2.example.com:user2:pass2`

Virtual parameters:

- `VIRTUAL_ALIAS_MAP` - virtual alias map in format: `VIRTUAL_ALIAS_MAP=someone@somewhere.com:local_user,postmaster@example.net:root`
- `VIRTUAL_ALIAS_REGEX_BASE64` - virtual alias regex base64 encoded. (example `VIRTUAL_ALIAS_REGEX_BASE64=aWYgIS8uKmV4YW1wbGUuY29tLwovLiovIHJlZGlyZWN0LWFkZHJlc3NAc29tZXdoZXJlLm5ldAplbmRpZgo=`)

TLS parameters:

- `USE_TLS` - Enable TLS. Default `yes` (options, `yes`, `no`)
- `TLS_SECURITY_LEVEL` - Default `may` (opportunistic) (options, `may`, `encrypt`, others see: [www.postfix.org/postconf.5.html#smtp_tls_security_level](http://www.postfix.org/postconf.5.html#smtp_tls_security_level)
- `TLS_KEY` - Default `/etc/ssl/private/ssl-cert-snakeoil.key`
- `TLS_CRT` - Default `/etc/ssl/certs/ssl-cert-snakeoil.pem`
- `TLS_CA` - Default ''

NB. A "snake-oil" certificate will be generated on start if required.

DKIM parameters:

- `USE_DKIM` - Enable DKIM. Default `no`
- `DKIM_KEYFILE` - DKIM Keyfile location. Default `/etc/opendkim/dkim.key`
- `DKIM_DOMAINS` - Domains to sign. Defaults to `MAILNAME`. Multiple domains will use the same key and selector.
- `DKIM_SELECTOR` - DKIM key selector. Default `mail`. `<selector>._domainkey.<domain>` is used for resolving the public key in DNS.
- `DKIM_INTERNALHOSTS` - Defaults to `MYNETWORKS`.
- `DKIM_EXTERNALIGNORE` - Defaults to `MYNETWORKS`.
- `DKIM_OVERSIGN_HEADERS` - Sets OversignHeaders. Default `From`.
- `DKIM_SENDER_HEADERS` - Sets SenderHeaders. Default unset.
- `DKIM_SIGN_HEADERS` - Sets SignHeaders. Default unset.
- `DKIM_OMIT_HEADERS` - Sets OmitHeaders. Default unset.

## Usage Example

`docker run -e MAILNAME=mail.example.com panubo/postfix`

## Volumes

No volumes are defined. If you want persistent spool storage then mount
`/var/spool/postfix` outside of the container.

## Test email

To send a test email via the command line, make sure heirloom-mailx is installed.

```
echo -e "To: Bob <bob@example.com>\nFrom: Bill <bill@example.com>\nSubject: Test email\n\nThis is a test email message" | mailx -v -S smtp=smtp://... -S from=bill@example.com -t

# With TLS
echo -e "To: Bob <bob@example.com>\nFrom: Bill <bill@example.com>\nSubject: Test email\n\nThis is a test email message" | mailx -v -S smtp-use-starttls -S ssl-verify=ignore -S smtp=smtp://... -S from=bill@example.com -t

# With TLS on Centos/Fedora (extra nss-config-dir)
echo -e "To: Bob <bob@example.com>\nFrom: Bill <bill@example.com>\nSubject: Test email\n\nThis is a test email message" | mailx -v -S smtp-use-starttls -S ssl-verify=ignore -S nss-config-dir=/etc/pki/nssdb -S smtp=smtp://... -S from=bill@example.com -t
```

## Developing

See the `Makefile` for make targets.

## Status

Production ready and stable.

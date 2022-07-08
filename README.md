# Postfix Docker Image

Postfix SMTP Relay based on Debian Bullseye.

Highly configurable Docker image for SMTP relaying. Use wherever a connected service
requires SMTP sending capabilities. Supports TLS out of the box and DKIM
(if enabled and configured).

Not intended to be used for receiving email for local delivery or end-user
email access.

## Environment Variables

- `MAILNAME` - set this to a legitimate FQDN hostname for this service (required). (example, `mail.example.com`)
- `MYNETWORKS` - comma separated list of IP subnets that are allowed to relay. Default `127.0.0.0/8, 10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16`
- `LOGOUTPUT` - Syslog log file location. eg `/var/log/maillog`. Default `/dev/stdout`.
- `TZ` - set timezone. This is used by Postfix to create `Received` headers. Default `UTC`.

**General Postfix:**

- `SIZELIMIT` - Postfix `message_size_limit`. Default `15728640`.
- `POSTFIX_ADD_MISSING_HEADERS` - add missing headers. Default `no`. (options, `yes`, `no`)
- `INET_PROTOCOLS` - IP protocols, eg `ipv4` or `ipv6`. Default `all`. (options, `ipv4`, `ipv6`, `all`)
- `BOUNCE_ADDRESS` - Email address to receive delivery failure notifications. Default is to log the delivery failure.
- `HEADER_CHECKS` - If `true` activates a set of pre-configured header_checks. (options, `true`, `false`)
- `DISABLE_VRFY_COMMAND` - Prevents some email address harvesting techniques. Default `yes`. (options, `yes`, `no`)

**Rate limiting parameters:**

These are common parameters to rate limit outbound mail:

- `SMTP_DESTINATION_CONCURRENCY_LIMIT` - Number of concurrent connections per receiving domain.
- `SMTP_DESTINATION_RATE_DELAY` - Additional delay (eg `5s`) between messages to the same receiving domain.
- `SMTP_EXTRA_RECIPIENT_LIMIT` - Limit the number of recipients of each message sent to the receiving domain.

**Relay host parameters:**

- `RELAYHOST` - Postfix relay host. Default ''. (example `mail.example.com:25`, or `[email-smtp.us-west-2.amazonaws.com]:587`). N.B. Use square brackets to prevent MX lookup on relay hostname.
- `RELAYHOST_AUTH` - Enable authentication for relay host. Generally used with `RELAYHOST_PASSWORDMAP`. Default `no`. (options, `yes`, `no`).
- `RELAYHOST_PASSWORDMAP` - Relay host password map in format: `RELAYHOST_PASSWORDMAP=[mail1.example.com]:587:user1:pass1,mail2.example.com:user2:pass2,user3:pass3`.
- `RELAYHOST_MAP` - Sender dependent relayhost map in format: `RELAYHOST_MAP=@domain1.com:smtp.example.com:587,@domain2.com:[smtp.example.com]:587`
- `SENDER_DEPENDENT_RELAYHOST_AUTH` - Enable sender dependent authentication for relay host. Generally used with `RELAYHOST_MAP` and `RELAYHOST_PASSWORDMAP`. Default `no`. (options, `yes`, `no`).

**Client authentication parameters:**

Client authentication is used to authenticate relay clients. Client authentication can be used in conjunction with, or as an alternative to `MYNETWORKS`.

- `SMTPD_USERS` - SMTPD Users `user1:password1,user2:password2`

**TLS parameters:**

- `USE_TLS` - Enable TLS. Default `yes` (options, `yes`, `no`)
- `TLS_SECURITY_LEVEL` - Default `may` (opportunistic). (options, `may`, `encrypt`, others see: [www.postfix.org/postconf.5.html#smtp_tls_security_level](http://www.postfix.org/postconf.5.html#smtp_tls_security_level))
- `TLS_KEY` - Default `/etc/ssl/private/ssl-cert-snakeoil.key`
- `TLS_CRT` - Default `/etc/ssl/certs/ssl-cert-snakeoil.pem`
- `TLS_CA` - Default ''

- `CLIENT_TLS_SECURITY_LEVEL` - Default `may` same as TLS_SECURITY_LEVEL but for client TLS
- `CLIENT_TLS_KEY` - Default `/etc/ssl/private/ssl-cert-snakeoil.key`
- `CLIENT_TLS_CRT` - Default `/etc/ssl/certs/ssl-cert-snakeoil.pem`
- `CLIENT_TLS_CA` - Default ''

NB. A self-signed ("snake-oil") certificate will be generated on start if required.

**DKIM parameters:**

- `USE_DKIM` - Enable DKIM. Default `no` (options, `yes`, `no`)
- `DKIM_KEYFILE` - DKIM Keyfile location. Default `/etc/opendkim/dkim.key`
- `DKIM_DOMAINS` - Domains to sign. Defaults to `MAILNAME`. Multiple domains will use the same key and selector.
- `DKIM_SELECTOR` - DKIM key selector. Default `mail`. `<selector>._domainkey.<domain>` is used for resolving the public key in DNS.
- `DKIM_INTERNALHOSTS` - Defaults to `MYNETWORKS`.
- `DKIM_EXTERNALIGNORE` - Defaults to `MYNETWORKS`.
- `DKIM_OVERSIGN_HEADERS` - Sets OversignHeaders. Default `From`.
- `DKIM_SENDER_HEADERS` - Sets SenderHeaders. Default unset.
- `DKIM_SIGN_HEADERS` - Sets SignHeaders. Default unset.
- `DKIM_OMIT_HEADERS` - Sets OmitHeaders. Default unset.

**Advanced Postfix parameters:**

In some cases it might be necessary to further customise Postfix parameters that are not explicitly exposed via environment variables. In this case the environment variable `POSTCONF` provides a hook that is directly passed to `postconf -e` after splitting it by `;`. N.B. this is different from existing usage of other multi-value options that use a comma.

Example usage:

```
POSTCONF=masquerade_domains=foo.example.com example.com;masquerade_exceptions=root,mailer-daemon
```

Would result in `masquerade_domains` and `masquerade_exceptions` being configured for Postfix.

## Custom Scripts

Executable shell scripts and binaries can be mounted or copied in to `/etc/entrypoint.d`. These will be run when the container is launched but before postfix is started. These can be used to customise the behaviour of the container.

## Usage Example

Simple example:

`docker run -e MAILNAME=mail.example.com panubo/postfix:latest`

Usage with SendGrid:

```
docker run --rm -t -i \
  --name smtp \
  -v $(pwd)/spool:/var/spool/postfix:rw \
  -e MAILNAME=mail1.example.com \
  -e RELAYHOST_AUTH='yes' \
  -e RELAYHOST='[smtp.sendgrid.net]:587' \
  -e RELAYHOST_PASSWORDMAP="[smtp.sendgrid.net]:587:apikey:<apikey goes here>" \
  panubo/postfix:latest
```

## Volumes

No volumes are defined. If you want persistent spool storage then mount
`/var/spool/postfix` outside of the container.

## Ports

Ports `25`, `587` and `2525` are enabled.

## Test email

To send a test email via the command line, make sure heirloom-mailx (aka bsd-mailx) is installed.

```
echo -e "To: Bob <bob@example.com>\nFrom: Bill <bill@example.com>\nSubject: Test email\n\nThis is a test email message" | mailx -v -S smtp=smtp://... -S from=bill@example.com -t

# With TLS
echo -e "To: Bob <bob@example.com>\nFrom: Bill <bill@example.com>\nSubject: Test email\n\nThis is a test email message" | mailx -v -S smtp-use-starttls -S ssl-verify=ignore -S smtp=smtp://... -S from=bill@example.com -t

# With TLS on Centos/Fedora (extra nss-config-dir)
echo -e "To: Bob <bob@example.com>\nFrom: Bill <bill@example.com>\nSubject: Test email\n\nThis is a test email message" | mailx -v -S smtp-use-starttls -S ssl-verify=ignore -S nss-config-dir=/etc/pki/nssdb -S smtp=smtp://... -S from=bill@example.com -t
```

## Developing

See the `Makefile` for make targets.

## Releases

For production usage, please use a versioned release rather than the floating 'latest' tag.

See the [releases](https://github.com/panubo/docker-postfix/releases) for tag usage
and release notes.

## Status

Production ready and stable.

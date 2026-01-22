# Postfix Docker Image

![build-push](https://github.com/panubo/docker-postfix/actions/workflows/build-push.yml/badge.svg)
[![release](https://img.shields.io/github/v/release/panubo/docker-postfix)](https://github.com/panubo/docker-postfix/releases/latest)
[![license](https://img.shields.io/github/license/panubo/docker-postfix)](LICENSE)

Postfix SMTP Relay based on Debian.

Highly configurable Docker image for SMTP relaying. Use wherever a connected service
requires SMTP sending capabilities. Supports TLS out of the box and DKIM
(if enabled and configured).

Not intended to be used for receiving email for local delivery or end-user
email access.

This image is available on quay.io `quay.io/panubo/postfix` and AWS ECR Public `public.ecr.aws/panubo/postfix`.

<!-- BEGIN_TOP_PANUBO -->
> [!IMPORTANT]
> **Maintained by Panubo** — Cloud Native & SRE Consultants in Sydney.
> [Work with us →](https://panubo.com.au)
<!-- END_TOP_PANUBO -->

## Table of Contents

- [Environment Variables](#environment-variables)
- [Postfix Prometheus Exporter](#postfix-prometheus-exporter)
- [Logging](#logging)
- [Custom Scripts](#custom-scripts)
- [Usage Example](#usage-example)
- [Volumes](#volumes)
- [Ports](#ports)
- [Test email](#test-email)
- [Developing](#developing)
- [Releases](#releases)
- [Status](#status)

## Environment Variables

- `MAILNAME` - set this to a legitimate FQDN hostname for this service (required). (example, `mail.example.com`)
- `MYNETWORKS` - comma separated list of IP subnets that are allowed to relay. Default `127.0.0.0/8, 10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16`
- `LOGOUTPUT` - Log file location. e.g. `/var/log/maillog`. Default `/dev/stdout`. See [Logging](#logging)
- `TZ` - set timezone. This is used by Postfix to create `Received` headers. Default `UTC`.
- `POSTFIX_EXPORTER_ENABLED` - enable the Prometheus postfix_exporter. Default `false`. See [Postfix Exporter](#postfix-prometheus-exporter)

**General Postfix:**

- `SIZELIMIT` - Postfix `message_size_limit`. Default `15728640`.
- `POSTFIX_ADD_MISSING_HEADERS` - add missing headers. Default `no`. (options, `yes`, `no`)
- `INET_PROTOCOLS` - IP protocols, e.g. `ipv4` or `ipv6`. Default `all`. (options, `ipv4`, `ipv6`, `all`)
- `BOUNCE_ADDRESS` - Email address to receive delivery failure notifications. Default is to log the delivery failure.
- `HEADER_CHECKS` - If `true` activates a set of pre-configured header_checks. (options, `true`, `false`)
- `DISABLE_VRFY_COMMAND` - Prevents some email address harvesting techniques. Default `yes`. (options, `yes`, `no`)

**Rate limiting parameters:**

These are common parameters to rate limit outbound mail:

- `SMTP_DESTINATION_CONCURRENCY_LIMIT` - Number of concurrent connections per receiving domain.
- `SMTP_DESTINATION_RATE_DELAY` - Additional delay (e.g. `5s`) between messages to the same receiving domain.
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

In some cases it might be necessary to further customise Postfix parameters that are not explicitly exposed via environment variables. In this case the environment variable `POSTCONF` provides a hook that is directly passed to `postconf -e` after splitting it by `;`. N.B. This is different from the comma-separated format used for other multi-value options.

Example usage:

```shell
POSTCONF=masquerade_domains=foo.example.com example.com;masquerade_exceptions=root,mailer-daemon
```

Would result in `masquerade_domains` and `masquerade_exceptions` being configured for Postfix.

**Config Reloader**

The config reloader watches the known TLS certificates and keys (`TLS_CRT`, `TLS_KEY`, etc.) for changes (e.g. `mv` or an updated Kubernetes secret) and then reloads Postfix.

- `CONFIG_RELOADER_ENABLED` - Enable the config reloader. Default `false`, must be set to `true` to enable.

## Postfix Prometheus Exporter

This image comes with [kumina/postfix_exporter](https://github.com/kumina/postfix_exporter) pre-installed. To enable set the environment variable `POSTFIX_EXPORTER_ENABLED=true` (this must be exactly "true"). The exporter requires that the log output is set to `/dev/stdout`; it cannot be anything else.

The exporter listens on port `9154/tcp`.

See [Logging](#logging)

## Logging

This container outputs the Postfix mail log to stdout by default. Additionally, logs are saved to `/var/log/s6-maillog/current` which is rotated every 10MB with only 3 log files retained.

If you want to output somewhere else you can set environment variable `LOGOUTPUT`. For example `LOGOUTPUT=/var/log/maillog`.

When enabled OpenDKIM only supports syslog output, the syslogd daemon is only used for OpenDKIM. Only /dev/stdout is supported for OpenDKIM syslog logs.

_Note: the Postfix Prometheus exporter only works when logs are sent to /dev/stdout. This requirement is due to the container's logging structure. This may be improved, but was needed to maintain backwards compatibility without adding additional configuration variables._

_Note: The log `/var/log/s6-maillog/current` is always created but won't actually contain any logs if `LOGOUTPUT` is not `/dev/stdout`._

## Custom Scripts

Executable shell scripts and binaries can be mounted or copied into `/etc/entrypoint.d`. These will be run when the container is launched but before postfix is started. These can be used to customise the behaviour of the container.

## Usage Example

Simple example:

`docker run -e MAILNAME=mail.example.com quay.io/panubo/postfix:latest`

Usage with SendGrid:

```shell
docker run --rm -t -i \
  --name smtp \
  -v $(pwd)/spool:/var/spool/postfix:rw \
  -e MAILNAME=mail1.example.com \
  -e RELAYHOST_AUTH='yes' \
  -e RELAYHOST='[smtp.sendgrid.net]:587' \
  -e RELAYHOST_PASSWORDMAP="[smtp.sendgrid.net]:587:apikey:<apikey goes here>" \
  quay.io/panubo/postfix:latest
```

Usage with `docker-compose.yml`:

```yaml
services:
  postfix:
    image: quay.io/panubo/postfix:latest
    environment:
      MAILNAME: mail.example.com
      RELAYHOST: '[smtp.sendgrid.net]:587'
      RELAYHOST_AUTH: 'yes'
      RELAYHOST_PASSWORDMAP: '[smtp.sendgrid.net]:587:apikey:YOUR_API_KEY'
    ports:
      - "2525:25"
```

## Volumes

No volumes are defined. If you want persistent spool storage then mount
`/var/spool/postfix` outside of the container.

## Ports

Ports `25`, `587` and `2525` are enabled.

## Test email

To send a test email via the command line, make sure heirloom-mailx (aka bsd-mailx) is installed.

```shell
echo -e "To: Bob <bob@example.com>\nFrom: Bill <bill@example.com>\nSubject: Test email\n\nThis is a test email message" | mailx -v -S smtp=smtp://... -S from=bill@example.com -t

# With TLS
echo -e "To: Bob <bob@example.com>\nFrom: Bill <bill@example.com>\nSubject: Test email\n\nThis is a test email message" | mailx -v -S smtp-use-starttls -S ssl-verify=ignore -S smtp=smtp://... -S from=bill@example.com -t

# With TLS on CentOS/Fedora (extra nss-config-dir)
echo -e "To: Bob <bob@example.com>\nFrom: Bill <bill@example.com>\nSubject: Test email\n\nThis is a test email message" | mailx -v -S smtp-use-starttls -S ssl-verify=ignore -S nss-config-dir=/etc/pki/nssdb -S smtp=smtp://... -S from=bill@example.com -t
```

## Developing

See the `Makefile` for make targets.

To run the BATS tests, use the `make test` command. This will build a test Docker image and execute the tests within it.


## Releases

For production usage, please use a versioned release rather than the floating 'latest' tag.

See the [releases](https://github.com/panubo/docker-postfix/releases) for tag usage
and release notes.

Images are available on:

- [quay.io/panubo/postfix](https://quay.io/repository/panubo/postfix?tab=tags)
- [public.ecr.aws/panubo/postfix](https://gallery.ecr.aws/panubo/postfix)

## Status

Production ready and stable.

<!-- BEGIN_BOTTOM_PANUBO -->
> [!IMPORTANT]
> ## About Panubo
>
> This project is maintained by Panubo, a technology consultancy based in Sydney, Australia. We build reliable, scalable systems and help teams master the cloud-native ecosystem.
>
> We are available for hire to help with:
>
> * SRE & Operations: Improving system reliability and incident response.
> * Platform Engineering: Building internal developer platforms that scale.
> * Kubernetes: Cluster design, security auditing, and migrations.
> * DevOps: Streamlining CI/CD pipelines and developer experience.
> * [See our other services](https://panubo.com.au/services)
>
> Need a hand with your infrastructure? [Let’s have a chat](https://panubo.com.au/contact) or email us at team@panubo.com.
<!-- END_BOTTOM_PANUBO -->

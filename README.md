# Postfix Docker Container

Postfix SMTP Relay.

Fairly simple drop-in container for SMTP relaying. Use wherever a connected service
requires SMTP sending capabilities.

## Environment Variables

- `MAILNAME` - set this to a legitimate FQDN hostname for this service (required).
- `MYNETWORKS` - comma separated list of IP subnets that are allowed to relay. Default `127.0.0.0/8, 10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16`
- `SIZELIMIT` -  Postfix `message_size_limit`. Default `15728640`.
- `LOGOUTPUT` - Postfix log file location. eg `/var/log/maillog`. Default `/dev/stdout`.

TLS parameters:

- `USETLS` - Enable opportunistic TLS. default `yes`
- `TLSKEY` - Default `/etc/ssl/private/ssl-cert-snakeoil.key`
- `TLSCRT` - Default `/etc/ssl/certs/ssl-cert-snakeoil.pem`
- `TLSCA` - Default ''

NB. The snake-oil certificate will generated on start if required.

## Volumes

No volumes are defined. If you want persistent spool storage then mount `/var/spool/postfix` outside of the container.

## Test email

To send a test email via the command line, make sure heirloom-mailx is installed.

```
echo -e "To: Bob <bob@example.com>\nFrom: Bill <bill@example.com>\nSubject: Test email\n\nThis is a test email message" | mailx -v -S smtp=smtp://... -S from=bill@example.com -t

# With TLS
echo -e "To: Bob <bob@example.com>\nFrom: Bill <bill@example.com>\nSubject: Test email\n\nThis is a test email message" | mailx -v -S smtp-use-starttls -S ssl-verify=ignore -S smtp=smtp://... -S from=bill@example.com -t
```

## Developing

See the `Makefile` for make targets. eg To build run `make build`.

## Status

Production ready and stable.

# Postfix Docker Container

Simple Postfix SMTP Relay.

Mail logs are streamed to stdout and not stored on disk.

## Environment Variables

- `MAILNAME` - set this to a legitimate hostname for this service (required).
- `MYNETWORKS` - comma separated list of IP subnets that are allowed to relay.
- `SIZELIMIT` -  Postfix `message_size_limit`.

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

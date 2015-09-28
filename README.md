# Postfix Docker Container

Simple Postfix SMTP Relay. 

Mail logs are streamed to stdout and not stored on disk.

## Environment Variables

- `MAILNAME` - set this to a legitimate hostname for this service (required).
- `MYNETWORKS` - comma separated list of IP subnets that are allowed to relay.

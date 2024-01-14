FROM golang:1.16 as postfix_exporter

ENV \
  POSTFIX_EXPORTER_VERSION=0.3.0 \
  POSTFIX_EXPORTER_CHECKSUM=a0d45f3615d6f24b5532d4048fbb08a248588cac7587279aef1473b6e50b6157

RUN set -x \
  && wget "https://github.com/kumina/postfix_exporter/archive/refs/tags/${POSTFIX_EXPORTER_VERSION}.tar.gz" \
  && echo "${POSTFIX_EXPORTER_CHECKSUM}  ${POSTFIX_EXPORTER_VERSION}.tar.gz" > SHA256SUM \
  && ( sha256sum -c SHA256SUM || ( echo "Expected ${POSTFIX_EXPORTER_VERSION}.tar.gz: $(sha256sum ${POSTFIX_EXPORTER_VERSION}.tar.gz)"; exit 1; )) \
  && tar -zxf ${POSTFIX_EXPORTER_VERSION}.tar.gz \
  && cd postfix_exporter-${POSTFIX_EXPORTER_VERSION} \
  && go mod download \
  && go install -tags nosystemd,nodocker \
  ;

# Postfix SMTP Relay

# Debian Bookworm
FROM debian:12

EXPOSE 25 587 2525

# Preselections for installation
RUN set -x \
  && echo mail > /etc/hostname \
  && echo "postfix postfix/main_mailer_type string Internet site" >> preseed.txt \
  && echo "postfix postfix/mailname string mail.example.com" >> preseed.txt \
  && debconf-set-selections preseed.txt && rm preseed.txt \
  ;

# Install packages
RUN set -x \
  && export DEBIAN_FRONTEND=noninteractive \
  && apt-get update \
  && apt-get install -y --no-install-recommends postfix mailutils busybox-syslogd opendkim opendkim-tools libsasl2-modules sasl2-bin curl ca-certificates procps s6 \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* \
  ;

# Configure Postfix / dkim
RUN set -x \
  && postconf -e smtpd_banner="\$myhostname ESMTP" \
  && postconf -Me submission/inet="submission inet n - y - - smtpd" \
  && postconf -Me 2525/inet="2525 inet n - y - - smtpd" \
  && cp --remove-destination /usr/share/postfix/makedefs.out /etc/postfix/makedefs.out \
  && cp -a /var/spool/postfix /var/spool/postfix.cache \
  && rm -f /etc/ssl/private/ssl-cert-snakeoil.key /etc/ssl/certs/ssl-cert-snakeoil.pem \
  && rm -f /etc/opendkim.conf \
  && mkdir /etc/opendkim/ \
  ;

COPY header_checks /etc/postfix/header_checks
COPY opendkim.conf.sh /etc/
COPY --from=postfix_exporter /go/bin/postfix_exporter /usr/local/bin/postfix_exporter
COPY s6 /etc/s6/
COPY entry.sh /

RUN set -x \
  && chmod 0644 /etc/postfix/header_checks \
  ;

ENTRYPOINT ["/entry.sh"]
CMD ["/usr/bin/s6-svscan", "/etc/s6"]

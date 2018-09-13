# Postfix SMTP Relay

FROM debian:stretch

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
  && apt-get update \
  && apt-get install -y --no-install-recommends postfix mailutils busybox-syslogd opendkim opendkim-tools libsasl2-modules sasl2-bin curl ca-certificates procps \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* \
  ;

# Install s6
RUN set -x \
  && S6_VERSION=2.7.1.1 \
  && S6_CHECKSUM=42ad7f2ae6028e7321e2acef432e7b9119bab5fb8748581ca729a2f92dacf613 \
  && EXECLINE_VERSION=2.5.0.0 \
  && EXECLINE_CHECKSUM=f65fba9eaea5d10d082ac75452595958af1f9ca8d298055539597de2f7b713cd \
  && SKAWARE_RELEASE=1.21.5 \
  && curl -sSf -L https://github.com/just-containers/skaware/releases/download/v${SKAWARE_RELEASE}/s6-${S6_VERSION}-linux-amd64-bin.tar.gz -o /tmp/s6-${S6_VERSION}-linux-amd64-bin.tar.gz \
  && curl -sSf -L https://github.com/just-containers/skaware/releases/download/v${SKAWARE_RELEASE}/execline-${EXECLINE_VERSION}-linux-amd64-bin.tar.gz -o /tmp/execline-${EXECLINE_VERSION}-linux-amd64-bin.tar.gz \
  && printf "%s  %s\n" "${S6_CHECKSUM}" "s6-${S6_VERSION}-linux-amd64-bin.tar.gz" "${EXECLINE_CHECKSUM}" "execline-${EXECLINE_VERSION}-linux-amd64-bin.tar.gz" > /tmp/SHA256SUM \
  && ( cd /tmp; sha256sum -c SHA256SUM; ) \
  && tar -C /usr -zxf /tmp/s6-${S6_VERSION}-linux-amd64-bin.tar.gz \
  && tar -C /usr -zxf /tmp/execline-${EXECLINE_VERSION}-linux-amd64-bin.tar.gz \
  && rm -rf /tmp/* \
  ;

# Configure Postfix / dkim
RUN set -x \
  && postconf -e smtpd_banner="\$myhostname ESMTP" \
  && postconf -Me submission/inet="submission inet n - y - - smtpd" \
  && postconf -Me 2525/inet="2525 inet n - y - - smtpd" \
  && cp -a /var/spool/postfix /var/spool/postfix.cache \
  && rm -f /etc/ssl/private/ssl-cert-snakeoil.key /etc/ssl/certs/ssl-cert-snakeoil.pem \
  && rm -f /etc/opendkim.conf \
  && mkdir /etc/opendkim/ \
  ;

COPY header_checks /etc/postfix/header_checks
COPY opendkim.conf.sh /etc/

COPY s6 /etc/s6/
COPY entry.sh /

ENTRYPOINT ["/entry.sh"]
CMD ["/usr/bin/s6-svscan", "/etc/s6"]

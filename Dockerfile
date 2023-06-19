# Postfix SMTP Relay

FROM debian:bullseye

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
  && apt-get install -y --no-install-recommends postfix mailutils busybox-syslogd opendkim opendkim-tools libsasl2-modules sasl2-bin curl ca-certificates procps \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* \
  ;

# Install s6
RUN set -x \
  && S6_VERSION=2.11.0.0 \
  && EXECLINE_VERSION=2.8.1.0 \
  && SKAWARE_RELEASE=2.0.7 \
  && S6_CHECKSUM_X86_64=fcf79204c1957016fc88b0ad7d98f150071483583552103d5822cbf56824cc87 \
  && S6_CHECKSUM_AARCH64=64151e136f887c6c2c7df69e3100573c318ec7400296680cc698bc7b0ca36943 \
  && EXECLINE_CHECKSUM_X86_64=b216cfc4db928729d950df5a354aa34bc529e8250b55ab0de700193693dea682 \
  && EXECLINE_CHECKSUM_AARCH64=8cb1d5c2d44cb94990d63023db48f7d3cd71ead10cbb19c05b99dbd528af5748 \
  && if [ "$(uname -m)" = "x86_64" ] ; then \
        S6_CHECKSUM="${S6_CHECKSUM_X86_64}"; \
        EXECLINE_CHECKSUM="${EXECLINE_CHECKSUM_X86_64}"; \
        SKAWARE_ARCH="amd64"; \
      elif [ "$(uname -m)" = "aarch64" ]; then \
        S6_CHECKSUM="${S6_CHECKSUM_AARCH64}"; \
        EXECLINE_CHECKSUM="${EXECLINE_CHECKSUM_AARCH64}"; \
        SKAWARE_ARCH="aarch64"; \
      fi \
  && curl -sSf -L -o /tmp/s6-${S6_VERSION}-linux-${SKAWARE_ARCH}-bin.tar.gz https://github.com/just-containers/skaware/releases/download/v${SKAWARE_RELEASE}/s6-${S6_VERSION}-linux-${SKAWARE_ARCH}-bin.tar.gz \
  && curl -sSf -L -o /tmp/execline-${EXECLINE_VERSION}-linux-${SKAWARE_ARCH}-bin.tar.gz https://github.com/just-containers/skaware/releases/download/v${SKAWARE_RELEASE}/execline-${EXECLINE_VERSION}-linux-${SKAWARE_ARCH}-bin.tar.gz \
  && echo "${S6_CHECKSUM}  s6-${S6_VERSION}-linux-${SKAWARE_ARCH}-bin.tar.gz" > /tmp/SHA256SUM \
  && echo "${EXECLINE_CHECKSUM}  execline-${EXECLINE_VERSION}-linux-${SKAWARE_ARCH}-bin.tar.gz" >> /tmp/SHA256SUM \
  && ( cd /tmp; sha256sum -c SHA256SUM || ( echo "Expected S6: $(sha256sum s6-${S6_VERSION}-linux-${SKAWARE_ARCH}-bin.tar.gz) Execline: $(sha256sum execline-${EXECLINE_VERSION}-linux-${SKAWARE_ARCH}-bin.tar.gz)"; exit 1; )) \
  && tar -C /usr -zxf /tmp/s6-${S6_VERSION}-linux-${SKAWARE_ARCH}-bin.tar.gz \
  && tar -C /usr -zxf /tmp/execline-${EXECLINE_VERSION}-linux-${SKAWARE_ARCH}-bin.tar.gz \
  && rm -rf /tmp/* \
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

COPY s6 /etc/s6/
COPY entry.sh /

ENTRYPOINT ["/entry.sh"]
CMD ["/usr/bin/s6-svscan", "/etc/s6"]

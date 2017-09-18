# Postfix SMTP Relay

FROM debian:jessie
MAINTAINER Andrew Cutler <andrew@panubo.io>

ENV S6_RELEASE=1.20.0 S6_VERSION=2.5.1.0 S6_SHA1=b798972cbf46e28f1c5d238f6703aba6edded57e

EXPOSE 25 587

# Preselections for installation
RUN echo mail > /etc/hostname; \
    echo "postfix postfix/main_mailer_type string Internet site" >> preseed.txt; \
    echo "postfix postfix/mailname string mail.example.com" >> preseed.txt; \
    debconf-set-selections preseed.txt && rm preseed.txt

# Install packages
RUN apt-get update && \
    apt-get install -y --no-install-recommends postfix mailutils busybox-syslogd opendkim opendkim-tools curl ca-certificates && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install s6
RUN DIR=$(mktemp -d) && cd ${DIR} && \
    curl -s -L https://github.com/just-containers/skaware/releases/download/v${S6_RELEASE}/s6-${S6_VERSION}-linux-amd64-bin.tar.gz -o s6.tar.gz && \
    echo "${S6_SHA1} s6.tar.gz" | sha1sum -c - && \
    tar -xzf s6.tar.gz -C /usr/local/ && \
    rm -rf ${DIR}

# Configure Postfix / dkim
RUN postconf -e smtpd_banner="\$myhostname ESMTP" && \
    # Enable submission
    postconf -Me submission/inet="submission inet n - - - - smtpd" && \
    # Cache spool dir as template
    cp -a /var/spool/postfix /var/spool/postfix.cache && \
    # Remove snakeoil certs
    rm -f /etc/ssl/private/ssl-cert-snakeoil.key /etc/ssl/certs/ssl-cert-snakeoil.pem && \
    rm -f /etc/opendkim.conf && \
    mkdir /etc/opendkim/

COPY header_checks /etc/postfix/header_checks
COPY opendkim.conf.sh /etc/

COPY s6 /etc/s6/
COPY entry.sh /

ENTRYPOINT ["/entry.sh"]
CMD ["/usr/local/bin/s6-svscan", "/etc/s6"]

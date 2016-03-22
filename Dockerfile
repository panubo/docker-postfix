# Postfix SMTP Relay

FROM debian:latest
MAINTAINER Andrew Cutler <andrew@panubo.io>

EXPOSE 25 587

VOLUME ["/var/spool/mail/"]

# Preselections for installation 
RUN echo mail > /etc/hostname; \
    echo "postfix postfix/main_mailer_type string Internet site" >> preseed.txt; \
    echo "postfix postfix/mailname string mail.example.com" >> preseed.txt; \
    debconf-set-selections preseed.txt && rm preseed.txt

# Install packages
RUN apt-get update && \
    apt-get install -y --no-install-recommends postfix mailutils rsyslog curl ca-certificates && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install s6
RUN curl -L https://github.com/just-containers/skaware/releases/download/v1.17.0/s6-2.2.4.0-linux-amd64-bin.tar.gz | tar -C / -zxf -

# Configure
RUN postconf -e smtpd_banner="\$myhostname ESMTP" && \
    postconf -e mail_spool_directory="/var/spool/mail/" && \
    postconf -e mailbox_command="" && \
    # Enable submission 
    postconf -Me submission/inet="submission inet n - - - - smtpd" && \
    # Configure Rsyslog: Disable mail logs
    sed -i -e 's@^mail.*@@g' /etc/rsyslog.conf && \
    # Cache spool dir as template
    cp -a /var/spool/postfix /var/spool/postfix.cache

COPY rsyslogd.conf /etc/rsyslog.d/
COPY s6 /etc/s6/

CMD ["/bin/s6-svscan","/etc/s6"]

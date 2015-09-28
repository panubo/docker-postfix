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
    apt-get install -y --no-install-recommends postfix mailutils rsyslog supervisor && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Configure
RUN postconf -e smtpd_banner="\$myhostname ESMTP" && \
    postconf -e mail_spool_directory="/var/spool/mail/" && \
    postconf -e mailbox_command="" && \
    # Configure Rsyslog: Disable mail logs
    sed -i -e 's@^mail.*@@g' /etc/rsyslog.conf

ADD rsyslogd.conf /etc/rsyslog.d/
ADD supervisord.conf /etc/supervisor/supervisord.conf
ADD *.sh /

ENTRYPOINT ["/entry.sh"]
CMD ["supervisord", "-n", "-c", "/etc/supervisor/supervisord.conf"]

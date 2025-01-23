#!/bin/bash

if [ "$MTA_ROLE" == "mailpit" ]
then BINDIP=$(ip addr | grep eth0 | grep inet | awk '{print $2}' | cut -d '/' -f 1)
     /mailpit.bin -s $BINDIP:25 --webroot mailpit

elif [ "$MTA_ROLE" == "postfix" ]
then echo "[$POSTFIX_RELAYHOST_FQDN]:$POSTFIX_RELAYHOST_PORT $POSTFIX_RELAYHOST_USERNAME:$POSTFIX_RELAYHOST_PASSWORD" > /etc/postfix/sasl_passwd
     cd /etc/postfix
     postmap sasl_passwd

     # Needed to make name resolution work for Postfix
     cp /etc/resolv.conf /var/spool/postfix/etc/resolv.conf

     # Update configuration values

     if [ "$POSTFIX_RELAYHOST_AUTH_ENABLED" == "yes" ]
     then export POSTFIX_SMTP_SASL_SECURITY_OPTIONS=noanonymous
          export POSTFIX_SMTP_SASL_TLS_SECURITY_OPTIONS=noanonymous
     else export POSTFIX_SMTP_SASL_SECURITY_OPTIONS=""
	  export POSTFIX_SMTP_SASL_TLS_SECURITY_OPTIONS=""
     fi

     perl -pi.bak -e '$postfix_relayhost_fqdn=$ENV{POSTFIX_RELAYHOST_FQDN}; s/INSERT_POSTFIX_RELAYHOST_FQDN/"$postfix_relayhost_fqdn"/ge' \
                 /etc/postfix/main.cf
     perl -pi.bak -e '$postfix_relayhost_port=$ENV{POSTFIX_RELAYHOST_PORT}; s/INSERT_POSTFIX_RELAYHOST_PORT/"$postfix_relayhost_port"/ge' \
                 /etc/postfix/main.cf
     perl -pi.bak -e '$postfix_relayhost_username=$ENV{POSTFIX_RELAYHOST_USERNAME}; s/INSERT_POSTFIX_RELAYHOST_USERNAME/"$postfix_relayhost_username"/ge' \
                 /etc/postfix/main.cf
     perl -pi.bak -e '$postfix_relayhost_password=$ENV{POSTFIX_RELAYHOST_PASSWORD}; s/INSERT_POSTFIX_RELAYHOST_PASSWORD/"$postfix_relayhost_password"/ge' \
                 /etc/postfix/main.cf
     perl -pi.bak -e '$postfix_relayhost_auth_enabled=$ENV{POSTFIX_RELAYHOST_AUTH_ENABLED}; s/INSERT_POSTFIX_RELAYHOST_AUTH_ENABLED/"$postfix_relayhost_auth_enabled"/ge' \
                 /etc/postfix/main.cf
     perl -pi.bak -e '$postfix_relayhost_tls_enabled=$ENV{POSTFIX_RELAYHOST_TLS_ENABLED}; s/INSERT_POSTFIX_RELAYHOST_TLS_ENABLED/"$postfix_relayhost_tls_enabled"/ge' \
                 /etc/postfix/main.cf

     perl -pi.bak -e '$postfix_myhostname=$ENV{POSTFIX_MYHOSTNAME}; s/INSERT_POSTFIX_MYHOSTNAME/"$postfix_myhostname"/ge' \
                 /etc/postfix/main.cf
     perl -pi.bak -e '$postfix_origin=$ENV{POSTFIX_ORIGIN}; s/INSERT_POSTFIX_ORIGIN/"$postfix_origin"/ge' \
                 /etc/postfix/main.cf

     perl -pi.bak -e '$postfix_smtp_sasl_security_options=$ENV{POSTFIX_SMTP_SASL_SECURITY_OPTIONS}; s/INSERT_POSTFIX_SMTP_SASL_SECURITY_OPTIONS/"$postfix_smtp_sasl_security_options"/ge' \
                 /etc/postfix/main.cf
     perl -pi.bak -e '$postfix_smtp_sasl_tls_security_options=$ENV{POSTFIX_SMTP_SASL_TLS_SECURITY_OPTIONS}; s/INSERT_POSTFIX_SMTP_SASL_TLS_SECURITY_OPTIONS/"$postfix_smtp_sasl_tls_security_options"/ge' \
                 /etc/postfix/main.cf

     /usr/sbin/postfix start-fg

else
     echo "Unknown MTA role: $MTA_ROLE."
     sleep 300
fi

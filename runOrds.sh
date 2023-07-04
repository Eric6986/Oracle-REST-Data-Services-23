#!/bin/bash

cd /etc/ords/config
echo -e "$ORACLE_PWD\n$ORDS_PWD" > ora_password.txt
echo -e "$ORDS_PWD\n$ORDS_PWD" > ords_password.txt
ords --config /etc/ords/config config set standalone.http.port $ORDS_HTTP_PORT
ords --config /etc/ords/config config set mongo.enabled true
ords --config /etc/ords/config config set security.verifySSL true
ords --config /etc/ords/config config set standalone.https.port $ORDS_HTTPS_PORT
ords --config /etc/ords/config config set standalone.https.cert $ORDS_CERT
ords --config /etc/ords/config config set standalone.https.cert.key $ORDS_CERT_KEY
ords --config /etc/ords/config config secret db.password < ords_password.txt
sleep 10
ords --config /etc/ords/config install --admin-user $ORACLE_ADMIN_USER --db-hostname $ORACLE_HOST --db-port $ORACLE_PORT --db-servicename $ORACLE_SERVICE --db-user $ORDS_USER --feature-rest-enabled-sql true --feature-sdw true --password-stdin < ora_password.txt
if [ "$ORDS_INITIAL" != "Yes" ]; then
  sleep 10
  ords --config /etc/ords/config serve
fi

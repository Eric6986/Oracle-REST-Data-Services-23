#!/bin/bash

# Transfer the cert-manager generated tls to der format.
openssl x509 -inform PEM -in $ORDS_CERT -out $ORDS_CONFIG/tls.der -outform DER
openssl pkcs8 -topk8 -inform PEM -outform DER -in $ORDS_CERT_KEY -out $ORDS_CONFIG/tls-key.der -nocrypt

cd $ORDS_CONFIG
echo -e "$ORACLE_PWD\n$ORDS_PWD" > ora_password.txt
echo -e "$ORDS_PWD\n$ORDS_PWD" > ords_password.txt
ords --config $ORDS_CONFIG config set standalone.http.port $ORDS_HTTP_PORT
ords --config $ORDS_CONFIG config set mongo.enabled true
ords --config $ORDS_CONFIG config set security.verifySSL true
ords --config $ORDS_CONFIG config set standalone.https.port $ORDS_HTTPS_PORT
ords --config $ORDS_CONFIG config set standalone.https.cert $ORDS_CONFIG/tls.der
ords --config $ORDS_CONFIG config set standalone.https.cert.key $ORDS_CONFIG/tls-key.der
ords --config $ORDS_CONFIG config secret db.password < ords_password.txt
sleep 10
ords --config $ORDS_CONFIG install --admin-user $ORACLE_ADMIN_USER --db-hostname $ORACLE_HOST --db-port $ORACLE_PORT --db-servicename $ORACLE_SERVICE --db-user $ORDS_USER --feature-rest-enabled-sql true --feature-sdw true --password-stdin < ora_password.txt
if [ "$ORDS_INITIAL" != "Yes" ]; then
  sleep 10
  ords --config $ORDS_CONFIG serve
fi

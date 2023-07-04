# Oracle-REST-Data-Services-23
# For MongoDB compatible API on oracle 23c testing on kubernetes, you can use the Dockerfile to build your latest version 23 Oracle-REST-Data-Services image. 

### STEP 1
### Deploy your first oracle 23c container database on kubernetes.
```
kubectl create ns oracle23c
kubectl apply -f oracle23c-deployment.yml -n oracle23c
```

`oracle23c-deployment.yml`
Note: If you want to change the default user [SYS] passowrd, please modify the env in deployment yaml.
```
...
        env:
          - name: ORACLE_PASSWORD
            value: 'abc123'   <---- Change it!
...
```
Now, we created the testing oracle 23c database in our kubernetes already. 

### STEP 2
### Generate your self-signed certificate for ords before you deploy it to kubernetes.
```
# Create a self-signed certificate in a JKS keystore.
$JAVA_HOME/bin/keytool -genkey -keyalg RSA -alias selfsigned -keystore keystore.jks -dname "CN=oracleords-service.oracle23c.svc.cluster.local, OU=Testing Department, O=Testing Company, L=Birmingham, ST=West Midlands, C=GB" -storepass password1 -validity 3600 -keysize 2048 -keypass password1

# Create a PKCS12 keystore from the JKS keystore.
$JAVA_HOME/bin/keytool -importkeystore -srckeystore keystore.jks -srcalias selfsigned -srcstorepass password1 -destkeystore keystore.p12 -deststoretype PKCS12 -deststorepass password1 -destkeypass password1 

# Extract the key and certificate in PEM format.
openssl pkcs12 -in keystore.p12 -nodes -nocerts -out test-key.pem -passin pass:password1
openssl pkcs12 -in keystore.p12 -nokeys -out test.pem -passin pass:password1

# Convert them to DER format.
openssl pkcs8 -topk8 -inform PEM -outform DER -in test-key.pem -out test-key.der -nocrypt
openssl x509 -inform PEM -outform DER -in test.pem -out test.der
```

Note: Since we are use the kubernetes DNS to apply the SSL on our ords service hostname, so you can following the default kubernetes DNS with a name of the form `my-svc.my-namespace.svc.cluster.local`. In here, we use the default DNS name as `oracleords-service.oracle23c.svc.cluster.local`. Please refer the detail from https://kubernetes.io/docs/concepts/services-networking/dns-pod-service/

### STEP 3
### Use docker build command to build the image.

```
docker build --platform linux/amd64 -t oracleords:latest -f Dockerfile .
docker push oracleords:latest  --> Use your container registry
```

--platform: If you are using the mac platform docker, you can use the command "linux/amd64" to build the amd64 image.


kubectl create secret docker-registry docker-registry --docker-server=sin.ocir.io --docker-username=***REMOVED***/oracleidentitycloudservice/***REMOVED*** --docker-password='***REMOVED***' --docker-email=***REMOVED*** -n oracle23c

### STEP 4
### After push the image to your container registry, you need to modify the ENV parameter in the ords.yml

```
...
       env:
        - name: ORACLE_ADMIN_USER
          value: "SYS"
        - name: ORACLE_SERVICE
          value: "freepdb1"
        - name: ORACLE_HOST
          value: "oracle23c-service.oracle23c.svc.cluster.local"
        - name: ORACLE_PORT
          value: "1521"
        - name: ORDS_USER
          value: "ORDS_PUBLIC_USER"
        - name: ORDS_PWD
          value: "abc123"
        - name: ORACLE_PWD
          value: "abc123"
        - name: ORDS_HTTPS_PORT
          value: "8443"
        - name: ORDS_HTTP_PORT
          value: "8080"
        - name: ORDS_CERT
          value: "/etc/ords/keystore/test.der"
        - name: ORDS_CERT_KEY
          value: "/etc/ords/keystore/test-key.der"
...
```

Parameter description:

--platform: If you are using the mac platform docker, you can use the command "linux/amd64" to build the amd64 image.

`ORACLE_ADMIN_USER_ARG`: When you create the oracle database 23c testing database container from docker hub, the default admin USER is 'SYS'. Keep default if you don't change.

`ORACLE_SERVICE_ARG`: The default pdb name in testing oracle 23c database.

`ORACLE_HOST_ARG`: The default oracle host name in testing oracle 23c database. Since we will deploy the image in kubernetes, so we use the kubernetes default DNS name as our oracle host name. It with a name of the form `my-svc.my-namespace.svc.cluster.local`. 

`ORACLE_PORT_ARG`: The default database port in testing oracle 23c database.

`ORDS_USER_ARG`: The default ords username.

`ORDS_PWD_ARG`: When the script setup the ords, we need to give a password for ords user to use the database.

`ORACLE_PWD_ARG`: The default database user SYS password.

`ORDS_HTTPS_PORT_ARG`: The ords default https port.

`ORDS_HTTP_PORT_ARG`: The ords default http port.

`ORDS_CERT_ARG`: Your self-signed SSL certificate. The file is der format. ec: {Your local certificate path}/test.der. We need to create the secret value for the mount volume later.

`ORDS_CERT_KEY_ARG`: Your self-signed SSL certificate key. The file is der format. ec: {Your local certificate path}/test-key.der. We need to create the secret value for the mount volume later.


### STEP 5
### Create your certificate secret in your deploy namespaces and mount the secret volume.
```
kubectl create secret generic ords-config-cert --from-file=./test.der -n oracle23c
kubectl create secret generic ords-config-cert-key --from-file=./test-key.der -n oracle23c
```

### STEP 6
### Deploy the ords service to kubernetes.

```
kubectl apply -f ords-deployment.yml -n oracle23c
helm install oracleords . -n oracle23c --create-namespace oracle23c
```




### STEP 7
### 

sqlplus SYS/abc123@freepdb1 as SYSDBA @service.sql 'MONGO_TEST' 'MyPassword1!'
sqlplus 'mongo_test/MyPassword1!'@freepdb1 @service2.sql



### STEP 8
### 
kubectl port-forward service/oracleords-service -n oracle23c 27017:27017

You can use the mongo client tool (ex: mongosh) try to access the testing ords mongodb database.
```
mongosh --tls --tlsCAFile "test.pem" "mongodb://mongo_test:MyPassword1\!@oracleords-service.oracle23c.svc.cluster.local:27017/mongo_test?authMechanism=PLAIN&ssl=true&retryWrites=false&loadBalanced=true"
```


# Certificate

## Convert certificat to pkcs12

Firefox need to import the certificate in pkcs12

```
sops -d --extract '["wildcard-domain.key.pem"]' hosts/secrets.yml > /tmp/wildcard-domain.crt.key 
openssl pkcs12 -export -inkey /tmp/wildcard-domain.crt.key -in hosts/wildcard-domain.crt.pem -name localdomain -out /tmp/localdomain.pfx
rm /tmp/wildcard-domain.crt.key
```


@echo off

echo Enter password for cert
set /p SERVER_PASSWORD=

openssl genrsa -des3 -passout pass:%SERVER_PASSWORD% -out server.pass.key 2048
openssl rsa -passin pass:%SERVER_PASSWORD% -in server.pass.key -out server.key
openssl req -new -key server.key -out server.csr
openssl x509 -req -sha256 -days 365 -in server.csr -signkey server.key -out server.crt
openssl enc -aes-256-cbc -k %SERVER_PASSWORD% -P -md sha1 -nosalt  

pause 

echo Enter KEY
set /p ENCRYPTION_KEY=

echo Enter IV
set /p ENCRYPTION_IV=

openssl enc -nosalt -aes-256-cbc -in server.key -out server.key.enc -base64 -K %ENCRYPTION_KEY% -iv %ENCRYPTION_IV% -md md5

del server.csr
del server.pass.key
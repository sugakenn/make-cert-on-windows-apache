REM openssl.exe path
SET OPENSSL=c:\Apache24\bin\openssl.exe

REM certs files folder
SET ROOTDIR=c:\Apache24\certs

REM apache server's domain or ip address
SET IPADDRESS=localhost

REM if use domain then "DNS" else "IP"
SET TYPE=DNS

REM CA and server's secret
SET PASSWORD_CA=debug
SET PASSWORD_SV=%PASSWORD_CA%

REM make cert dir
if not exist %ROOTDIR% mkdir %ROOTDIR%

REM make ca cert
%OPENSSL% genrsa -aes256 -out %ROOTDIR%\ca.key 2048 -passin pass:%PASSWORD_CA%

REM move to work folder
cd /d %ROOTDIR%

REM clear ca serial
if exist ca.srl del ca.srl

REM make ca private key
echo %PASSWORD_CA%
%OPENSSL% genrsa -aes256 -out ca.key -passout pass:%PASSWORD_CA% 2048

REM make ca csr
%OPENSSL% req -subj "/C=JP/ST=Tokyo/O=MyCom/CN=MyCA" -new -key ca.key -out ca.csr -passin pass:%PASSWORD_CA%

REM ca self sign
%OPENSSL% x509 -req -in ca.csr -signkey ca.key -days 730 -out ca.crt -passin pass:%PASSWORD_CA%

REM file for v3 option
echo basicConstraints=CA:FALSE>option.v3
echo subjectKeyIdentifier=hash>>option.v3
echo authorityKeyIdentifier=keyid,issuer>>option.v3
echo keyUsage= nonRepudiation, digitalSignature, keyEncipherment>>option.v3
echo subjectAltName=%TYPE%:%IPADDRESS%>>option.v3

REM make apche server's private key
%OPENSSL% genrsa -aes256 -out server.key -passout pass:%PASSWORD_SV% 2048

REM make apache server's csr
%OPENSSL% req -subj "/C=JP/ST=Tokyo/O=MyCom/CN=%IPADDRESS%" -new -key server.key -out server.csr -passin pass:%PASSWORD_SV%

REM sign csr
%OPENSSL% x509 -req -in server.csr -CA ca.crt -CAkey ca.key -days 730 -out server.crt -passin pass:%PASSWORD_SV% -extfile option.v3 -CAcreateserial

REM remove secret apace server's private key 
%OPENSSL% rsa -in server.key -out server.key -passin pass:%PASSWORD_SV%

REM delete files for security reason
DEL ca.key ca.csr ca.srl option.v3 server.csr

REM openssl.exeの場所
SET OPENSSL=c:\Apache24\bin\openssl.exe

REM 証明書用データの出力場所
SET ROOTDIR=c:\Apache24\certs

REM サーバーのドメインまたはIPアドレス
SET IPADDRESS=localhost

REM ドメインの場合はDNS IPアドレスの場合はIP
SET TYPE=DNS

REM CA サーバー用の秘密鍵のパスワード
SET PASSWORD_CA=debug
SET PASSWORD_SV=%PASSWORD_CA%

REM 証明書用データフォルダ作成
if not exist %ROOTDIR% mkdir %ROOTDIR%

REM CA用の証明書作成
%OPENSSL% genrsa -aes256 -out %ROOTDIR%\ca.key 2048 -passin pass:%PASSWORD_CA%

REM 作業フォルダに移動
cd /d %ROOTDIR%

REM CAのシリアルクリア
if exist ca.srl del ca.srl

REM CA用の秘密鍵作成
echo %PASSWORD_CA%
%OPENSSL% genrsa -aes256 -out ca.key -passout pass:%PASSWORD_CA% 2048

REM CA用の署名要求を作成
%OPENSSL% req -subj "/C=JP/ST=Tokyo/O=MyCom/CN=MyCA" -new -key ca.key -out ca.csr -passin pass:%PASSWORD_CA%

REM 自己署名
%OPENSSL% x509 -req -in ca.csr -signkey ca.key -days 730 -out ca.crt -passin pass:%PASSWORD_CA%

REM 証明書V3オプション作成
echo basicConstraints=CA:FALSE>option.v3
echo subjectKeyIdentifier=hash>>option.v3
echo authorityKeyIdentifier=keyid,issuer>>option.v3
echo keyUsage= nonRepudiation, digitalSignature, keyEncipherment>>option.v3
echo subjectAltName=%TYPE%:%IPADDRESS%>>option.v3

REM サーバーの秘密鍵作成
%OPENSSL% genrsa -aes256 -out server.key -passout pass:%PASSWORD_SV% 2048

REM サーバー用の署名要求
%OPENSSL% req -subj "/C=JP/ST=Tokyo/O=MyCom/CN=%IPADDRESS%" -new -key server.key -out server.csr -passin pass:%PASSWORD_SV%

REM サーバー用の署名要求を署名
%OPENSSL% x509 -req -in server.csr -CA ca.crt -CAkey ca.key -days 730 -out server.crt -passin pass:%PASSWORD_SV% -extfile option.v3 -CAcreateserial

REM サーバーの秘密鍵はパスワード解除
%OPENSSL% rsa -in server.key -out server.key -passin pass:%PASSWORD_SV%

REM ワークファイルの削除、仮の証明書を作るCAなのでCAの秘密鍵も削除しています
DEL ca.key ca.csr ca.srl option.v3 server.csr

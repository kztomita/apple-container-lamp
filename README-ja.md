# 概要

Apple ContainerでNginx, PHP-FPM, MySQLのLAMP構成を作成するサンプルスクリプト。

Apple Containerにはまだcomposeがないため、シェルスクリプトでリソースやコンテナをまとめて作成できるようにした。

# 前提条件

<a href="https://github.com/apple/container">Apple Container</a>はインストールしてサービスが起動済みであるとする。

使用した Containerのバージョンはv0.4.1。

```
% container --version
container CLI version 0.4.1 (build: release, commit: 4ac18b5)
```

# 準備

ホスト名でコンテナ間の通信を行うために、DNSドメインを作成しデフォルト設定しておく必要がある。名前はなんでもいいが、以下では"box"とする。

```
% sudo container system dns create box
% container system dns default set box
```

これで起動する各コンテナのホスト名は "<コンテナ名>.box" となり、このホスト名でコンテナにアクセスできるようになる。ドメイン名(.box)を省略して"<コンテナ名>"でアクセスすることもできる。

# 起動方法
```
% ./app.sh create
```
これで、MySQLコンテナ用のボリュームを作成する。

```
% ./app.sh build
```

イメージのビルドを行う。
ここでは、PHP-FPMコンテナのイメージをビルドする。

```
% ./app.sh run
```

コンテナを起動する。
Nginx, PHP-FPM, MySQLの３つのコンテナが起動する。

```
% container ls
ID          IMAGE                                               OS     ARCH   STATE    ADDR
buildkit    ghcr.io/apple/container-builder-shim/builder:0.6.0  linux  arm64  running  192.168.64.23
lamp-nginx  docker.io/library/nginx:latest                      linux  arm64  running  192.168.64.182
lamp-mysql  docker.io/library/mysql:latest                      linux  arm64  running  192.168.64.183
lamp-php    lamp-php:latest                                     linux  arm64  running  192.168.64.181
```

# コンテナへのアクセス
```
% curl http://localhost:8080
This is index.html.
```
のようにアクセスできる。

```
curl http://lamp-nginx.box/
```
のようにホスト名を使ってコンテナに直接アクセスすることもできる。

PHPスクリプトの動作確認。
```
curl http://localhost:8080/test.php
```

DBへの接続確認。
```
curl http://localhost:8080/db.php
```

# その他のコマンド

## コンテナの停止
```
% ./app.sh stop
```
Nginx, PHP-FPM, MySQLの3つのコンテナをcontainer stopする。

## コンテナの開始
```
% ./app.sh start
```

3つのコンテナをcontainer startする。

Nginxのconfig(nginx-container/conf.d/default.conf)を修正した場合は
```
% ./app.sh stop
% ./app.sh start
```
で反映される。

## コンテナの削除
```
% ./app.sh cleanup_container
```

ボリューム等のリソースは削除しない。

container run時の引数を変更したい場合は、app.shのrun()関数を修正後、
```
% ./app.sh cleanup_container
% ./app.sh run
```
でコンテナを作り直せばよい。

## 後片付け

```
% ./app.sh cleanup
```

作成したコンテナやリソースをまとめて削除する。

- ３つのコンテナを停止して削除
- ./app.sh buildでbuildしたイメージを削除
- ./app.sh createで作成したボリュームを削除

# ディレクトリ構成

**./html**

DocumentRootとなるVolume。<br />
NginxとPHP-FPMのコンテナからbind mountする。

**./nginx-container/conf.d**

Nginxコンテナの/etc/nginx/conf.dにbindする。<br />
Nginxの設定ファイルを配置する。

**./php-container/Dockerfile**

PHP-FPMコンテナのイメージをビルドするためのDockerfile。<br />
./app.sh build でビルドする。

**./php-container/php.ini**

PHPの設定ファイルを配置する。<br />
イメージビルド時にphp.iniをイメージ内にコピーする。

**./php-container/docker-php-ext-xdebug.ini**

xdebugを使う場合はこのファイルをイメージ内にコピーする。<br />
コンテナのネットワーク設定によってはxdebug.client_hostの調整が必要な場合がある。

**./mysql-container/docker-entrypoint-initdb.d/init.sql**

MySQLコンテナのDB初期化用SQL。

# 概要
このドキュメントでは、ハンズオン課題の`Sprint1：AWS基本サービス`で必要とされるWebサーバの設定方法について説明します。

# 前提条件
- Webサーバとして使用するEC2インスタンスにSSHでログイン済みであること。

# 手順
## 1. システムの更新
システムを最新の状態に保つため、以下のコマンドでyumパッケージを更新します。
```shell
sudo yum update -y
```

## 2. Gitのインストール
EC2インスタンスにソースコードをダウンロードするため、Gitをインストールします。
```shell
sudo yum install -y git
```

## 3. nginxのインストール
WebサーバとしてNginxをインストールし、起動します。
```shell
sudo yum install -y nginx
sudo systemctl start nginx
sudo systemctl enable nginx
```

## 4. 動作確認
ブラウザで `http://[web-serverのパブリックIPアドレス]` を開き、`Welcome to nginx!` のページが表示されることを確認します。

## 5. ソースコードの配置
Gitを使用してソースコードを以下のディレクトリにクローンします。
```shell
cd /usr/share/nginx/html/
sudo git clone https://github.com/CloudTechOrg/cloudtech-reservation-web.git
```

## 6. Nginxのデフォルト設定の変更
Nginxの設定ファイルを編集し、表示するWebページのディレクトリを変更します。
```shell
sudo vi /etc/nginx/nginx.conf
```
- 変更前の設定：`root /usr/share/nginx/html;`
- 変更後の設定：`root /usr/share/nginx/html/cloudtech-reservation-web;`

設定を変更した後、Nginxを再起動して変更を適用します。
```shell
sudo systemctl restart nginx
```

## 7. API接続先の設定
WebアプリケーションからAPIを呼び出すための設定ファイル `config.js` を編集します。
```shell
sudo vi /usr/share/nginx/html/cloudtech-reservation-web/config.js
```
baseURLの設定を、APIサーバのパブリックIPアドレスに設定値を変更します。
```javascript
const apiConfig = {
  baseURL: 'http://[API-serverのパブリックIPアドレス]'
};
```

# 動作確認
以下のURLでWebアプリケーションが正しく起動していることを確認します。
`http://[web-serverのパブリックIPアドレス]`

# 概要
このドキュメントでは、ハンズオン課題の`Sprint3：冗長化構成`で必要とされる、WebサーバからAPIサーバに向けての接続設定の変更方法を説明します。

# 前提条件
- Webサーバとして使用するEC2インスタンスにSSHでログイン済みであること。

# 手順
## 7. API接続先の設定
WebアプリケーションからAPIを呼び出すための設定ファイル `config.js` を編集します。
```shell
sudo vi /usr/share/nginx/html/cloudtech-reservation-web/config.js
```
baseURLの設定を、ALBのDNS名に変更します。
```javascript
const apiConfig = {
  baseURL: 'http://[ALBのDNS名]'
};
```

# 動作確認
Webサイトをブラウザで起動し、`API Test`ボタンが正しく起動されることを確認する

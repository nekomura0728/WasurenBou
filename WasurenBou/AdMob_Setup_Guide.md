# AdMob Setup Guide for WasurenBou

## 対応状況
✅ **完了** - 2025年8月12日

## 実施内容

### 1. app-ads.txtファイルの作成
以下の内容でapp-ads.txtファイルを作成済み：
```
google.com, pub-4187811193514537, DIRECT, f08c47fec0942fa0
```

### 2. ファイル配置場所
- **プロジェクトルート**: `/Users/s.maemura/AppPJ/WasurenBou/app-ads.txt`
- **GitHub Pages**: `https://s-maemura.github.io/WasurenBou-support/app-ads.txt`

### 3. AdMobでの確認事項
AdMobアカウントでの確認に関する重要な注意点：

1. **app-ads.txtファイルの設定確認**
   - ファイルは作成・公開済み
   - AdMobダッシュボードで検証されるまで最大24時間かかる場合がある

2. **サポートサイトについて**
   - app-ads.txtファイルはサポートサイト（https://s-maemura.github.io/WasurenBou-support/）に公開済み
   - このURLはApp Store Connectに登録されているサポートURLと一致

3. **変更したファイル公開後の確認**
   - デベロッパーウェブサイトのルートに配置済み
   - HTTPSで正しくアクセス可能であることを確認

### 4. AdMobアカウントでの次のステップ

1. **AdMobダッシュボードで確認**
   - 「アプリ」→「すべてのアプリを表示」から該当アプリを選択
   - 「app-ads.txt」のステータスを確認

2. **ステータスが「承認済み」になるまで待機**
   - 通常24時間以内に自動的に検証される
   - 問題がある場合はAdMobから通知が来る

3. **広告配信の確認**
   - app-ads.txtが承認されると広告配信が正常化される
   - 形式が正しくない場合は広告収益に影響する可能性がある

## トラブルシューティング

### app-ads.txtファイルが検証されない場合
1. ファイルのエンコーディングがUTF-8であることを確認
2. ファイル名が正確に「app-ads.txt」であることを確認（大文字小文字区別）
3. HTTPSでアクセス可能であることを確認
4. ファイルの内容が正確であることを確認

### その他の注意点
- IAB Tech Labの仕様に準拠していることを確認済み
- 複数の広告ネットワークを使用する場合は、各ネットワークのエントリを追加する必要がある

## 参考リンク
- [AdMob app-ads.txt ガイド](https://support.google.com/admob/answer/9363762)
- [IAB Tech Lab app-ads.txt 仕様](https://iabtechlab.com/app-ads-txt/)
- [WasurenBou サポートサイト](https://s-maemura.github.io/WasurenBou-support/)
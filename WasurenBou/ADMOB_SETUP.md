# AdMob設定ガイド - Remind!!!

## 概要
Remind!!!アプリのAdMob設定手順です。現在実装されている広告ID:

**アプリID**: `ca-app-pub-4187811193514537~8449937639`
**バナー広告ID**: `ca-app-pub-4187811193514537/6354257330`

## AdMob管理画面での設定手順

### 1. AdMob管理画面にアクセス
https://apps.admob.com/ にアクセスしてログイン

### 2. ストアの追加
現在「ストアを追加しろ」と言われている状態のため、以下手順で対応:

#### 手順:
1. AdMob管理画面で該当するアプリを選択
2. 「アプリの設定」→「ストア情報」へ移動
3. 「ストアの追加」をクリック
4. 以下情報を入力:
   - **ストア**: App Store (iOS)
   - **アプリ名**: Remind!!!
   - **Bundle ID**: com.lizaria.WasurenBou
   - **ストアURL**: (App Store Connectで承認後のURL)

### 3. App Store Connect との連携

#### App Store Connect側で必要な設定:
1. App Store Connectにログイン
2. 「Remind!!!」アプリを選択
3. 「App情報」→「一般情報」で以下を確認:
   - Bundle ID: `com.lizaria.WasurenBou`
   - アプリ名: Remind!!!
   
#### AdMob側での確認事項:
1. アプリIDが正しく設定されている
2. 広告ユニットIDが正しく設定されている
3. ストア情報が正確

### 4. 実装確認
現在のコード実装は適切です:

**Info.plist**:
```xml
<key>GADApplicationIdentifier</key>
<string>ca-app-pub-4187811193514537~8449937639</string>
```

**AdMobService.swift**:
```swift
private let productionBannerUnitID = "ca-app-pub-4187811193514537/6354257330"
```

### 5. テスト方法

#### シミュレータでのテスト:
- テスト用広告IDが自動使用される
- `ca-app-pub-3940256099942544/2934735716` (テスト用)

#### 実機でのテスト:
- Debug構成時: テスト広告表示
- Release構成時: 本番広告表示

### 6. 注意事項

1. **App Store承認前**: 
   - ストアURLが未設定でも開発は可能
   - 承認後に正式URLを設定

2. **広告収益化**:
   - アプリがApp Storeで公開される前は収益化されない
   - 公開後、AdMobで広告配信が開始される

3. **コンプライアンス**:
   - ATT (App Tracking Transparency) 実装済み
   - GDPR対応(ConsentService)実装済み

### 7. リリース後のモニタリング
- AdMob管理画面で収益とパフォーマンスを確認
- 広告表示率、クリック率の監視
- ユーザーエクスペリエンスへの影響を評価

## トラブルシューティング

### 「ストアを追加しろ」エラー
→ 上記手順2でストア情報を追加

### 広告が表示されない
1. ネットワーク接続確認
2. AdMob管理画面でアプリステータス確認
3. 広告IDの再確認

### テスト広告が表示され続ける
→ Release構成でビルドしているか確認
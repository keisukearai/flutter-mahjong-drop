# 麻雀ドロップ (Mahjong Drop)

落ちゲー × 麻雀パズル。上から落ちてくる麻雀牌で面子を完成させるシンプル＆爽快なゲーム。

- **パッケージ名**: `com.keisukearai.mahjongdrop`
- **バージョン**: 1.0.0+1

---

## ビルド

### 前提

- Flutter SDK
- Android SDK（NDK 28.2.13676358 含む）
- Android SDK `cmdline-tools` （初回のみ手動インストールが必要、下記参照）

### Android App Bundle（Google Play 提出用）

```bash
flutter build appbundle --release
# → build/app/outputs/bundle/release/app-release.aab
```

### iOS

```bash
flutter build ipa --release
```

---

## リリース署名（Android）

### キーストア

`android/app/mahjong-release.jks` にリリース用キーストアを配置する。  
このファイルは `.gitignore` により **git に含まれない**。

> **重要**: キーストアを紛失するとアップデートの公開が不可能になる。iCloud やパスワードマネージャーに必ずバックアップすること。

### key.properties

`android/key.properties` に署名情報を記載する（同様に git 管理外）。

```properties
storePassword=<パスワード>
keyPassword=<パスワード>
keyAlias=mahjong-key
storeFile=mahjong-release.jks
```

---

## Google Play ストア素材

| ファイル | 用途 | サイズ |
|---|---|---|
| `assets/icon/app_icon_512.png` | アプリアイコン | 512×512px |
| `assets/icon/feature_graphic.png` | フィーチャーグラフィック | 1024×500px |
| `assets/icon/app_icon.png` | 元画像（1024×1024px） | - |

素材の再生成:
```bash
cd assets/icon
python3 gen_icon.py          # アプリアイコン
python3 gen_feature_graphic.py  # フィーチャーグラフィック
```

---

## 注意事項

### Android cmdline-tools が未インストールの場合

`flutter build appbundle --release` が `Failed to find cmdline-tools` で失敗する場合、以下の手順でインストールする。

1. [Android cmdline-tools](https://developer.android.com/studio#command-line-tools-only) をダウンロード
2. 解凍して `~/Library/Android/sdk/cmdline-tools/latest/` に配置
3. ライセンスファイルを作成（または Android Studio で承認）

### NDK の llvm-strip（Apple Silicon Mac）

NDK の llvm-strip は `darwin-x86_64` バイナリのため、Apple Silicon では Rosetta 2 が必要。  
Rosetta がインストールされていれば自動的に動作する。

### in_app_purchase（鬼モード）

- Product ID: `oni_mode_unlock`
- Google Play Console の「アプリ内商品」に登録が必要
- テストは Google Play の内部テストトラックで行う

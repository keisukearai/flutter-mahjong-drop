# flu-mahjong-v2 — Claude Code Instructions

## プロジェクト概要
Flutterで作る落ちもの系麻雀パズルゲーム（iOS/Android）。
牌が上から落ちてきて、3枚の面子（刻子・順子）を完成させるとブロックが消える。

## ゴール（デザインリファレンス）
牌のビジュアルは**伝統的な中国式麻雀牌**のスタイルにする。
- 背景：クリーム色（#FFF9E6）
- 絵柄：濃い緑（#1A6B1A）＋赤（#CC0000）のイラスト
- 一索（1-sou）は鳳凰（フェニックス・孔雀）柄
- 角丸・立体感あり

## 残りの主要タスク（完成度60%→100%へ）
- [ ] 牌デザインの全種類を伝統スタイルに洗練する
- [ ] ゲームバランス調整（落下速度・スコアリング）
- [ ] UI/UXの仕上げ（タイトル画面・ゲームオーバー画面）
- [ ] App Store申請用メタデータ整備

## アーキテクチャ
- `lib/game/` — Flameゲームエンジン層
  - `components/tile_painter.dart` — 牌の描画（Canvas API）
  - `components/board_component.dart` — ボード描画
  - `components/falling_tile_component.dart` — 落下牌
  - `game_controller.dart` — ゲームロジック
- `lib/mahjong/` — 麻雀ルール（tile, meld）
- `lib/ui/` — Flutter Widget層（画面・オーバーレイ）
- `lib/services/` — BGM/SFX

## 開発ルール
- 実機インストールは必ず `flutter run --release` を使う（debugモード不可）
- バージョン更新時は `pubspec.yaml` と `ios/Runner.xcodeproj/project.pbxproj` を同時更新
- コメントは「なぜ」が非自明な場合のみ書く
- 絵柄はCanvasで直接描画（画像ファイルは使わない）

## 作業開始時の確認事項
1. `flutter analyze` でエラーがないことを確認
2. `tile_preview_screen.dart` でプレビュー確認可能
3. 実機確認は `flutter run --release -d <device>` で

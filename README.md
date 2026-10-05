# Odins_GUNGUNIR_GOLD-framework
### リアルタイム市場分析・非同期シグナル配信アーキテクチャ

![Language](https://img.shields.io/badge/Language-MQL4%20%2F%20C%2B%2B%20Dialect-blue?logo=cplusplus)
![Platform](https://img.shields.io/badge/Platform-MetaTrader%204%20Client-orange)
![Network](https://img.shields.io/badge/API-REST%20%2F%20multipart--form--data-green)
![Resilience](https://img.shields.io/badge/Design-Fault--Tolerant%20%26%20Circuit--Breaker-red)

MetaTrader 4 (MT4) 上で動作するイベント駆動型の統合市場分析フレームワークです。
時系列データの多変量解析、外部REST APIによるライセンス認証、低レイヤバイナリ操作によるDiscordへの画像非同期送信、およびシステムレベルでの資金保護機構（サーキットブレーカー）を備えた商用耐障害性アーキテクチャを採用しています。

> **※ ソースコードの公開範囲について**  
> 本システムは実運用環境で稼働している商用プロダクトのため、独自の市場分析アルゴリズム（SMC判定、相関分析等）は知的財産保護の観点から非公開（抽象化プレースホルダー）としています。  
> 本リポジトリでは技術評価の対象として、**「通信プロトコル・バイナリ操作基盤」「耐障害性ネットワーク制御」「資金保護サーキットブレーカー」**に該当するモジュールおよびメインフレームワークのみを公開しています。
>
> flowchart TD
    Init[初期化 / OnInit] --> AuthCheck{ライセンス認証\nGAS REST API}
    AuthCheck -->|認証成功| TickEngine[イベント駆動エンジン\nOnTick]
    AuthCheck -->|通信障害| Retry[リトライ機構\n60秒間隔 / 最大5回]

 🏗 システムアーキテクチャ

    TickEngine --> RiskCheck{日次損失監視\n日次DD 4.5%超過?}
    RiskCheck -->|超過| CircuitBreaker[サーキットブレーカー発動\n全機能緊急停止]
    
    RiskCheck -->|安全圏| MarketAnalysis[多重環境認識パイプライン\nSMC / VWAP / 相関判定]
    MarketAnalysis --> SignalCondition{シグナル検知?}
    SignalCondition -->|成立| ScreenCapture[チャート画面キャプチャ\nローカルPNG出力]
    
    ScreenCapture --> BinaryProc[バイナリ読込 & WHOLE_ARRAY制御\nmultipart/form-data生成]
    BinaryProc --> Dispatcher{Discord送信処理}
    Dispatcher -->|正常| SendImage[画像+メタデータ送信]
    Dispatcher -->|I/O例外| Fallback[テキストフォールバック\nJSON形式で送信]

💡 主要なエンジニアリング課題と解決策
1. 低レイヤバイナリ操作による multipart/form-data の手動生成
課題: MT4標準のネットワーク関数（WebRequest）は高レベルなHTTPライブラリを備えておらず、画像ファイルのマルチパート送信に対応していない。
解決策:
チャート画像をローカルに書き出し後、バイナリモードでメモリ配列へロード。
HTTPヘッダー、境界識別子（Boundary）、メタデータ、画像バイナリを正確に連結するバッファ操作を実装。
日本語混入時のHTTP 400エラーに対し、文字数ではなく全バイト長（WHOLE_ARRAY）ベースでContent-Lengthを計算するエンコーディング処理を構築。
2. 多層フェイルセーフと通信耐障害性（Fault Tolerance）
指数バックオフ・リトライ: 認証APIとの通信タイムアウト（HTTP: -1）発生時、即時停止せず60秒インターバルのリトライ（最大5回）を実行。
動的フォールバック: リソース制約やファイルI/Oエラーで画像生成が失敗した場合、即座に例外をキャッチし、テキスト形式（JSON）のみのメッセージ送信へ自動縮退運転。
シンボル自動解決: ブローカーごとに異なる銘柄命名規則（XAGUSD, SILVER, XAGUSDm 等）を実行時に動的探索・バインド。
3. 資金保護サーキットブレーカー（Circuit Breaker Pattern）
厳格なリスク管理: プロップファームの失格規定に準拠し、口座の確定損益および含み損益を毎ティック監視。
自動キルスイッチ: 当日の損失率が事前に設定した閾値（4.5%）に達した瞬間、シグナル生成および注文監視を完全停止。

## 🛠 技術スタック

* **開発言語**
  * `MQL4` (C++ Dialect) — 低レイヤメモリ制御、Tick単位のリアルタイムイベント駆動処理
* **ネットワーク通信**
  * `Win32 API` / `WebRequest` — HTTP/HTTPS通信、カスタムヘッダー制御
* **認証・バックエンド基盤**
  * `Google Apps Script` (RESTful Web API) — サーバーレスでの動的ライセンス認証・管理
* **外部連携**
  * `Discord Webhook API` — リアルタイム通知、チャート画像マルチパートバイナリ配信
* **アーキテクチャ設計**
  * イベント駆動型アーキテクチャ / 耐障害性（Fault Tolerance）設計 / サーキットブレーカーパターン

## 📁 ディレクトリ構成

```text
Odins_GUNGUNIR_GOLD-framework/
│
├── include/                     # コア設計モジュール群
│   ├── CircuitBreaker.mqh       # 日次損失監視・フェイルセーフ自動停止機構
│   ├── DiscordNotifier.mqh      # バイナリI/O・multipart/form-data動的生成
│   ├── LicenseAuth.mqh          # GAS REST API認証・指数リトライ制御
│   └── SymbolResolver.mqh       # ブローカー別シンボル動的バインド
│
├── src/
│   └── Main_Framework.mq4      # ライフサイクル制御（OnInit / OnTick / OnDeinit）
│
└── README.md                    # システム仕様・アーキテクチャ設計ドキュメント

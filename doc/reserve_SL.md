
## 名前

  tool/reserve_SL.rb  予約データの save & load

## 書式

   reserve_SL.rb [オプション]

## 説明

   データベース中の予約関係データを保存、読み込みを行う。

## オプション

-s  &emsp; 
データセーブモード : DBの中の予約関係データ を yaml 形式でダンプする。

-l  &emsp; 
データロードモード : ダンプしたファイルを読み込む。

-f  file名 &emsp; 
出力先又は入力先のファイル名を指定する。デフォルトは標準出力、標準入力。

-o &emsp; 
データロード時に、現在より古いデータは無視する。

## 例

```
% ruby tool/reserve_SL.rb

```



## 注意
* 事前に config.rb の設定がされている事が必要です。
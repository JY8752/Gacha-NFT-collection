# NFTガチャ

## 概要

本プロジェクトはNFTコレクションにガチャの要素を持たせたサンプルアプリであり、NFTコレクションにガチャの要素・機能を持たせるためのインターフェイスを提供する。

## 背景

web2の領域においてデジタルアイテムの収集といえばソーシャルゲームなどのガチャが一般的である。
ブロックチェーンやNFT、仮想通貨に馴染みのない非cryptoユーザーにデジタルアイテムのコレクションに興味を持ってもらうにはこのガチャという要素をdappsに取り入れることがNFTの普及への近道かもしれない。

## イメージ図

![](https://user-images.githubusercontent.com/58534052/219954369-d8c63ffa-7749-4ff7-8c7f-f3dcee099e75.png)

## accounts

アカウント作成
```
flow accounts create 
```

## transactions

アカウントセットアップ
```
flow transactions send ./cadence/transactions/setup_account.cdc --signer alice
```

minter準備
```
flow transactions send ./cadence/transactions/setup_nft_minter.cdc --signer default
```

mint
```
flow transactions send ./cadence/transactions/lottery_mint.cdc --signer default eb179c27144f783c
```

## scripts
 
```
flow scripts execute ./cadence/scripts/get_amounts.cdc eb179c27144f783c
```
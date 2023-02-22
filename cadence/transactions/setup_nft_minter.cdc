/*
管理者アカウントで実行する
NFTをmintするためのminterリソースをストレージに保存する
 */
import GachaNFT from "../contracts/GachaNFT.cdc"
import NonFungibleToken from "../contracts/lib/NonFungibleToken.cdc"

transaction {
  prepare(signer: AuthAccount) {
    let minter <- GachaNFT.createNFTMinter()
    signer.save(<- minter, to: GachaNFT.MinterStoragePath)
  }
}
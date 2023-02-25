import GachaNFT from "../contracts/GachaNFT.cdc"
import Gacha from "../contracts/Gacha.cdc"
import NonFungibleToken from "../contracts/lib/NonFungibleToken.cdc"

transaction {
  prepare(signer: AuthAccount) {
    // 既にコレクションを持っている
    if signer.borrow<&GachaNFT.Collection>(from: GachaNFT.CollectionStoragePath) != nil {
      return
    }

    // リソース作成
    let collection <- GachaNFT.createEmptyCollection()

    // リソース保存
    signer.save(<- collection, to: GachaNFT.CollectionStoragePath)

    // linkの作成
    signer.link<&{NonFungibleToken.CollectionPublic}>(
      GachaNFT.CollectionPublicPath,
      target: GachaNFT.CollectionStoragePath
    )

    signer.link<&{Gacha.IncreceAmount, Gacha.GetAmounts}>(
      GachaNFT.GachaPublicPath,
      target: GachaNFT.CollectionStoragePath
    )

    log("complete setup!!")
  }
}
 
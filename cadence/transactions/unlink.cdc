import GachaNFT from "../contracts/GachaNFT.cdc"
transaction {
  prepare(signer: AuthAccount) {
    signer.unlink(GachaNFT.CollectionPublicPath)
    signer.unlink(GachaNFT.GachaPublicPath)
  }
}
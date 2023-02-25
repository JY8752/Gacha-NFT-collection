import GachaNFT from "../contracts/GachaNFT.cdc"
transaction {
  prepare(acc: AuthAccount) {
    let collection <- acc.load<@GachaNFT.Collection>(from: GachaNFT.CollectionStoragePath)!
    destroy collection
  }
}
import GachaNFT from "../contracts/GachaNFT.cdc"
transaction {
  prepare(signer: AuthAccount) {
    destroy signer.load<@GachaNFT.NFTMinter>(from: GachaNFT.MinterStoragePath)
  }
}
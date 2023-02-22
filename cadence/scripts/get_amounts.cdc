import GachaNFT from "../contracts/GachaNFT.cdc"

pub fun main(address: Address): {UInt64: UInt32} {
  let account = getAccount(address)
  let collectionRef = account
    .getCapability(GachaNFT.CollectionPublicPath)
    .borrow<&{GachaNFT.GachaNFTCollectionPublic}>()
    ?? panic("Does not store collection at the public path!")

  return collectionRef.getAmounts()
}
 
import GachaNFT from "../contracts/GachaNFT.cdc"
import Gacha from "../contracts/Gacha.cdc"

pub fun main(address: Address): {UInt64: UInt32} {
  let account = getAuthAccount(address)
  let ref = account.borrow<&GachaNFT.Collection>(from: GachaNFT.CollectionStoragePath) ?? panic("Does not store collection at the storage path.")
  return ref.getAmounts()
}
 
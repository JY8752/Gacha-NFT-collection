import GachaNFT from "../contracts/GachaNFT.cdc"

pub fun main(addr: Address): [UInt64] {
  return GachaNFT.ids.keys
}
/// NFTコレクションにガチャの機能を組み込むためのインターフェイス
/// このインターフェイスが実装されたコントラクトが１つのガチャ筐体を表現する
/// Interface to incorporate gacha functionality into NFT collectionss.
/// The contract in which this interface is implemented represents a single mess enclosure.
pub contract interface Gacha {
    /// increce amount event
    pub event Increce(id: UInt64, beforeAmount: UInt32, afterAmount: UInt32)
    /// decrece amount event
    pub event Decrece(id: UInt64, beforeAmount: UInt32, afterAmount: UInt32)

    /// 抽選mintするための重み設定 Weight setting for lottery minting
    pub struct interface HasWeight {
      /// 重み weight
      pub let weight: UInt64
    }

    /// ガチャコントラクトからmintされるアイテム
    /// item minted by this gacha contract
    pub struct Item: HasWeight {
      pub let weight: UInt64
    }

    /// key: item_id value: item
    pub let ids: {UInt64: AnyStruct{HasWeight}}

    pub resource Collection {
      /// key: item_id value: amount
      pub var ownedAmounts: {UInt64:UInt32}

      /// increce the item amount
      pub fun increceAmount(id: UInt64, amount: UInt32)

      /// decrece the item amount.
      /// must have more than specifyed amount.
      pub fun decreseAmount(id: UInt64, amount: UInt32) {
        pre {
          self.ownedAmounts[id] == nil: "Not have token!!"
          self.ownedAmounts[id]! - amount < 0: "The amount you do not have is specified!"
        }
      }

      /// get specified id item amount 
      pub fun getAmount(id: UInt64): UInt32

      /// get all item id and amount
      pub fun getAmounts(): {UInt64:UInt32}
    }
}
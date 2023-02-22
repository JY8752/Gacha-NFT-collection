import GachaNFT from "../contracts/GachaNFT.cdc"
import NonFungibleToken from "../contracts/lib/NonFungibleToken.cdc"

transaction(
    recipient: Address
) {
    let minter: &GachaNFT.NFTMinter
    let recipientCollectionRef: &{NonFungibleToken.CollectionPublic, GachaNFT.GachaNFTCollectionPublic}

    prepare(acct: AuthAccount) {
        self.minter = acct.borrow<&GachaNFT.NFTMinter>(from: GachaNFT.MinterStoragePath)
            ?? panic("Account does not store minter object at the specify storage path")
        
        self.recipientCollectionRef = getAccount(recipient)
            .getCapability(GachaNFT.CollectionPublicPath)
            .borrow<&{NonFungibleToken.CollectionPublic, GachaNFT.GachaNFTCollectionPublic}>()
            ?? panic("Account does not store collection object at the specify public path")
    }

    execute {
        // アイテムと重みの対応表
        let ids = GachaNFT.ids

        // 重みの総和
        var total: UInt64 = 0
        ids.forEachKey(fun (id: UInt64): Bool {
            let item = ids[id]
            if item != nil {
                total = total + item!.weight
                return true
            } else {
                return false
            }
        })

        // 乱数
        let rand = unsafeRandom() % total // 0 ~ (total - 1)までの乱数

        // 重み付け抽選
        var currentWeight: UInt64 = 0
        var lotteryItem: GachaNFT.Item? = nil
        for i, key in ids.keys {
            let item = ids[key]!
            currentWeight = currentWeight + item.weight
            if rand < currentWeight {
                lotteryItem = item
                break
            }
        }

        // たぶんありえない
        if lotteryItem == nil {
            panic("Fail lottery NFT!")
        }

        if self.recipientCollectionRef.getAmount(id: lotteryItem!.id) == 0 {
            // まだ持ってないトークンなので普通にmintする
            self.minter.mint(
                recipient: self.recipientCollectionRef,
                royalties: [],
                item: lotteryItem!
            )
        } else {
            // 既に持ってるので個数を増やす
            self.recipientCollectionRef.increceAmount(id: lotteryItem!.id, amount: 1)
        }
    }
}
 
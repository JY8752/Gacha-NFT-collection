import GachaNFT from "../contracts/GachaNFT.cdc"
import Gacha from "../contracts/Gacha.cdc"
import NonFungibleToken from "../contracts/lib/NonFungibleToken.cdc"

transaction(
    recipient: Address
) {
    let minter: &GachaNFT.NFTMinter
    let recipientCollectionRef: &{NonFungibleToken.CollectionPublic}
    let gachaRef: &{Gacha.IncreceAmount, Gacha.GetAmounts}

    prepare(acct: AuthAccount) {
        self.minter = acct.borrow<&GachaNFT.NFTMinter>(from: GachaNFT.MinterStoragePath)
            ?? panic("Account does not store minter object at the specify storage path")
        
        self.recipientCollectionRef = getAccount(recipient)
            .getCapability(GachaNFT.CollectionPublicPath)
            .borrow<&{NonFungibleToken.CollectionPublic}>()
            ?? panic("Account does not store collection object at the specify public path")
        
        self.gachaRef = getAccount(recipient)
            .getCapability(GachaNFT.GachaPublicPath)
            .borrow<&{Gacha.IncreceAmount, Gacha.GetAmounts}>()
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
                lotteryItem = item as? GachaNFT.Item ?? panic("LotteryItem type is not GachaNFT.Item!!")
                break
            }
        }

        // たぶんありえない
        if lotteryItem == nil {
            panic("Fail lottery NFT!")
        }

        if self.gachaRef.getAmount(id: lotteryItem!.id) == 0 {
            // まだ持ってないトークンなので普通にmintする
            self.minter.mint(
                recipient: self.recipientCollectionRef,
                royalties: [],
                item: lotteryItem!
            )
            log("execute mint!!")
        } else {
            // 既に持ってるので個数を増やす
            self.gachaRef.increceAmount(id: lotteryItem!.id, amount: 1)
            log("increce item amount!!")
        }

        log("complete lottery!!")
    }
}
 
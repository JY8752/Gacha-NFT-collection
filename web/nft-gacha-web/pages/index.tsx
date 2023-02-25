import { useEffect, useState } from 'react';
import * as fcl from '@onflow/fcl';

const Home = () => {
  // コレクションのアイテムを取得
  const getItems = async (addr: string) => {
    const items = await fcl.query({
      cadence: `
        import GachaNFT from 0xGacha
        import Gacha from 0xGacha

        pub fun main(address: Address): {UInt64: UInt32} {
          let account = getAuthAccount(address)
          let ref = account.borrow<&GachaNFT.Collection>(from: GachaNFT.CollectionStoragePath) ?? panic("Does not store collection at the storage path.")
          return ref.getAmounts()
        }
      `,
      args: (arg: any, t: any) => [arg(addr, t.Address)],
    });
    console.log(items);
  };

  // コレクションの作成
  const setupCollection = async () => {
    const transactionId = await fcl.mutate({
      cadence: `
        import GachaNFT from 0xGacha
        import Gacha from 0xGacha
        import NonFungibleToken from 0xGacha
        
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
      `,
      payer: fcl.authz,
      proposer: fcl.authz,
      authorizations: [fcl.authz],
      limit: 50,
    });
    const transaction = await fcl.tx(transactionId).onceSealed();
    console.log(transaction);
  };

  // mint
  const lotteryMint = async (addr: string) => {
    const transactionId = await fcl.mutate({
      cadence: `
        import GachaNFT from 0xGacha
        import Gacha from 0xGacha
        import NonFungibleToken from 0xGacha

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
      `,
      args: (arg: any, t: any) => [arg(addr, t.Address)],
      payer: fcl.authz,
      proposer: fcl.authz,
      authorizations: [fcl.authz],
      limit: 50,
    });
    const transaction = await fcl.tx(transactionId).onceSealed();
    console.log(transaction);
  };

  // setup minter
  const setupMinter = async () => {
    const transactionId = await fcl.mutate({
      cadence: `
        import GachaNFT from 0xGacha
        import NonFungibleToken from 0xGacha

        transaction {
          prepare(signer: AuthAccount) {
            let minter <- GachaNFT.createNFTMinter()
            signer.save(<- minter, to: GachaNFT.MinterStoragePath)
            log("complete setup minter!!")
          }
        }
      `,
      proposer: fcl.currentUser,
      payer: fcl.currentUser,
      authorizations: [fcl.currentUser],
      limit: 50,
    });
    const transaction = await fcl.tx(transactionId).onceSealed();
    console.log(transaction);
  };

  // destroy collection
  const destroyCollection = async () => {
    const transactionId = await fcl.mutate({
      cadence: `
        import GachaNFT from 0xGacha
        transaction {
          prepare(acc: AuthAccount) {
            let collection <- acc.load<@GachaNFT.Collection>(from: GachaNFT.CollectionStoragePath)!
            destroy collection
          }
        }
      `,
      proposer: fcl.currentUser,
      payer: fcl.currentUser,
      authorizations: [fcl.currentUser],
      limit: 50,
    });
    const transaction = await fcl.tx(transactionId).onceSealed();
    console.log(transaction);
  };

  // remove collection storage
  const removeCollection = async () => {
    const transactionId = await fcl.mutate({
      cadence: `
        import GachaNFT from 0xGacha
        transaction {
          prepare(signer: AuthAccount) {
            destroy signer.load<@GachaNFT.Collection>(from: GachaNFT.CollectionStoragePath)
          }
        }
      `,
      proposer: fcl.currentUser,
      payer: fcl.currentUser,
      authorizations: [fcl.currentUser],
      limit: 50,
    });
    const transaction = await fcl.tx(transactionId).onceSealed();
    console.log(transaction);
  };

  // unlink
  const unlink = async () => {
    const transactionId = await fcl.mutate({
      cadence: `
        import GachaNFT from 0xGacha
        transaction {
          prepare(signer: AuthAccount) {
            signer.unlink(GachaNFT.CollectionPublicPath)
            signer.unlink(GachaNFT.GachaPublicPath)
          }
        }
      `,
      proposer: fcl.currentUser,
      payer: fcl.currentUser,
      authorizations: [fcl.currentUser],
      limit: 50,
    });
    const transaction = await fcl.tx(transactionId).onceSealed();
    console.log(transaction);
  };

  // test
  const random = async () => {
    const rand = await fcl.query({
      cadence: `
        pub fun main(): UInt64 {
          return unsafeRandom()
        }
      `,
    });
    console.log(rand);
    console.log(rand % 100);
  };

  return (
    <>
      <h1 className="text-xl">Scripts/Transactions</h1>
      <div>
        <button
          className="m-2 rounded bg-green-400 p-2 hover:bg-green-300"
          onClick={() => getItems('0x823341d5284d4fc1')}
        >
          getItems
        </button>
        <button
          className="m-2 rounded bg-green-400 p-2 hover:bg-green-300"
          onClick={() => setupCollection()}
        >
          setupCollection
        </button>
        <button
          className="m-2 rounded bg-green-400 p-2 hover:bg-green-300"
          onClick={() => lotteryMint('0x823341d5284d4fc1')}
        >
          lotteryMint
        </button>
        <button
          className="m-2 rounded bg-green-400 p-2 hover:bg-green-300"
          onClick={() => setupMinter()}
        >
          setupMinter
        </button>
        <button
          className="m-2 rounded bg-red-400 p-2 hover:bg-red-300"
          onClick={() => destroyCollection()}
        >
          destroyCollection
        </button>
        <button
          className="m-2 rounded bg-red-400 p-2 hover:bg-red-300"
          onClick={() => removeCollection()}
        >
          removeCollection
        </button>
        <button
          className="m-2 rounded bg-red-400 p-2 hover:bg-red-300"
          onClick={() => unlink()}
        >
          unlink
        </button>
        <button
          className="m-2 rounded bg-amber-400 p-2 hover:bg-amber-300"
          onClick={() => random()}
        >
          random
        </button>
      </div>
    </>
  );
};

export default Home;

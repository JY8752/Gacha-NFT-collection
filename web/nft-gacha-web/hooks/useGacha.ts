import * as fcl from '@onflow/fcl';
import { useEffect, useState } from 'react';
import { Display, GachaCollectionItem, Transaction } from '../types/gacha';

export const useGacha = (addr: string) => {
  const [collectionItems, setCollectionItems] = useState<GachaCollectionItem[]>(
    [],
  );

  useEffect(() => {
    (async () => {
      setCollectionItems(await getCollectionOwnedMap());
    })();
  }, []);

  // コレクション情報を取得する
  const getCollectionOwnedMap = async (): Promise<GachaCollectionItem[]> => {
    const amounts = await getAmounts(addr);
    const ids = await getIds();
    const collection = await getCollection(addr);

    return ids.map((id) => {
      const display = collection.find((item) => item[id]);
      if (display) {
        // 所持してる
        return {
          id,
          name: display[id].name,
          description: display[id].description,
          thumbnail: display[id].thumbnail.cid,
          amount: Number(amounts[id]) ?? 0,
        };
      } else {
        return {
          id,
          amount: 0,
        };
      }
    });
  };

  // コレクションのアイテム数を取得する
  const getAmounts = async (addr: string) => {
    try {
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
      return items;
    } catch (e: unknown) {
      console.log(e);
      alert('接続しているアカウント内にコレクションが保存されていません');
    }
  };

  // コレクション情報を取得する
  const getCollection = async (
    addr: string,
  ): Promise<{ [key: number]: Display }[]> => {
    try {
      const collection = await fcl.query({
        cadence: `
          import GachaNFT from 0xGacha
          import MetadataViews from 0xGacha

          pub fun main(address: Address): [{UInt64:MetadataViews.Display}] {
            let account = getAuthAccount(address)
            let collectionRef = account.borrow<&GachaNFT.Collection>(from: GachaNFT.CollectionStoragePath)
              ?? panic("Does not have collection!!")

              let ids = collectionRef.getIDs()
              let items: [{UInt64:MetadataViews.Display}] = []
              for id in ids {
                let resolver = collectionRef.borrowViewResolver(id: id)
                let view = resolver.resolveView(Type<MetadataViews.Display>()) as? MetadataViews.Display?
                let display = (view
                  ?? panic("Can not get Metadata Views!!"))
                  ?? panic("Can not cast MetadataViews.Display!!")
                items.append({id:display})
              }

              return items
          }
        `,
        args: (arg: any, t: any) => [arg(addr, t.Address)],
      });
      console.log(collection);
      return collection;
    } catch (e: unknown) {
      console.log(e);
      alert('接続しているアカウント内にコレクションが保存されていません');
      return Promise.resolve([]);
    }
  };

  // コレクションアイテムのIDを全て取得する
  const getIds = async (): Promise<number[]> => {
    const ids: number[] = await fcl.query({
      cadence: `
          import GachaNFT from 0xGacha

          pub fun main(): [UInt64] {
            return GachaNFT.ids.keys
          }
        `,
    });
    console.log(ids);
    return ids.sort();
  };

  // コレクションの作成
  const setupCollection = async (): Promise<Transaction> => {
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
    const transaction: Transaction = await fcl.tx(transactionId).onceSealed();
    console.log(transaction);
    return transaction;
  };

  // mint
  const lotteryMint = async (addr: string): Promise<Transaction> => {
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
    const transaction: Transaction = await fcl.tx(transactionId).onceSealed();
    console.log(transaction);
    return transaction;
  };

  // setup minter
  const setupMinter = async (): Promise<Transaction> => {
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
    const transaction: Transaction = await fcl.tx(transactionId).onceSealed();
    console.log(transaction);
    return transaction;
  };

  // destroy collection
  const destroyCollection = async (): Promise<Transaction> => {
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
    const transaction: Transaction = await fcl.tx(transactionId).onceSealed();
    console.log(transaction);
    return transaction;
  };

  // remove collection storage
  const removeCollection = async (): Promise<Transaction> => {
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
    const transaction: Transaction = await fcl.tx(transactionId).onceSealed();
    console.log(transaction);
    return transaction;
  };

  // remove minter storage
  const removeMinter = async (): Promise<Transaction> => {
    const transactionId = await fcl.mutate({
      cadence: `
        import GachaNFT from 0xGacha
        transaction {
          prepare(signer: AuthAccount) {
            destroy signer.load<@GachaNFT.NFTMinter>(from: GachaNFT.MinterStoragePath)
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
    return transaction;
  };

  // unlink
  const unlink = async (): Promise<Transaction> => {
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
    const transaction: Transaction = await fcl.tx(transactionId).onceSealed();
    console.log(transaction);
    return transaction;
  };

  return {
    getAmounts,
    getCollection,
    getIds,
    setupCollection,
    lotteryMint,
    setupMinter,
    destroyCollection,
    removeCollection,
    removeMinter,
    unlink,
    getCollectionOwnedMap,
    collectionItems,
    setCollectionItems,
  };
};

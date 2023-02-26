import NonFungibleToken from "./lib/NonFungibleToken.cdc"
import MetadataViews from "./lib/MetadataViews.cdc"
import Gacha from "./Gacha.cdc"

pub contract GachaNFT: NonFungibleToken, Gacha {
    // NonFungibleToken override
    pub var totalSupply: UInt64

    /// event
    // NonFungibleToken override
    pub event ContractInitialized()
    // NonFungibleToken override
    pub event Withdraw(id: UInt64, from: Address?)
    // NonFungibleToken override
    pub event Deposit(id: UInt64, to: Address?)

    pub event Increce(id: UInt64, beforeAmount: UInt32, afterAmount: UInt32)
    pub event Decrece(id: UInt64, beforeAmount: UInt32, afterAmount: UInt32)

    /// path
    pub let CollectionStoragePath: StoragePath
    pub let CollectionPublicPath: PublicPath
    pub let MinterStoragePath: StoragePath
    pub let GachaPublicPath: PublicPath

    /// NFTとして発行するトークン情報
    pub struct Item: Gacha.HasWeight {
      pub let id: UInt64
      pub let name: String
      pub let description: String
      pub let thumbnail: String
      pub let weight: UInt64

      init(
        id: UInt64,
        name: String,
        description: String,
        thumbnail: String,
        rarity: String,
        weight: UInt64
      ) {
        self.id = id
        self.name = name
        self.description = description
        self.thumbnail = thumbnail
        self.weight = weight
      }
    }

    /// key: token_kind_id value: token_info
    pub let ids: {UInt64: AnyStruct{Gacha.HasWeight}}

    // NonFungibleToken override
    pub fun createEmptyCollection(): @NonFungibleToken.Collection {
      return <- create Collection()
    }

    // NonFungibleToken override
    pub resource NFT: NonFungibleToken.INFT, MetadataViews.Resolver {
      // NonfungibleToken.INFT override token kind id(not unique)
      pub let id: UInt64

      /// metadata
      pub let name: String
      pub let description: String
      pub let thumbnail: String
      access(self) let royalties: [MetadataViews.Royalty]
      access(self) let metadata: {String: AnyStruct}

      init(
        id: UInt64,
        name: String,
        description: String,
        thumbnail: String,
        royalties: [MetadataViews.Royalty],
        metadata: {String: AnyStruct}
      ) {
        self.id = id
        self.name = name
        self.description = description
        self.thumbnail = thumbnail
        self.royalties = royalties
        self.metadata = metadata
      }
    
      // MetadaViews.Resolver override 
      pub fun getViews(): [Type] {
        return [
            Type<MetadataViews.Display>(),
            Type<MetadataViews.Royalties>(),
            Type<MetadataViews.Editions>(),
            Type<MetadataViews.ExternalURL>(),
            Type<MetadataViews.NFTCollectionData>(),
            Type<MetadataViews.NFTCollectionDisplay>(),
            Type<MetadataViews.Serial>(),
            Type<MetadataViews.Traits>()
        ]
      }

      // MetadaViews.Resolver override 
      pub fun resolveView(_ view: Type): AnyStruct? {
        switch view {
          // basic view thumbnail is http url or ipfs path
          case Type<MetadataViews.Display>():
            return MetadataViews.Display(
                name: self.name,
                description: self.description,
                thumbnail: MetadataViews.IPFSFile(
                    cid: self.thumbnail,
                    path: nil
                )
            )
          // 複数のオブジェクトを発行するコレクション
          case Type<MetadataViews.Editions>():
            let editionInfo = MetadataViews.Edition(
              name: "Example NFT Edition", // ex) Play, Series...
              number: self.id, // #20/100 の20の部分
              max: nil // #20/100の100の部分。無制限の場合はnil
            )
            let editionList: [MetadataViews.Edition] = [editionInfo]
            return MetadataViews.Editions(
                editionList
            )
          // プロジェクト内の他のNFTの間で一意となるSerial number
          case Type<MetadataViews.Serial>():
            return MetadataViews.Serial(self.id)
          // ロイヤリティー情報
          case Type<MetadataViews.Royalties>():
            return MetadataViews.Royalties(self.royalties)
          // 外部URL
          case Type<MetadataViews.ExternalURL>():
            return MetadataViews.ExternalURL("https://example.com/".concat(self.id.toString()))
          // NFTコレクション情報
          case Type<MetadataViews.NFTCollectionData>():
            return MetadataViews.NFTCollectionData(
              storagePath: GachaNFT.CollectionStoragePath, // NFTのストレージパス
              publicPath: GachaNFT.CollectionPublicPath, // NFTの参照publicパス
              providerPath: /private/GachaNFTCollection, // NFTの参照privateパス
              publicCollection: Type<&GachaNFT.Collection{GachaNFT.GachaNFTCollectionPublic}>(), // publicなNFTコレクション型.通常、以下のpublicLinkedTypeと一致するが古いコレクションの下位互換のためにある
              publicLinkedType: Type<&GachaNFT.Collection{GachaNFT.GachaNFTCollectionPublic,NonFungibleToken.CollectionPublic,NonFungibleToken.Receiver,MetadataViews.ResolverCollection}>(),
              // 前述のprivateパスにある参照の型
              providerLinkedType: Type<&GachaNFT.Collection{GachaNFT.GachaNFTCollectionPublic,NonFungibleToken.CollectionPublic,NonFungibleToken.Provider,MetadataViews.ResolverCollection}>(), 
              createEmptyCollectionFunction: (fun (): @NonFungibleToken.Collection {
                  return <-GachaNFT.createEmptyCollection()
              })
            )
          // NFTコレクションを表示するのに必要な情報
          case Type<MetadataViews.NFTCollectionDisplay>():
            let media = MetadataViews.Media(
              file: MetadataViews.IPFSFile(
                cid: "QmTA3bk8GiXDnNdtLKWzXVGQxNqbfQv7WKZ7YoqCHCs6bJ",
                path: nil
              ),
              mediaType: "image/svg+xml"
            )
            return MetadataViews.NFTCollectionDisplay(
                name: "GachaNFT Collection",
                description: "This collection has Gacha feature.",
                externalURL: MetadataViews.ExternalURL("https://xxxxx"),
                squareImage: media, // コレクションのスクエア画像
                bannerImage: media, // コレクションのバナー画像
                // SNSなど
                socials: {
                    "twitter": MetadataViews.ExternalURL("https://twitter.com/xxxxxx")
                }
            )
          // key-valueで取り出せる属性的なやつ
          case Type<MetadataViews.Traits>():
            // exclude mintedTime and foo to show other uses of Traits
            let excludedTraits = ["mintedTime", "foo"]
            let traitsView = MetadataViews.dictToTraits(dict: self.metadata, excludedNames: excludedTraits)

            // mintedTime is a unix timestamp, we should mark it with a displayType so platforms know how to show it.
            let mintedTimeTrait = MetadataViews.Trait(name: "mintedTime", value: self.metadata["mintedTime"]!, displayType: "Date", rarity: nil)
            traitsView.addTrait(mintedTimeTrait)

            // foo is a trait with its own rarity
            let fooTraitRarity = MetadataViews.Rarity(score: 10.0, max: 100.0, description: "Common")
            let fooTrait = MetadataViews.Trait(name: "foo", value: self.metadata["foo"], displayType: nil, rarity: fooTraitRarity)
            traitsView.addTrait(fooTrait)
            
            return traitsView
        }
        return nil
      }
    }

    // publicに公開する機能群
    pub resource interface GachaNFTCollectionPublic {
      pub fun deposit(token: @NonFungibleToken.NFT)
      pub fun getIDs(): [UInt64]
      pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT
      pub fun borrowGachaNFT(id: UInt64): &GachaNFT.NFT? {
          post {
              (result == nil) || (result?.id == id):
                  "Cannot borrow ExampleNFT reference: the ID of the returned reference is incorrect"
          }
      }
    }

    // NonFungibleToken override
    pub resource Collection: 
      GachaNFTCollectionPublic,
      NonFungibleToken.Provider,
      NonFungibleToken.Receiver,  
      NonFungibleToken.CollectionPublic, 
      MetadataViews.ResolverCollection,
      Gacha.IncreceAmount,
      Gacha.DecreceAmount,
      Gacha.GetAmounts
    {
      // NonFungibleToken.Collection override
      pub var ownedNFTs: @{UInt64: NonFungibleToken.NFT}

      pub var ownedAmounts: {UInt64: UInt32}

      init() {
        self.ownedNFTs <- {}
        self.ownedAmounts = {}
      } 

      pub fun increceAmount(id: UInt64, amount: UInt32) {
        let beforeAmount = self.ownedAmounts[id] ?? panic("Does Not have token, so instedof deposit!")
        let afterAmount = beforeAmount + amount
        self.ownedAmounts[id] = afterAmount

        emit Increce(id: id, beforeAmount: beforeAmount, afterAmount: afterAmount)
      }

      pub fun decreseAmount(id: UInt64, amount: UInt32) {
        let beforeAmount = self.ownedAmounts[id] ?? panic("Does Not have token!")
        let afterAmount = beforeAmount - amount
        self.ownedAmounts[id] = afterAmount

        emit Decrece(id: id, beforeAmount: beforeAmount, afterAmount: afterAmount)

        if(afterAmount == 0) {
          // なくなったのでリソースも消す
          destroy self.withdraw(withdrawID: id)
        }
      }

      pub fun getAmount(id: UInt64): UInt32 {
        return self.ownedAmounts[id] ?? 0
      }

      pub fun getAmounts(): {UInt64:UInt32} {
        return self.ownedAmounts
      }

      // NonFungibleToken.Provider override
      pub fun withdraw(withdrawID: UInt64): @NonFungibleToken.NFT {
        let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")
        self.ownedAmounts.remove(key: withdrawID)               

        emit Withdraw(id: token.id, from: self.owner?.address)

        return <-token
      }

      // NonFungibleToken.Receiver override
      pub fun deposit(token: @NonFungibleToken.NFT) {
        pre {
          self.ownedAmounts[token.id] == nil || self.ownedAmounts[token.id]! <= 0: "Already owned!"
        }
        let token <- token as! @GachaNFT.NFT // important! castする必要がある

        let id: UInt64 = token.id

        // add the new token to the dictionary which removes the old one
        let oldToken <- self.ownedNFTs[id] <- token

        self.ownedAmounts[id] = 1

        emit Deposit(id: id, to: self.owner?.address)

        destroy oldToken
      }

      // NonFungibleToken.CollectionPublic override
      pub fun getIDs(): [UInt64] {
          return self.ownedNFTs.keys
      }

      // NonFungibleToken.CollectionPublic override
      pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT {
          return (&self.ownedNFTs[id] as &NonFungibleToken.NFT?)!
      }
 
      // GachaNFTCollectionPublic override
      pub fun borrowGachaNFT(id: UInt64): &GachaNFT.NFT? {
          if self.ownedNFTs[id] != nil {
              // Create an authorized reference to allow downcasting
              let ref = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
              return ref as! &GachaNFT.NFT
          }

          return nil
      }

      // MetadataViews.ResolverCollection override
      pub fun borrowViewResolver(id: UInt64): &AnyResource{MetadataViews.Resolver} {
          let nft = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
          let gachaNFT = nft as! &GachaNFT.NFT
          return gachaNFT
      }

      destroy() {
          destroy self.ownedNFTs
          self.ownedAmounts = {}
      }
    }

    pub resource NFTMinter {
    
      pub fun mint(
        recipient: &{NonFungibleToken.CollectionPublic},
        royalties: [MetadataViews.Royalty],
        item: Item,
      ) {
          let metadata: {String: AnyStruct} = {}
          let currentBlock = getCurrentBlock()
          metadata["mintedBlock"] = currentBlock.height
          metadata["mintedTime"] = currentBlock.timestamp
          metadata["minter"] = recipient.owner!.address

          // create a new NFT
          var newNFT <- create NFT(
              id: item.id,
              name: item.name,
              description: item.description,
              thumbnail: item.thumbnail,
              royalties: royalties,
              metadata: metadata,
          )

          // deposit it in the recipient's account using their reference
          recipient.deposit(token: <-newNFT)

          GachaNFT.totalSupply = GachaNFT.totalSupply + 1
      }
    }

    pub fun createNFTMinter(): @NFTMinter {
      return <- create NFTMinter()
    }

    init() {
      self.totalSupply = 0
      
      self.CollectionStoragePath = StoragePath(identifier: "GachaNFTCollection") ?? panic("can not specify storage path.")
      self.CollectionPublicPath = PublicPath(identifier: "GachaNFTCollection") ?? panic("can not specify public path.")
      self.MinterStoragePath = StoragePath(identifier: "GachaNFTMinter") ?? panic("can not specify storage path.")
      self.GachaPublicPath = PublicPath(identifier: "GachaPublic") ?? panic("can not specify public path.")

      // TODO コントラクタ引数にする
      self.ids = {
        1: Item(
          id: 1, name: "Item1", description: "Normal item.", thumbnail: "QmSzzQjaQSsUgYpxXxtF1mRgUzFYKh5HZQRi2RehNs8ZhH", rarity: "N", weight: 60
        ),
        2: Item(
          id: 2, name: "Item2", description: "Rea item.", thumbnail: "QmeHqCZ2M3FJa1J91Rd8arhKj5UBAmbs4i3mHxs6QVz6xS", rarity: "R", weight: 30
        ),
        3: Item(
          id: 3, name: "Item3", description: "Super Rea item.", thumbnail: "QmQCrYirym911cBSygYX84sWmUmirtRqpXiZFVr67s5pm7", rarity: "SR", weight: 10
        )
      }
    }
}
 
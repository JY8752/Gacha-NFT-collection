import NonFungibleToken from "../lib/NonFungibleToken.cdc"
import MetadataViews from "../lib/MetadataViews.cdc"

pub contract GachaNFT: NonFungibleToken {
    // NonFungibleToken override
    pub var totalSupply: UInt64

    /// event
    // NonFungibleToken override
    pub event ContractInitialized()
    // NonFungibleToken override
    pub event Withdraw(id: UInt64, from: Address?)
    // NonFungibleToken override
    pub event Deposit(id: UInt64, to: Address?)

    /// path
    pub let CollectionStoragePath: StoragePath
    pub let CollectionPublicPath: PublicPath
    pub let MinterStoragePath: StoragePath

    // NonFungibleToken override
    pub fun createEmptyCollection(): @NonFungibleToken.Collection {
      return <- create Collection()
    }

    // NonFungibleToken override
    pub resource NFT: NonFungibleToken.INFT, MetadataViews.Resolver {
      // NonfungibleToken.INFT override unique id
      pub let id: UInt64

      /// amount
      pub var amount: UInt32

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
        self.amount = 1
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
                thumbnail: MetadataViews.HTTPFile(
                    url: self.thumbnail
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
            return MetadataViews.ExternalURL("https://...../".concat(self.id.toString())) // TODO
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
              file: MetadataViews.HTTPFile(
                url: "https://xxxxxxxx.svg" // TODO
              ),
              mediaType: "image/svg+xml"
            )
            return MetadataViews.NFTCollectionDisplay(
                name: "GachaNFT Collection",
                description: "This collection has Gacha feature.",
                externalURL: MetadataViews.ExternalURL("https://xxxxx"), // TODO
                squareImage: media, // コレクションのスクエア画像
                bannerImage: media, // コレクションのバナー画像
                // SNSなど
                socials: {
                    "twitter": MetadataViews.ExternalURL("https://twitter.com/xxxxxx") // TODO
                }
            )
          // key-valueで取り出せる属性的なやつ // TODO
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
      MetadataViews.ResolverCollection 
    {
      // NonFungibleToken.Collection override
      pub var ownedNFTs: @{UInt64: NonFungibleToken.NFT}

      init() {
        self.ownedNFTs <- {}
      }

      // NonFungibleToken.Provider override
      pub fun withdraw(withdrawID: UInt64): @NonFungibleToken.NFT {
        let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")

        emit Withdraw(id: token.id, from: self.owner?.address)

        return <-token
      }

      // NonFungibleToken.Receiver override
      pub fun deposit(token: @NonFungibleToken.NFT) {
        let token <- token as! @GachaNFT.NFT // important! castする必要がある

        let id: UInt64 = token.id

        // add the new token to the dictionary which removes the old one
        let oldToken <- self.ownedNFTs[id] <- token

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
          return gachaNFT as &AnyResource{MetadataViews.Resolver}
      }

      destroy() {
          destroy self.ownedNFTs
      }
    }

    pub resource NFTMinter {
      
    }

    init() {
      self.totalSupply = 0
      
      self.CollectionStoragePath = StoragePath(identifier: "GachaNFTCollection") ?? panic("can not specify storage path.")
      self.CollectionPublicPath = PublicPath(identifier: "GachaNFTCollection") ?? panic("can not specify public path.")
      self.MinterStoragePath = StoragePath(identifier: "GachaNFTMinter") ?? panic("can not specify storage path.")
    }
}
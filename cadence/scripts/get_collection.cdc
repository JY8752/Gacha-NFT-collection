import GachaNFT from "../contracts/GachaNFT.cdc"
import MetadataViews from "../contracts/lib/MetadataViews.cdc"

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
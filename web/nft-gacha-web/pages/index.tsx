import Image from 'next/image';
import { useGacha } from '../hooks/useGacha';

const Home = () => {
  const addr = '0x823341d5284d4fc1';
  const increceEvent = `A.${process.env.NEXT_PUBLIC_GACHA_CONTRACT_ADDRESS}.GachaNFT.Increce`;

  const {
    getAmounts,
    getIds,
    getCollection,
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
  } = useGacha(addr);

  const buyGacha = async () => {
    const transaction = await lotteryMint(addr);
    setCollectionItems(await getCollectionOwnedMap());
    const getId =
      transaction.events.find((tx) => tx.type === increceEvent)?.data.id ?? '';
    alert(`
      Get Item!!
      item id: ${getId}
    `);
  };

  return (
    <>
      <h1 className="text-3xl">Scripts/Transactions</h1>
      <div>
        <button
          className="m-2 rounded bg-green-400 p-2 hover:bg-green-300"
          onClick={() => getAmounts(addr)}
        >
          getItems
        </button>
        <button
          className="m-2 rounded bg-green-400 p-2 hover:bg-green-300"
          onClick={() => getIds()}
        >
          getIds
        </button>
        <button
          className="m-2 rounded bg-green-400 p-2 hover:bg-green-300"
          onClick={() => getCollection(addr)}
        >
          getCollection
        </button>
        <button
          className="m-2 rounded bg-green-400 p-2 hover:bg-green-300"
          onClick={() => console.log(getCollectionOwnedMap())}
        >
          getCollectionOwnedMap
        </button>
        <button
          className="m-2 rounded bg-green-400 p-2 hover:bg-green-300"
          onClick={() => setupCollection()}
        >
          setupCollection
        </button>
        <button
          className="m-2 rounded bg-green-400 p-2 hover:bg-green-300"
          onClick={() => lotteryMint(addr)}
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
          onClick={() => removeMinter()}
        >
          removeMinter
        </button>
        <button
          className="m-2 rounded bg-red-400 p-2 hover:bg-red-300"
          onClick={() => unlink()}
        >
          unlink
        </button>
      </div>
      <div className="flex flex-col items-center">
        <Image
          src={'/gachagacha.png'}
          height={400}
          width={300}
          alt={'gachagacha'}
          priority={true}
        />
        <button
          className="mt-2 rounded bg-indigo-500 p-3 hover:bg-indigo-400"
          onClick={buyGacha}
        >
          ガチャを引く
        </button>
      </div>
      <h1 className="text-3xl">Collection</h1>
      <div className="flex">
        {collectionItems.map((item) => {
          if (item.amount !== 0) {
            return (
              <div className="m-1 w-60 rounded bg-blue-300 p-3" key={item.id}>
                <div className="relative h-96 max-w-full">
                  <Image
                    src={`https://cloudflare-ipfs.com/ipfs/${item.thumbnail}`}
                    fill
                    style={{
                      objectFit: 'contain',
                    }}
                    alt={'collection item'}
                    sizes="(max-width: 768px) 100vw,
                    (max-width: 1200px) 50vw,
                    33vw"
                  />
                </div>
                <p>id: {item.id}</p>
                <p>name: {item.name ?? ''}</p>
                <p>description: {item.description ?? ''}</p>
                <p>amount: {item.amount}</p>
                <p className="overflow-x-auto">
                  thumbnail: {item.thumbnail ?? ''}
                </p>
              </div>
            );
          } else {
            return (
              <div className="m-1 w-60 rounded bg-gray-400 p-3">
                <p>id: {item.id}</p>
                <p className="text-2xl">Don't have yet!!</p>
              </div>
            );
          }
        })}
      </div>
    </>
  );
};

export default Home;

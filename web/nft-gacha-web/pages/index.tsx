import Image from 'next/image';
import { useGacha } from '../hooks/useGacha';

const Home = () => {
  const addr = '0x823341d5284d4fc1';

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
    amounts,
    setAmounts,
    ids,
    setIds,
    collection,
    setCollection,
  } = useGacha(addr);

  return (
    <>
      <h1 className="text-xl">Scripts/Transactions</h1>
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
        <button className="mt-2 rounded bg-indigo-500 p-3 hover:bg-indigo-400">
          ガチャを引く
        </button>
      </div>
    </>
  );
};

export default Home;

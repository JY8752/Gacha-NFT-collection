import Head from 'next/head';
import { useConnect } from '../hooks/useConnect';

const Header = () => {
  const { user, unauthenticate, logIn, signUp } = useConnect();

  // 認証済み
  const AuthedState = () => {
    return (
      <div className="flex items-center">
        <div className="p-3">My Address: {user?.addr ?? 'No Address'}</div>
        <button
          onClick={unauthenticate}
          className="m-4 ml-2 cursor-pointer rounded border-none bg-blue-700 p-3 hover:bg-blue-300"
        >
          Log Out
        </button>
      </div>
    );
  };

  // 未認証
  const UnauthenticatedState = () => {
    return (
      <div className="flex items-center">
        <button
          onClick={logIn}
          className="m-4 cursor-pointer rounded border-none bg-blue-700 p-3 hover:bg-blue-300"
        >
          Log In
        </button>
        <button
          onClick={signUp}
          className="m-4 cursor-pointer rounded border-none bg-blue-700 p-3 hover:bg-blue-300"
        >
          Sign Up
        </button>
      </div>
    );
  };

  return (
    <div className="flex h-20 justify-between bg-slate-700 align-middle">
      <Head>
        <title>FCL Quickstart with NextJS</title>
        <meta name="description" content="My first web3 app on Flow!" />
        <link rel="icon" href="/favicon.ico" />
      </Head>
      <div className="flex items-center">
        <h1 className="p-2 text-3xl text-blue-300">Flow App</h1>
      </div>
      {user.loggedIn ? <AuthedState /> : <UnauthenticatedState />}
    </div>
  );
};

export default Header;

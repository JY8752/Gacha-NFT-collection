import Head from 'next/head';
import '../flow/config';
import * as fcl from '@onflow/fcl';
import { useEffect, useState } from 'react';

type User = {
  loggedIn?: any;
  addr: any;
};

export default function Home() {
  const [user, setUser] = useState<User>({ loggedIn: null, addr: null });

  useEffect(() => fcl.currentUser.subscribe(setUser), []);

  const AuthedState = () => {
    return (
      <div>
        <div>Address: {user?.addr ?? 'No Address'}</div>
        <button onClick={fcl.unauthenticate}>Log Out</button>
      </div>
    );
  };

  const UnauthenticatedState = () => {
    return (
      <div>
        <button onClick={fcl.logIn}>Log In</button>
        <button onClick={fcl.signUp}>Sign Up</button>
      </div>
    );
  };

  return (
    <div>
      <Head>
        <title>FCL Quickstart with NextJS</title>
        <meta name="description" content="My first web3 app on Flow!" />
        <link rel="icon" href="/favicon.png" />
      </Head>
      <h1 className="text-3xl text-blue-300">Flow App</h1>
      {user.loggedIn ? <AuthedState /> : <UnauthenticatedState />}
    </div>
  );
}

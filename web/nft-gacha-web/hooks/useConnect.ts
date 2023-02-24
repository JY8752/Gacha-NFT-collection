import { useEffect, useState } from 'react';
import * as fcl from '@onflow/fcl';

type User = {
  loggedIn?: any;
  addr: any;
};

export const useConnect = () => {
  const [user, setUser] = useState<User>({ loggedIn: null, addr: null });

  useEffect(() => fcl.currentUser.subscribe(setUser), []);

  return {
    user,
    unauthenticate: fcl.unauthenticate,
    logIn: fcl.logIn,
    signUp: fcl.signUp,
  };
};

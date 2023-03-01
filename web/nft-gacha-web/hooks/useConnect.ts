import { createContext, useEffect, useState } from 'react';
import * as fcl from '@onflow/fcl';

type User = {
  loggedIn?: boolean;
  addr?: string;
};

type UserContext = {
  user?: User;
  unauthenticate?: () => void;
  logIn?: () => void;
  signUp?: () => void;
};

export const UserContext = createContext<UserContext>({});

export const useConnect = () => {
  const [user, setUser] = useState<User>({
    loggedIn: undefined,
    addr: undefined,
  });

  useEffect(() => fcl.currentUser.subscribe(setUser), []);

  return {
    user,
    unauthenticate: fcl.unauthenticate,
    logIn: fcl.logIn,
    signUp: fcl.signUp,
  };
};

import '@/styles/globals.css';
import type { AppProps } from 'next/app';
import { Layout } from '../components/Layout';
import '../flow/config';
import { useConnect, UserContext } from '../hooks/useConnect';

export default function App({ Component, pageProps }: AppProps) {
  const { user, unauthenticate, logIn, signUp } = useConnect();

  return (
    <UserContext.Provider value={{ user, unauthenticate, logIn, signUp }}>
      <Layout>
        <Component {...pageProps} />
      </Layout>
    </UserContext.Provider>
  );
}

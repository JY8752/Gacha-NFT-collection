import { ReactElement } from 'react';
import Header from './Header';

type LayoutProps = Required<{
  readonly children: ReactElement;
}>;

export const Layout = ({ children }: LayoutProps) => (
  <div className="container mx-auto p-5">
    <Header />
    {children}
  </div>
);

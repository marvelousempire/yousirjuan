import type { Metadata } from 'next';
import './globals.css';
import { SessionProvider } from './session-provider';

export const metadata: Metadata = {
  title: 'You-Sir Juan',
  description: 'Family Interface — your Associate Agent, your world.',
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body>
        <SessionProvider>{children}</SessionProvider>
      </body>
    </html>
  );
}

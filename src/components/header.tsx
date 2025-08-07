import { WalletButton } from '@/components/wallet-button';

export function Header() {
  return (
    <header className="flex justify-between items-center py-4 w-full">
      <h1 className="text-xl font-bold">Hedera Agent Kit Next.js Demo</h1>
      <WalletButton />
    </header>
  );
}

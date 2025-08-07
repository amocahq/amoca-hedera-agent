'use client';


import { useDAppConnector } from './client-providers';

export function WalletButton() {
  const connector = useDAppConnector();
  const baseButtonClasses = 'truncate bg-zinc-600 py-1 px-4 rounded-md';

  // If context is not ready yet, show loading
  if (!connector) {
    return (
      <button
        className={`${baseButtonClasses} cursor-not-allowed opacity-60`}
        disabled
        aria-disabled="true"
      >
        Loading wallet...
      </button>
    );
  }

  const { dAppConnector, userAccountId, disconnect, refresh } = connector;

  const handleLogin = async () => {
    if (!dAppConnector) return;
    try {
      await dAppConnector.openModal();
      refresh?.();
    } catch (err) {
      console.error('Wallet connection failed:', err);
    }
  };

  const handleDisconnect = async () => {
    if (!disconnect) return;
    try {
      await disconnect();
    } catch (err) {
      console.error('Wallet disconnect failed:', err);
    }
  };

  if (!userAccountId) {
    return (
      <button
        className={`${baseButtonClasses} cursor-pointer`}
        onClick={handleLogin}
        disabled={!dAppConnector}
        aria-disabled={!dAppConnector}
      >
        Log in
      </button>
    );
  }

  return (
    <button
      className={`${baseButtonClasses} cursor-pointer`}
      onClick={handleDisconnect}
      disabled={!dAppConnector}
      aria-disabled={!dAppConnector}
      title={`Disconnect from ${userAccountId}`}
    >
      {`Disconnect (${userAccountId})`}
    </button>
  );
}

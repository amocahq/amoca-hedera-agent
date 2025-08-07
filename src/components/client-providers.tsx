'use client';

import { ReactNode, useEffect, useState, createContext, useContext } from 'react';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import {
  HederaSessionEvent,
  HederaJsonRpcMethod,
  DAppConnector,
  HederaChainId,
} from '@hashgraph/hedera-wallet-connect';
import { LedgerId } from '@hashgraph/sdk';
import { Loading } from './loading';

const projectId = process.env.NEXT_PUBLIC_WALLET_CONNECT_ID;
if (!projectId) {
  throw new Error('NEXT_PUBLIC_WALLET_CONNECT_ID is not set');
}

const queryClient = new QueryClient();

const metadata = {
  name: 'AgentKit Next.js Demo',
  description: 'AgentKit Next.js Demo',
  url: 'https://example.com',
  icons: ['https://avatars.githubusercontent.com/u/179229932'],
};

type DAppConnectorContextType = {
  dAppConnector: DAppConnector | null;
  userAccountId: string | null;
  sessionTopic: string | null;
  disconnect: (() => Promise<void>) | null;
  refresh: (() => void) | null;
};

const DAppConnectorContext = createContext<DAppConnectorContextType | null>(null);
export const useDAppConnector = () => {
  const context = useContext(DAppConnectorContext);
  if (!context) {
    throw new Error('useDAppConnector must be used within a ClientProviders');
  }
  return context;
};

type ClientProvidersProps = {
  children: ReactNode;
};

export function ClientProviders({ children }: ClientProvidersProps) {
  const [dAppConnector, setDAppConnector] = useState<DAppConnector | null>(null);
  const [isReady, setIsReady] = useState(false);
  const [userAccountId, setUserAccountId] = useState<string | null>(null);
  const [sessionTopic, setSessionTopic] = useState<string | null>(null);

  useEffect(() => {
    let isMounted = true;
    async function init() {
      try {
        const connector = new DAppConnector(
          metadata,
          LedgerId.TESTNET,
          projectId!,
          Object.values(HederaJsonRpcMethod),
          [HederaSessionEvent.ChainChanged, HederaSessionEvent.AccountsChanged],
          [HederaChainId.Mainnet, HederaChainId.Testnet],
        );
        await connector.init();
        if (isMounted) {
          setDAppConnector(connector);
          setIsReady(true);
        }
      } catch (error) {
        console.error('Failed to initialize DAppConnector:', error);
      }
    }
    init();
    return () => {
      isMounted = false;
    };
  }, []);

  useEffect(() => {
    if (!dAppConnector) return;

    const handleAccountsChanged = (data: any) => {
      setUserAccountId(dAppConnector.signers?.[0]?.getAccountId().toString() ?? null);
      if (data?.topic) {
        setSessionTopic(data.topic);
      } else if (dAppConnector.signers?.[0]?.topic) {
        setSessionTopic(dAppConnector.signers[0].topic);
      } else {
        setSessionTopic(null);
      }
    };

    const handleSessionDelete = () => {
      setUserAccountId(null);
      setSessionTopic(null);
    };

    const subscription = (dAppConnector as any).events$?.subscribe(
      (event: { name: string; data: any }) => {
        switch (event.name) {
          case 'accountsChanged':
          case 'chainChanged':
            handleAccountsChanged(event.data);
            break;
          case 'session_delete':
          case 'sessionDelete':
            handleSessionDelete();
            break;
          default:
            break;
        }
      },
    );

    // Set initial state
    setUserAccountId(dAppConnector.signers?.[0]?.getAccountId().toString() ?? null);
    if (dAppConnector.signers?.[0]?.topic) {
      setSessionTopic(dAppConnector.signers[0].topic);
    }

    return () => subscription?.unsubscribe();
  }, [dAppConnector]);

  const disconnect = async () => {
    if (dAppConnector && sessionTopic) {
      try {
        await dAppConnector.disconnect(sessionTopic);
      } catch (error) {
        console.error('Failed to disconnect:', error);
      } finally {
        setUserAccountId(null);
        setSessionTopic(null);
      }
    }
  };

  const refresh = () => {
    if (dAppConnector) {
      setUserAccountId(dAppConnector.signers?.[0]?.getAccountId().toString() ?? null);
      setSessionTopic(dAppConnector.signers?.[0]?.topic ?? null);
    }
  };

  if (!isReady) return <Loading />;

  return (
    <DAppConnectorContext.Provider
      value={{ dAppConnector, userAccountId, sessionTopic, disconnect, refresh }}
    >
      <QueryClientProvider client={queryClient}>{children}</QueryClientProvider>
    </DAppConnectorContext.Provider>
  );
}

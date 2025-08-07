'use client';

import { ChatMessage } from '@/shared/types';
import { useState, useEffect, useRef, useCallback } from 'react';
import { useHandleChat } from '@/lib/handle-chat';
import { ChatInput } from '@/components/chat-input';
import { Header } from '@/components/header';
import { useDAppConnector } from '@/components/client-providers';
import { Chat } from '@/components/chat';

export default function Home() {
  const [chatHistory, setChatHistory] = useState<ChatMessage[]>([]);
  const [prompt, setPrompt] = useState('');
  const { mutateAsync, isPending } = useHandleChat();
  const { dAppConnector, userAccountId } = useDAppConnector();
  const chatContainerRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (chatContainerRef.current) {
      chatContainerRef.current.scrollTop = chatContainerRef.current.scrollHeight;
    }
  }, [chatHistory]);

  const handleUserMessage = useCallback(async () => {
    if (!prompt.trim()) return;

    const currentPrompt = prompt;
    setPrompt('');

    setChatHistory((prev) => [...prev, { type: 'human', content: currentPrompt }]);

    try {
      if (!userAccountId) {
        throw new Error('User is not connected.');
      }

      const agentResponse = await mutateAsync({
        userAccountId,
        input: currentPrompt,
        history: chatHistory,
      });

      setChatHistory((prev) => [...prev, { type: 'ai', content: agentResponse.message }]);

      if (agentResponse.transactionBytes) {
        const result = await dAppConnector?.signAndExecuteTransaction({
          signerAccountId: userAccountId,
          transactionList: agentResponse.transactionBytes,
        });

        const transactionId = result && 'transactionId' in result ? result.transactionId : null;

        setChatHistory((prev) => [
          ...prev,
          {
            type: 'ai',
            content: `Transaction signed and executed successfully, txId: ${transactionId}`,
          },
        ]);
      }
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'An unknown error occurred.';
      setChatHistory((prev) => [...prev, { type: 'ai', content: `Error: ${errorMessage}` }]);
    }
  }, [prompt, userAccountId, mutateAsync, chatHistory, dAppConnector]);

  return (
    <div className="h-screen w-full bg-zinc-900 flex items-center justify-center flex-col">
      <main className="w-full max-w-4xl h-full flex flex-col">
        <Header />

        <div ref={chatContainerRef} className="flex-grow overflow-y-auto">
          <Chat chatHistory={chatHistory} isLoading={isPending} />
        </div>

        <ChatInput
          handleUserMessage={handleUserMessage}
          prompt={prompt}
          setPrompt={setPrompt}
          isPending={isPending}
        />
      </main>
    </div>
  );
}

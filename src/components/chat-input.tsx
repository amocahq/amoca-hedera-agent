'use client';

import { Dispatch, SetStateAction } from 'react';

type ChatInputProps = {
  isPending: boolean;
  prompt: string;
  setPrompt: Dispatch<SetStateAction<string>>;
  handleUserMessage: () => void;
};

export function ChatInput({ handleUserMessage, setPrompt, isPending, prompt }: ChatInputProps) {
  const handleSubmit = (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    if (prompt.trim()) {
      handleUserMessage();
    }
  };

  return (
    <form className="flex py-4 gap-3" onSubmit={handleSubmit}>
      <input
        disabled={isPending}
        className="grow bg-zinc-700 rounded-lg pl-2"
        value={prompt}
        onChange={(e) => setPrompt(e.target.value)}
        placeholder="Ask me anything about Hedera..."
        aria-label="Chat input"
      />
      <button
        disabled={isPending || !prompt.trim()}
        type="submit"
        className="bg-zinc-700 rounded-lg px-4 py-2 disabled:opacity-50 disabled:cursor-not-allowed"
        aria-label="Send message"
      >
        Send
      </button>
    </form>
  );
}

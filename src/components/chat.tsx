import { LoaderCircle } from 'lucide-react';
import { EmptyChat } from '@/components/empty-chat';
import { ChatMessage as ChatMessageType } from '@/shared/types';
import { ChatMessage } from './chat-message';

type ChatProps = {
  isLoading: boolean;
  chatHistory: ChatMessageType[];
};

export function Chat({ chatHistory, isLoading }: ChatProps) {
  return (
    <div className="bg-zinc-800 grow rounded-lg flex flex-col gap-2 p-4 overflow-y-auto">
      {chatHistory.map((message, idx) => (
        <ChatMessage key={idx} message={message} />
      ))}

      {isLoading && (
        <div>
          <div className="bg-zinc-700 inline-block px-4 py-2 rounded-md">
            <LoaderCircle className="animate-spin" />
          </div>
        </div>
      )}

      <EmptyChat isChatEmpty={chatHistory.length <= 0} />
    </div>
  );
}

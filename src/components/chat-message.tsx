import { ChatMessage as ChatMessageType } from '@/shared/types';

type ChatMessageProps = {
  message: ChatMessageType;
};

export function ChatMessage({ message }: ChatMessageProps) {
  const isHuman = message.type === 'human';
  const bubbleClasses = `inline-block px-4 py-2 rounded-md ${
    isHuman ? 'bg-zinc-700 ml-auto' : 'bg-zinc-700 break-all'
  }`;

  return (
    <div className="flex">
      <div className={bubbleClasses}>{message.content}</div>
    </div>
  );
}

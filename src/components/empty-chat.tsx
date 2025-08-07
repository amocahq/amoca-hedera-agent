type EmptyChatProps = {
  isChatEmpty: boolean;
};

export function EmptyChat({ isChatEmpty }: EmptyChatProps) {
  if (!isChatEmpty) {
    return null;
  }

  return (
    <div className="flex items-center justify-center h-full opacity-30">
      <p>No messages, ask the chat about something e.g. your HBAR balance</p>
    </div>
  );
}

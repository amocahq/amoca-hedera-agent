import { z } from 'zod';
import { useMutation } from '@tanstack/react-query';
import { ChatRequest } from '@/shared/types';

const chatResponseSchema = z.object({
  message: z.string(),
  transactionBytes: z.string().optional(),
});

export type ChatResponse = z.infer<typeof chatResponseSchema>;

export async function handleChatRequest(body: ChatRequest): Promise<ChatResponse> {
  try {
    const response = await fetch('/api/chat', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(body),
    });

    if (!response.ok) {
      const errorText = await response.text();
      throw new Error(`Network response was not ok: ${errorText}`);
    }

    const rawData = await response.json();
    return chatResponseSchema.parse(rawData);
  } catch (error) {
    console.error('There was a problem with the fetch operation:', error);
    throw error;
  }
}

export function useHandleChat() {
  return useMutation<ChatResponse, Error, ChatRequest>({
    mutationKey: ['handle-ai-chat'],
    mutationFn: handleChatRequest,
  });
}

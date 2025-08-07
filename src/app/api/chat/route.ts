import { handleChatBodySchema } from '@/server/schema';
import { initializeAgent } from '@/server/initialize-agent';
import { NextRequest, NextResponse } from 'next/server';
import { AgentExecutor } from 'langchain/agents';

export const runtime = 'nodejs';

type ResponseData = {
  message: string;
  transactionBytes?: string;
};

function extractBytesFromAgentResponse(response: any): string | undefined {
  if (
    response.intermediateSteps &&
    response.intermediateSteps.length > 0 &&
    response.intermediateSteps[0].observation
  ) {
    const obs = response.intermediateSteps[0].observation;
    try {
      const obsObj = typeof obs === 'string' ? JSON.parse(obs) : obs;
      if (obsObj.bytes) {
        const bytes = obsObj.bytes;
        const buffer = Buffer.isBuffer(bytes) ? bytes : Buffer.from(bytes.data ?? bytes);
        return buffer.toString('base64');
      }
    } catch (e) {
      console.error('Error parsing observation:', e);
    }
  }
  return undefined;
}

async function getAgentExecutor(userAccountId: string): Promise<AgentExecutor> {
  // This could be extended to cache the agent executor
  return initializeAgent(userAccountId);
}

export async function POST(req: NextRequest) {
  try {
    const data = await req.json();
    const parsedBody = handleChatBodySchema.safeParse(data);

    if (!parsedBody.success) {
      return NextResponse.json({ message: 'Invalid request body' }, { status: 400 });
    }

    const { userAccountId, input, history } = parsedBody.data;
    const agentExecutor = await getAgentExecutor(userAccountId);

    const agentResponse = await agentExecutor.invoke({
      input,
      chat_history: history,
    });

    const response: ResponseData = {
      message: agentResponse.output ?? 'No response from agent.',
    };

    const transactionBytes = extractBytesFromAgentResponse(agentResponse);
    if (transactionBytes) {
      response.transactionBytes = transactionBytes;
      response.message = 'Please sign the transaction to proceed.';
    }

    return NextResponse.json(response);
  } catch (error) {
    console.error('Error in chat API:', error);
    const errorMessage = error instanceof Error ? error.message : 'An unknown error occurred.';
    return NextResponse.json({ message: `Internal Server Error: ${errorMessage}` }, { status: 500 });
  }
}
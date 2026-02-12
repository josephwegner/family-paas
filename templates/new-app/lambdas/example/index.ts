import type { APIGatewayProxyEvent, APIGatewayProxyResult, Context } from 'aws-lambda';
import { createSuccessResponse, createErrorResponse } from '@family-paas/lambda-response';

export const handler = async (
  event: APIGatewayProxyEvent,
  context: Context
): Promise<APIGatewayProxyResult> => {
  try {
    return createSuccessResponse({ message: 'Hello from your new app!' });
  } catch (error) {
    return createErrorResponse(500, 'Internal server error', error);
  }
};

import type { APIGatewayProxyResult } from 'aws-lambda';

const CORS_HEADERS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'Content-Type',
  'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
};

export function createSuccessResponse(
  data: any,
  statusCode: number = 200
): APIGatewayProxyResult {
  return {
    statusCode,
    headers: {
      'Content-Type': 'application/json',
      ...CORS_HEADERS,
    },
    body: JSON.stringify(data),
  };
}

export function createErrorResponse(
  statusCode: number,
  message: string,
  error?: any
): APIGatewayProxyResult {
  console.error('Error response:', { statusCode, message, error });
  return {
    statusCode,
    headers: {
      'Content-Type': 'application/json',
      ...CORS_HEADERS,
    },
    body: JSON.stringify({
      error: message,
      ...(process.env.NODE_ENV === 'development' && error
        ? { details: error.message }
        : {}),
    }),
  };
}

import { Request, Response } from 'express';
import {
  APIGatewayProxyEvent,
  APIGatewayProxyResult,
  Context,
} from 'aws-lambda';

export interface SimulatorOptions {
  simulateAuth?: boolean;
}

function decodeJwtPayload(token: string): Record<string, unknown> | null {
  try {
    const parts = token.split('.');
    if (parts.length !== 3) return null;
    const payload = Buffer.from(parts[1], 'base64url').toString('utf-8');
    return JSON.parse(payload);
  } catch {
    return null;
  }
}

export async function simulateLambda(
  handler: (
    event: APIGatewayProxyEvent,
    context: Context
  ) => Promise<APIGatewayProxyResult>,
  req: Request,
  res: Response,
  options?: SimulatorOptions
): Promise<void> {
  const event: APIGatewayProxyEvent = {
    resource: req.route?.path || '',
    path: req.path,
    httpMethod: req.method,
    headers: req.headers as { [key: string]: string },
    multiValueHeaders: {},
    queryStringParameters: (req.query as any) || null,
    multiValueQueryStringParameters: null,
    pathParameters: req.params || null,
    stageVariables: null,
    requestContext: {
      accountId: 'local',
      apiId: 'local',
      protocol: 'HTTP/1.1',
      httpMethod: req.method,
      path: req.path,
      stage: 'local',
      requestId: `local-${Date.now()}`,
      requestTime: new Date().toISOString(),
      requestTimeEpoch: Date.now(),
      identity: {
        sourceIp: req.ip || '127.0.0.1',
        userAgent: req.get('user-agent') || '',
      },
    } as any,
    body: req.body ? JSON.stringify(req.body) : null,
    isBase64Encoded: false,
  };

  if (options?.simulateAuth) {
    const authHeader = req.headers['authorization'] as string | undefined;
    if (authHeader?.startsWith('Bearer ')) {
      const claims = decodeJwtPayload(authHeader.slice(7));
      if (claims) {
        (event.requestContext as any).authorizer = {
          jwt: { claims, scopes: [] },
        };
      }
    }
  }

  const context: Context = {
    callbackWaitsForEmptyEventLoop: true,
    functionName: 'local-dev',
    functionVersion: '$LATEST',
    invokedFunctionArn:
      'arn:aws:lambda:local:000000000000:function:local-dev',
    memoryLimitInMB: '512',
    awsRequestId: `local-${Date.now()}`,
    logGroupName: '/aws/lambda/local-dev',
    logStreamName: 'local-stream',
    getRemainingTimeInMillis: () => 30000,
    done: () => {},
    fail: () => {},
    succeed: () => {},
  };

  try {
    const result = await handler(event, context);

    res.status(result.statusCode);

    if (result.headers) {
      Object.entries(result.headers).forEach(([key, value]) => {
        res.setHeader(key, value as string);
      });
    }

    res.send(result.body);
  } catch (error) {
    console.error('Lambda simulation error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
}

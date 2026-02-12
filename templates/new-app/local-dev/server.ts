import dotenv from 'dotenv';
dotenv.config();

import express from 'express';
import cors from 'cors';
import { simulateLambda } from '@family-paas/lambda-simulator';

import { handler as exampleHandler } from '../lambdas/example/index.js';

const app = express();
const PORT = process.env.PORT || 3001;

app.use(cors());
app.use(express.json());

app.get('/health', (req, res) => {
  res.json({ status: 'ok' });
});

app.get('/api/example', async (req, res) => {
  await simulateLambda(exampleHandler, req, res);
});

app.listen(PORT, () => {
  console.log(`Local dev server running on http://localhost:${PORT}`);
});

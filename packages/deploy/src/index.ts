#!/usr/bin/env node

import { readFileSync, rmSync, mkdirSync, existsSync } from 'fs';
import { execSync } from 'child_process';
import { resolve, join } from 'path';

interface AppConfig {
  name: string;
  environment: string;
  region: string;
  lambdas: string[];
  frontend: {
    buildCommand: string;
    distDir: string;
  };
  esbuild?: {
    target?: string;
    external?: string[];
  };
}

function run(cmd: string, opts?: { cwd?: string }) {
  console.log(`  $ ${cmd}`);
  execSync(cmd, { stdio: 'inherit', cwd: opts?.cwd });
}

function loadConfig(cwd: string): AppConfig {
  const configPath = join(cwd, 'app.config.json');
  if (!existsSync(configPath)) {
    console.error('Error: app.config.json not found in current directory');
    process.exit(1);
  }
  return JSON.parse(readFileSync(configPath, 'utf-8'));
}

function getAccountId(): string {
  return execSync('aws sts get-caller-identity --query Account --output text')
    .toString()
    .trim();
}

function buildLambdas(config: AppConfig, cwd: string) {
  console.log('\n== Building Lambda functions ==\n');

  const outputDir = join(cwd, 'dist/lambdas');
  if (existsSync(outputDir)) {
    rmSync(outputDir, { recursive: true });
  }
  mkdirSync(outputDir, { recursive: true });

  const target = config.esbuild?.target || 'node20';
  const externals = (config.esbuild?.external || ['aws-sdk', 'aws-lambda'])
    .map((e) => `--external:${e}`)
    .join(' ');

  for (const lambda of config.lambdas) {
    console.log(`Building ${lambda}...`);
    const lambdaDir = join(outputDir, lambda);
    mkdirSync(lambdaDir, { recursive: true });

    run(
      `npx esbuild "lambdas/${lambda}/index.ts" --bundle --platform=node --target=${target} ${externals} --outfile="${join(lambdaDir, 'index.js')}"`,
      { cwd }
    );

    run(`cd "${lambdaDir}" && zip -r "../${lambda}.zip" .`);
    console.log(`  Created dist/lambdas/${lambda}.zip\n`);
  }
}

function uploadLambdas(config: AppConfig, cwd: string) {
  console.log('\n== Uploading Lambda packages to S3 ==\n');

  const accountId = getAccountId();
  const bucket = `lambda-deployments-${accountId}`;

  for (const lambda of config.lambdas) {
    console.log(`Uploading ${lambda}...`);
    run(
      `aws s3 cp "dist/lambdas/${lambda}.zip" "s3://${bucket}/${config.name}/${config.environment}/${lambda}.zip"`,
      { cwd }
    );
  }
}

function updateLambdas(config: AppConfig, cwd: string) {
  console.log('\n== Updating Lambda function code ==\n');

  const accountId = getAccountId();
  const bucket = `lambda-deployments-${accountId}`;

  for (const lambda of config.lambdas) {
    const functionName = `${config.name}-${lambda}-${config.environment}`;
    const s3Key = `${config.name}/${config.environment}/${lambda}.zip`;

    console.log(`Updating ${functionName}...`);
    run(
      `aws lambda update-function-code --function-name "${functionName}" --s3-bucket "${bucket}" --s3-key "${s3Key}" --output json > /dev/null`,
      { cwd }
    );
  }
}

function deployFrontend(config: AppConfig, cwd: string) {
  console.log('\n== Building & deploying frontend ==\n');

  console.log('Building frontend...');
  run(config.frontend.buildCommand, { cwd });

  const accountId = getAccountId();
  const bucket = `${config.name}-frontend-${config.environment}-${accountId}`;

  console.log(`\nUploading to s3://${bucket}/...`);
  run(`aws s3 sync "${config.frontend.distDir}/" "s3://${bucket}/" --delete`, {
    cwd,
  });
}

function main() {
  const cwd = process.cwd();
  const config = loadConfig(cwd);

  const mode = process.argv[2] || 'all';

  console.log(`\n  Deploying: ${config.name}`);
  console.log(`  Environment: ${config.environment}`);
  console.log(`  Mode: ${mode}\n`);

  if (mode === 'all' || mode === '--lambdas-only') {
    buildLambdas(config, cwd);
    uploadLambdas(config, cwd);
    updateLambdas(config, cwd);
  }

  if (mode === 'all' || mode === '--frontend-only') {
    deployFrontend(config, cwd);
  }

  console.log('\n  Deploy complete!\n');
}

main();

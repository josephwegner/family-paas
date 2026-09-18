#!/usr/bin/env node

import { readFileSync, rmSync, mkdirSync, existsSync } from 'fs';
import { execFileSync, execSync } from 'child_process';
import { resolve, join } from 'path';

export interface AppConfig {
  name: string;
  tenantId: string;
  workloadAccountId: string;
  environment: string;
  region: string;
  terraform: {
    stateBucket: string;
    stateRegion: string;
    statePrefix: string;
    stateRoleArn: string;
  };
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

function requireString(value: unknown, path: string): asserts value is string {
  if (typeof value !== 'string' || value.trim() === '') {
    throw new Error(`Invalid app.config.json: ${path} must be a non-empty string`);
  }
}

export function validateConfig(value: unknown): AppConfig {
  if (typeof value !== 'object' || value === null || Array.isArray(value)) {
    throw new Error('Invalid app.config.json: expected an object');
  }

  const config = value as Record<string, unknown>;
  for (const key of ['name', 'tenantId', 'workloadAccountId', 'environment', 'region']) {
    requireString(config[key], key);
  }
  if (!/^[0-9]{12}$/.test(config.workloadAccountId as string)) {
    throw new Error('Invalid app.config.json: workloadAccountId must be a 12-digit AWS account ID');
  }
  if (!Array.isArray(config.lambdas) || !config.lambdas.every((item) => typeof item === 'string')) {
    throw new Error('Invalid app.config.json: lambdas must be an array of strings');
  }

  const terraform = config.terraform as Record<string, unknown> | undefined;
  const frontend = config.frontend as Record<string, unknown> | undefined;
  if (!terraform || !frontend) {
    throw new Error('Invalid app.config.json: terraform and frontend objects are required');
  }
  for (const key of ['stateBucket', 'stateRegion', 'statePrefix', 'stateRoleArn']) {
    requireString(terraform[key], `terraform.${key}`);
  }
  for (const key of ['buildCommand', 'distDir']) {
    requireString(frontend[key], `frontend.${key}`);
  }
  if (!(terraform.statePrefix as string).startsWith(`tenants/${config.tenantId}/`)) {
    throw new Error('Invalid app.config.json: terraform.statePrefix must be beneath tenants/<tenantId>/');
  }

  return value as AppConfig;
}

export function loadConfig(cwd: string): AppConfig {
  const configPath = join(cwd, 'app.config.json');
  if (!existsSync(configPath)) {
    throw new Error('app.config.json not found in current directory');
  }
  return validateConfig(JSON.parse(readFileSync(configPath, 'utf-8')));
}

export function getAccountId(): string {
  return execSync('aws sts get-caller-identity --query Account --output text')
    .toString()
    .trim();
}

export function assertExpectedAccount(expectedAccountId: string, actualAccountId: string) {
  if (actualAccountId !== expectedAccountId) {
    throw new Error(
      `AWS account mismatch: app requires ${expectedAccountId}, but the active session is ${actualAccountId}. No deployment work was started.`
    );
  }
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

  const bucket = `lambda-deployments-${config.workloadAccountId}`;

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

  const bucket = `lambda-deployments-${config.workloadAccountId}`;

  for (const lambda of config.lambdas) {
    const functionName = `${config.name}-${lambda}-${config.environment}`;
    const s3Key = `${config.name}/${config.environment}/${lambda}.zip`;

    console.log(`Updating ${functionName}...`);
    const update = JSON.parse(
      execSync(
        `aws lambda update-function-code --function-name "${functionName}" --s3-bucket "${bucket}" --s3-key "${s3Key}" --publish --output json`,
        { cwd }
      ).toString()
    ) as { Version?: string };
    if (!update.Version) {
      throw new Error(`Lambda did not return a published version for ${functionName}`);
    }
    run(
      `aws lambda update-alias --function-name "${functionName}" --name live --function-version "${update.Version}" --output json > /dev/null`,
      { cwd }
    );
  }
}

function deployFrontend(config: AppConfig, cwd: string) {
  console.log('\n== Building & deploying frontend ==\n');

  console.log('Building frontend...');
  run(config.frontend.buildCommand, { cwd });

  const bucket = `${config.name}-frontend-${config.environment}-${config.workloadAccountId}`;

  console.log(`\nUploading to s3://${bucket}/...`);
  run(`aws s3 sync "${config.frontend.distDir}/" "s3://${bucket}/" --delete`, {
    cwd,
  });
}

export function terraformInitArgs(config: AppConfig, terraformDir: string): string[] {
  const backendKey = `${config.terraform.statePrefix}/${config.name}/${config.environment}/terraform.tfstate`;
  return [
    `-chdir=${terraformDir}`,
    'init',
    '-reconfigure',
    `-backend-config=bucket=${config.terraform.stateBucket}`,
    `-backend-config=key=${backendKey}`,
    `-backend-config=region=${config.terraform.stateRegion}`,
    `-backend-config=assume_role={role_arn="${config.terraform.stateRoleArn}"}`,
    '-backend-config=encrypt=true',
    '-backend-config=use_lockfile=true',
  ];
}

function terraformInit(config: AppConfig, cwd: string) {
  const terraformDir = join(cwd, 'terraform');
  const args = terraformInitArgs(config, terraformDir);
  console.log(`  $ terraform ${args.join(' ')}`);
  execFileSync('terraform', args, { stdio: 'inherit', cwd });
}

export function main() {
  const cwd = process.cwd();
  const config = loadConfig(cwd);

  const mode = process.argv[2] || 'all';
  const modes = new Set([
    'all',
    '--lambdas-only',
    '--seed-lambdas',
    '--frontend-only',
    '--terraform-init',
  ]);
  if (!modes.has(mode)) {
    throw new Error(`Unsupported deployment mode: ${mode}`);
  }

  const accountId = getAccountId();
  assertExpectedAccount(config.workloadAccountId, accountId);

  console.log(`\n  Deploying: ${config.name}`);
  console.log(`  Environment: ${config.environment}`);
  console.log(`  Tenant: ${config.tenantId}`);
  console.log(`  AWS account: ${accountId}`);
  console.log(`  Mode: ${mode}\n`);

  if (mode === '--terraform-init') {
    terraformInit(config, cwd);
    return;
  }

  if (mode === 'all' || mode === '--lambdas-only' || mode === '--seed-lambdas') {
    buildLambdas(config, cwd);
    uploadLambdas(config, cwd);
  }

  if (mode === 'all' || mode === '--lambdas-only') {
    updateLambdas(config, cwd);
  }

  if (mode === 'all' || mode === '--frontend-only') {
    deployFrontend(config, cwd);
  }

  console.log('\n  Deploy complete!\n');
}

const entrypoint = process.argv[1] ? resolve(process.argv[1]) : '';
if (entrypoint === resolve(new URL(import.meta.url).pathname)) {
  try {
    main();
  } catch (error) {
    console.error(`Error: ${error instanceof Error ? error.message : String(error)}`);
    process.exitCode = 1;
  }
}

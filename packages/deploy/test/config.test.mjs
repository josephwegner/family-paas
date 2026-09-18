import assert from 'node:assert/strict';
import test from 'node:test';

import { assertExpectedAccount, terraformInitArgs, validateConfig } from '../dist/index.js';

const valid = {
  name: 'weather-app',
  tenantId: 'joe',
  workloadAccountId: '444455556666',
  environment: 'dev',
  region: 'us-east-1',
  terraform: {
    stateBucket: 'family-paas-state',
    stateRegion: 'us-east-1',
    statePrefix: 'tenants/joe/apps',
    stateRoleArn: 'arn:aws:iam::111122223333:role/family-paas-joe-state',
  },
  lambdas: ['current'],
  frontend: { buildCommand: 'npm run build', distDir: 'dist' },
};

test('accepts tenant-isolated configuration', () => {
  assert.equal(validateConfig(valid), valid);
});

test('rejects state outside the tenant prefix', () => {
  assert.throws(
    () => validateConfig({ ...valid, terraform: { ...valid.terraform, statePrefix: 'tenants/scott/apps' } }),
    /statePrefix/
  );
});

test('rejects malformed workload account IDs', () => {
  assert.throws(() => validateConfig({ ...valid, workloadAccountId: '123' }), /12-digit/);
});

test('fails closed when the active account differs', () => {
  assert.throws(() => assertExpectedAccount(valid.workloadAccountId, '777788889999'), /account mismatch/);
});

test('allows the configured workload account', () => {
  assert.doesNotThrow(() => assertExpectedAccount(valid.workloadAccountId, valid.workloadAccountId));
});

test('uses the nested S3 backend assume-role object', () => {
  const args = terraformInitArgs(valid, '/app/terraform');
  assert.ok(
    args.includes(
      '-backend-config=assume_role={role_arn="arn:aws:iam::111122223333:role/family-paas-joe-state"}'
    )
  );
  assert.ok(!args.some((arg) => arg.includes('assume_role.role_arn=')));
});

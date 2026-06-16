#!/usr/bin/env node
/**
 * Local verify gate — Gitea Actions + pre-push on operator Mac.
 * No network; fast checks only.
 */
import { readdir, readFile, stat } from 'node:fs/promises';
import { join } from 'node:path';

const ROOT = new URL('..', import.meta.url).pathname;
const SETUP = join(ROOT, 'docs/setup');
const FAIL = [];

async function mustExist(rel) {
  try {
    await stat(join(ROOT, rel));
  } catch {
    FAIL.push(`missing required file: ${rel}`);
  }
}

async function checkSetupIndex() {
  const readme = await readFile(join(SETUP, 'README.md'), 'utf8');
  const files = (await readdir(SETUP)).filter((f) => f.endsWith('.md') && f !== 'README.md');
  for (const f of files) {
    if (!readme.includes(f)) FAIL.push(`docs/setup/README.md missing index row for ${f}`);
  }
  if (!readme.includes('marvelousempire/yousirjuan')) {
    FAIL.push('setup README must cite marvelousempire/yousirjuan as Gitea master');
  }
}

async function checkNoSecrets() {
  const bad = [
    /BEGIN (RSA |OPENSSH |EC )?PRIVATE KEY/,
    /ghp_[A-Za-z0-9]{20,}/,
    /github_pat_[A-Za-z0-9_]+/,
    /x-access-token:[A-Za-z0-9]+@github/,
  ];
  const scan = ['docs/setup/README.md', 'docs/setup/23-forge-sync-automation.md'];
  for (const rel of scan) {
    const body = await readFile(join(ROOT, rel), 'utf8').catch(() => '');
    for (const re of bad) {
      if (re.test(body)) FAIL.push(`possible secret pattern in ${rel}`);
    }
  }
}

async function main() {
  await mustExist('.gitea/workflows/verify.yml');
  await mustExist('scripts/forge-sync.sh');
  await mustExist('scripts/forge-push.sh');
  await mustExist('scripts/forge-sync-core.sh');
  await mustExist('scripts/forge-pull-on-gitea.sh');
  await mustExist('artifacts/forge-sync-core.txt');
  await mustExist('Makefile');
  await checkSetupIndex();
  await checkNoSecrets();

  if (FAIL.length) {
    console.error('yousirjuan-verify FAILED:');
    for (const f of FAIL) console.error(`  ✗ ${f}`);
    process.exit(1);
  }
  console.log('✓ yousirjuan-verify passed');
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});

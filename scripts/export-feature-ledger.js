const fs = require('fs');
const path = require('path');

const ledgerPath = path.join(process.cwd(), 'features', 'ledger', 'features-ledger.md');
const outputPath = path.join(process.cwd(), 'features', 'ledger', 'features-ledger.json');

try {
  const raw = fs.readFileSync(ledgerPath, 'utf8');

  const payload = {
    exportedAt: new Date().toISOString(),
    source: 'features-ledger.md',
    content: raw
  };

  fs.writeFileSync(outputPath, JSON.stringify(payload, null, 2));

  console.log('Feature ledger exported successfully.');
} catch (error) {
  console.error('Export failed:', error.message);
}

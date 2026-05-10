const fs = require('fs');
const path = require('path');

exports.list = async (req, res) => {
  const ledgerPath = path.join(process.cwd(), 'features', 'ledger', 'features-ledger.md');

  try {
    const raw = fs.readFileSync(ledgerPath, 'utf8');

    res.json({
      success: true,
      source: 'features-ledger.md',
      content: raw
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
};

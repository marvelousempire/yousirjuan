require('dotenv').config();

const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');

const app = express();

app.use(cors());
app.use(helmet());
app.use(express.json({ limit: '25mb' }));
app.use(morgan('dev'));

const namespaces = require('./src/namespaces');
const features = require('./src/features');
const health = require('./src/health');

app.get('/health', health.status);
app.get('/api/features', features.list);
app.get('/api/namespaces/:id', namespaces.getNamespace);
app.post('/api/namespaces/resolve', namespaces.resolve);

const PORT = process.env.PORT || 4000;

app.listen(PORT, () => {
  console.log(`Sovereign API runtime listening on ${PORT}`);
});

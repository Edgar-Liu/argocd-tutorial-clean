const express = require('express');
const os = require('os');

const app = express();
const PORT = process.env.PORT || 3000;
const VERSION = process.env.VERSION || 'v1.0.0';

app.get('/', (req, res) => {
  const imageTag = process.env.IMAGE_TAG || 'unknown';
  res.json({
    message: 'Welcome to ArgoCD Tutorial Demo App!',
    version: VERSION,
    imageTag: imageTag,
    hostname: os.hostname(),
    timestamp: new Date().toISOString()
  });
});

app.get('/health', (req, res) => {
  res.json({ status: 'healthy' });
});

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
  console.log(`Version: ${VERSION}`);
});
// Testing CI/CD

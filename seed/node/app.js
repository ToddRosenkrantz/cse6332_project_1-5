const http = require('http');

http.createServer((req, res) => {
  res.writeHead(200, { 'Content-Type': 'application/json' });
  res.end(JSON.stringify({ service: 'node', node: process.version, url: req.url }));
}).listen(3000, '127.0.0.1');

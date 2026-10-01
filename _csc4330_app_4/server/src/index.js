require('dotenv').config();

const http = require('http');
const express = require('express');
const { Server } = require('socket.io');
const registerSocketHandlers = require('./socketHandlers');

const PORT = process.env.PORT || 3000;

const app = express();
app.get('/health', (req, res) => res.json({ status: 'ok' }));

const server = http.createServer(app);
const io = new Server(server, {
  cors: { origin: '*' },
});

io.on('connection', (socket) => {
  registerSocketHandlers(io, socket);
});

if (require.main === module) {
  server.listen(PORT, () => {
    console.log(`Gomoku server listening on port ${PORT}`);
  });
}

module.exports = { app, server, io };

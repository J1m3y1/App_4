const store = require('./gameStore');

function isNonEmptyString(value) {
  return typeof value === 'string' && value.length > 0;
}

function isInt(value) {
  return Number.isInteger(value);
}

function errorPayload(err) {
  if (err instanceof store.GameStoreError) {
    return { code: err.code, message: err.message };
  }
  return { code: 'INTERNAL_ERROR', message: 'Something went wrong' };
}

function reply(ack, payload) {
  if (typeof ack === 'function') ack(payload);
}

function registerSocketHandlers(io, socket) {
  socket.on('create_game', (payload, ack) => {
    try {
      const result = store.createGame();
      socket.join(result.roomCode);
      store.setPlayerSocket(result.roomCode, 'black', socket.id);
      reply(ack, { ok: true, ...result });
    } catch (err) {
      reply(ack, { ok: false, error: errorPayload(err) });
    }
  });

  socket.on('join_game', (payload, ack) => {
    try {
      const { roomCode } = payload || {};
      if (!isNonEmptyString(roomCode)) {
        throw new store.GameStoreError('INVALID_INPUT', 'roomCode is required');
      }

      const result = store.joinGame(roomCode);
      socket.join(roomCode);
      store.setPlayerSocket(roomCode, 'white', socket.id);
      reply(ack, { ok: true, roomCode, ...result });
      io.to(roomCode).emit('player_joined', {
        roomCode,
        color: 'white',
        game: result.game,
      });
    } catch (err) {
      reply(ack, { ok: false, error: errorPayload(err) });
    }
  });

  socket.on('move', (payload, ack) => {
    try {
      const { roomCode, playerToken, row, col } = payload || {};
      if (!isNonEmptyString(roomCode) || !isNonEmptyString(playerToken) || !isInt(row) || !isInt(col)) {
        throw new store.GameStoreError('INVALID_INPUT', 'roomCode, playerToken, row, col are required');
      }

      const result = store.makeMove(roomCode, playerToken, row, col);
      reply(ack, { ok: true, game: result.game });

      if (result.event === 'game_over') {
        io.to(roomCode).emit('game_over', {
          status: result.game.status,
          winner: result.game.winner,
          board: result.game.board,
          lastMove: result.lastMove,
        });
      } else {
        io.to(roomCode).emit('move_made', {
          board: result.game.board,
          currentTurn: result.game.currentTurn,
          lastMove: result.lastMove,
        });
      }
    } catch (err) {
      reply(ack, { ok: false, error: errorPayload(err) });
    }
  });

  socket.on('resign', (payload, ack) => {
    try {
      const { roomCode, playerToken } = payload || {};
      if (!isNonEmptyString(roomCode) || !isNonEmptyString(playerToken)) {
        throw new store.GameStoreError('INVALID_INPUT', 'roomCode and playerToken are required');
      }

      const result = store.resign(roomCode, playerToken);
      reply(ack, { ok: true, game: result.game });
      io.to(roomCode).emit('game_over', {
        status: result.game.status,
        winner: result.game.winner,
        board: result.game.board,
      });
    } catch (err) {
      reply(ack, { ok: false, error: errorPayload(err) });
    }
  });

  socket.on('disconnect', () => {
    const entry = store.clearSocket(socket.id);
    if (entry) {
      io.to(entry.roomCode).emit('player_disconnected', { color: entry.color });
    }
  });
}

module.exports = registerSocketHandlers;

const crypto = require('crypto');
const db = require('./db');
const { generateRoomCode } = require('./utils/roomCode');
const {
  createEmptyBoard,
  isValidMove,
  applyMove,
  checkWin,
  isBoardFull,
} = require('./gameEngine');

// roomCode -> GameState (source of truth during play; write-through to SQLite below)
const games = new Map();
// socketId -> { roomCode, color } (reverse lookup for disconnect handling)
const socketToRoom = new Map();

class GameStoreError extends Error {
  constructor(code, message) {
    super(message);
    this.code = code;
  }
}

const insertGameStmt = db.prepare(`
  INSERT INTO games (room_code, board, current_turn, status, winner, player1_token, player2_token, created_at, updated_at)
  VALUES (@roomCode, @board, @currentTurn, @status, @winner, @player1Token, @player2Token, @createdAt, @updatedAt)
`);

const updateGameStmt = db.prepare(`
  UPDATE games
  SET board = @board, current_turn = @currentTurn, status = @status, winner = @winner,
      player2_token = @player2Token, updated_at = @updatedAt
  WHERE room_code = @roomCode
`);

const insertMoveStmt = db.prepare(`
  INSERT INTO moves (room_code, player_color, row, col, move_number, created_at)
  VALUES (@roomCode, @playerColor, @row, @col, @moveNumber, @createdAt)
`);

function persistNewGame(game) {
  insertGameStmt.run({
    roomCode: game.roomCode,
    board: JSON.stringify(game.board),
    currentTurn: game.currentTurn,
    status: game.status,
    winner: game.winner,
    player1Token: game.player1Token,
    player2Token: game.player2Token,
    createdAt: game.createdAt,
    updatedAt: game.updatedAt,
  });
}

function persistGameUpdate(game) {
  updateGameStmt.run({
    roomCode: game.roomCode,
    board: JSON.stringify(game.board),
    currentTurn: game.currentTurn,
    status: game.status,
    winner: game.winner,
    player2Token: game.player2Token,
    updatedAt: game.updatedAt,
  });
}

function persistMove(roomCode, playerColor, row, col, moveNumber) {
  insertMoveStmt.run({
    roomCode,
    playerColor,
    row,
    col,
    moveNumber,
    createdAt: new Date().toISOString(),
  });
}

// Strips tokens/socket ids before anything crosses to a client.
function toPublicState(game) {
  return {
    roomCode: game.roomCode,
    board: game.board,
    currentTurn: game.currentTurn,
    status: game.status,
    winner: game.winner,
    createdAt: game.createdAt,
    updatedAt: game.updatedAt,
  };
}

function colorForToken(game, playerToken) {
  if (playerToken === game.player1Token) return 'black';
  if (playerToken === game.player2Token) return 'white';
  return null;
}

function createGame() {
  const roomCode = generateRoomCode((code) => games.has(code));
  const now = new Date().toISOString();

  const game = {
    roomCode,
    board: createEmptyBoard(),
    currentTurn: 'black',
    status: 'waiting',
    winner: null,
    player1Token: crypto.randomUUID(),
    player2Token: null,
    player1SocketId: null,
    player2SocketId: null,
    moveCount: 0,
    createdAt: now,
    updatedAt: now,
  };

  games.set(roomCode, game);
  persistNewGame(game);

  return { roomCode, playerToken: game.player1Token, color: 'black', game: toPublicState(game) };
}

function joinGame(roomCode) {
  const game = games.get(roomCode);
  if (!game) throw new GameStoreError('NOT_FOUND', `No game with room code ${roomCode}`);
  if (game.player2Token) throw new GameStoreError('GAME_FULL', 'Game already has two players');

  game.player2Token = crypto.randomUUID();
  game.status = 'active';
  game.updatedAt = new Date().toISOString();

  persistGameUpdate(game);

  return { playerToken: game.player2Token, color: 'white', game: toPublicState(game) };
}

function getGame(roomCode) {
  const game = games.get(roomCode);
  return game ? toPublicState(game) : null;
}

function makeMove(roomCode, playerToken, row, col) {
  const game = games.get(roomCode);
  if (!game) throw new GameStoreError('NOT_FOUND', `No game with room code ${roomCode}`);
  if (game.status !== 'active') throw new GameStoreError('GAME_NOT_ACTIVE', 'Game is not active');

  const color = colorForToken(game, playerToken);
  if (!color) throw new GameStoreError('WRONG_TOKEN', 'Player token does not belong to this game');
  if (color !== game.currentTurn) throw new GameStoreError('NOT_YOUR_TURN', 'It is not your turn');
  if (!isValidMove(game.board, row, col)) {
    throw new GameStoreError('INVALID_MOVE', 'Cell is occupied or out of bounds');
  }

  game.board = applyMove(game.board, row, col, color);
  game.moveCount += 1;

  let event = 'move_made';
  if (checkWin(game.board, row, col, color)) {
    game.status = 'finished';
    game.winner = color;
    event = 'game_over';
  } else if (isBoardFull(game.board)) {
    game.status = 'finished';
    game.winner = null;
    event = 'game_over';
  } else {
    game.currentTurn = color === 'black' ? 'white' : 'black';
  }

  game.updatedAt = new Date().toISOString();

  persistGameUpdate(game);
  persistMove(roomCode, color, row, col, game.moveCount);

  return { event, game: toPublicState(game), lastMove: { row, col, color } };
}

function resign(roomCode, playerToken) {
  const game = games.get(roomCode);
  if (!game) throw new GameStoreError('NOT_FOUND', `No game with room code ${roomCode}`);
  if (game.status !== 'active') throw new GameStoreError('GAME_NOT_ACTIVE', 'Game is not active');

  const color = colorForToken(game, playerToken);
  if (!color) throw new GameStoreError('WRONG_TOKEN', 'Player token does not belong to this game');

  game.status = 'finished';
  game.winner = color === 'black' ? 'white' : 'black';
  game.updatedAt = new Date().toISOString();

  persistGameUpdate(game);

  return { game: toPublicState(game) };
}

// --- Socket bookkeeping (Part 4 will call these from the connection/disconnect handlers) ---

function setPlayerSocket(roomCode, color, socketId) {
  const game = games.get(roomCode);
  if (!game) throw new GameStoreError('NOT_FOUND', `No game with room code ${roomCode}`);

  if (color === 'black') game.player1SocketId = socketId;
  else if (color === 'white') game.player2SocketId = socketId;
  else throw new GameStoreError('INVALID_COLOR', `Unknown color ${color}`);

  socketToRoom.set(socketId, { roomCode, color });
}

function getRoomBySocketId(socketId) {
  return socketToRoom.get(socketId) || null;
}

function clearSocket(socketId) {
  const entry = socketToRoom.get(socketId);
  if (!entry) return null;

  const game = games.get(entry.roomCode);
  if (game) {
    if (game.player1SocketId === socketId) game.player1SocketId = null;
    if (game.player2SocketId === socketId) game.player2SocketId = null;
  }

  socketToRoom.delete(socketId);
  return entry;
}

module.exports = {
  GameStoreError,
  createGame,
  joinGame,
  getGame,
  makeMove,
  resign,
  setPlayerSocket,
  getRoomBySocketId,
  clearSocket,
};

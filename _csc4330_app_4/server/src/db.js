const fs = require('fs');
const path = require('path');
const Database = require('better-sqlite3');

const dataDir = path.join(__dirname, '..', 'data');
fs.mkdirSync(dataDir, { recursive: true });

const db = new Database(path.join(dataDir, 'gomoku.db'));
db.pragma('journal_mode = WAL');
db.pragma('foreign_keys = ON');

db.exec(`
  CREATE TABLE IF NOT EXISTS games (
    room_code TEXT PRIMARY KEY,
    board TEXT NOT NULL,
    current_turn TEXT NOT NULL,
    status TEXT NOT NULL,
    winner TEXT,
    player1_token TEXT NOT NULL,
    player2_token TEXT,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL
  );

  CREATE TABLE IF NOT EXISTS moves (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    room_code TEXT NOT NULL REFERENCES games(room_code),
    player_color TEXT NOT NULL,
    row INTEGER NOT NULL,
    col INTEGER NOT NULL,
    move_number INTEGER NOT NULL,
    created_at TEXT NOT NULL
  );

  CREATE INDEX IF NOT EXISTS idx_moves_room_code ON moves(room_code);
`);

module.exports = db;

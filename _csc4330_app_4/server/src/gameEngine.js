const BOARD_SIZE = 15;
const WIN_LENGTH = 5;

function createEmptyBoard(size = BOARD_SIZE) {
  return Array.from({ length: size }, () => Array(size).fill(null));
}

function isValidMove(board, row, col) {
  if (row < 0 || row >= board.length) return false;
  if (col < 0 || col >= board[row].length) return false;
  return board[row][col] === null;
}

function applyMove(board, row, col, color) {
  const newBoard = board.map((r, i) => (i === row ? [...r] : r));
  newBoard[row][col] = color;
  return newBoard;
}

const DIRECTIONS = [
  [0, 1],  // horizontal
  [1, 0],  // vertical
  [1, 1],  // diagonal down-right
  [1, -1], // diagonal down-left
];

function checkWin(board, row, col, color) {
  const size = board.length;

  return DIRECTIONS.some(([dRow, dCol]) => {
    let count = 1;

    for (let step = 1; step < WIN_LENGTH; step++) {
      const r = row + dRow * step;
      const c = col + dCol * step;
      if (r < 0 || r >= size || c < 0 || c >= size || board[r][c] !== color) break;
      count++;
    }

    for (let step = 1; step < WIN_LENGTH; step++) {
      const r = row - dRow * step;
      const c = col - dCol * step;
      if (r < 0 || r >= size || c < 0 || c >= size || board[r][c] !== color) break;
      count++;
    }

    return count >= WIN_LENGTH;
  });
}

function isBoardFull(board) {
  return board.every((r) => r.every((cell) => cell !== null));
}

module.exports = {
  BOARD_SIZE,
  WIN_LENGTH,
  createEmptyBoard,
  isValidMove,
  applyMove,
  checkWin,
  isBoardFull,
};

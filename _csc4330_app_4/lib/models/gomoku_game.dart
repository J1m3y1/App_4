/// Core game logic for Gomoku (five-in-a-row), independent of any UI.

enum Stone { none, black, white }

extension StoneOpponent on Stone {
  Stone get opponent {
    switch (this) {
      case Stone.black:
        return Stone.white;
      case Stone.white:
        return Stone.black;
      case Stone.none:
        return Stone.none;
    }
  }
}

class Position {
  final int row;
  final int col;

  const Position(this.row, this.col);

  @override
  bool operator ==(Object other) =>
      other is Position && other.row == row && other.col == col;

  @override
  int get hashCode => Object.hash(row, col);

  @override
  String toString() => 'Position($row, $col)';
}

/// Directions checked from a placed stone: horizontal, vertical, and both diagonals.
const List<Position> _directions = [
  Position(0, 1),
  Position(1, 0),
  Position(1, 1),
  Position(1, -1),
];

class GomokuGame {
  final int boardSize;
  final int winLength;

  late List<List<Stone>> board;
  late Stone currentPlayer;
  Stone? winner;
  bool isDraw = false;
  List<Position> winningLine = const [];
  final List<Position> moveHistory = [];

  GomokuGame({this.boardSize = 15, this.winLength = 5}) {
    reset();
  }

  bool get isGameOver => winner != null || isDraw;

  void reset() {
    board = List.generate(
      boardSize,
      (_) => List.filled(boardSize, Stone.none),
    );
    currentPlayer = Stone.black;
    winner = null;
    isDraw = false;
    winningLine = const [];
    moveHistory.clear();
  }

  bool _inBounds(int row, int col) =>
      row >= 0 && row < boardSize && col >= 0 && col < boardSize;

  Stone stoneAt(int row, int col) => board[row][col];

  /// Places the current player's stone at [row]/[col]. Returns false if the
  /// move is illegal (out of bounds, occupied, or the game has already ended).
  bool placeStone(int row, int col) {
    if (isGameOver || !_inBounds(row, col) || board[row][col] != Stone.none) {
      return false;
    }

    final player = currentPlayer;
    board[row][col] = player;
    moveHistory.add(Position(row, col));

    final line = _winningLineThrough(row, col, player);
    if (line != null) {
      winner = player;
      winningLine = line;
    } else if (moveHistory.length == boardSize * boardSize) {
      isDraw = true;
    } else {
      currentPlayer = player.opponent;
    }

    return true;
  }

  /// Undoes the most recent move, restoring turn order and any win/draw state.
  bool undoLastMove() {
    if (moveHistory.isEmpty) return false;

    final last = moveHistory.removeLast();
    final player = board[last.row][last.col];
    board[last.row][last.col] = Stone.none;
    currentPlayer = player;
    winner = null;
    isDraw = false;
    winningLine = const [];
    return true;
  }

  /// Checks whether placing [player]'s stone at [row]/[col] completes a line
  /// of at least [winLength] stones, returning the full line if so.
  List<Position>? _winningLineThrough(int row, int col, Stone player) {
    for (final dir in _directions) {
      final line = [Position(row, col)];

      var r = row + dir.row;
      var c = col + dir.col;
      while (_inBounds(r, c) && board[r][c] == player) {
        line.add(Position(r, c));
        r += dir.row;
        c += dir.col;
      }

      r = row - dir.row;
      c = col - dir.col;
      while (_inBounds(r, c) && board[r][c] == player) {
        line.insert(0, Position(r, c));
        r -= dir.row;
        c -= dir.col;
      }

      if (line.length >= winLength) return line;
    }
    return null;
  }
}

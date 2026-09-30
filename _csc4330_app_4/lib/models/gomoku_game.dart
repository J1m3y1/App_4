import 'package:flutter/foundation.dart';

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

/// Like [ValueNotifier], but notifies listeners on every assignment, even when
/// the new value equals the old one. Game events can legitimately repeat, e.g.
/// placing a stone on the same cell again after an undo.
class EventNotifier<T> extends ChangeNotifier implements ValueListenable<T> {
  EventNotifier(this._value);

  T _value;

  @override
  T get value => _value;

  set value(T newValue) {
    _value = newValue;
    notifyListeners();
  }
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

  /// The player who conceded, if the game ended by concession.
  Stone? concededBy;

  /// Fires with the coordinate of every stone placed. Read the stone's color
  /// from [board] (or [stoneAt]).
  final EventNotifier<(int, int)> piecePlacedNotifier = EventNotifier<(int, int)>((0, 0));

  /// Fires with the coordinate of every stone removed, by undo or by [reset].
  /// The cell is already cleared in [board] when listeners run.
  final EventNotifier<(int, int)> pieceRemovedNotifier = EventNotifier<(int, int)>((0, 0));

  /// Fires true when a game starts (or resumes after an undo past its end) and
  /// false when it ends by win, draw, or concession.
  final EventNotifier<bool> gameStartedNotifier = EventNotifier<bool>(false);

  GomokuGame({this.boardSize = 15, this.winLength = 5})
      : assert(boardSize > 0),
        assert(winLength > 0) {
    reset();
  }

  bool get isGameOver => winner != null || isDraw;

  /// Clears the board and starts a new game with black to move. Each stone
  /// still on the board is announced through [pieceRemovedNotifier] so the UI
  /// can clear it.
  void reset() {
    for (final pos in moveHistory.reversed) {
      board[pos.row][pos.col] = Stone.none;
      pieceRemovedNotifier.value = (pos.row, pos.col);
    }

    board = List.generate(
      boardSize,
      (_) => List.filled(boardSize, Stone.none),
    );
    currentPlayer = Stone.black;
    winner = null;
    isDraw = false;
    winningLine = const [];
    concededBy = null;
    moveHistory.clear();

    gameStartedNotifier.value = true;
  }

  /// Ends the game with [player] (the current player by default) conceding,
  /// making their opponent the winner. Returns false if the game is already
  /// over.
  bool concede([Stone? player]) {
    final loser = player ?? currentPlayer;
    if (isGameOver || loser == Stone.none) return false;

    concededBy = loser;
    winner = loser.opponent;
    winningLine = const [];

    gameStartedNotifier.value = false;
    return true;
  }

  /// Releases the notifiers. The game must not be used afterwards.
  void dispose() {
    piecePlacedNotifier.dispose();
    pieceRemovedNotifier.dispose();
    gameStartedNotifier.dispose();
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

    // Update all listeners
    piecePlacedNotifier.value = (row, col);
    if (isGameOver){
      gameStartedNotifier.value = false;
    }

    return true;
  }

  /// Undoes the most recent move, restoring turn order and any win/draw state.
  /// If the game ended by concession, only the concession is taken back.
  bool undoLastMove() {
    if (concededBy != null) {
      concededBy = null;
      winner = null;
      gameStartedNotifier.value = true;
      return true;
    }

    if (moveHistory.isEmpty) return false;

    final wasOver = isGameOver;
    final last = moveHistory.removeLast();
    final player = board[last.row][last.col];
    board[last.row][last.col] = Stone.none;
    currentPlayer = player;
    winner = null;
    isDraw = false;
    winningLine = const [];

    // Update undo listeners
    pieceRemovedNotifier.value = (last.row, last.col);
    if (wasOver) {
      gameStartedNotifier.value = true;
    }

    return true;
  }

  /// Checks whether placing [player]'s stone at [row]/[col] completes a line
  /// of exactly [winLength] stones, returning the line if so. Longer lines
  /// (overlines) do not win, per standard Gomoku rules.
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

      if (line.length == winLength) return line;
    }
    return null;
  }
}

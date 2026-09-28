import 'package:flutter_test/flutter_test.dart';
import 'package:_csc4330_app_4/models/gomoku_game.dart';
//added info

void main() {
  group('GomokuGame', () {
    test('starts empty with black to move', () {
      final game = GomokuGame(boardSize: 9);
      expect(game.currentPlayer, Stone.black);
      expect(game.isGameOver, isFalse);
      expect(game.stoneAt(0, 0), Stone.none);
    });

    test('alternates turns after each move', () {
      final game = GomokuGame(boardSize: 9);
      game.placeStone(0, 0);
      expect(game.currentPlayer, Stone.white);
      game.placeStone(0, 1);
      expect(game.currentPlayer, Stone.black);
    });

    test('rejects moves out of bounds or on occupied cells', () {
      final game = GomokuGame(boardSize: 9);
      expect(game.placeStone(-1, 0), isFalse);
      expect(game.placeStone(0, 0), isTrue);
      expect(game.placeStone(0, 0), isFalse);
    });

    test('detects a horizontal five-in-a-row win', () {
      final game = GomokuGame(boardSize: 9);
      // Black: (0,0)-(0,4), White: (1,0)-(1,3)
      game.placeStone(0, 0); // B
      game.placeStone(1, 0); // W
      game.placeStone(0, 1); // B
      game.placeStone(1, 1); // W
      game.placeStone(0, 2); // B
      game.placeStone(1, 2); // W
      game.placeStone(0, 3); // B
      game.placeStone(1, 3); // W
      game.placeStone(0, 4); // B wins

      expect(game.isGameOver, isTrue);
      expect(game.winner, Stone.black);
      expect(game.winningLine.length, 5);
    });

    test('detects a diagonal win', () {
      final game = GomokuGame(boardSize: 9);
      game.placeStone(0, 0); // B
      game.placeStone(0, 1); // W
      game.placeStone(1, 1); // B
      game.placeStone(0, 2); // W
      game.placeStone(2, 2); // B
      game.placeStone(0, 3); // W
      game.placeStone(3, 3); // B
      game.placeStone(0, 4); // W
      game.placeStone(4, 4); // B wins diagonally

      expect(game.winner, Stone.black);
    });

    test('no further moves accepted after a win', () {
      final game = GomokuGame(boardSize: 9);
      game.placeStone(0, 0);
      game.placeStone(1, 0);
      game.placeStone(0, 1);
      game.placeStone(1, 1);
      game.placeStone(0, 2);
      game.placeStone(1, 2);
      game.placeStone(0, 3);
      game.placeStone(1, 3);
      game.placeStone(0, 4); // black wins

      expect(game.placeStone(2, 2), isFalse);
    });

    test('undo restores previous state', () {
      final game = GomokuGame(boardSize: 9);
      game.placeStone(0, 0);
      game.placeStone(1, 0);
      expect(game.undoLastMove(), isTrue);
      expect(game.stoneAt(1, 0), Stone.none);
      expect(game.currentPlayer, Stone.white);
    });

    test('a full board with no winner is a draw', () {
      final game = GomokuGame(boardSize: 3, winLength: 5);
      final moves = [
        [0, 0], [0, 1], [0, 2],
        [1, 0], [1, 1], [1, 2],
        [2, 0], [2, 1], [2, 2],
      ];
      for (final m in moves) {
        game.placeStone(m[0], m[1]);
      }
      expect(game.isDraw, isTrue);
      expect(game.winner, isNull);
    });
  });
}

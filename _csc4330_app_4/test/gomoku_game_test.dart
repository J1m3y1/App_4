import 'package:flutter_test/flutter_test.dart';
import 'package:_csc4330_app_4/models/gomoku_game.dart';


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
    test('placing a stone at (0, 0) notifies listeners', () {
      final game = GomokuGame(boardSize: 9);
      final placed = <(int, int)>[];
      game.piecePlacedNotifier.addListener(
          () => placed.add(game.piecePlacedNotifier.value));

      game.placeStone(0, 0);
      expect(placed, [(0, 0)]);
    });

    test('replaying the same cell after undo notifies again', () {
      final game = GomokuGame(boardSize: 9);
      var placedCount = 0;
      var removedCount = 0;
      game.piecePlacedNotifier.addListener(() => placedCount++);
      game.pieceRemovedNotifier.addListener(() => removedCount++);

      game.placeStone(4, 4);
      game.undoLastMove();
      game.placeStone(4, 4);
      game.undoLastMove();

      expect(placedCount, 2);
      expect(removedCount, 2);
    });

    test('removed stone is already cleared when listeners run', () {
      final game = GomokuGame(boardSize: 9);
      final seen = <Stone>[];
      game.pieceRemovedNotifier.addListener(() {
        final (r, c) = game.pieceRemovedNotifier.value;
        seen.add(game.stoneAt(r, c));
      });

      game.placeStone(2, 3);
      game.undoLastMove();
      expect(seen, [Stone.none]);
    });

    test('reset announces every stone removed and starts a new game', () {
      final game = GomokuGame(boardSize: 9);
      game.placeStone(0, 0);
      game.placeStone(1, 1);
      game.placeStone(2, 2);

      final removed = <(int, int)>[];
      final cellsWhenRemoved = <Stone>[];
      game.pieceRemovedNotifier.addListener(() {
        final (r, c) = game.pieceRemovedNotifier.value;
        removed.add((r, c));
        cellsWhenRemoved.add(game.stoneAt(r, c));
      });

      game.reset();

      expect(removed.toSet(), {(0, 0), (1, 1), (2, 2)});
      expect(cellsWhenRemoved, everyElement(Stone.none));
      expect(game.moveHistory, isEmpty);
      expect(game.currentPlayer, Stone.black);
      expect(game.gameStartedNotifier.value, isTrue);
    });

    test('reset after a win clears the game over state', () {
      final game = GomokuGame(boardSize: 9);
      for (var i = 0; i < 4; i++) {
        game.placeStone(0, i);
        game.placeStone(1, i);
      }
      game.placeStone(0, 4); // black wins
      expect(game.gameStartedNotifier.value, isFalse);

      var startedEvents = 0;
      game.gameStartedNotifier.addListener(() => startedEvents++);
      game.reset();

      expect(startedEvents, 1);
      expect(game.isGameOver, isFalse);
      expect(game.winner, isNull);
      expect(game.winningLine, isEmpty);
    });

    test('winning fires the game ended event', () {
      final game = GomokuGame(boardSize: 9);
      final events = <bool>[];
      game.gameStartedNotifier
          .addListener(() => events.add(game.gameStartedNotifier.value));

      for (var i = 0; i < 4; i++) {
        game.placeStone(0, i);
        game.placeStone(1, i);
      }
      game.placeStone(0, 4);

      expect(events, [false]);
    });

    test('undo after a win resumes the game', () {
      final game = GomokuGame(boardSize: 9);
      for (var i = 0; i < 4; i++) {
        game.placeStone(0, i);
        game.placeStone(1, i);
      }
      game.placeStone(0, 4);

      expect(game.undoLastMove(), isTrue);
      expect(game.isGameOver, isFalse);
      expect(game.currentPlayer, Stone.black);
      expect(game.gameStartedNotifier.value, isTrue);
    });

    test('concede makes the opponent the winner', () {
      final game = GomokuGame(boardSize: 9);
      game.placeStone(0, 0); // black; white to move

      expect(game.concede(), isTrue);
      expect(game.concededBy, Stone.white);
      expect(game.winner, Stone.black);
      expect(game.isGameOver, isTrue);
      expect(game.gameStartedNotifier.value, isFalse);
      expect(game.placeStone(5, 5), isFalse);
      expect(game.concede(), isFalse);
    });

    test('a specific player can concede out of turn', () {
      final game = GomokuGame(boardSize: 9);
      expect(game.concede(Stone.white), isTrue);
      expect(game.winner, Stone.black);
      expect(game.concede(Stone.none), isFalse);
    });

    test('undo after a concession only takes back the concession', () {
      final game = GomokuGame(boardSize: 9);
      game.placeStone(0, 0);
      game.concede();

      expect(game.undoLastMove(), isTrue);
      expect(game.isGameOver, isFalse);
      expect(game.concededBy, isNull);
      expect(game.stoneAt(0, 0), Stone.black);
      expect(game.currentPlayer, Stone.white);
    });

    test('reset clears a concession', () {
      final game = GomokuGame(boardSize: 9);
      game.concede();
      game.reset();
      expect(game.concededBy, isNull);
      expect(game.isGameOver, isFalse);
    });

    test('dispose releases the notifiers', () {
      final game = GomokuGame(boardSize: 9);
      game.dispose();
      expect(() => game.piecePlacedNotifier.addListener(() {}),
          throwsFlutterError);
    });
  });
}

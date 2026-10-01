import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as socket_io;

import 'gomoku_game.dart';
import 'player.dart';

class Client extends ChangeNotifier {
  final String serverUrl;
  final GomokuGame game;
  final Player player;

  socket_io.Socket? _socket;
  Completer<void>? _connectionCompleter;
  String? _roomCode;
  String? _playerToken;
  String? _gameStatus;
  String? _errorMessage;
  bool _isConnected = false;

  Client({
    required this.game,
    required this.player,
    this.serverUrl = 'http://localhost:3000',
  });

  bool get isOnline => _roomCode != null && _playerToken != null;
  bool get isConnected => _isConnected;
  bool get canMove =>
      isOnline &&
      _isConnected &&
      _gameStatus == 'active' &&
      player.color == game.currentPlayer &&
      !game.isGameOver;
  String? get roomCode => _roomCode;
  String? get gameStatus => _gameStatus;
  String? get errorMessage => _errorMessage;

  Future<void> connect() => _ensureConnected();

  Future<String> createGame() async {
    final response = await _emitWithAck('create_game', <String, dynamic>{});
    _setSession(response);
    return _roomCode!;
  }

  Future<void> joinGame(String roomCode) async {
    final normalizedRoomCode = roomCode.trim().toUpperCase();
    if (normalizedRoomCode.isEmpty) {
      throw ArgumentError.value(roomCode, 'roomCode', 'Room code is required');
    }

    final response = await _emitWithAck('join_game', <String, dynamic>{
      'roomCode': normalizedRoomCode,
    });
    _setSession(response, fallbackRoomCode: normalizedRoomCode);
  }

  Future<void> makeMove(int row, int col) async {
    if (!canMove) {
      throw StateError('It is not your turn or the game is not active');
    }

    await _emitWithAck('move', <String, dynamic>{
      'roomCode': _roomCode,
      'playerToken': _playerToken,
      'row': row,
      'col': col,
    });
  }

  Future<void> resign() async {
    if (!isOnline) throw StateError('You are not in an online game');

    await _emitWithAck('resign', <String, dynamic>{
      'roomCode': _roomCode,
      'playerToken': _playerToken,
    });
  }

  Future<void> _ensureConnected() async {
    if (_socket?.connected == true) return;
    _socket ??= _createSocket();

    final pendingConnection = _connectionCompleter;
    if (pendingConnection != null) {
      await pendingConnection.future;
      return;
    }

    final completer = Completer<void>();
    _connectionCompleter = completer;
    _socket!.connect();

    try {
      await completer.future.timeout(const Duration(seconds: 12));
    } catch (error) {
      _errorMessage = error.toString();
      notifyListeners();
      rethrow;
    } finally {
      if (identical(_connectionCompleter, completer)) {
        _connectionCompleter = null;
      }
    }
  }

  socket_io.Socket _createSocket() {
    final socket = socket_io.io(
      serverUrl,
      socket_io.OptionBuilder()
          .disableAutoConnect()
          .enableForceNew()
          .setTransports(['websocket'])
          .setTimeout(5000)
          .setAckTimeout(5000)
          .build(),
    );

    socket.onConnect((_) {
      _isConnected = true;
      _errorMessage = null;
      if (!(_connectionCompleter?.isCompleted ?? true)) {
        _connectionCompleter!.complete();
      }
      notifyListeners();
    });
    socket.onConnectError((error) {
      _isConnected = false;
      _errorMessage = 'Could not connect to $serverUrl: $error';
      if (!(_connectionCompleter?.isCompleted ?? true)) {
        _connectionCompleter!.completeError(StateError(_errorMessage!));
      }
      notifyListeners();
    });
    socket.onDisconnect((_) {
      _isConnected = false;
      notifyListeners();
    });
    socket.on('move_made', _handleMoveMade);
    socket.on('game_over', _handleGameOver);
    socket.on('player_joined', _handlePlayerJoined);
    socket.on('player_disconnected', _handlePlayerDisconnected);
    return socket;
  }

  Future<Map<String, dynamic>> _emitWithAck(
    String event,
    Map<String, dynamic> payload,
  ) async {
    await _ensureConnected();
    final rawResponse = await _socket!
        .emitWithAckAsync(event, payload)
        .timeout(const Duration(seconds: 8));
    if (rawResponse is! Map) {
      throw StateError('Invalid response from server');
    }
    final response = Map<String, dynamic>.from(rawResponse);
    if (response['ok'] != true) {
      final error = response['error'];
      final message = error is Map ? error['message'] : null;
      throw StateError(
        message?.toString() ?? 'The server rejected the request',
      );
    }
    _errorMessage = null;
    return response;
  }

  void _setSession(Map<String, dynamic> response, {String? fallbackRoomCode}) {
    _roomCode = response['roomCode'] as String? ?? fallbackRoomCode;
    _playerToken = response['playerToken'] as String?;
    if (_roomCode == null || _playerToken == null) {
      throw StateError('The server returned an incomplete game session');
    }

    player.color = _stoneFromServer(response['color']);
    _applyGameSnapshot(response['game']);
    notifyListeners();
  }

  void _handleMoveMade(dynamic data) => _applyGameSnapshot(data);

  void _handleGameOver(dynamic data) => _applyGameSnapshot(data);

  void _handlePlayerJoined(dynamic data) {
    final event = _asMap(data);
    _applyGameSnapshot(event['game']);
  }

  void _handlePlayerDisconnected(dynamic _) {
    _errorMessage = 'The other player disconnected';
    notifyListeners();
  }

  void _applyGameSnapshot(dynamic data) {
    try {
      final snapshot = _asMap(data);
      final rawBoard = snapshot['board'];
      if (rawBoard is! List || rawBoard.length != game.boardSize) {
        throw const FormatException('Invalid board received from server');
      }

      final remoteBoard = rawBoard
          .map((rawRow) {
            if (rawRow is! List || rawRow.length != game.boardSize) {
              throw const FormatException(
                'Invalid board row received from server',
              );
            }
            return rawRow
                .map(
                  (value) =>
                      value == null ? Stone.none : _stoneFromServer(value),
                )
                .toList(growable: false);
          })
          .toList(growable: false);

      final lastMove = snapshot['lastMove'];
      final lastMoveColor = lastMove is Map ? lastMove['color'] : null;
      final turn =
          snapshot['currentTurn'] ??
          lastMoveColor ??
          _stoneName(game.currentPlayer);
      final winner = snapshot['winner'];
      game.applyRemoteState(
        board: remoteBoard,
        currentPlayer: _stoneFromServer(turn),
        winner: winner == null ? null : _stoneFromServer(winner),
      );
      _gameStatus = snapshot['status'] as String? ?? _gameStatus;
      _errorMessage = null;
      notifyListeners();
    } catch (error) {
      _errorMessage = 'Invalid game update from server: $error';
      notifyListeners();
    }
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map) return Map<String, dynamic>.from(value);
    throw const FormatException('Expected a game object from server');
  }

  Stone _stoneFromServer(dynamic color) {
    return switch (color) {
      'black' => Stone.black,
      'white' => Stone.white,
      _ => throw FormatException('Unknown stone color: $color'),
    };
  }

  String _stoneName(Stone stone) => switch (stone) {
    Stone.black => 'black',
    Stone.white => 'white',
    Stone.none => throw StateError('No player has the current turn'),
  };

  @override
  void dispose() {
    _socket?.disconnect();
    super.dispose();
  }
}

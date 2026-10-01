import 'package:_csc4330_app_4/models/client.dart';
import 'package:_csc4330_app_4/models/gomoku_game.dart';
import 'package:_csc4330_app_4/models/player.dart';
import 'package:_csc4330_app_4/ui/board.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

final Provider<GomokuGame> defaultGameProvider = Provider<GomokuGame>(
  create: (context) {
    GomokuGame game = GomokuGame();
    return game;
  },
);

Provider<Player> defaultPlayerProvider = Provider<Player>(
  create: (context) => Player(color: Stone.black),
);

ChangeNotifierProvider<Client> defaultClientProvider =
    ChangeNotifierProvider<Client>(
      create: (context) => Client(
        game: context.read<GomokuGame>(),
        player: context.read<Player>(),
      ),
    );

class LevelProvider extends StatelessWidget {
  final Provider<GomokuGame>? gameProvider;
  final Provider<Player>? playerProvider;
  final ChangeNotifierProvider<Client>? clientProvider;

  const LevelProvider({
    super.key,
    this.gameProvider,
    this.playerProvider,
    this.clientProvider,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        gameProvider ?? defaultGameProvider,
        playerProvider ?? defaultPlayerProvider,
        clientProvider ?? defaultClientProvider,
      ],
      child: MainLevel(),
    );
  }
}

class MainLevel extends StatefulWidget {
  const MainLevel({super.key});

  @override
  State<MainLevel> createState() => _MainLevelState();
}

class _MainLevelState extends State<MainLevel> {
  late bool _gameOver;
  GomokuGame? _game;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    GomokuGame newGame = context.watch();
    if (newGame != _game) {
      _game?.gameStartedNotifier.removeListener(_onGameStartedChange);
      _game = newGame;
      _gameOver = _game!.isGameOver;
      _game!.gameStartedNotifier.addListener(_onGameStartedChange);
    }
  }

  void _onGameStartedChange() {
    print(_game!.gameStartedNotifier.value);
    setState(() => _gameOver = !_game!.gameStartedNotifier.value);
  }

  Widget _winnerImage() {
    if (_game!.winner == Stone.black) {
      return Image.asset("assets/black-wins.jpg", fit: BoxFit.fitWidth);
    } else if (_game!.winner == Stone.white) {
      return Image.asset("assets/white-wins.jpg", fit: BoxFit.fitWidth);
    } else {
      return Image.asset("assets/draw.jpg", fit: BoxFit.fitWidth);
    }
  }

  Future<void> _createOnlineGame() async {
    try {
      final roomCode = await context.read<Client>().createGame();
      _showMessage('Share room code $roomCode with the other player');
    } catch (error) {
      _showMessage(error.toString());
    }
  }

  Future<void> _joinOnlineGame() async {
    final controller = TextEditingController();
    final roomCode = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Join a game'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(labelText: 'Room code'),
          onSubmitted: (value) => Navigator.of(dialogContext).pop(value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(controller.text),
            child: const Text('Join'),
          ),
        ],
      ),
    );
    controller.dispose();

    if (roomCode == null || !mounted) return;
    try {
      await context.read<Client>().joinGame(roomCode);
      _showMessage('Joined room ${roomCode.trim().toUpperCase()}');
    } catch (error) {
      _showMessage(error.toString());
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _onlineControls() {
    final client = context.watch<Client>();
    final colorScheme = Theme.of(context).colorScheme;
    final status = !client.isOnline
        ? 'Local game'
        : !client.isConnected
        ? 'Disconnected'
        : switch (client.gameStatus) {
            'waiting' => 'Waiting for player',
            'active' => client.canMove ? 'Your turn' : 'Opponent\'s turn',
            'finished' => 'Game over',
            _ => 'Online game',
          };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        runSpacing: 4,
        children: [
          if (!client.isOnline) ...[
            OutlinedButton.icon(
              onPressed: _createOnlineGame,
              style: OutlinedButton.styleFrom(
                foregroundColor: colorScheme.onPrimary,
                side: BorderSide(color: colorScheme.onPrimary),
              ),
              icon: const Icon(Icons.add_link),
              label: const Text('Create online'),
            ),
            OutlinedButton.icon(
              onPressed: _joinOnlineGame,
              style: OutlinedButton.styleFrom(
                foregroundColor: colorScheme.onPrimary,
                side: BorderSide(color: colorScheme.onPrimary),
              ),
              icon: const Icon(Icons.login),
              label: const Text('Join online'),
            ),
          ] else ...[
            Text(
              'Room ${client.roomCode} · $status',
              style: TextStyle(color: colorScheme.onPrimary),
            ),
            if (client.gameStatus == 'active')
              TextButton.icon(
                onPressed: () async {
                  try {
                    await client.resign();
                  } catch (error) {
                    _showMessage(error.toString());
                  }
                },
                style: TextButton.styleFrom(
                  foregroundColor: colorScheme.onPrimary,
                ),
                icon: const Icon(Icons.flag_outlined),
                label: const Text('Resign'),
              ),
          ],
          if (client.errorMessage != null)
            Text(
              client.errorMessage!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> gameStackChildren = [
      BoardWidget(),
      // Game over screen
      Positioned.fill(
        child: FractionallySizedBox(
          widthFactor: .75,
          alignment: Alignment.center,
          child: AnimatedScale(
            scale: _gameOver ? 1.0 : 0.0,
            duration: const Duration(seconds: 10),
            curve: Curves.linearToEaseOut,
            child: _winnerImage(),
          ),
        ),
      ),
    ];

    List<Widget> backgroundStackChildren = [
      Positioned(
        left: 0,
        top: 0,
        bottom: 0,
        child: IgnorePointer(
          child: Opacity(
            opacity: 0.08,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: Image.asset(
                "assets/player1.png",
                fit: BoxFit.fitHeight,
                alignment: Alignment.centerRight,
              ),
            ),
          ),
        ),
      ),

      Positioned(
        right: 0,
        top: 0,
        bottom: 0,
        child: IgnorePointer(
          child: Opacity(
            opacity: 0.08,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: Image.asset(
                "assets/player2.png",
                fit: BoxFit.fitHeight,
                alignment: Alignment.centerRight,
              ),
            ),
          ),
        ),
      ),

      Center(
        child: FittedBox(
          fit: BoxFit.contain,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Stack(children: gameStackChildren),
          ),
        ),
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
          ),
          child: Column(
            children: [
              _onlineControls(),
              Expanded(child: Stack(children: backgroundStackChildren)),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:_csc4330_app_4/models/client.dart';
import 'package:_csc4330_app_4/models/gomoku_game.dart';
import 'package:_csc4330_app_4/models/player.dart';
import 'package:_csc4330_app_4/ui/board.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

final Provider<GomokuGame> defaultGameProvider = Provider<GomokuGame>(
  create: (context) 
    {
      GomokuGame game = GomokuGame();
      return game;
    } 
);

Provider<Player> defaultPlayerProvider = Provider<Player>(
  create: (context) => Player(color: Stone.black)
);

Provider<Client> defaultClientProvider = Provider<Client>(
  create: (context) => Client() 
);

class LevelProvider extends StatelessWidget {
  final Provider<GomokuGame>? gameProvider;
  final Provider<Player>? playerProvider; 
  final Provider<Client>? clientProvider;

  const LevelProvider({
    super.key,
    this.gameProvider,
    this.playerProvider,
    this.clientProvider
  });

  @override
  Widget build(BuildContext context){
    return MultiProvider(
      providers: [gameProvider ?? defaultGameProvider, playerProvider ?? defaultPlayerProvider, clientProvider ?? defaultClientProvider],
      child: MainLevel()
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
  void didChangeDependencies(){
    super.didChangeDependencies();

    GomokuGame newGame = context.watch();
    if(newGame != _game){
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
    if(_game!.winner == Stone.black) {
      return Image.asset("assets/black-wins.jpg", fit: BoxFit.fitWidth);
    } else if(_game!.winner == Stone.white){
      return Image.asset("assets/white-wins.jpg", fit: BoxFit.fitWidth);
    } else {
      return Image.asset("assets/draw.jpg", fit: BoxFit.fitWidth); 
    }
  }

  @override 
  Widget build(BuildContext context){
    List<Widget> stackChildren = [
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
            child: _winnerImage()
          )
        )
      )
    ];

    return Container(
        decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary),
        child: Center(
          child: FittedBox(
            fit: BoxFit.contain,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Stack(
                children: stackChildren
              )
            )
          )
        )
    );
  }
}
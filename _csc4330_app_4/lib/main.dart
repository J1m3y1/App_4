import 'package:_csc4330_app_4/models/client.dart';
import 'package:_csc4330_app_4/models/gomoku_game.dart';
import 'package:_csc4330_app_4/models/player.dart';
import 'package:_csc4330_app_4/ui/board.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: .fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Gomoku'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Provider<GomokuGame> gameProvider = Provider<GomokuGame>(
    create: (context) 
      {
        GomokuGame game = GomokuGame();
        game.placeStone(1, 1);
        game.placeStone(2, 2); 
        return game;
      } 
  );

  Provider<Player> playerProvider = Provider<Player>(
    create: (context) => Player(color: Stone.black)
  );

  Provider<Client> clientProvider = Provider<Client>(
    create: (context) => Client() 
  );

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
  
    return MultiProvider(
      providers: [gameProvider, playerProvider, clientProvider], 
      child: Scaffold(
        appBar: AppBar(
          // TRY THIS: Try changing the color here to a specific color (to
          // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
          // change color while the other colors stay the same.
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          // Here we take the value from the MyHomePage object that was created by
          // the App.build method, and use it to set our appbar title.
          title: Text(widget.title),
        ),
        body: Container(
          decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary),
          child: Center(
            child: FittedBox(
              fit: BoxFit.contain,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: BoardWidget()
              )
            )
          )
        )
      )
    );
  }
}

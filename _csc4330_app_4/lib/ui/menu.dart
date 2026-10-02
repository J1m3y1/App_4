import 'package:_csc4330_app_4/models/client.dart';
import 'package:_csc4330_app_4/models/gomoku_game.dart';
import 'package:_csc4330_app_4/models/player.dart';
import 'package:_csc4330_app_4/ui/level.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class MainMenu extends StatelessWidget {
  void _showMessage(BuildContext context, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }


  Future<void> _createOnlineGame(BuildContext context, Client client) async {
    try {
      final roomCode = await client.createGame();
      _showMessage(context, 'Share room code $roomCode with the other player');
    } catch (error) {
      _showMessage(context, error.toString());
    }
  }

  Future<void> _joinOnlineGame(BuildContext context, Client client) async {
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

    if (roomCode == null || !context.mounted) return;
    try {
      await client.joinGame(roomCode);
      _showMessage(context, 'Joined room ${roomCode.trim().toUpperCase()}');
    } catch (error) {
      _showMessage(context, error.toString());
    }
  }
  void _startServer(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) {
        return LevelProvider(
          clientProvider: ChangeNotifierProvider<Client>(create: (context) {
              final client = Client(
                game: context.read<GomokuGame>(),
                player: context.read<Player>(),
              );
              _createOnlineGame(context, client); 
              return client;
          }
          )
        );
      })
    );
  }

  Future<void> _joinServer(BuildContext context) async {
    // 1. Show the dialog directly using the current context
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

    // 2. Abort if user cancelled or input is empty
    if (roomCode == null || roomCode.trim().isEmpty || !context.mounted) return;

    

    // 3. Navigate and inject the configured client
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LevelProvider(
          clientProvider: ChangeNotifierProvider<Client>(
            create: (innerContext) {
              final client = Client(game: innerContext.read<GomokuGame>(), player:  innerContext.read<Player>());
              client.joinGame(roomCode.trim().toUpperCase()).catchError((error) {
                if (innerContext.mounted) {
                  _showMessage(innerContext, error.toString());
                }
              });
              return client;
            },
          ),
        ),
      ),
    );
  }

    // Navigator.of(context).push(
    //   MaterialPageRoute(builder: (_) {
    //     return levelProvider;
    //   })
    // );
    
  
  void _startLocal(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => 
        LevelProvider() 
      )
    );
  }

  @override
  Widget build(BuildContext context){
    return Scaffold(body: SafeArea(child: Container(
      width: MediaQuery.widthOf(context),
      height: MediaQuery.widthOf(context),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor
      ),

      child: FractionallySizedBox(
        widthFactor: .3,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: .center,
          children: [
            Padding (
              padding: EdgeInsetsGeometry.symmetric(vertical: 20),
              child: 
                Text(
                  "Gomoku Royale",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 100,
                    color: Theme.of(context).secondaryHeaderColor,
                    decoration: TextDecoration.none
                  )
                )
            ),

            Column(
              mainAxisAlignment: .center,
              crossAxisAlignment: .stretch,
              mainAxisSize: MainAxisSize.min,
              spacing: 40,
              children: [
                Flexible(
                  child: ElevatedButton(onPressed: () => _startServer(context), child: Text("Start Server", style: TextStyle(fontSize: 50))),
                ),
                Flexible(
                  child: ElevatedButton(onPressed: () => _joinServer(context), child: Text("Join Server", style: TextStyle(fontSize: 50))),
                ),
                Flexible(
                  child: ElevatedButton(onPressed: () => _startLocal(context), child: Text("Play Local", style: TextStyle(fontSize: 50))),
                )
                
              ]
            ),
          ]
        )
      )
    )));
    

  }
}
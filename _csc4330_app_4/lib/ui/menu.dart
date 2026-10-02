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

  Widget _menuButton(BuildContext context, String label, IconData icon, VoidCallback onPressed) {
    final scheme = Theme.of(context).colorScheme;
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 40),
      label: Text(label, style: const TextStyle(fontSize: 50, fontWeight: FontWeight(1000))),
      style: ElevatedButton.styleFrom(
        backgroundColor: scheme.primary,
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        foregroundColor: scheme.onPrimary,
        elevation: 8,
        shadowColor: Colors.black45,
        side: BorderSide(color: scheme.onPrimary.withValues(alpha: .25)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
    );
  }

  // Five in a row: purely decorative stones between title and buttons.
  Widget _stones() {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 18,
        children: [
          for (final dark in const [true, false, true, false, true])
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: dark ? const Color(0xFF16121C) : Colors.white,
                border: Border.all(color: Colors.white24),
                boxShadow: const [
                  BoxShadow(color: Colors.black38, blurRadius: 8, offset: Offset(0, 4)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context){
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(body: SafeArea(child: Container(
      width: MediaQuery.widthOf(context),
      height: MediaQuery.widthOf(context),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(-.4, -.5),
          radius: 1.5,
          colors: [
            scheme.primary,
            Color.lerp(scheme.primary, Colors.black, .72)!,
            const Color(0xFF0E0616),
          ],
        )
      ),

      child: FractionallySizedBox(
        widthFactor: .3,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeOutCubic,
          builder: (context, t, child) => Opacity(
            opacity: t,
            child: Transform.translate(offset: Offset(0, 24 * (1 - t)), child: child),
          ),
          child: Column(
            spacing: 20,
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
                      color: scheme.onPrimary,
                      decoration: TextDecoration.none,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 3,
                      shadows: [
                        Shadow(color: scheme.primary.withValues(alpha: .6), blurRadius: 48),
                        const Shadow(color: Colors.black54, blurRadius: 16, offset: Offset(0, 6)),
                      ],
                    )
                  )
              ),

              _stones(),

              Column(
                mainAxisAlignment: .center,
                crossAxisAlignment: .stretch,
                mainAxisSize: MainAxisSize.min,
                spacing: 40,
                children: [
                  Flexible(
                    child: _menuButton(context, "Start Server", Icons.wifi_tethering, () => _startServer(context)),
                  ),
                  Flexible(
                    child: _menuButton(context, "Join Server", Icons.login, () => _joinServer(context)),
                  ),
                  Flexible(
                    child: _menuButton(context, "Play Local", Icons.group, () => _startLocal(context)),
                  )
                ]
              ),
            ]
          ),
        ),
      )
    )));


  }
}
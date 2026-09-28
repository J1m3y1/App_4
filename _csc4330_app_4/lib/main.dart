import 'package:_csc4330_app_4/models/shaders.dart';
import 'package:_csc4330_app_4/ui/level.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui' as ui;

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
  Future<Provider<Shaders>> _fetchShaderProvider() async {
    final shadingProgram = await ui.FragmentProgram.fromAsset("assets/shaders/shading.frag");
    final shading = shadingProgram.fragmentShader();

    final lightingProgram = await ui.FragmentProgram.fromAsset("assets/shaders/lighting.frag");
    final lighting = lightingProgram.fragmentShader();

    Shaders shaders = Shaders(shading: shading, lighting: lighting);
    return Provider(create: (context) => shaders);
  }
  
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _fetchShaderProvider(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting){
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError){
          return Text('Error: ${snapshot.error}');
        }
        else {
          return MultiProvider(
            providers: [snapshot.data!], 
            child: Scaffold(
              appBar: AppBar(
                backgroundColor: Theme.of(context).colorScheme.inversePrimary,
                title: Text(widget.title),
              ),
              // TODO: Fill in level provider providers with providers obtained from instatiting client-server connections and new games
              body: LevelProvider()
            )
          );
        }
      }
    );
  }
}

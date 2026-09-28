import 'dart:ui';

import 'package:_csc4330_app_4/models/client.dart';
import 'package:_csc4330_app_4/models/gomoku_game.dart';
import 'package:_csc4330_app_4/models/player.dart';
import 'package:_csc4330_app_4/ui/animations.dart';
import 'package:_csc4330_app_4/ui/decoration.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import './piece.dart';



Container _boardContainer (Widget? interior) {
  List<Widget> children = [];
  children.add(SizedBox(width: 64.0, height: 64.0, child: const SizedBox.shrink()));
  if (interior != null) children.add(interior);
  
  return Container(
    decoration: BoxDecoration(
      border: Border.all(
        color: Colors.black,
        width: 1.0
      )
    ),
    child: Stack( 
      children: children
    )
  );
}

class BoardWidget extends StatefulWidget {
  const BoardWidget({super.key});
  

  @override
  State<BoardWidget> createState() => _BoardWidgetState();
}

class _BoardWidgetState extends State<BoardWidget> {
  GomokuGame? _game;
  Player? _player;
  Client? _client;

  late List<List<Piece?>> pieces;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final GomokuGame newGame = context.watch();
    final Player newPlayer = context.watch();
    final Client newClient = context.watch();

    if(_game != newGame){
      _detachListeners();
      _game = newGame;
      _initBoard();
      _attachListeners();
    }

    if(_player != newPlayer){
      _player = newPlayer;
    }

    if(_client != newClient){
      _client = newClient;
    }
  }

  void _attachListeners(){
    _game?.piecePlacedNotifier.addListener(_onPiecePlaced);
    _game?.pieceRemovedNotifier.addListener(_onPieceRemoved);
    _game?.gameStartedNotifier.addListener(_onGameStartChange);
  }

  void _detachListeners(){
    _game?.piecePlacedNotifier.removeListener(_onPiecePlaced);
    _game?.pieceRemovedNotifier.removeListener(_onPieceRemoved);
    _game?.gameStartedNotifier.removeListener(_onGameStartChange);
  }

  void _initBoard(){
    pieces = [ for (List<Stone> row in _game!.board)
        [ for (Stone stone in row) if (stone == Stone.black) Piece(PieceColor.black) else if (stone == Stone.white) Piece(PieceColor.white) else null]
    ];
  }

  @override
  void dispose(){
    _detachListeners();
    super.dispose(); 
  }

  void _onPiecePlaced() {
    (int, int) coordinate = _game!.piecePlacedNotifier.value;
    Stone stone = _game!.board[coordinate.$1][coordinate.$2];

    setState(() {
      Piece? piece;
      if (stone == Stone.black){
        piece = Piece(PieceColor.black); 
      } else if (stone == Stone.white){
        piece = Piece(PieceColor.white);
      } else {
        piece = null;
      }

      pieces[coordinate.$1][coordinate.$2] = piece;
    }); 
  }

  void _onGameStartChange(){

  }

  void _onPieceRemoved(){
    (int, int) coordinate = _game!.pieceRemovedNotifier.value;
    Stone stone = _game!.board[coordinate.$1][coordinate.$2];

    setState(() {
      Piece? piece;
      if (stone == Stone.black){
        piece = Piece(PieceColor.black); 
      } else if (stone == Stone.white){
        piece = Piece(PieceColor.white);
      } else {
        piece = null;
      }

      pieces[coordinate.$1][coordinate.$2] = piece;
    }); 
  }

  bool _moveIsValid(){
    Stone color = _player!.color;
    Stone currentColor = _game!.currentPlayer;
    bool gameIsOver =_game!.isGameOver;
    bool online = _client!.isOnline;

    return (!gameIsOver && ((color == currentColor) || !online));
  } 

  void Function() _onClick(int row, int column) {
    return (() {
      if (_moveIsValid()) {
        _game!.placeStone(row, column);
      }
    });
  }

  HoverableAnimation _previewPiece(int row, int column) {
    Stone color = _player!.color;
    Stone currentColor = _game!.currentPlayer;
    Widget pieceWidget;
    ValueNotifier<bool> toggleAnimation = ValueNotifier(_moveIsValid() && color != Stone.none);

    if(_moveIsValid()){
      if (currentColor == Stone.black){
        pieceWidget = Image.asset(
          "assets/black-piece.png",
          opacity: AlwaysStoppedAnimation(.5),
          height: 64,
          width: 64
        );
      } else if (currentColor == Stone.white){
        pieceWidget = Image.asset(
          "assets/white-piece.png",
          opacity: AlwaysStoppedAnimation(.5),
          height: 64,
          width: 64
        );
      } else {
        pieceWidget = SizedBox.shrink();
      }
    } else {
      pieceWidget = SizedBox.shrink();
    }
    
    (Widget, BoxDecoration) hoverOn = (
      pieceWidget,
      BoxDecoration()
    );

    (Widget, BoxDecoration) hoverOff = (
      const SizedBox(width: 64, height: 64),
      BoxDecoration() 
    );

    return HoverableAnimation(
      hoverOn: hoverOn,
      hoverOff: hoverOff,
      duration: const Duration(milliseconds: 10),
      onClickCallback: _onClick(row, column),
      toggleAnimation: toggleAnimation
    );
  }

  @override 
  Widget build(BuildContext context){
    FragmentShader? shader = context.read();

    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.black,
          width: 1.0
        )
      ),
      child: Container(
        decoration: ShaderDecoration(shader: shader!, baseColor: Colors.brown, intensity:.08),
        child: Row(
        mainAxisAlignment: .center,
          children: [
            for (int i=0; i<pieces.length; i++) Column(
              mainAxisAlignment: .center,
              children: [
                for (int j=0; j<pieces[i].length; j++) if (pieces[i][j] != null) _boardContainer(pieces[i][j]) else _boardContainer(_previewPiece(i, j))
              ]
            )
          ]
        )
      )
    ); 
  }
}
import 'dart:math';

import 'package:_csc4330_app_4/models/client.dart';
import 'package:_csc4330_app_4/models/gomoku_game.dart';
import 'package:_csc4330_app_4/models/player.dart';
import 'package:_csc4330_app_4/models/shaders.dart';
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
      clipBehavior: Clip.none,
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
  
  (int, int)? _pieceIsPlaying;
  late bool _gameIsOver; 
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
      _gameIsOver = !_game!.gameStartedNotifier.value;
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
    _game?.gameStartedNotifier.addListener(_onGameStartedChange);
  }

  void _detachListeners(){
    _game?.piecePlacedNotifier.removeListener(_onPiecePlaced);
    _game?.pieceRemovedNotifier.removeListener(_onPieceRemoved);
    _game?.gameStartedNotifier.removeListener(_onGameStartedChange);
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

  void _onGameStartedChange(){
    setState(() => _gameIsOver = !_game!.gameStartedNotifier.value);
  }

  bool _moveIsValid(){
    Stone color = _player!.color;
    Stone currentColor = _game!.currentPlayer;
    bool online = _client!.isOnline;

    return (_pieceIsPlaying == null) && (!_gameIsOver && ((color == currentColor) || !online));
  } 

  void Function() _onClick(int row, int column) {
    return (() {
      if (_moveIsValid()) {
        setState(() => _pieceIsPlaying = (row, column));
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

  PlacingPieceAnimation _placingPiece(int row, int column){
    return PlacingPieceAnimation(
      pieceWidget: pieces[row][column]!,
      onLanded: () => setState(() => _pieceIsPlaying = null)
    );
  }

  @override 
  Widget build(BuildContext context){
    Shaders shaders = context.read();

    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.black,
          width: 1.0
        )
      ),
      child: Container(
        decoration: ShaderDecoration(shader: shaders.shading, baseColor: Colors.brown, intensity:.08),
        child: Row(
        mainAxisAlignment: .center,
          children: [
            for (int i=0; i<pieces.length; i++) Column(
              mainAxisAlignment: .center,
              children: [
                for (int j=0; j<pieces[i].length; j++) (() {
                  if ((_pieceIsPlaying == (i, j)) && pieces[i][j] != null){
                    return Stack(
                      clipBehavior: Clip.none ,
                      children: [
                        _boardContainer(null),
                        _placingPiece(i, j)
                      ]
                    );
                  }
                  else if (pieces[i][j] != null){
                    return _boardContainer(pieces[i][j]);
                  }
                  else {
                    return _boardContainer(_previewPiece(i, j));
                  }
                })()
              ]
            )
          ]
        )
      )
    );
  }
}
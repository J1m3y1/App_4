import 'package:_csc4330_app_4/models/gomoku_game.dart';
import 'package:flutter/material.dart';
import './piece.dart';


Container _boardContainer (Widget? interior) {
  List<Widget> children = [];
  children.add(SizedBox(width: 64.0, height: 64.0, child: const SizedBox.shrink()));
  if (interior != null) children.add(interior);
  
  return Container(
    padding: const EdgeInsets.all(16.0),
    decoration: BoxDecoration(
      color: Colors.amber,
      border: Border.all(
        color: Colors.white,
        width: 2.0
      )
    ),
    child: Stack( 
      children: children
    )
  );
}

class BoardWidget extends StatefulWidget {
  final GomokuGame game; // Game singleton

  const BoardWidget(this.game, {super.key});
  

  @override
  State<BoardWidget> createState() => _BoardWidgetState(game);
}

class _BoardWidgetState extends State<BoardWidget> {
  final GomokuGame game;
  late List<List<Piece?>> pieces;

  _BoardWidgetState(this.game);

  @override
  void initState() {
    super.initState();

    setState(() {
      pieces = [ for (List<Stone> row in game.board)
        [ for (Stone stone in row) if (stone == Stone.black) Piece(PieceColor.black) else if (stone == Stone.white) Piece(PieceColor.white) else null]
      ];
    }); 

    game.piecePlacedNotifier.addListener(_onPiecePlaced);
    game.pieceRemovedNotifier.addListener(_onPieceRemoved);
    game.gameStartedNotifier.addListener(_onGameStartChange);
  }
  
  void _onPiecePlaced() {
    (int, int) coordinate = game.piecePlacedNotifier.value;
    Stone stone = game.board[coordinate.$1][coordinate.$2];

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
    (int, int) coordinate = game.pieceRemovedNotifier.value;
    Stone stone = game.board[coordinate.$1][coordinate.$2];

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


  @override 
  Widget build(BuildContext context){
    return Row(
      mainAxisAlignment: .center,
      children: [
        for (List<Piece?> row in pieces) Column(
          mainAxisAlignment: .center,
          children: [
            for (Piece? piece in row) _boardContainer(piece)
          ]
        )
      ]
    ); 
  }
}
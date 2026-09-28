import 'package:flutter/material.dart';

enum PieceColor {
  black,
  white
}

class Piece extends StatelessWidget {
  final PieceColor color;

  const Piece(this.color, {super.key}); 


  @override build(BuildContext context){
    String imageFp;
    if(color == PieceColor.black){
      imageFp = "assets/black-piece.png";
    } else {
      imageFp = "assets/white-piece.png";
    }

    return Image.asset(
      imageFp,
      width: 64.0,
      height: 64.0,
    );
  }
}
import 'package:_csc4330_app_4/models/gomoku_game.dart';
import 'package:_csc4330_app_4/models/player.dart';
import 'package:flutter/material.dart' hide Matrix4;
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:vector_math/vector_math_64.dart' hide Matrix4, Colors;

void doNothing() {}

class HoverableAnimation extends StatefulWidget {
  final (Widget, BoxDecoration) hoverOn;
  final (Widget, BoxDecoration) hoverOff; 
  final Duration duration;
  final Curve curve; 
  final Matrix4? transform;
  final ValueNotifier<bool>? toggleAnimation;
  final void Function() onClickCallback; 

  const HoverableAnimation({
    required this.hoverOn,
    required this.hoverOff,
    super.key,
    this.curve = Curves.easeOut,
    this.transform,
    this.duration=const Duration(milliseconds: 100),
    this.toggleAnimation,
    this.onClickCallback = doNothing
  });



  @override
  State<HoverableAnimation> createState() => _HoverableAnimationState();

}

class _HoverableAnimationState extends State<HoverableAnimation> {
  bool _isHovered = false;
  late bool _isOn;
  

  @override
  void initState() {
    super.initState();
    _isOn = widget.toggleAnimation?.value ?? true;
    widget.toggleAnimation?.addListener(_onToggleChanged);
  }

  void _onToggleChanged(){
    if (mounted){
      setState(() => _isOn = widget.toggleAnimation!.value);
    }
  }

  @override
  void didUpdateWidget(covariant HoverableAnimation oldWidget){
    super.didUpdateWidget(oldWidget);
    if(oldWidget.toggleAnimation != widget.toggleAnimation){
      oldWidget.toggleAnimation?.removeListener(_onToggleChanged);
      _isOn = widget.toggleAnimation?.value ?? true;
      widget.toggleAnimation?.addListener(_onToggleChanged);
    }
  }

  @override
  void dispose(){
    widget.toggleAnimation?.removeListener(_onToggleChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context){
    final showHover = (_isHovered && _isOn);

    return MouseRegion(
      cursor: _isOn ? SystemMouseCursors.click : MouseCursor.defer,
      hitTestBehavior: HitTestBehavior.opaque,
      onEnter: (context) => setState(() => _isHovered = true),
      onExit: (context) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onClickCallback,
        child: AnimatedContainer(
          duration: widget.duration,
          curve: widget.curve,
          transform: widget.transform,
          decoration: showHover ? widget.hoverOn.$2 : widget.hoverOff.$2,
          child: Stack(
            alignment: Alignment.center,
            children: [
              AnimatedOpacity(
                opacity: showHover ? 0 : 1,
                duration: widget.duration,
                curve: widget.curve,
                child: RepaintBoundary(child: widget.hoverOff.$1)
              ),
              AnimatedOpacity(
                opacity: showHover ? 1 : 0,
                duration: widget.duration,
                curve: widget.curve,
                child: RepaintBoundary(child: widget.hoverOn.$1)
              ),
            ],
          )
        )
      )
    ); 
  }

}

class PlacingPieceAnimation extends StatefulWidget {
  final Widget pieceWidget;
  final VoidCallback? onLanded;
  final Duration duration;

  const PlacingPieceAnimation({
    super.key,
    required this.pieceWidget,
    this.onLanded,
    this.duration = const Duration(seconds: 2)
  });

  @override
  State<PlacingPieceAnimation> createState() => _PlacingPieceAnimationState();
}

class _PlacingPieceAnimationState extends State<PlacingPieceAnimation> with SingleTickerProviderStateMixin{
  late final AnimationController _controller;
  late final Animation<double> _dropAnimation;
  final OverlayPortalController _portalController = OverlayPortalController(); 
  final LayerLink _layerLink = LayerLink();

  @override
  void initState(){
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: widget.duration  
    );

    _dropAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.bounceOut
    );

    _portalController.show(); 

    _controller.forward().then((_) {
      _portalController.hide();
      widget.onLanded?.call();
    });

    
  }

  @override
  void dispose(){
    _controller.dispose();
    super.dispose();
  }

  CompositedTransformTarget _overlayController(Widget child){
    return CompositedTransformTarget(
      link: _layerLink,
      child: OverlayPortal(
        controller: _portalController,
        overlayChildBuilder: (BuildContext context) {
          return CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            targetAnchor: Alignment.center,
            followerAnchor: Alignment.center,
            child: UnconstrainedBox(
              alignment: Alignment.center,
              child: child
            )
          );
        },
      child: SizedBox(width: 64, height: 64)
      )

    );
  }

  @override 
  Widget build(BuildContext context){
    return _overlayController(AnimatedBuilder(
      animation: _dropAnimation,
      builder: (context, child) {
        final progress = _dropAnimation.value;
        final heightAboveBoard = 1.0 - progress;

        final GomokuGame game = context.read();
        double sign = (game.currentPlayer == Stone.white) ? -1 : 1;

        final Matrix4 perspectiveMatrix = Matrix4.identity()..setEntry(3, 2, .0018)
          ..translateByVector3(Vector3(sign * 400.0 * heightAboveBoard, sign * 80.0 * heightAboveBoard, 200.0 * heightAboveBoard))
          ..rotateX(0.05*heightAboveBoard)
          ..rotateY(-0.05*heightAboveBoard)
          ..rotateZ(0.05*heightAboveBoard)
          ..scaleByDouble(1.0, 1.0, 1.0, (1.0 * progress).clamp(.1, 1));
          //..scaleAdjoint(1.0 + (200.0 * heightAboveBoard));

        final shadowBlur = 2.0 + (28.0 * heightAboveBoard);
        final shadowSpread = .5 + (8.0 * heightAboveBoard);
        final shadowOffset = Offset(3.0 + (40.0 * heightAboveBoard), 5.0 + (30.0 * heightAboveBoard));
        final shadowOpacity = ((0.5 - (0.35 * heightAboveBoard)).clamp(0.0, 1.0) * 255).toInt();

        return SizedBox(
            width: 64,
            height: 64,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Transform.translate(
                  offset: shadowOffset,
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(shadowOpacity),
                          blurRadius: shadowBlur,
                          spreadRadius: shadowSpread,
                        )
                      ]
                    )
                  )
                ),

                Transform(
                  alignment: Alignment.center,
                  transform: perspectiveMatrix,
                  child: widget.pieceWidget
                )
              ]
            )
        );
      }
    )); 
  }
}
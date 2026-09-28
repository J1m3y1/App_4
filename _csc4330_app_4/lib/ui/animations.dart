import 'package:flutter/widgets.dart';

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
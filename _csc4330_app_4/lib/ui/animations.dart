import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

class HoverableAnimation extends StatefulWidget {
  final (Widget, BoxDecoration) hoverOn;
  final (Widget, BoxDecoration) hoverOff; 
  final Duration duration;
  final Curve curve; 
  final Matrix4? transform;
  final ValueNotifier<bool>? toggleAnimation;

  const HoverableAnimation({
    required this.hoverOn,
    required this.hoverOff,
    super.key,
    this.curve = Curves.easeOut,
    this.transform,
    this.duration=const Duration(milliseconds: 100),
    this.toggleAnimation,
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
      hitTestBehavior: HitTestBehavior.opaque,
      onEnter: (context) => setState(() => _isHovered = true),
      onExit: (context) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: widget.duration,
        curve: widget.curve,
        transform: widget.transform,
        decoration: showHover ? widget.hoverOn.$2 : widget.hoverOff.$2,
        child: AnimatedCrossFade(
          duration: widget.duration,
          firstCurve: widget.curve,
          secondCurve: widget.curve,
          firstChild: widget.hoverOn.$1,
          secondChild: widget.hoverOff.$1,
          crossFadeState: showHover ? CrossFadeState.showFirst : CrossFadeState.showSecond
        )
      )
    ); 
  }

}
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
    this.duration=const Duration(milliseconds: 300),
    this.toggleAnimation,
  });



  @override
  State<HoverableAnimation> createState() => _HoverableAnimationState(hoverOn, hoverOff, duration, curve, transform, toggleAnimation);

}

class _HoverableAnimationState extends State<HoverableAnimation> {
  bool _isHovered = false;
  bool _isOn = true;
  (Widget, BoxDecoration) hoverOn;
  (Widget, BoxDecoration) hoverOff;
  Curve curve;
  Matrix4? transform;
  Duration duration;
  ValueNotifier<bool>? toggleAnimation;

  _HoverableAnimationState(this.hoverOn, this.hoverOff, this.duration, this.curve, this.transform, this.toggleAnimation);

  @override
  void initState() {
    super.initState();
    toggleAnimation?.addListener(() => _isOn = toggleAnimation!.value);
  }

  @override
  Widget build(BuildContext context){
    return MouseRegion(
      onEnter: (context) => setState(() => _isHovered = true),
      onExit: (context) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: duration,
        curve: curve,
        transform: transform,
        decoration: (_isHovered && _isOn) ? hoverOn.$2 : hoverOff.$2,
        child: (_isHovered && _isOn) ? hoverOn.$1 : hoverOff.$1
      )
    ); 
  }

}
import 'dart:ui' as ui;
import 'package:_csc4330_app_4/models/shaders.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; 

class ShaderDecoration extends Decoration {
  final ui.FragmentShader shader;
  final Color baseColor; 
  final double intensity;
  final BorderRadius? borderRadius;

  const ShaderDecoration({
    required this.shader, 
    required this.baseColor,
    this.intensity = 0.15,
    this.borderRadius,
  });

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]){
    return _ShaderBoxPainter(this);
  }
}

class _ShaderBoxPainter extends BoxPainter {
  final ShaderDecoration decoration;

  _ShaderBoxPainter(this.decoration);

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration){
    final Size size = configuration.size ?? Size.zero;
    if (size.isEmpty) return;

    final shader = decoration.shader;
    int index = 0;

    // Uniform 0: vec2 uResolution (2 floats)
    shader.setFloat(index++, size.width);
    shader.setFloat(index++, size.height);

    // Uniform 1: vec4 uBaseColor (4 floats)
    final color = decoration.baseColor;
    shader.setFloat(index++, color.r);
    shader.setFloat(index++, color.g);
    shader.setFloat(index++, color.b);
    shader.setFloat(index++, color.a);

    // Uniform 2: float uIntensity (1 float)
    shader.setFloat(index++, decoration.intensity);

    final Paint paint = Paint()..shader = shader;
    final Rect rect = offset & size;

    if (decoration.borderRadius != null) {
      final RRect rrect = decoration.borderRadius!.toRRect(rect);
      canvas.drawRRect(rrect, paint);
    } else {
      canvas.drawRect(rect, paint);
    }
  }
}

class SceneLighting extends StatefulWidget {
  final Widget child;
  final Offset lightPosition;
  final double lightRadius;
  final Color lightColor;
  final double ambientIntensity;

  const SceneLighting({
    super.key,
    required this.child,
    required this.lightPosition,
    this.lightRadius = 350.0,
    this.lightColor = Colors.white,
    this.ambientIntensity = 0.35,
  });

  @override
  State<SceneLighting> createState() => _SceneLightingState();
}

class _SceneLightingState extends State<SceneLighting> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    Shaders shaders = context.read();
    ui.FragmentShader shader = shaders.lighting;

    return LayoutBuilder(
      builder: (context, constraints) {
        return ShaderMask(
          blendMode: BlendMode.modulate, // Multiplies light map with the scene
          shaderCallback: (Rect bounds) {
            int index = 0;
            
            // Uniform 1: vec2 uLightPos (2 floats)
            shader.setFloat(index++, widget.lightPosition.dx);
            shader.setFloat(index++, widget.lightPosition.dy);

            // Uniform 2: vec3 uLightColor (3 floats)
            shader.setFloat(index++, widget.lightColor.r);
            shader.setFloat(index++, widget.lightColor.g);
            shader.setFloat(index++, widget.lightColor.b);

            // Uniform 3: float uLightRadius (1 float)
            shader.setFloat(index++, widget.lightRadius);

            // Uniform 4: float uAmbientIntensity (1 float)
            shader.setFloat(index++, widget.ambientIntensity);

            return shader;
          },
          child: widget.child,
        );
      },
    );
  }
}
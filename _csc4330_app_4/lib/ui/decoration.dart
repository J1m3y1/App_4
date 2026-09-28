import 'dart:ui' as ui;
import 'package:flutter/material.dart'; 

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
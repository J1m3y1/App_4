#version 460 core
precision mediump float;

#include <flutter/runtime_effect.glsl>

layout(location = 0) uniform vec2 uResolution;
layout(location = 1) uniform vec4 uBaseColor;
layout(location = 2) uniform float uIntensity;

out vec4 fragColor;

float random(vec2 st){
    return fract(sin(dot(st.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

void main() {
    vec2 pos = FlutterFragCoord().xy;
    float noise = (random(pos) - 0.5) * 2.0;
    vec3 shadedColor = uBaseColor.rgb + (noise * uIntensity);
    fragColor = vec4(clamp(shadedColor, 0.0, 1.0), uBaseColor.a);
}
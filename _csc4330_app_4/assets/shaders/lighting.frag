#version 460 core
precision mediump float;

#include <flutter/runtime_effect.glsl>

// 2. Light position in canvas pixel coordinates (x, y)
layout(location = 0) uniform vec2 uLightPos;
// 3. Light color (RGB)
layout(location = 1) uniform vec3 uLightColor;
// 4. Light radius in pixels
layout(location = 2) uniform float uLightRadius;
// 5. Ambient brightness (e.g., 0.2 = dark ambient, 1.0 = full unlit)
layout(location = 3) uniform float uAmbientIntensity;


out vec4 fragColor;

void main() {
    vec2 fragCoord = FlutterFragCoord().xy;

    // Calculate distance from current pixel to the light source
    float dist = distance(fragCoord, uLightPos);

    // Smooth radial attenuation/falloff
    float attenuation = clamp(1.0 - (dist / uLightRadius), 0.0, 1.0);
    attenuation = attenuation * attenuation; // quadratic falloff for soft glow

    // Calculate total illumination factor
    vec3 light = vec3(uAmbientIntensity) + (uLightColor * attenuation);

    fragColor = vec4(clamp(light, 0.0, 1.0), 1.0);
}
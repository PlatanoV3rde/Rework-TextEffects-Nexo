#version 150

#moj_import <fog.glsl>

uniform sampler2D Sampler0;
uniform vec4 ColorModulator;
uniform float FogStart;
uniform float FogEnd;
uniform vec4 FogColor;

in float vertexDistance;
in vec4 vertexColor;
in vec2 texCoord0;

in vec3 spinT0;
in vec3 spinT1;
in vec3 spinT2;
in vec3 spinT3;
in float spinFlip;
in float spinScale;

out vec4 fragColor;

vec2 calculateUVBounds(vec3 t0, vec3 t1, vec3 t2, vec3 t3, out vec2 uvMin, out vec2 uvMax) {
    uvMin = vec2(100.0);
    uvMax = vec2(-100.0);

    if (t0.z > 0.001) { vec2 p = t0.xy / t0.z; uvMin = min(uvMin, p); uvMax = max(uvMax, p); }
    if (t1.z > 0.001) { vec2 p = t1.xy / t1.z; uvMin = min(uvMin, p); uvMax = max(uvMax, p); }
    if (t2.z > 0.001) { vec2 p = t2.xy / t2.z; uvMin = min(uvMin, p); uvMax = max(uvMax, p); }
    if (t3.z > 0.001) { vec2 p = t3.xy / t3.z; uvMin = min(uvMin, p); uvMax = max(uvMax, p); }

    return uvMax - uvMin;
}

void applySpinEffect(inout vec2 uv, vec3 t0, vec3 t1, vec3 t2, vec3 t3, float scale, float flip, vec2 originalUV) {
    if (scale >= 0.99 && flip <= 0.5) {
        return;
    }

    vec2 uvMin, uvMax;
    vec2 uvSize = calculateUVBounds(t0, t1, t2, t3, uvMin, uvMax);

    float minX = 1.0;
    float maxX = 0.0;
    bool hasInk = false;

    for (float x = 0.0; x <= 1.0; x += 0.05) {
        for (float y = 0.0; y <= 1.0; y += 0.05) {
            if (texture(Sampler0, uvMin + vec2(x, y) * uvSize).a > 0.1) {
                if (x < minX) minX = x;
                maxX = x;
                hasInk = true;
            }
        }
    }

    float inkCenter = 0.5;
    if (hasInk) {
        inkCenter = (minX + maxX) * 0.5;
    }

    float currentNormX = (originalUV.x - uvMin.x) / uvSize.x;
    float distFromInkCenter = currentNormX - inkCenter;
    float sampleDist = distFromInkCenter / scale;

    if (flip > 0.5) {
        sampleDist = -sampleDist;
    }

    float targetNormX = inkCenter + sampleDist;
    if (targetNormX < 0.0 || targetNormX > 1.0) {
        discard;
    }

    uv.x = uvMin.x + targetNormX * uvSize.x;
}

void main() {
    vec2 uv = texCoord0;
    applySpinEffect(uv, spinT0, spinT1, spinT2, spinT3, spinScale, spinFlip, texCoord0);

    vec4 color = texture(Sampler0, uv) * vertexColor * ColorModulator;
    if (color.a < 0.1) {
        discard;
    }

    if (vertexColor.rgb == vec3(1.0, 1.0, 1.0)) {
        fragColor = color;
    } else {
        fragColor = linear_fog(color, vertexDistance, FogStart, FogEnd, FogColor);
    }
}

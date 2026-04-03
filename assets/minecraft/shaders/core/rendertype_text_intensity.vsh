#version 150

precision highp float;

#define PI 3.14159265359
#define TAU 6.28318530718

in vec3 Position;
in vec4 Color;
in vec2 UV0;
in ivec2 UV2;

uniform sampler2D Sampler2;
uniform mat4 ModelViewMat;
uniform mat4 ProjMat;
uniform float GameTime;

out float vertexDistance;
out vec4 vertexColor;
out vec2 texCoord0;

out vec3 spinT0;
out vec3 spinT1;
out vec3 spinT2;
out vec3 spinT3;
out float spinFlip;
out float spinScale;

float random(vec2 seed) {
    return fract(sin(dot(seed, vec2(12.9898, 78.233))) * 43758.5453);
}

float noise(float n) {
    float i = floor(n);
    float f = fract(n);
    return mix(random(vec2(i, 0.0)), random(vec2(i + 1.0, 0.0)), smoothstep(0.0, 1.0, f));
}

vec3 hue(float t) {
    t = fract(t);
    float r = abs(t * 6.0 - 3.0) - 1.0;
    float g = 2.0 - abs(t * 6.0 - 2.0);
    float b = 2.0 - abs(t * 6.0 - 4.0);
    return clamp(vec3(r, g, b), 0.0, 1.0);
}

void resetSpinData() {
    spinT0 = vec3(0.0);
    spinT1 = vec3(0.0);
    spinT2 = vec3(0.0);
    spinT3 = vec3(0.0);
    spinFlip = 0.0;
    spinScale = 1.0;
}

void finalize(in vec4 vertex) {
    vertexDistance = length((ModelViewMat * vertex).xyz);
    texCoord0 = UV0;
}

void applyProjection(inout vec4 vertex) {
    gl_Position = ProjMat * ModelViewMat * vertex;
}

void applyColorTexture() {
    vertexColor = Color * texelFetch(Sampler2, UV2 / 16, 0);
}

void applyWhiteColor() {
    vec4 texColor = texelFetch(Sampler2, UV2 / 16, 0);
    vertexColor = vec4(1.0, 1.0, 1.0, Color.a) * texColor;
}

void applyHueColor(float speed, float xPos, float yPos, float shadowScale) {
    vec3 rainbowColor = hue((GameTime * speed) + (xPos + yPos) * 0.01) * shadowScale;
    vertexColor = vec4(rainbowColor, 1.0) * texelFetch(Sampler2, UV2 / 16, 0);
}

void applyGradientColor(vec3 startColor, vec3 endColor, float direction, float shadowScale) {
    float vid = mod(float(gl_VertexID), 4.0);
    float x_t = (vid == 2.0 || vid == 3.0) ? 1.0 : 0.0;
    float y_t = (vid == 1.0 || vid == 2.0) ? 1.0 : 0.0;

    int dir = int(direction);
    float t;
    if      (dir == 0) t = 1.0 - y_t;
    else if (dir == 1) t = (x_t + (1.0 - y_t)) * 0.5;
    else if (dir == 2) t = x_t;
    else if (dir == 3) t = (x_t + y_t) * 0.5;
    else if (dir == 4) t = y_t;
    else if (dir == 5) t = ((1.0 - x_t) + y_t) * 0.5;
    else if (dir == 6) t = 1.0 - x_t;
    else               t = ((1.0 - x_t) + (1.0 - y_t)) * 0.5;

    vec3 gradColor = mix(startColor, endColor, t) * shadowScale;
    vertexColor = vec4(gradColor, 1.0) * texelFetch(Sampler2, UV2 / 16, 0);
}

void applyDynamicGradientColor(vec3 startColor, vec3 endColor, float direction, float speed, float xPos, float yPos, float shadowScale) {
    int dir = int(direction);
    float spatial;
    if      (dir == 0) spatial =  yPos;
    else if (dir == 1) spatial =  xPos + yPos;
    else if (dir == 2) spatial =  xPos;
    else if (dir == 3) spatial =  xPos - yPos;
    else if (dir == 4) spatial = -yPos;
    else if (dir == 5) spatial = -xPos - yPos;
    else if (dir == 6) spatial = -xPos;
    else               spatial = -xPos + yPos;

    float t = 1.0 - abs(fract(GameTime * speed + spatial * 0.01) * 2.0 - 1.0);
    vec3 gradColor = mix(startColor, endColor, t) * shadowScale;
    vertexColor = vec4(gradColor, 1.0) * texelFetch(Sampler2, UV2 / 16, 0);
}

void processSpinCommon() {
    int vid = gl_VertexID % 4;
    if (vid == 0) spinT0 = vec3(texCoord0, 1.0);
    if (vid == 1) spinT2 = vec3(texCoord0, 1.0);
    if (vid == 2) spinT1 = vec3(texCoord0, 1.0);
    if (vid == 3) spinT3 = vec3(texCoord0, 1.0);
}

void processSpin(inout vec4 vertex, float speed) {
    if (speed <= 0.0) speed = 2500.0;
    float time = GameTime * speed;
    float cosA = cos(mod(time, PI * 2.0));
    spinFlip = (cosA < 0.0) ? 1.0 : 0.0;
    spinScale = abs(cosA);
    processSpinCommon();
    applyProjection(vertex);
}

void processSequentialSpin(inout vec4 vertex, float speed) {
    if (speed <= 0.0) speed = 2500.0;
    float charIndex = floor(float(gl_VertexID) / 4.0);
    float t = mod((charIndex * 0.4 - GameTime * speed / TAU), 5.0);
    float cosA;
    if (t > 1.0) cosA = 1.0;
    else cosA = cos(TAU * t);
    spinFlip = (cosA < 0.0) ? 1.0 : 0.0;
    spinScale = abs(cosA);
    processSpinCommon();
    applyProjection(vertex);
}

void processRainbowEffect(inout vec4 vertex, float speed) {
    float preX = vertex.x;
    float preY = vertex.y;
    applyProjection(vertex);
    applyHueColor(speed, preX, preY, 1.0);
    finalize(vertex);
}

void processWavyEffect(inout vec4 vertex, float speed, float amplitude, float xFrequency) {
    applyProjection(vertex);
    gl_Position.y += sin(GameTime * speed + (Position.x * xFrequency)) * (amplitude / 150.0);
    applyColorTexture();
    finalize(vertex);
}

void processWavyRainbowEffect(inout vec4 vertex) {
    float preX = vertex.x;
    float preY = vertex.y;
    applyProjection(vertex);
    gl_Position.y += sin(GameTime * 12000.0 + (Position.x * 0.35)) * (0.5 / 150.0);
    applyHueColor(500.0, preX, preY, 1.0);
    finalize(vertex);
}

void processBouncyEffect(inout vec4 vertex, float speed, float amp) {
    applyColorTexture();
    float vertexId = mod(float(gl_VertexID), 4.0);
    if (speed <= 0.0) speed = 3000.0;
    if (amp <= 0.0) amp = 1.0;
    float time = GameTime * speed;
    if (vertexId == 3.0 || vertexId == 0.0) {
        vertex.y += cos(time) * amp;
        vertex.y += max(cos(time) * amp, 0.0);
    }
    applyProjection(vertex);
    finalize(vertex);
}

void processBouncyRainbowEffect(inout vec4 vertex) {
    float preX = vertex.x;
    float preY = vertex.y;
    float vertexId = mod(float(gl_VertexID), 4.0);
    if (vertexId == 3.0 || vertexId == 0.0) {
        vertex.y += cos(GameTime * 3000.0) * 1.0;
        vertex.y += max(cos(GameTime * 3000.0) * 1.0, 0.0);
    }
    applyProjection(vertex);
    applyHueColor(500.0, preX, preY, 1.0);
    finalize(vertex);
}

void processBlinkingEffect(inout vec4 vertex, float speed) {
    applyProjection(vertex);
    if (speed <= 0.0) speed = 0.5;
    float blink = abs(sin(GameTime * 12000.0 * speed));
    vertexColor = Color * blink * texelFetch(Sampler2, UV2 / 16, 0);
    finalize(vertex);
}

void processNoShadow(inout vec4 vertex) {
    applyProjection(vertex);
    applyWhiteColor();
    finalize(vertex);
}

void processShakeEffect(inout vec4 vertex, float speed, float intensity) {
    if (speed <= 0.0) speed = 1.0;
    if (intensity <= 0.0) intensity = 1.0;
    float charId = floor(float(gl_VertexID) / 4.0);
    float time = GameTime * 32000.0 * speed;
    float noiseX = noise(charId * 10.0 + time) - 0.5;
    float noiseY = noise(charId * 10.0 - time + 100.0) - 0.5;
    vertex.x += noiseX * intensity;
    vertex.y += noiseY * intensity;
    applyProjection(vertex);
    applyColorTexture();
    finalize(vertex);
}

void processPulseEffect(inout vec4 vertex, float speed, float size) {
    if (speed <= 0.0) speed = 20.0;
    if (size <= 0.0) size = 0.4;
    float time = GameTime * speed * 1000.0;
    float factor = (sin(time) * 0.5 + 0.5);
    float expansion = size * 2.5 * factor;

    float vertexId = mod(float(gl_VertexID), 4.0);
    vec2 dir = vec2(0.0);
    if (vertexId < 0.5) dir = vec2(-1.0, -1.0);
    else if (vertexId < 1.5) dir = vec2(-1.0, 1.0);
    else if (vertexId < 2.5) dir = vec2(1.0, 1.0);
    else dir = vec2(1.0, -1.0);
    dir *= vec2(0.7, 1.0);

    vertex.xy += dir * expansion;
    applyProjection(vertex);
    applyColorTexture();
    finalize(vertex);
}

void processFadeEffect(inout vec4 vertex, float speed) {
    if (speed <= 0.0) speed = 1.0;
    applyProjection(vertex);
    float alpha = sin(GameTime * 3000.0 * speed);
    alpha = (alpha + 1.0) * 0.5;
    vec4 texColor = texelFetch(Sampler2, UV2 / 16, 0);
    vertexColor = Color * texColor;
    vertexColor.a *= alpha;
    finalize(vertex);
}

void processIteratingEffect(inout vec4 vertex, float speed, float space) {
    if (speed <= 0.0) speed = 1.0;
    if (space <= 0.0) space = 1.0;
    float charX = floor(vertex.x / 8.0);
    float time = GameTime * 18000.0 * speed;
    float x = mod(charX * 0.4 - time, (5.0 * space) * TAU);
    if (x > TAU) x = TAU;
    vertex.y -= (-cos(x) * 0.5 + 0.5) * 2.0;
    applyProjection(vertex);
    applyColorTexture();
    finalize(vertex);
}

void processGlitchEffect(inout vec4 vertex, float speed, float intensity) {
    if (speed <= 0.0) speed = 1.0;
    if (intensity <= 0.0) intensity = 2.0;
    float time = floor(GameTime * 32000.0 * speed);
    float charX = floor(vertex.x / 8.0);
    float glitchTrigger = random(vec2(time * 0.1, 0.0));
    if (glitchTrigger > 0.7) {
        float offsetX = (random(vec2(charX + time, 1.0)) - 0.5) * intensity * 4.0;
        vertex.x += offsetX;
    }
    if (glitchTrigger > 0.85) {
        float offsetY = (random(vec2(charX - time + 50.0, 2.0)) - 0.5) * intensity;
        vertex.y += offsetY;
    }
    applyProjection(vertex);
    applyColorTexture();
    finalize(vertex);
}

void processScaleEffect(inout vec4 vertex, float expansion, float offsetX, float offsetY) {
    float vertexId = mod(float(gl_VertexID), 4.0);
    vec2 dir;
    if      (vertexId < 0.5) dir = vec2(-1.0, -1.0);
    else if (vertexId < 1.5) dir = vec2(-1.0,  1.0);
    else if (vertexId < 2.5) dir = vec2( 1.0,  1.0);
    else                     dir = vec2( 1.0, -1.0);

    float actualExpansion = (expansion - 1.0) * 4.0;
    dir *= vec2(0.7, 1.0);
    vertex.xy += dir * actualExpansion + vec2(offsetX, offsetY);

    applyProjection(vertex);
    applyColorTexture();
    finalize(vertex);
}

void processTintedScaleEffect(inout vec4 vertex, float expansion, float offsetX, float offsetY, vec3 tint, float shadowScale) {
    float vertexId = mod(float(gl_VertexID), 4.0);
    vec2 dir;
    if      (vertexId < 0.5) dir = vec2(-1.0, -1.0);
    else if (vertexId < 1.5) dir = vec2(-1.0,  1.0);
    else if (vertexId < 2.5) dir = vec2( 1.0,  1.0);
    else                     dir = vec2( 1.0, -1.0);

    float actualExpansion = (expansion - 1.0) * 4.0;
    dir *= vec2(0.7, 1.0);
    vertex.xy += dir * actualExpansion + vec2(offsetX, offsetY);

    applyProjection(vertex);
    vertexColor = vec4(tint * shadowScale, 1.0) * texelFetch(Sampler2, UV2 / 16, 0);
    finalize(vertex);
}

void processGradientEffect(inout vec4 vertex, vec3 startColor, vec3 endColor, float direction, float shadowScale) {
    applyProjection(vertex);
    applyGradientColor(startColor, endColor, direction, shadowScale);
    finalize(vertex);
}

void processDynamicGradientEffect(inout vec4 vertex, vec3 startColor, vec3 endColor, float direction, float speed, float shadowScale) {
    float xPos = vertex.x;
    float yPos = vertex.y;
    applyProjection(vertex);
    applyDynamicGradientColor(startColor, endColor, direction, speed, xPos, yPos, shadowScale);
    finalize(vertex);
}

void processSpinEffect(inout vec4 vertex, float speed) {
    processSpin(vertex, speed);
    applyColorTexture();
    finalize(vertex);
}

void processSequentialSpinEffect(inout vec4 vertex, float speed) {
    processSequentialSpin(vertex, speed);
    applyColorTexture();
    finalize(vertex);
}

void processTintedSequentialSpinEffect(inout vec4 vertex, float speed, vec3 tint, float shadowScale) {
    processSequentialSpin(vertex, speed);
    vertexColor = vec4(tint * shadowScale, 1.0) * texelFetch(Sampler2, UV2 / 16, 0);
    finalize(vertex);
}



void processTintedWavyEffect(inout vec4 vertex, float speed, float amplitude, float xFrequency, vec3 tint, float shadowScale) {
    applyProjection(vertex);
    gl_Position.y += sin(GameTime * speed + (Position.x * xFrequency)) * (amplitude / 150.0);
    vertexColor = vec4(tint * shadowScale, 1.0) * texelFetch(Sampler2, UV2 / 16, 0);
    finalize(vertex);
}

void processTintedBouncyEffect(inout vec4 vertex, float speed, float amp, vec3 tint, float shadowScale) {
    float vertexId = mod(float(gl_VertexID), 4.0);
    if (speed <= 0.0) speed = 3000.0;
    if (amp <= 0.0) amp = 1.0;
    float time = GameTime * speed;
    if (vertexId == 3.0 || vertexId == 0.0) {
        vertex.y += cos(time) * amp;
        vertex.y += max(cos(time) * amp, 0.0);
    }
    applyProjection(vertex);
    vertexColor = vec4(tint * shadowScale, 1.0) * texelFetch(Sampler2, UV2 / 16, 0);
    finalize(vertex);
}

void processTintedBlinkingEffect(inout vec4 vertex, float speed, vec3 tint, float shadowScale) {
    applyProjection(vertex);
    if (speed <= 0.0) speed = 0.5;
    float blink = abs(sin(GameTime * 12000.0 * speed));
    vertexColor = vec4(tint * shadowScale, Color.a) * blink * texelFetch(Sampler2, UV2 / 16, 0);
    finalize(vertex);
}

void processTintedShakeEffect(inout vec4 vertex, float speed, float intensity, vec3 tint, float shadowScale) {
    if (speed <= 0.0) speed = 1.0;
    if (intensity <= 0.0) intensity = 1.0;
    float charId = floor(float(gl_VertexID) / 4.0);
    float time = GameTime * 32000.0 * speed;
    float noiseX = noise(charId * 10.0 + time) - 0.5;
    float noiseY = noise(charId * 10.0 - time + 100.0) - 0.5;
    vertex.x += noiseX * intensity;
    vertex.y += noiseY * intensity;
    applyProjection(vertex);
    vertexColor = vec4(tint * shadowScale, 1.0) * texelFetch(Sampler2, UV2 / 16, 0);
    finalize(vertex);
}

void processTintedPulseEffect(inout vec4 vertex, float speed, float size, vec3 tint, float shadowScale) {
    if (speed <= 0.0) speed = 20.0;
    if (size <= 0.0) size = 0.4;
    float time = GameTime * speed * 1000.0;
    float factor = (sin(time) * 0.5 + 0.5);
    float expansion = size * 2.5 * factor;

    float vertexId = mod(float(gl_VertexID), 4.0);
    vec2 dir = vec2(0.0);
    if (vertexId < 0.5) dir = vec2(-1.0, -1.0);
    else if (vertexId < 1.5) dir = vec2(-1.0, 1.0);
    else if (vertexId < 2.5) dir = vec2(1.0, 1.0);
    else dir = vec2(1.0, -1.0);
    dir *= vec2(0.7, 1.0);

    vertex.xy += dir * expansion;
    applyProjection(vertex);
    vertexColor = vec4(tint * shadowScale, 1.0) * texelFetch(Sampler2, UV2 / 16, 0);
    finalize(vertex);
}

void processTintedSpinEffect(inout vec4 vertex, float speed, vec3 tint, float shadowScale) {
    processSpin(vertex, speed);
    vertexColor = vec4(tint * shadowScale, 1.0) * texelFetch(Sampler2, UV2 / 16, 0);
    finalize(vertex);
}

void processTintedFadeEffect(inout vec4 vertex, float speed, vec3 tint, float shadowScale) {
    if (speed <= 0.0) speed = 1.0;
    applyProjection(vertex);
    float alpha = sin(GameTime * 3000.0 * speed);
    alpha = (alpha + 1.0) * 0.5;
    vertexColor = vec4(tint * shadowScale, 1.0) * texelFetch(Sampler2, UV2 / 16, 0);
    vertexColor.a *= alpha;
    finalize(vertex);
}

void processTintedIteratingEffect(inout vec4 vertex, float speed, float space, vec3 tint, float shadowScale) {
    if (speed <= 0.0) speed = 1.0;
    if (space <= 0.0) space = 1.0;
    float charX = floor(vertex.x / 8.0);
    float time = GameTime * 18000.0 * speed;
    float x = mod(charX * 0.4 - time, (5.0 * space) * TAU);
    if (x > TAU) x = TAU;
    vertex.y -= (-cos(x) * 0.5 + 0.5) * 2.0;
    applyProjection(vertex);
    vertexColor = vec4(tint * shadowScale, 1.0) * texelFetch(Sampler2, UV2 / 16, 0);
    finalize(vertex);
}

void processTintedGlitchEffect(inout vec4 vertex, float speed, float intensity, vec3 tint, float shadowScale) {
    if (speed <= 0.0) speed = 1.0;
    if (intensity <= 0.0) intensity = 2.0;
    float time = floor(GameTime * 32000.0 * speed);
    float charX = floor(vertex.x / 8.0);
    float glitchTrigger = random(vec2(time * 0.1, 0.0));
    if (glitchTrigger > 0.7) {
        float offsetX = (random(vec2(charX + time, 1.0)) - 0.5) * intensity * 4.0;
        vertex.x += offsetX;
    }
    if (glitchTrigger > 0.85) {
        float offsetY = (random(vec2(charX - time + 50.0, 2.0)) - 0.5) * intensity;
        vertex.y += offsetY;
    }
    applyProjection(vertex);
    vertexColor = vec4(tint * shadowScale, 1.0) * texelFetch(Sampler2, UV2 / 16, 0);
    finalize(vertex);
}

void hideGlyph(inout vec4 vertex) {
    gl_Position = vec4(2.0, 2.0, 2.0, 1.0);
    applyColorTexture();
    finalize(vertex);
}

void main() {
    vec4 vertex = vec4(Position, 1.0);
    ivec3 iColor = ivec3(Color.xyz * 255.0 + vec3(0.5));
    texCoord0 = UV0;
    resetSpinData();

    if (fract(Position.z) < 0.1) {
        if (iColor == ivec3(19, 23, 9)) {
            hideGlyph(vertex);
            return;
        }
        if (iColor == ivec3(57, 63, 63)) {
            applyProjection(vertex);
            applyColorTexture();
            finalize(vertex);
            return;
        }
        if (iColor == ivec3(57, 63, 62) || iColor == ivec3(57, 62, 63)) {
            processTintedWavyEffect(vertex, 12000.0, 0.5, 0.35, vec3(80.0/255.0, 1.0, 80.0/255.0), 1.0);
            return;
        }
        if (iColor == ivec3(57, 62, 62) || iColor == ivec3(57, 61, 63)) {
            processTintedBouncyEffect(vertex, 3000.0, 1.0, vec3(1.0, 170.0/255.0, 0.0), 1.0);
            return;
        }
        if (iColor == ivec3(57, 61, 62)) {
            processTintedBlinkingEffect(vertex, 0.5, vec3(80.0/255.0, 80.0/255.0, 1.0), 1.0);
            return;
        }

        if (iColor == ivec3(57, 63, 61)) { processTintedShakeEffect(vertex, 1.0, 1.0, vec3(1.0, 80.0/255.0, 80.0/255.0), 0.25); return; }
        if (iColor == ivec3(57, 63, 60)) { processTintedPulseEffect(vertex, 20.0, 0.4, vec3(80.0/255.0, 1.0, 1.0), 0.25); return; }
        if (iColor == ivec3(57, 62, 61)) { processTintedSpinEffect(vertex, 2500.0, vec3(1.0, 80.0/255.0, 1.0), 0.25); return; }
        if (iColor == ivec3(57, 62, 60)) { processTintedFadeEffect(vertex, 1.0, vec3(1.0, 1.0, 80.0/255.0), 0.25); return; }
        if (iColor == ivec3(57, 61, 61)) { processTintedIteratingEffect(vertex, 1.0, 1.0, vec3(170.0/255.0, 0.0, 1.0), 0.25); return; }
        if (iColor == ivec3(57, 61, 60)) { processTintedGlitchEffect(vertex, 1.0, 2.0, vec3(1.0, 80.0/255.0, 80.0/255.0), 0.25); return; }
        if (iColor == ivec3(57, 60, 63)) { processTintedScaleEffect(vertex, 1.5, 0.0, 0.0, vec3(80.0/255.0, 1.0, 1.0), 0.25); return; }
        
        
        if (iColor == ivec3(57, 59, 63)) { processDynamicGradientEffect(vertex, vec3(1.0, 20.0/255.0, 0.0), vec3(1.0, 200.0/255.0, 0.0), 2.0, 300.0, 0.25); return; }
        if (iColor == ivec3(57, 59, 62)) { processTintedSequentialSpinEffect(vertex, 12000.0, vec3(1.0), 0.25); return; }
    }

    if (iColor == ivec3(78, 92, 36)) {
        processNoShadow(vertex);
        return;
    }
    if (iColor == ivec3(230, 255, 254)) {
        processRainbowEffect(vertex, 500.0);
        return;
    }
    if (iColor == ivec3(230, 255, 250)) {
        processTintedWavyEffect(vertex, 12000.0, 0.5, 0.35, vec3(80.0/255.0, 1.0, 80.0/255.0), 1.0);
        return;
    }
    if (iColor == ivec3(230, 251, 254)) {
        processWavyRainbowEffect(vertex);
        return;
    }
    if (iColor == ivec3(230, 251, 250)) {
        processTintedBouncyEffect(vertex, 3000.0, 1.0, vec3(1.0, 170.0/255.0, 0.0), 1.0);
        return;
    }
    if (iColor == ivec3(230, 247, 254)) {
        processBouncyRainbowEffect(vertex);
        return;
    }
    if (iColor == ivec3(230, 247, 250)) {
        processTintedBlinkingEffect(vertex, 0.5, vec3(80.0/255.0, 80.0/255.0, 1.0), 1.0);
        return;
    }

    if (iColor == ivec3(230, 255, 246)) { processTintedShakeEffect(vertex, 1.0, 1.0, vec3(1.0, 80.0/255.0, 80.0/255.0), 1.0); return; }
    if (iColor == ivec3(230, 255, 242)) { processTintedPulseEffect(vertex, 20.0, 0.4, vec3(80.0/255.0, 1.0, 1.0), 1.0); return; }
    if (iColor == ivec3(230, 251, 246)) { processTintedSpinEffect(vertex, 2500.0, vec3(1.0, 80.0/255.0, 1.0), 1.0); return; }
    if (iColor == ivec3(230, 251, 242)) { processTintedFadeEffect(vertex, 1.0, vec3(1.0, 1.0, 80.0/255.0), 1.0); return; }
    if (iColor == ivec3(230, 247, 246)) { processTintedIteratingEffect(vertex, 1.0, 1.0, vec3(170.0/255.0, 0.0, 1.0), 1.0); return; }
    if (iColor == ivec3(230, 247, 242)) { processTintedGlitchEffect(vertex, 1.0, 2.0, vec3(1.0, 80.0/255.0, 80.0/255.0), 1.0); return; }
    if (iColor == ivec3(230, 243, 254)) { processTintedScaleEffect(vertex, 1.5, 0.0, 0.0, vec3(80.0/255.0, 1.0, 1.0), 1.0); return; }
    if (iColor == ivec3(230, 243, 246)) { processGradientEffect(vertex, vec3(0.0, 200.0/255.0, 0.0), vec3(1.0, 1.0, 0.0), 4.0, 1.0); return; }
    if (iColor == ivec3(230, 243, 242)) { processDynamicGradientEffect(vertex, vec3(1.0, 0.0, 0.0), vec3(0.0, 0.0, 1.0), 2.0, 500.0, 1.0); return; }
    if (iColor == ivec3(230, 239, 254)) { processDynamicGradientEffect(vertex, vec3(1.0, 20.0/255.0, 0.0), vec3(1.0, 200.0/255.0, 0.0), 2.0, 300.0, 1.0); return; }
    if (iColor == ivec3(230, 239, 250)) { processTintedSequentialSpinEffect(vertex, 12000.0, vec3(1.0), 1.0); return; }

    applyProjection(vertex);
    applyColorTexture();
    finalize(vertex);
}

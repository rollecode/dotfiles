// Quantum realm: endless non-repeating fog with hashed color pockets.
// All structure derives from absolute canvas coordinates: no tiles, ever.
// driftwm contract: GLSL ES 1.0, no #version line.

precision highp float;

varying vec2 v_coords;
uniform vec2 size;
uniform vec2 u_camera;
uniform float u_time;

const vec3 BASE = vec3(0.030, 0.026, 0.060);   // deep violet-black
const vec3 MIST = vec3(0.50, 0.44, 0.70);      // purple-grey

float hash(vec2 p) {
    p = fract(p * vec2(443.897, 441.423));
    p += dot(p, p.yx + 19.19);
    return fract((p.x + p.y) * p.x);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    return mix(
        mix(hash(i),                  hash(i + vec2(1.0, 0.0)), f.x),
        mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x),
        f.y
    );
}

float fbm(vec2 p) {
    float v = 0.0;
    float a = 0.5;
    mat2 rot = mat2(0.8, 0.6, -0.6, 0.8);
    for (int i = 0; i < 4; i++) {
        v += a * noise(p);
        p = rot * p * 2.0;
        a *= 0.5;
    }
    return v;
}

// One fog stratum: domain-warped fbm at a given world scale and parallax.
float stratum(vec2 screenPx, float par, float scale, vec2 drift, float t) {
    vec2 p = (screenPx + u_camera * par) * scale + drift * t;
    vec2 q = vec2(fbm(p), fbm(p + vec2(5.2, 1.3)));
    vec2 r = vec2(fbm(p + 3.0 * q + vec2(1.7, 9.2)),
                  fbm(p + 3.0 * q + vec2(8.3, 2.8)));
    return fbm(p + 2.5 * r);
}

void main() {
    vec2 screenPx = v_coords * size;
    float t = u_time;

    // Three depths of fog.
    float f1 = stratum(screenPx, 0.25, 1.0 / 4200.0, vec2( 0.0016, 0.0007), t);
    float f2 = stratum(screenPx, 0.55, 1.0 / 1400.0, vec2(-0.0011, 0.0013), t);
    float f3 = stratum(screenPx, 1.00, 1.0 / 450.0,  vec2( 0.0007,-0.0018), t);
    float fog = f1 * 0.55 + f2 * 0.32 + f3 * 0.18;

    vec3 col = BASE + MIST * pow(max(fog, 0.0), 2.4) * 0.55;

    // Quantum pockets: unique colored glows hashed from world position.
    vec2 pc = (screenPx + u_camera * 0.4) / 3200.0;
    vec2 cell = floor(pc);
    vec3 tint = vec3(0.0);
    for (int cy = -1; cy <= 1; cy++) {
        for (int cx = -1; cx <= 1; cx++) {
            vec2 c = cell + vec2(float(cx), float(cy));
            float h = hash(c);
            if (h > 0.68) {
                vec2 centre = c + 0.25 + 0.5 * vec2(hash(c + 7.7), hash(c + 13.1));
                float d = length(pc - centre);
                float glow = exp(-d * d * 9.0);
                float hue = hash(c + 29.3);
                vec3 pcol =
                    hue < 0.26 ? vec3(0.30, 0.14, 0.58) :   // deep purple
                    hue < 0.50 ? vec3(0.38, 0.30, 0.72) :   // blue-purple
                    hue < 0.70 ? vec3(0.58, 0.48, 0.82) :   // light purple
                    hue < 0.84 ? vec3(0.55, 0.18, 0.52) :   // magenta
                    hue < 0.94 ? vec3(0.16, 0.42, 0.55) :   // cyan
                                 vec3(0.58, 0.34, 0.16);     // ember
                tint += pcol * glow * (0.5 + 0.5 * hash(c + 41.0));
            }
        }
    }
    // Glow lives in the fog, not on top of it.
    col += tint * (0.25 + 0.75 * pow(max(fog, 0.0), 1.6)) * 0.85;

    // Kill banding in the darks.
    col += (hash(screenPx * 0.7231) - 0.5) * 0.008;

    gl_FragColor = vec4(col, 1.0);
}

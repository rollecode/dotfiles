// Quantum realm: endless non-repeating fog with hashed color pockets.
// All structure derives from absolute canvas coordinates: no tiles, ever.
// driftwm contract: GLSL ES 1.0, no #version line.

precision highp float;

varying vec2 v_coords;
uniform vec2 size;
uniform vec2 u_camera;
uniform float u_time;

const vec3 BASE = vec3(0.020, 0.017, 0.042);   // dark violet, not dead
const vec3 MIST_FAR  = vec3(0.22, 0.26, 0.48);  // cool, dim, distant
const vec3 MIST_NEAR = vec3(0.62, 0.55, 0.85);  // pale near-wisps

// Quantum palette: the fog itself is colored by region.
vec3 palette(float h) {
    vec3 deepblue = vec3(0.10, 0.18, 0.52);
    vec3 bluepurp = vec3(0.30, 0.26, 0.72);
    vec3 violet   = vec3(0.48, 0.26, 0.78);
    vec3 pink     = vec3(0.88, 0.34, 0.70);
    vec3 magenta  = vec3(0.68, 0.20, 0.64);
    if (h < 0.28) return mix(deepblue, bluepurp, h / 0.28);
    if (h < 0.55) return mix(bluepurp, violet, (h - 0.28) / 0.27);
    if (h < 0.80) return mix(violet, pink, (h - 0.55) / 0.25);
    return mix(pink, magenta, (h - 0.80) / 0.20);
}

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
    float f1 = stratum(screenPx, 0.25, 1.0 / 4200.0, vec2( 0.0055, 0.0025), t);
    float f2 = stratum(screenPx, 0.55, 1.0 / 1400.0, vec2(-0.0040, 0.0045), t);
    float f3 = stratum(screenPx, 1.00, 1.0 / 450.0,  vec2( 0.0026,-0.0062), t);
    float fog = f2;  // pockets glow inside the mid plane

    // Depth by atmospheric perspective: far is cool and faint, mid carries
    // the body. Near wisps come later, as an occluding veil.
    vec3 col = BASE;
    col += MIST_FAR * pow(max(f1, 0.0), 2.8) * 0.36;

    // Colored fog body: hue varies across the canvas, bright where dense.
    float hueF = fbm((screenPx + u_camera * 0.45) / 2600.0 + vec2(3.7, 8.1) + t * 0.0035);
    vec3 fogColor = palette(hueF);
    col += fogColor * pow(max(f2, 0.0), 2.3) * 0.95;

    // Distant sheet-lightning: rare soft pulses that light the far fog from
    // behind. Position and rhythm hashed from absolute coordinates.
    vec2 lc = (screenPx + u_camera * 0.2) / 5200.0;
    vec2 lcell = floor(lc);
    for (int ly = -1; ly <= 1; ly++) {
        for (int lx = -1; lx <= 1; lx++) {
            vec2 lcp = lcell + vec2(float(lx), float(ly));
            if (hash(lcp + 61.7) > 0.75) {
                float period = 24.0 + 30.0 * hash(lcp + 71.3);
                float lt = mod(t + hash(lcp + 83.9) * period, period);
                if (lt < 2.6) {
                    float env = pow(max(0.0, 1.0 - lt / 2.6), 2.0) * (lt < 0.25 ? lt / 0.25 : 1.0);
                    vec2 lpos = lcp + 0.2 + 0.6 * vec2(hash(lcp + 91.1), hash(lcp + 97.7));
                    float ld = length(lc - lpos);
                    float lglow = exp(-ld * ld * 4.0);
                    col += vec3(0.50, 0.55, 0.90) * lglow * env * pow(max(f1, 0.0), 1.5) * 0.5;
                }
            }
        }
    }

    // Quantum pockets: unique colored glows hashed from world position.
    vec2 pc = (screenPx + u_camera * 0.4) / 3200.0;
    vec2 cell = floor(pc);
    vec3 tint = vec3(0.0);
    for (int cy = -1; cy <= 1; cy++) {
        for (int cx = -1; cx <= 1; cx++) {
            vec2 c = cell + vec2(float(cx), float(cy));
            float h = hash(c);
            if (h > 0.58) {
                vec2 centre = c + 0.25 + 0.5 * vec2(hash(c + 7.7), hash(c + 13.1));
                float d = length(pc - centre);
                float glow = exp(-d * d * 6.0);
                float hue = hash(c + 29.3);
                vec3 pcol =
                    hue < 0.26 ? vec3(0.30, 0.14, 0.58) :   // deep purple
                    hue < 0.50 ? vec3(0.38, 0.30, 0.72) :   // blue-purple
                    hue < 0.70 ? vec3(0.58, 0.48, 0.82) :   // light purple
                    hue < 0.84 ? vec3(0.55, 0.18, 0.52) :   // magenta
                    hue < 0.94 ? vec3(0.16, 0.42, 0.55) :   // cyan
                                 vec3(0.58, 0.34, 0.16);     // ember
                float breathe = 0.85 + 0.15 * sin(t * 0.3 + hash(c + 53.7) * 6.2831);
                tint += pcol * glow * breathe * (0.5 + 0.5 * hash(c + 41.0));
            }
        }
    }
    // Glow lives in the fog, not on top of it.
    col += tint * (0.30 + 0.70 * pow(max(fog, 0.0), 1.8)) * 1.25;

    // Near plane: fine wisps VEIL what is behind them: true occlusion depth.
    float wisp = pow(max(f3, 0.0), 6.0);
    float veil = wisp > 0.35 ? 0.35 : wisp;
    col = col * (1.0 - veil * 0.30) + MIST_NEAR * veil * 0.22;

    // Kill banding in the darks.
    col += (hash(screenPx * 0.7231) - 0.5) * 0.008;

    gl_FragColor = vec4(col, 1.0);
}

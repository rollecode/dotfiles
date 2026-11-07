// Endless nebula: living space for driftwm. v3, 3.7.2026.
// Rewritten after LOOKING at v2 on screen: stars are now pinpoint gaussian
// PSFs sized in pixels (not fuzzy cell-fraction blobs), the field is dense
// with a heavy-tail brightness distribution, the nebula wavelength fits the
// screen so warped filaments and dark dust lanes actually read, and the sky
// is patchy: most of it near-black, glow lives in regions. Canvas-anchored:
// endless, no tiles. GLSL ES 1.0 (driftwm docs/shaders.md contract).

precision highp float;

varying vec2 v_coords;
uniform vec2 size;
uniform vec2 u_camera;
uniform float u_time;

const float EXPOSURE    = 1.30;
const float NEBULA_GAIN = 1.15;
const float DUST_GAIN   = 0.85;
const float NOVA_PERIOD = 97.0;
const vec3 NEB_VIOLET   = vec3(0.34, 0.17, 0.52);
const vec3 NEB_BLUE     = vec3(0.08, 0.20, 0.44);
const vec3 NEB_MAGENTA  = vec3(0.52, 0.22, 0.46);

float hash(vec2 p) {
    p = fract(p * vec2(443.897, 441.423));
    p += dot(p, p.yx + 19.19);
    return fract((p.x + p.y) * p.x);
}

vec2 hash2(vec2 p) {
    return vec2(hash(p), hash(p + 71.3));
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
    for (int i = 0; i < 5; i++) {
        v += a * noise(p);
        p = rot * p * 2.0;
        a *= 0.5;
    }
    return v;
}

float ridge(vec2 p) {
    float v = 0.0;
    float a = 0.5;
    mat2 rot = mat2(0.8, 0.6, -0.6, 0.8);
    for (int i = 0; i < 4; i++) {
        float n = noise(p);
        n = 1.0 - abs(n - 0.5) * 2.0;
        v += a * n * n;
        p = rot * p * 2.0;
        a *= 0.5;
    }
    return v;
}

// Star layer: gaussian point-spread cores measured in PIXELS. Dense faint
// field, rare bright suns, independent twinkle per star.
vec3 starLayer(vec2 screenPx, float cellPx, float par, float gain, bool spikes) {
    vec2 canvas = screenPx + u_camera * par;
    vec2 id = floor(canvas / cellPx);
    vec3 col = vec3(0.0);
    for (int y = -1; y <= 1; y++) {
        for (int x = -1; x <= 1; x++) {
            vec2 cell = id + vec2(float(x), float(y));
            float h = hash(cell);
            if (h > 0.30) {
                vec2 jitter = hash2(cell + 3.7);
                float mag = 0.05 + pow(hash(cell + 57.3), 9.0) * 2.4;  // heavy tail
                float hueT  = hash(cell + 11.1);
                float phase = hash(cell + 23.9) * 6.2831853;
                float freq  = 0.3 + hash(cell + 41.7) * 1.5;

                vec2 starPos = (cell + 0.08 + jitter * 0.84) * cellPx;
                vec2 dp = canvas - starPos;
                float dpx = length(dp);          // distance in canvas pixels

                // Point-spread: tight gaussian core, radius grows only for
                // genuinely bright stars. Faint stars stay ~1 px.
                float r = 0.65 + 1.9 * min(mag, 1.0);
                float core = exp(-(dpx * dpx) / (2.0 * r * r));
                float glow = exp(-dpx / (7.0 + 26.0 * mag)) * 0.06 * min(mag * 2.0, 1.0);

                float twAmp = mix(0.32, 0.05, min(mag, 1.0));
                float twinkle = 1.0 - twAmp + twAmp * sin(u_time * freq * 3.0 + phase);

                vec3 starCol = mix(vec3(0.80, 0.87, 1.0), vec3(1.0, 0.93, 0.80), hueT);

                float s = core + glow;
                if (spikes && mag > 1.0) {
                    float ax = abs(dp.x);
                    float ay = abs(dp.y);
                    float armLen = 26.0 * mag;
                    float arm = exp(-ax / armLen) * exp(-(ay * ay) / 1.6)
                              + exp(-ay / armLen) * exp(-(ax * ax) / 1.6);
                    s += arm * 0.30;
                }

                col += starCol * s * mag * twinkle;
            }
        }
    }
    return col * gain;
}

// Patchy domain-warped nebula: glow regions with filaments and dark dust,
// most of the sky stays near-black.
vec3 nebulaCol(vec2 screenPx, float t, out float mass) {
    vec2 p = (screenPx + u_camera * 0.30) * 0.0011;

    // Region mask: where the nebula lives at all.
    float region = fbm(p * 0.32 + vec2(3.1, 7.7));
    mass = pow(smoothstep(0.42, 0.82, region), 1.6);
    if (mass < 0.003) return vec3(0.0);

    vec2 q = vec2(fbm(p), fbm(p + vec2(5.2, 1.3)));
    vec2 r = vec2(fbm(p + 4.0 * q + vec2(1.7, 9.2) + t * 0.010),
                  fbm(p + 4.0 * q + vec2(8.3, 2.8) - t * 0.007));
    float f = fbm(p + 3.4 * r);

    float body = pow(max(f, 0.0), 2.0);
    vec3 col = mix(NEB_BLUE, NEB_VIOLET, smoothstep(0.30, 0.72, f)) * body;

    // Bright strands.
    float fil = ridge(p * 2.4 + 3.0 * r);
    col += NEB_MAGENTA * pow(fil, 2.6) * body * 1.7;

    // Dark dust lanes carve the glow.
    float dust = pow(ridge(p * 3.4 + 1.8 * q), 2.4);
    col *= 1.0 - dust * DUST_GAIN;

    // Unresolved star-cloud grain inside the bright mass (astrophoto texture).
    vec2 gcell = floor((screenPx + u_camera * 0.30) * 0.55);
    float grain = pow(hash(gcell), 10.0);
    col += vec3(0.9, 0.85, 0.95) * grain * body * 0.35;

    return col * mass * NEBULA_GAIN;
}

vec3 galaxyLayer(vec2 screenPx) {
    vec2 canvas = screenPx + u_camera * 0.10;
    float cellPx = 2800.0;
    vec2 id = floor(canvas / cellPx);
    vec3 col = vec3(0.0);
    for (int y = -1; y <= 1; y++) {
        for (int x = -1; x <= 1; x++) {
            vec2 cell = id + vec2(float(x), float(y));
            float h = hash(cell + 101.0);
            if (h > 0.93) {
                vec2 jitter = hash2(cell + 113.0);
                vec2 gpos = (cell + 0.2 + jitter * 0.6) * cellPx;
                vec2 p = canvas - gpos;
                float ang = hash(cell + 131.0) * 3.14159;
                float ca = cos(ang), sa = sin(ang);
                p = mat2(ca, -sa, sa, ca) * p;
                p.y *= 2.2 + hash(cell + 149.0) * 1.6;
                float r2 = dot(p, p) / (cellPx * cellPx * 0.028);
                if (r2 < 4.0) {
                    float theta = atan(p.y, p.x);
                    float arms = 0.70 + 0.30 * cos(2.0 * theta - 3.2 * log(r2 + 0.05));
                    float halo = exp(-r2 * 6.0) * 0.20 * arms;
                    float core = exp(-r2 * 50.0) * 0.55;
                    vec3 gcol = mix(vec3(0.74, 0.72, 0.92), vec3(0.94, 0.86, 0.72),
                                    hash(cell + 163.0));
                    col += gcol * (halo + core);
                }
            }
        }
    }
    return col;
}

vec3 novaLayer(vec2 screenPx) {
    vec2 canvas = screenPx + u_camera * 0.5;
    float cellPx = 1700.0;
    vec2 id = floor(canvas / cellPx);
    vec3 col = vec3(0.0);
    for (int y = -1; y <= 1; y++) {
        for (int x = -1; x <= 1; x++) {
            vec2 cell = id + vec2(float(x), float(y));
            if (hash(cell + 211.0) > 0.80) {
                float phase = hash(cell + 223.0);
                float t = mod(u_time + phase * NOVA_PERIOD, NOVA_PERIOD);
                if (t < 9.0) {
                    vec2 jitter = hash2(cell + 227.0);
                    vec2 npos = (cell + 0.2 + jitter * 0.6) * cellPx;
                    float dpx = length(canvas - npos);
                    float env = smoothstep(0.0, 0.35, t) * (1.0 - smoothstep(0.9, 9.0, t));
                    float flash = exp(-(dpx * dpx) / (2.0 * 9.0)) * env * 2.0
                                + exp(-dpx / 60.0) * env * 0.25;
                    float ringR = 20.0 + t * 55.0;
                    float ring = exp(-abs(dpx - ringR) / 6.0) * env * 0.30;
                    vec3 ncol = mix(vec3(1.0, 0.93, 0.82), vec3(0.55, 0.70, 1.0),
                                    smoothstep(0.0, 9.0, t));
                    col += ncol * (flash + ring);
                }
            }
        }
    }
    return col;
}

void main() {
    vec2 screenPx = v_coords * size;
    float t = u_time;

    vec3 col = vec3(0.005, 0.006, 0.012);

    float mass;
    col += nebulaCol(screenPx, t, mass);

    col += galaxyLayer(screenPx);

    // Starfield far to near: dense faint dust of stars, then brighter suns.
    col += starLayer(screenPx,  34.0, 0.12, 0.42, false);
    col += starLayer(screenPx,  70.0, 0.35, 0.62, false);
    col += starLayer(screenPx, 180.0, 0.65, 0.85, false);
    col += starLayer(screenPx, 750.0, 1.00, 1.30, true);

    col += novaLayer(screenPx);

    col = 1.0 - exp(-col * EXPOSURE);
    col += (hash(screenPx * 0.731) - 0.5) * 0.006;

    gl_FragColor = vec4(col, 1.0);
}

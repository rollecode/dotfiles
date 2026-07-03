// Endless nebula: ultra-realistic living space for driftwm. v2, 3.7.2026.
//
// Nebula-forward rewrite: a vast domain-warped emission nebula with bright
// filaments and DARK dust lanes is the subject; over it a power-law starfield
// (thousands of faint pinpricks, a rare bright star with diffraction spikes),
// spiral-hinted galaxies, and occasional supernovae. Everything is anchored
// to canvas coordinates: endless in every direction, no tiles, no repeats.
// Realism rules applied: star brightness follows a heavy-tail distribution,
// bright stars barely twinkle while dim ones shimmer, color is restrained,
// dark extinction dust breaks up the glow, exposure tonemap + dither kill
// banding on the dark end.
//
// driftwm contract (docs/shaders.md): GLSL ES 1.0, no #version line.

precision highp float;

varying vec2 v_coords;
uniform vec2 size;
uniform vec2 u_camera;
uniform float u_time;

// Tunables
const float EXPOSURE     = 1.35;
const float NEBULA_GAIN  = 0.55;   // overall nebula strength
const float DUST_GAIN    = 0.75;   // dark lane extinction strength
const float STAR_GAIN    = 1.0;
const float NOVA_PERIOD  = 97.0;
const vec3 NEB_VIOLET    = vec3(0.30, 0.16, 0.46);  // Rolle purple, deepened
const vec3 NEB_BLUE      = vec3(0.07, 0.19, 0.40);
const vec3 NEB_MAGENTA   = vec3(0.46, 0.20, 0.42);

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

// Sharp bright strands at noise contour lines (filaments, dust ridges).
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

// Domain-warped nebula body: emission glow, bright filaments, dark dust.
vec3 nebula(vec2 screenPx, float par, float scale, float gain, float t) {
    vec2 p = (screenPx + u_camera * par) * scale;

    vec2 q = vec2(fbm(p + vec2(0.0, 0.0)),
                  fbm(p + vec2(5.2, 1.3)));
    vec2 r = vec2(fbm(p + 3.6 * q + vec2(1.7, 9.2) + t * 0.010),
                  fbm(p + 3.6 * q + vec2(8.3, 2.8) - t * 0.007));
    float f = fbm(p + 3.0 * r);

    // Emission body: violet core regions bleeding into cold blue.
    float body = pow(max(f, 0.0), 2.3);
    vec3 col = mix(NEB_BLUE, NEB_VIOLET, smoothstep(0.35, 0.75, f)) * body;

    // Bright filament strands inside the body only.
    float fil = ridge(p * 2.1 + 2.4 * r);
    col += NEB_MAGENTA * pow(fil, 3.0) * body * 1.4;

    // Dark dust lanes: multiplicative extinction eating into the glow.
    float dust = pow(ridge(p * 3.2 + 1.7 * q), 3.0);
    col *= 1.0 - dust * DUST_GAIN;

    return col * gain;
}

// One star layer. Power-law magnitudes: most stars are barely-there points,
// brightness gates size, spikes appear only on the very brightest.
vec3 starLayer(vec2 screenPx, float cellPx, float par, float gain, bool spikes) {
    vec2 canvas = screenPx + u_camera * par;
    vec2 id = floor(canvas / cellPx);
    vec3 col = vec3(0.0);
    for (int y = -1; y <= 1; y++) {
        for (int x = -1; x <= 1; x++) {
            vec2 cell = id + vec2(float(x), float(y));
            float h = hash(cell);
            if (h > 0.55) {
                vec2 jitter = hash2(cell + 3.7);
                float mag   = pow(hash(cell + 57.3), 7.0);   // heavy tail
                if (mag < 0.002) continue;
                float hueT  = hash(cell + 11.1);
                float phase = hash(cell + 23.9) * 6.2831853;
                float freq  = 0.3 + hash(cell + 41.7) * 1.5;

                vec2 starPos = (cell + 0.1 + jitter * 0.8) * cellPx;
                vec2 dp = canvas - starPos;
                float d = length(dp) / cellPx;

                // Dim stars scintillate, bright stars hold steady.
                float twAmp = mix(0.30, 0.06, min(mag * 8.0, 1.0));
                float twinkle = 1.0 - twAmp + twAmp * sin(u_time * freq * 3.0 + phase);

                // Mostly white, faint temperature tint.
                vec3 starCol = mix(vec3(0.78, 0.86, 1.0), vec3(1.0, 0.92, 0.78), hueT);

                float coreR = 0.015 + 0.10 * mag;
                float core = smoothstep(coreR, 0.0, d);
                float halo = smoothstep(coreR * 6.0, 0.0, d) * 0.10 * min(mag * 6.0, 1.0);
                float s = core + halo;

                if (spikes && mag > 0.35) {
                    // Diffraction cross on the brightest few.
                    float ax = abs(dp.x) / cellPx;
                    float ay = abs(dp.y) / cellPx;
                    float arm = smoothstep(0.5 * mag, 0.0, ax) * smoothstep(0.012, 0.0, ay)
                              + smoothstep(0.5 * mag, 0.0, ay) * smoothstep(0.012, 0.0, ax);
                    s += arm * 0.35 * mag;
                }

                col += starCol * s * mag * twinkle;
            }
        }
    }
    return col * gain;
}

// Distant galaxies with a spiral-arm brightness hint.
vec3 galaxyLayer(vec2 screenPx) {
    vec2 canvas = screenPx + u_camera * 0.10;
    float cellPx = 3200.0;
    vec2 id = floor(canvas / cellPx);
    vec3 col = vec3(0.0);
    for (int y = -1; y <= 1; y++) {
        for (int x = -1; x <= 1; x++) {
            vec2 cell = id + vec2(float(x), float(y));
            float h = hash(cell + 101.0);
            if (h > 0.94) {
                vec2 jitter = hash2(cell + 113.0);
                vec2 gpos = (cell + 0.2 + jitter * 0.6) * cellPx;
                vec2 p = canvas - gpos;
                float ang = hash(cell + 131.0) * 3.14159;
                float ca = cos(ang), sa = sin(ang);
                p = mat2(ca, -sa, sa, ca) * p;
                p.y *= 2.2 + hash(cell + 149.0) * 1.6;
                float r2 = dot(p, p) / (cellPx * cellPx * 0.030);
                if (r2 < 4.0) {
                    float theta = atan(p.y, p.x);
                    float arms = 0.72 + 0.28 * cos(2.0 * theta - 3.2 * log(r2 + 0.05));
                    float halo = exp(-r2 * 7.0) * 0.14 * arms;
                    float core = exp(-r2 * 55.0) * 0.40;
                    vec3 gcol = mix(vec3(0.72, 0.70, 0.90), vec3(0.92, 0.84, 0.70),
                                    hash(cell + 163.0));
                    col += gcol * (halo + core);
                }
            }
        }
    }
    return col;
}

// Rare supernova: sharp flare, expanding shell, slow fade. Usually zero or
// one on screen: catching one stays an event.
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
                    float d = length(canvas - npos) / cellPx;
                    float env = smoothstep(0.0, 0.35, t) * (1.0 - smoothstep(0.9, 9.0, t));
                    float flash = smoothstep(0.10, 0.0, d) * env;
                    float ringR = 0.02 + t * 0.045;
                    float ring = smoothstep(0.03, 0.0, abs(d - ringR)) * env * 0.35;
                    vec3 ncol = mix(vec3(1.0, 0.93, 0.82), vec3(0.55, 0.70, 1.0),
                                    smoothstep(0.0, 9.0, t));
                    col += ncol * (flash * 1.6 + ring);
                }
            }
        }
    }
    return col;
}

void main() {
    vec2 screenPx = v_coords * size;
    float t = u_time;

    // Space is nearly black; the nebula provides all the character.
    vec3 col = vec3(0.006, 0.007, 0.014);

    // Two nebula strata: a distant cold veil and the main violet body.
    col += nebula(screenPx, 0.16, 0.00019, NEBULA_GAIN * 0.45, t * 0.6);
    col += nebula(screenPx, 0.32, 0.00042, NEBULA_GAIN, t);

    // Galaxies behind the stars.
    col += galaxyLayer(screenPx);

    // Starfield, far to near: dense faint dust first, rare bright suns last.
    col += starLayer(screenPx,  55.0, 0.15, 0.35 * STAR_GAIN, false);
    col += starLayer(screenPx, 105.0, 0.35, 0.60 * STAR_GAIN, false);
    col += starLayer(screenPx, 170.0, 0.65, 0.85 * STAR_GAIN, false);
    col += starLayer(screenPx, 640.0, 1.00, 1.60 * STAR_GAIN, true);

    // The occasional supernova.
    col += novaLayer(screenPx);

    // Filmic-ish exposure roll-off, then a static micro-dither so the dark
    // gradients never band.
    col = 1.0 - exp(-col * EXPOSURE);
    col += (hash(screenPx * 0.731) - 0.5) * 0.006;

    gl_FragColor = vec4(col, 1.0);
}

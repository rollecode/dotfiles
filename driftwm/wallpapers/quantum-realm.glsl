// Quantum realm (final): transparent evolving fog over a swaybg starmap
// layer. Colored fog regions, quantum pockets, energy filaments, distant
// sheet-lightning, radiant cores, rare cratered planets and rarer black
// holes (gargantuas). All structure derives from hashed absolute canvas
// coordinates (no tiles); the domain warp is time-dependent, so forms
// genuinely morph, not just translate.

precision highp float;

varying vec2 v_coords;
uniform vec2 size;
uniform vec2 u_camera;
uniform float u_time;
uniform float u_zoom;

const vec3 BASE = vec3(0.010, 0.009, 0.026);   // deep near-black

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
    for (int i = 0; i < 3; i++) {
        v += a * noise(p);
        p = rot * p * 2.0;
        a *= 0.5;
    }
    return v;
}

// Two octaves only: for warp vectors, whose fine detail is invisible
// after warping. Cheaper than full fbm.
float fbm2(vec2 p) {
    float v = 0.5 * noise(p);
    p = mat2(0.8, 0.6, -0.6, 0.8) * p * 2.0;
    v += 0.25 * noise(p);
    return v;
}

float ridge(vec2 p) {
    float v = 0.0;
    float a = 0.5;
    mat2 rot = mat2(0.8, 0.6, -0.6, 0.8);
    for (int i = 0; i < 3; i++) {
        float n = noise(p);
        n = 1.0 - abs(n - 0.5) * 2.0;
        v += a * n * n;
        p = rot * p * 2.0;
        a *= 0.5;
    }
    return v;
}

// Evolving fog stratum: the warp vectors move through time, so cloud
// shapes continuously reform.
float stratum(vec2 screenPx, float par, float scale, vec2 drift, float t) {
    vec2 p = (screenPx + u_camera * par) * scale + drift * t;
    vec2 q = vec2(fbm2(p + vec2(0.0,  t * 0.011)),
                  fbm2(p + vec2(5.2, 1.3) - vec2(t * 0.008, 0.0)));
    vec2 r = vec2(fbm2(p + 3.0 * q + vec2(1.7, 9.2) + vec2(t * 0.013, -t * 0.006)),
                  fbm2(p + 3.0 * q + vec2(8.3, 2.8) + vec2(-t * 0.007, t * 0.010)));
    return fbm(p + 2.5 * r);
}

// Cheaper stratum: single warp, for far/near planes.
float stratumLite(vec2 screenPx, float par, float scale, vec2 drift, float t) {
    vec2 p = (screenPx + u_camera * par) * scale + drift * t;
    vec2 q = vec2(fbm2(p + vec2(0.0, t * 0.010)),
                  fbm2(p + vec2(5.2, 1.3) - vec2(t * 0.007, 0.0)));
    return fbm(p + 2.2 * q);
}

void main() {
    vec2 screenPx = v_coords * size;
    float t = u_time;

    float f1 = stratumLite(screenPx, 0.25, 1.0 / 4200.0, vec2( 0.020, 0.009), t);
    float f2 = stratum(screenPx, 0.55, 1.0 / 1400.0, vec2(-0.014, 0.016), t);
    float f3 = fbm((screenPx + u_camera) / 450.0 + vec2(0.009, -0.022) * t);
    float fog = f2;

    // Coverage doubles as output alpha: where fog is thin, the layer-shell
    // starmap wallpaper beneath shows through.
    float cover = pow(max(f1, 0.0), 2.2) * 0.55 + pow(max(f2, 0.0), 2.0) * 0.75;
    cover = cover > 0.92 ? 0.92 : cover;
    vec3 col = BASE;

    // Distant sheet-lightning behind the far fog.
    vec2 lc = (screenPx + u_camera * 0.2) / 5200.0;
    // Full 3x3 scan: a flash at peak brightness reaches past the 2x2
    // window and clips along the cell edge as a huge faint square.
    vec2 lcell = floor(lc);
    for (int ly = -1; ly <= 1; ly++) {
        for (int lx = -1; lx <= 1; lx++) {
            vec2 lcp = lcell + vec2(float(lx), float(ly));
            if (hash(lcp + 61.7) > 0.40) {
                float period = 12.0 + 18.0 * hash(lcp + 71.3);
                float lt = mod(t + hash(lcp + 83.9) * period, period);
                if (lt < 2.6) {
                    float env = pow(max(0.0, 1.0 - lt / 2.6), 2.0) * (lt < 0.25 ? lt / 0.25 : 1.0);
                    vec2 lpos = lcp + 0.2 + 0.6 * vec2(hash(lcp + 91.1), hash(lcp + 97.7));
                    float ld = length(lc - lpos);
                    col += vec3(0.50, 0.55, 0.90) * exp(-ld * ld * 4.0) * env * pow(max(f1, 0.0), 1.5) * 0.75;
                }
            }
        }
    }

    // Colored fog body: hue regions migrate slowly.
    float hueF = noise((screenPx + u_camera * 0.45) / 2600.0 + vec2(3.7, 8.1) + t * 0.006);
    col += palette(hueF) * pow(max(f2, 0.0), 2.3) * 0.95;
    col += vec3(0.22, 0.26, 0.48) * pow(max(f1, 0.0), 2.8) * 0.30;

    // Radiant cores: luminous nebula hearts in white-pink, blue-white,
    // violet-white and rare teal. The bright areas of the realm.
    vec2 rc = (screenPx + u_camera * 0.45) / 3000.0;
    vec2 rcell = floor(rc - 0.5);
    for (int ry = 0; ry <= 1; ry++) {
        for (int rx = 0; rx <= 1; rx++) {
            vec2 rcp = rcell + vec2(float(rx), float(ry));
            if (hash(rcp + 201.7) > 0.62) {
                vec2 rpos = rcp + 0.25 + 0.5 * vec2(hash(rcp + 207.1), hash(rcp + 211.9));
                float rd = length(rc - rpos);
                float amp = 0.7 + 0.6 * hash(rcp + 219.1);
                float core = exp(-rd * rd * 26.0) * amp;
                // Fade to zero before the 2x2 scan window can drop the cell
                // (worst case 0.75 cells), else the cutoff draws a straight
                // seam across the halo.
                float halo = exp(-rd * rd * 5.0) * amp * (1.0 - smoothstep(0.52, 0.72, rd));
                float ch = hash(rcp + 223.3);
                vec3 coreCol =
                    ch < 0.40 ? vec3(1.00, 0.85, 0.96) :
                    ch < 0.72 ? vec3(0.75, 0.88, 1.00) :
                    ch < 0.92 ? vec3(0.88, 0.80, 1.00) :
                                vec3(0.62, 0.95, 0.92);
                vec3 haloCol =
                    ch < 0.40 ? vec3(0.85, 0.35, 0.70) :
                    ch < 0.72 ? vec3(0.25, 0.45, 0.95) :
                    ch < 0.92 ? vec3(0.55, 0.35, 0.90) :
                                vec3(0.18, 0.55, 0.60);
                float breathe = 0.9 + 0.1 * sin(t * 0.22 + hash(rcp + 229.7) * 6.2831);
                col += coreCol * core * 1.15 * breathe * (0.55 + 0.45 * pow(max(f2, 0.0), 1.1));
                col += haloCol * halo * 0.60 * breathe * (0.40 + 0.60 * pow(max(f2, 0.0), 1.3));
            }
        }
    }

    // Gargantuas: black holes with a blazing lensed accretion ring.
    // The rarest wonder of the realm.
    vec2 ga = (screenPx + u_camera) / 9000.0;
    vec2 gacell = floor(ga - 0.5);
    float gargMask = 0.0;
    for (int gy = 0; gy <= 1; gy++) {
        for (int gx = 0; gx <= 1; gx++) {
            vec2 gcp = gacell + vec2(float(gx), float(gy));
            if (hash(gcp + 401.7) > 0.93) {
                vec2 gpos = gcp + 0.3 + 0.4 * vec2(hash(gcp + 403.1), hash(gcp + 405.7));
                vec2 gdp = ga - gpos;
                float gd = length(gdp);
                float gr = 0.06 + 0.05 * hash(gcp + 407.3);
                if (gd < gr * 2.6) {
                    float ringR = gr * 1.30;
                    float rw = gr * 0.11;
                    float ringD = gd - ringR;
                    float ring = exp(-ringD * ringD / (rw * rw));
                    vec2 gdir = gd > 0.001 ? gdp / gd : vec2(1.0, 0.0);
                    float ang = atan(gdp.y, gdp.x);
                    // The doppler-bright side orbits, and hot clumps stream
                    // visibly along the disc.
                    float rang = hash(gcp + 409.1) * 6.2831 + t * 0.12;
                    vec2 rdir = vec2(cos(rang), sin(rang));
                    float dopp = 0.45 + 0.55 * dot(gdir, rdir);
                    float clump = 0.80 + 0.28 * sin(ang * 3.0 - t * 0.40 + hash(gcp + 411.3) * 6.2831)
                                       * sin(ang * 5.0 + t * 0.23);
                    vec3 ringCol = mix(vec3(1.00, 0.62, 0.25), vec3(1.00, 0.93, 0.80), ring * dopp);
                    col += ringCol * ring * dopp * clump * 1.6;
                    // Photon ring: hairline of light hugging the horizon.
                    float phD = gd - gr * 1.04;
                    col += vec3(1.0, 0.95, 0.88) * exp(-phD * phD / (gr * gr * 0.0016)) * 0.9;
                    // Warm haze bleeding off the disc.
                    col += vec3(0.95, 0.55, 0.30) * exp(-ringD * ringD / (gr * gr * 0.55)) * 0.16 * clump;
                    // Event horizon: pure black, swallows everything.
                    float hole = 1.0 - smoothstep(gr * 0.80, gr * 0.98, gd);
                    col = mix(col, vec3(0.0), hole);
                    gargMask = max(gargMask, 1.0 - smoothstep(ringR, ringR * 1.5, gd));
                }
            }
        }
    }

    // The Planet: a single hand-placed world, anchored to the canvas
    // (zoom is applied externally, so it scales and sticks like a window).
    // Modeled on the smooth blue-grey sphere; no craters, no gimmicks.
    float planetMask = 0.0;
    {
        vec2 dp = (screenPx + u_camera) - vec2(16000.0, 9000.0);
        float prad = 420.0;
        float pd = length(dp);
        if (pd < prad * 1.5) {
            float body = 1.0 - smoothstep(prad * 0.99, prad * 1.003, pd);
            vec2 sp = dp / prad;
            float nz = sqrt(max(1.0 - dot(sp, sp), 0.0));
            vec3 nrm = vec3(sp, nz);
            vec3 l3 = normalize(vec3(0.62, 0.50, 0.45));
            float lit = pow(max(dot(nrm, l3), 0.0), 0.85);
            vec2 uv = sp * (1.0 + 0.65 * (1.0 - nz));
            float tex1 = fbm(uv * 4.0 + 11.3);
            float tex2 = fbm(uv * 9.0 + 47.7);
            float tex3 = fbm(uv * 21.0 + 83.1);
            vec3 pbase = mix(vec3(0.20, 0.30, 0.44), vec3(0.36, 0.42, 0.55), tex1);
            vec3 surf = pbase * (0.72 + 0.42 * tex2) + vec3(0.06) * (tex3 - 0.5);
            surf *= (0.06 + 0.94 * lit) * (0.60 + 0.40 * nz);
            float fres = pow(1.0 - nz, 3.0);
            vec3 atmo = mix(vec3(0.45, 0.58, 0.95), vec3(0.82, 0.80, 1.0), lit);
            surf += atmo * fres * (0.15 + 0.85 * lit) * 0.7;
            vec2 edir = pd > 0.001 ? dp / pd : vec2(0.0);
            float eLit = max(dot(edir, l3.xy), 0.0);
            float outerGlow = exp(-(pd - prad) * (pd - prad) / (prad * prad * 0.010)) * step(prad, pd);
            col += atmo * outerGlow * eLit * 0.40;
            col = mix(col, surf, body);
            planetMask = body;
        }
    }

    // Asteroid fields: rare wide swarms of small rocks, anchored to the
    // canvas, dense mid-band and thinning outward.
    vec2 af = (screenPx + u_camera) / 9000.0;
    vec2 afcell = floor(af - 0.5);
    float rockMask = 0.0;
    for (int ay = 0; ay <= 1; ay++) {
        for (int ax = 0; ax <= 1; ax++) {
            vec2 acp = afcell + vec2(float(ax), float(ay));
            if (hash(acp + 501.7) > 0.92) {
                vec2 apos = acp + 0.3 + 0.4 * vec2(hash(acp + 503.1), hash(acp + 507.9));
                vec2 ad = af - apos;
                float aang = hash(acp + 509.3) * 6.2831;
                vec2 adir = vec2(cos(aang), sin(aang));
                float along = dot(ad, adir);
                float across = dot(ad, vec2(-adir.y, adir.x));
                float band = exp(-across * across * 40.0) * exp(-along * along * 5.5);
                if (band > 0.05) {
                    // Tiny distant rocks: organic clumps (density noise),
                    // sizes skewed small, heavy jitter so no lattice shows.
                    vec2 rg = ad * 46.0 + hash(acp + 511.3) * 71.0;
                    vec2 rgc = floor(rg);
                    float clumpN = smoothstep(0.35, 0.75, noise(rg * 0.33 + hash(acp + 513.9) * 19.0));
                    float rh = hash(rgc + 517.1);
                    if (rh > 1.0 - band * clumpN * 0.9) {
                        vec2 rpos2 = rgc + 0.2 + 0.6 * vec2(hash(rgc + 521.3), hash(rgc + 523.9));
                        float rr = 0.04 + 0.16 * pow(hash(rgc + 527.7), 2.2);
                        vec2 rrel = rg - rpos2;
                        float rdist = length(rrel);
                        if (rdist < rr) {
                            vec2 rdirJ = rdist > 0.001 ? rrel / rdist : vec2(1.0, 0.0);
                            float rrJ = rr * (0.78 + 0.38 * noise(rdirJ * 1.8 + hash(rgc + 533.9) * 29.0));
                            float rockBody = 1.0 - smoothstep(rrJ * 0.65, rrJ, rdist);
                            // Hazed by distance: low contrast, soft edge light.
                            float lump = 0.80 + 0.4 * noise(rg * 3.0 + hash(rgc + 531.7) * 23.0);
                            vec3 rockCol = vec3(0.045, 0.040, 0.070) * lump;
                            float elit = max(dot(rdirJ, vec2(0.71, 0.55)), 0.0);
                            float redge = smoothstep(rrJ * 0.40, rrJ * 0.85, rdist) * rockBody;
                            col = mix(col, rockCol, rockBody * 0.75);
                            col += vec3(0.55, 0.48, 0.65) * redge * elit * 0.22;
                            rockMask = max(rockMask, rockBody * 0.6);
                        }
                    }
                }
            }
        }
    }

    // Alioth: a vast shadow leviathan patrolling rare cells. Devours the
    // realm's light; faint violet rim, green inner flicker. Organic: its
    // silhouette is noise-wobbled fog-darkness, no geometry.
    vec2 al = (screenPx + u_camera) / 16000.0;
    vec2 alcell = floor(al - 0.5);
    float darkMask = 0.0;
    for (int ay2 = 0; ay2 <= 1; ay2++) {
        for (int ax2 = 0; ax2 <= 1; ax2++) {
            vec2 acp2 = alcell + vec2(float(ax2), float(ay2));
            if (hash(acp2 + 601.7) > 0.94) {
                float aph = hash(acp2 + 607.3) * 6.2831;
                vec2 centre2 = acp2 + 0.5
                    + 0.15 * vec2(sin(t * 0.005 + aph), cos(t * 0.004 + aph));
                vec2 rel = al - centre2;
                float ad2 = length(rel);
                float wob = 0.75 + 0.30 * noise(normalize(rel + 0.0001) * 1.6 + aph * 7.0 + t * 0.02);
                float body2 = 1.0 - smoothstep(0.20 * wob, 0.34 * wob, ad2);
                body2 *= 1.0 - smoothstep(0.50, 0.70, ad2);
                if (body2 > 0.003) {
                    float rim3 = smoothstep(0.14 * wob, 0.30 * wob, ad2) * body2;
                    col = mix(col, BASE * 0.6, body2 * 0.85);
                    col += vec3(0.30, 0.22, 0.55) * rim3 * 0.35;
                    float flick = pow(max(sin(t * 0.7 + aph * 3.0), 0.0), 8.0);
                    col += vec3(0.20, 0.55, 0.30) * rim3 * flick * 0.4;
                    darkMask = max(darkMask, body2);
                }
            }
        }
    }

    // Quantum pockets: unique, breathing.
    vec2 pc = (screenPx + u_camera * 0.4) / 3200.0;
    vec2 cell = floor(pc - 0.5);
    vec3 tint = vec3(0.0);
    for (int cy = 0; cy <= 1; cy++) {
        for (int cx = 0; cx <= 1; cx++) {
            vec2 c = cell + vec2(float(cx), float(cy));
            float h = hash(c);
            if (h > 0.58) {
                vec2 centre = c + 0.25 + 0.5 * vec2(hash(c + 7.7), hash(c + 13.1));
                float d = length(pc - centre);
                // Same 2x2 window guard as the cores: fade out before drop.
                float glow = exp(-d * d * 6.0) * (1.0 - smoothstep(0.52, 0.72, d));
                float hue = hash(c + 29.3);
                vec3 pcol =
                    hue < 0.26 ? vec3(0.30, 0.14, 0.58) :
                    hue < 0.50 ? vec3(0.38, 0.30, 0.72) :
                    hue < 0.70 ? vec3(0.58, 0.48, 0.82) :
                    hue < 0.84 ? vec3(0.55, 0.18, 0.52) :
                    hue < 0.94 ? vec3(0.16, 0.42, 0.55) :
                                 vec3(0.58, 0.34, 0.16);
                float breathe = 0.85 + 0.15 * sin(t * 0.3 + hash(c + 53.7) * 6.2831);
                tint += pcol * glow * breathe * (0.5 + 0.5 * hash(c + 41.0));
            }
        }
    }
    col += tint * (0.30 + 0.70 * pow(max(fog, 0.0), 1.8)) * 1.25;

    // Energy filaments: thin luminous veins inside the mid fog. Kept sparse
    // and faint: dense bright veins read as snakes at far zoom-out.
    vec2 fp = (screenPx + u_camera * 0.5) / 900.0 + vec2(t * 0.009, -t * 0.006);
    float fil = pow(ridge(fp * 2.2), 9.0);
    col += vec3(0.36, 0.42, 0.85) * fil * pow(max(f2, 0.0), 1.4) * 0.55;


    // Sparse near wisps, thin veil only.
    float wisp = pow(max(f3, 0.0), 6.0);
    float veil = wisp > 0.35 ? 0.35 : wisp;
    col = col * (1.0 - veil * 0.30) + vec3(0.62, 0.55, 0.85) * veil * 0.22;

    // Anti-banding dither.
    col += (hash(screenPx * 0.7231) - 0.5) * 0.008;

    // No see-through windows: the far fog plane's features are 4000+ px, so
    // any thresholded gap opens as a screen-sized hole of bare starmap.
    // Instead the stars glimmer faintly INSIDE thin fog, smoothly, capped.
    float thin = (1.0 - pow(max(f1, 0.0), 0.8)) * (1.0 - pow(max(f2, 0.0), 0.8));
    float gapZoom = clamp((u_zoom - 0.35) / 0.45, 0.0, 1.0);
    float alpha = 0.97 - thin * 0.09 * gapZoom + veil * 0.1;
    alpha = alpha > 0.99 ? 0.99 : (alpha < 0.90 ? 0.90 : alpha);
    alpha = max(alpha, max(max(planetMask, gargMask), max(rockMask, darkMask)) * 0.99);
    gl_FragColor = vec4(col * alpha, alpha);
}

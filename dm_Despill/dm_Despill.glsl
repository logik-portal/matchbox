// dm_Despill — Matchbox shader for Autodesk Flame
// Inspired by DespillMadness (Andreas Frickinger, Nukepedia 2010)
// and the IBKGizmo weighted despill approach

uniform float adsk_result_w;
uniform float adsk_result_h;
uniform sampler2D front;

uniform int   screenType;
uniform bool  useCustomColor;
uniform vec3  customScreenColor;
uniform int   algorithm;
uniform float fineTune;
uniform bool  restoreLuma;
uniform float saturation;
uniform float gamma;
uniform float offset;
uniform bool  spillMatteInAlpha;
uniform float mix_amount;
uniform float redWeight;
uniform float ch2Weight;

vec3 applySaturation(vec3 c, float sat) {
vec3  lw   = vec3(0.2126, 0.7152, 0.0722);
float luma = dot(c, lw);
return mix(vec3(luma), c, sat);
}

vec3 applyGamma(vec3 c, float g) {
return pow(max(c, vec3(0.0)), vec3(1.0 / max(g, 0.0001)));
}

float computeLimit(float ch1, float ch2, int algo, float rw, float c2w) {
if      (algo == 0) return (ch1 + ch2) * 0.5;
else if (algo == 1) return (ch1 + 2.0 * ch2) / 3.0;
else if (algo == 2) return (2.0 * ch1 + ch2) / 3.0;
else if (algo == 3) return ch1;
else if (algo == 4) return ch2;
else                return ch1 * rw + ch2 * c2w;
}

void main() {
vec2 uv   = gl_FragCoord.xy / vec2(adsk_result_w, adsk_result_h);
vec3 s    = texture2D(front, uv).rgb;
vec3 supp = s;

// ── 1. DESPILL ───────────────────────────────────────────
float lim;

if (useCustomColor) {
    float scR = customScreenColor.r;
    float scG = customScreenColor.g;
    float scB = customScreenColor.b;

    if (scR >= scG && scR >= scB) {
        float total = scG + scB;
        float w1 = total > 0.0 ? scG / total : 0.5;
        float w2 = total > 0.0 ? scB / total : 0.5;
        lim    = (s.g * w1 + s.b * w2) * fineTune;
        supp.r = min(s.r, lim);
    }
    else if (scG >= scR && scG >= scB) {
        float total = scR + scB;
        float w1 = total > 0.0 ? scR / total : 0.5;
        float w2 = total > 0.0 ? scB / total : 0.5;
        lim    = (s.r * w1 + s.b * w2) * fineTune;
        supp.g = min(s.g, lim);
    }
    else {
        float total = scR + scG;
        float w1 = total > 0.0 ? scR / total : 0.5;
        float w2 = total > 0.0 ? scG / total : 0.5;
        lim    = (s.r * w1 + s.g * w2) * fineTune;
        supp.b = min(s.b, lim);
    }
}
else {
    if (screenType == 0) {
        lim    = computeLimit(s.r, s.b, algorithm, redWeight, ch2Weight) * fineTune;
        supp.g = min(s.g, lim);
    }
    else if (screenType == 1) {
        lim    = computeLimit(s.r, s.g, algorithm, redWeight, ch2Weight) * fineTune;
        supp.b = min(s.b, lim);
    }
    else {
        lim    = computeLimit(s.g, s.b, algorithm, redWeight, ch2Weight) * fineTune;
        supp.r = min(s.r, lim);
    }
}

// ── 2. SPILL MATTE ───────────────────────────────────────
vec3  spillDiff  = max(s - supp, 0.0);
float spillMatte = clamp(spillDiff.r + spillDiff.g + spillDiff.b, 0.0, 1.0);

// ── 3. RESTORE SOURCE LUMINANCE ──────────────────────────
vec3 lw = vec3(0.2126, 0.7152, 0.0722);
if (restoreLuma) {
    float lumaOrig = dot(s,    lw);
    float lumaSupp = dot(supp, lw);
    if (lumaSupp > 0.0001)
        supp = supp * (lumaOrig / lumaSupp);
}

// ── 4. SPILL AREA CORRECTION ─────────────────────────────
supp = applySaturation(supp, saturation);
supp = applyGamma(supp, gamma);
supp = supp + vec3(offset);

// ── 5. MIX ───────────────────────────────────────────────
vec3 result = mix(s, supp, mix_amount);

// ── 6. ALPHA OUTPUT ──────────────────────────────────────
float outAlpha = spillMatteInAlpha ? spillMatte : 1.0;

gl_FragColor = vec4(result, outAlpha);
}
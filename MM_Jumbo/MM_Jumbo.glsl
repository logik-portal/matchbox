#version 430

layout(location = 0) out vec4 fragColor;

layout(binding = 1) uniform AdskUniformBlock
{
    float adsk_result_w, adsk_result_h;
    float adsk_time;
};

layout(binding = 2) uniform UniformBlock
{
    // Page 0 Col 0 – Grid Shape
    float PixelSize;
    float DotSize;
    float DotSoftness;
    float GridAngle;
    float BloomRadius;
    // Page 0 Col 1 – Grid Look
    float BloomAmount;
    float Brightness;
    float BlackLevel;
    float Variation;
    float SatAmount;
    // Page 0 Col 2 – Grid Enable
    float JumboOn;
    float MonoMode;
    float PanelGridOn;
    // Page 0 Col 3 – Panel Grid
    float PanelSize;
    float PanelLineWidth;
    float PanelLineOpacity;
    // Page 1 Col 0 – Mono Tint
    float TintColorR;
    float TintColorG;
    float TintColorB;
};

// "front" is the clip being turned into a jumbotron/LED-wall look.
layout(binding = 3) uniform sampler2D front;

float hash21(vec2 p)
{
    vec3 q = fract(vec3(p.xyx) * vec3(0.1031, 0.1030, 0.0973));
    q += dot(q, q.yzx + 33.33);
    return fract((q.x + q.y) * q.z);
}

// One glowing LED dot: a hard-ish core (softened by DotSoftness) plus a
// soft exponential bloom halo bleeding a little beyond it — matching the
// reference photos, where each diode reads as a small bright point with
// its own glow rather than a flat filled circle.
float ledDotCoverage(vec2 p, vec2 center, float r, float softness, float bloomAmt, float bloomR)
{
    float d = length(p - center) - r;
    float aa = max(fwidth(d), 1e-5);
    float coreEdge = max(r * clamp(softness, 0.05, 1.0), aa);
    float core = 1.0 - smoothstep(-coreEdge, coreEdge, d);
    float halo = exp(-max(d, 0.0) / max(bloomR, 1e-5)) * bloomAmt;
    return clamp(core + halo * (1.0 - core), 0.0, 1.0);
}

void main()
{
    vec2  res = vec2(adsk_result_w, adsk_result_h);
    vec2  uv  = gl_FragCoord.xy / res;
    float asp = adsk_result_w / adsk_result_h;

    if (JumboOn < 0.5)
    {
        fragColor = vec4(texture(front, uv).rgb, 1.0);
        return;
    }

    // Aspect-corrected, centred coordinates in frame-height units — same
    // resolution-independent convention as the rest of this shader family.
    vec2 aUV = vec2((uv.x - 0.5) * asp, uv.y - 0.5);

    // Optional grid rotation, e.g. to match a camera slightly off-axis to
    // the physical LED wall.
    float ang = GridAngle * 0.017453;
    float cA = cos(ang), sA = sin(ang);
    vec2  rotUV = vec2(cA * aUV.x - sA * aUV.y, sA * aUV.x + cA * aUV.y);

    float cell = max(PixelSize, 0.002);
    vec2  ci = floor(rotUV / cell);
    vec2  cf = fract(rotUV / cell);
    vec2  localP = (cf - 0.5) * cell;

    // Sample the source clip once per cell, at the cell's own centre —
    // rotate that centre back to plain screen space to know where to
    // sample "front".
    vec2  cellCenterRot = (ci + 0.5) * cell;
    vec2  cellCenterAUV = vec2(cA * cellCenterRot.x + sA * cellCenterRot.y,
                              -sA * cellCenterRot.x + cA * cellCenterRot.y);
    vec2  sampleUV = vec2(cellCenterAUV.x / asp + 0.5, cellCenterAUV.y + 0.5);
    vec3  srcCol = texture(front, clamp(sampleUV, 0.0, 1.0)).rgb;

    // Slight per-cell brightness variation, like the subtle non-uniformity
    // real LED panels show up close, rather than perfectly identical diodes.
    float variClamp = clamp(Variation, 0.0, 1.0);
    float variMult = mix(1.0 - variClamp * 0.5, 1.0 + variClamp * 0.5, hash21(ci));

    float r        = cell * 0.12 * max(DotSize, 0.05);
    float bloomRadiusClamp = clamp(BloomRadius, 0.0, 1.0);
    float bloomAmt = clamp(BloomAmount, 0.0, 3.0);
    float soft     = clamp(DotSoftness, 0.05, 1.0);
    float brightness = max(Brightness, 0.0) * variMult;

    float blackClamp = clamp(BlackLevel, 0.0, 1.0);
    vec3 col = vec3(blackClamp);

    // Force each cell's glow to fade to nothing before reaching its own
    // boundary, so neighbouring cells always meet at zero and never show a
    // visible seam/box where one cell's bloom stops short of the next.
    float cellEdgeDist = max(abs(localP.x), abs(localP.y));
    float cellFade = 1.0 - smoothstep(cell * 0.4, cell * 0.5, cellEdgeDist);

    if (MonoMode > 0.5)
    {
        // Single dot per cell, driven by luminance, tinted a single colour
        // — matches the plain blue/white LED wall reference.
        float monoR = r * 1.6;
        float monoMargin = max(cell * 0.5 - monoR, cell * 0.02);
        float monoBloomR = mix(monoMargin * 0.15, monoMargin * 0.75, bloomRadiusClamp);
        float monoLum = dot(srcCol, vec3(0.299, 0.587, 0.114));
        float tintRClamp = clamp(TintColorR, 0.0, 1.0);
        float tintGClamp = clamp(TintColorG, 0.0, 1.0);
        float tintBClamp = clamp(TintColorB, 0.0, 1.0);
        vec3  tintR = vec3(tintRClamp, tintGClamp, tintBClamp);
        float cov = ledDotCoverage(localP, vec2(0.0), monoR, soft, bloomAmt, monoBloomR);
        col += tintR * monoLum * brightness * cov * cellFade;
    }
    else
    {
        // Three individual R/G/B sub-diodes side by side — the actual
        // subpixel structure visible in the close-up reference photos,
        // rather than a single blended-colour dot per cell. Spread wider
        // and sized a little smaller than the mono dot so each one has
        // room to stay perfectly round: the bloom radius is scaled to the
        // actual gap left between the dot and the cell edge (not a flat
        // multiple of the dot size), so it always decays to nothing before
        // the boundary regardless of how far out the dots are offset.
        float colorR    = r * 0.8;
        float offsetMag = cell * 0.32;
        float colorMargin = max(cell * 0.5 - offsetMag - colorR, cell * 0.02);
        float colorBloomR = mix(colorMargin * 0.15, colorMargin * 0.75, bloomRadiusClamp);

        float covR = ledDotCoverage(localP, vec2(-offsetMag, 0.0), colorR, soft, bloomAmt, colorBloomR);
        float covG = ledDotCoverage(localP, vec2(0.0, 0.0),        colorR, soft, bloomAmt, colorBloomR);
        float covB = ledDotCoverage(localP, vec2( offsetMag, 0.0), colorR, soft, bloomAmt, colorBloomR);

        col += vec3(1.0, 0.0, 0.0) * srcCol.r * brightness * covR * cellFade;
        col += vec3(0.0, 1.0, 0.0) * srcCol.g * brightness * covG * cellFade;
        col += vec3(0.0, 0.0, 1.0) * srcCol.b * brightness * covB * cellFade;
    }

    // Punch up (or reduce) saturation — real LED walls tend to read as
    // more vivid/oversaturated than the source content actually is.
    float lum = dot(col, vec3(0.299, 0.587, 0.114));
    float satClamp = clamp(SatAmount, -1.0, 2.0);
    col = mix(vec3(lum), col, 1.0 + satClamp);

    // Optional panel/module seams — real LED walls are built from smaller
    // physical panels bolted together, each showing as a thin black dividing
    // line. Drawn in the same rotated grid space as the LED cells so the
    // seams rotate together with the dot pattern, on a coarser spacing
    // (PanelSize cells per panel side).
    if (PanelGridOn > 0.5)
    {
        float panelCells = max(PanelSize, 1.0);
        float panelDim    = cell * panelCells;
        vec2  panelUV     = rotUV / panelDim;
        vec2  panelFrac   = fract(panelUV) - 0.5;
        vec2  distToEdge  = (0.5 - abs(panelFrac)) * panelDim;
        float distLine    = min(distToEdge.x, distToEdge.y);
        float lineHalf    = max(PanelLineWidth, 0.0) * 0.5;
        float aaLine      = max(fwidth(distLine), 1e-5);
        float panelLineMask = 1.0 - smoothstep(lineHalf - aaLine, lineHalf + aaLine, distLine);
        float panelOpacity  = clamp(PanelLineOpacity, 0.0, 1.0);
        float panelBlend    = panelLineMask * panelOpacity;
        col = mix(col, vec3(0.0), panelBlend);
    }

    vec3 colClamp = clamp(col, 0.0, 4.0);
    fragColor = vec4(colClamp, 1.0);
}

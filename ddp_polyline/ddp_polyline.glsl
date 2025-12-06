#version 120

uniform sampler2D front;
uniform float adsk_result_w;
uniform float adsk_result_h;
uniform int transition;

// Coordinates (pixel units)
uniform vec2 Atrack;
uniform vec2 Btrack;
uniform vec2 Ctrack;
uniform vec2 Dtrack;
uniform vec2 Aoffset;
uniform vec2 Boffset;
uniform vec2 Coffset;
uniform vec2 Doffset;

// Line settings
uniform float lineRadius;
uniform float ABline_start;
uniform float ABline_end;
uniform float ABCline_start;
uniform float ABCline_end;
uniform float ABCDline_start;
uniform float ABCDline_end;

// Circle settings
uniform float circleRadiusA;
uniform float circleRadiusB;
uniform float circleRadiusC;
uniform float circleRadiusD;

// Color & anti-aliasing
uniform vec3 colorRGB;
uniform float Anti_aliasing;
uniform bool overlay;

// Calculate line mask
float lineMask(vec2 p, vec2 start, vec2 end, float radius, float aa) {
    vec2 dir = end - start;
    float len = length(dir);
    if (len < 1e-6) return 0.0;
    vec2 dirNorm = dir / len;

    float tRaw = dot(p - start, dirNorm);
    float t = clamp(tRaw, 0.0, len);  // Clamp to line segment
    vec2 closest = start + dirNorm * t;
    float dist = length(p - closest);
    return aa <= 0.0 ? (dist < radius ? 1.0 : 0.0) : smoothstep(radius, radius - aa, dist);
}

// Calculate circle mask
float circleMask(vec2 p, vec2 center, float radius, float aa) {
    float dist = length(p - center);
    return aa <= 0.0 ? (dist < radius ? 1.0 : 0.0) : smoothstep(radius, radius - aa, dist);
}

void main() {
    vec2 res = vec2(adsk_result_w, adsk_result_h);
    vec2 coords = gl_FragCoord.xy;
    vec3 bg = texture2D(front, coords / res).rgb;
    vec3 color = colorRGB;

    float maskLine = 0.0;
    float maskA = 0.0;
    float maskB = 0.0;
    float maskC = 0.0;
    float maskD = 0.0;

    if (transition == 0) {
        // 2-point mode
        vec2 A = Atrack + Aoffset * res;
        vec2 B = Btrack + Boffset * res;

        float startDist = min(ABline_start, ABline_end) * length(B - A);
        float endDist   = max(ABline_start, ABline_end) * length(B - A);

        // Line
        maskLine = lineMask(coords, A + (B - A) * (startDist / length(B - A)), 
                                  A + (B - A) * (endDist / length(B - A)), 
                                  lineRadius, Anti_aliasing);

        // Circles
        maskA = circleMask(coords, A, circleRadiusA, Anti_aliasing);
        maskB = circleMask(coords, B, circleRadiusB, Anti_aliasing);
    }
    else if (transition == 1) {
        // 3-point mode
        vec2 A = Atrack + Aoffset * res;
        vec2 B = Btrack + Boffset * res;
        vec2 C = Ctrack + Coffset * res;

        float lenAB = length(B - A);
        float lenBC = length(C - B);
        float totalLen = lenAB + lenBC;

        float startDist = min(ABCline_start, ABCline_end) * totalLen;
        float endDist   = max(ABCline_start, ABCline_end) * totalLen;

        // AB line
        if (startDist < lenAB && endDist > 0.0)
            maskLine = max(maskLine, lineMask(coords, A + (B - A) * (max(startDist,0.0)/lenAB),
                                                  A + (B - A) * (min(endDist,lenAB)/lenAB),
                                                  lineRadius, Anti_aliasing));

        // BC line
        if (endDist > lenAB && startDist < totalLen)
            maskLine = max(maskLine, lineMask(coords, B + (C - B) * (max(startDist - lenAB,0.0)/lenBC),
                                                  B + (C - B) * (min(endDist - lenAB,lenBC)/lenBC),
                                                  lineRadius, Anti_aliasing));

        // Circles
        maskA = circleMask(coords, A, circleRadiusA, Anti_aliasing);
        maskB = circleMask(coords, B, circleRadiusB, Anti_aliasing);
        maskC = circleMask(coords, C, circleRadiusC, Anti_aliasing);
    }
    else if (transition == 2) {
        // 4-point mode
        vec2 A = Atrack + Aoffset * res;
        vec2 B = Btrack + Boffset * res;
        vec2 C = Ctrack + Coffset * res;
        vec2 D = Dtrack + Doffset * res;

        float lenAB = length(B - A);
        float lenBC = length(C - B);
        float lenCD = length(D - C);
        float totalLen = lenAB + lenBC + lenCD;

        float startDist = min(ABCDline_start, ABCDline_end) * totalLen;
        float endDist   = max(ABCDline_start, ABCDline_end) * totalLen;

        // AB line
        if (startDist < lenAB && endDist > 0.0)
            maskLine = max(maskLine, lineMask(coords, A + (B - A) * (max(startDist,0.0)/lenAB),
                                                  A + (B - A) * (min(endDist,lenAB)/lenAB),
                                                  lineRadius, Anti_aliasing));
        // BC line
        if (endDist > lenAB && startDist < lenAB + lenBC)
            maskLine = max(maskLine, lineMask(coords, B + (C - B) * (max(startDist - lenAB,0.0)/lenBC),
                                                  B + (C - B) * (min(endDist - lenAB,lenBC)/lenBC),
                                                  lineRadius, Anti_aliasing));
        // CD line
        if (endDist > lenAB + lenBC && startDist < totalLen)
            maskLine = max(maskLine, lineMask(coords, C + (D - C) * (max(startDist - lenAB - lenBC,0.0)/lenCD),
                                                  C + (D - C) * (min(endDist - lenAB - lenBC,lenCD)/lenCD),
                                                  lineRadius, Anti_aliasing));

        // Circles
        maskA = circleMask(coords, A, circleRadiusA, Anti_aliasing);
        maskB = circleMask(coords, B, circleRadiusB, Anti_aliasing);
        maskC = circleMask(coords, C, circleRadiusC, Anti_aliasing);
        maskD = circleMask(coords, D, circleRadiusD, Anti_aliasing);
    }

    float finalMask = max(maskLine, max(maskA, max(maskB, max(maskC, maskD))));
    vec3 result = overlay ? mix(bg, color, finalMask) : color * finalMask;
    gl_FragColor = vec4(result, 1.0);
}

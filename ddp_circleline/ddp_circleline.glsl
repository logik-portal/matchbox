#version 120

uniform float adsk_result_w;
uniform float adsk_result_h;

uniform sampler2D front;

uniform vec2 Center;
uniform float Radius;
uniform float LineWidth;
uniform float ProgressStart;
uniform float ProgressEnd;
uniform float Rotation;
uniform vec3 Line_Color;
uniform vec3 Fill_Color;

uniform bool overlay;
uniform bool fillVisible;
uniform bool lineVisible;
uniform bool capVisible;
uniform float lineAA;
uniform float fillAA;

// --------------------------
// Signed Distance Field
float circleSDF(vec2 p, float r)
{
    return length(p) - r;
}

float circleEdgeSDF(vec2 p, float r)
{
    return abs(length(p) - r);
}

// --------------------------
// AA angle mask (with special cases)
float angleMask(float angle, float start, float end, float edgeAA)
{
    float len = mod(end - start + 1.0, 1.0);

    // Full (start=0, end=1)
    if (abs((start - 0.0) - (end - 1.0)) < 1e-6) {
        return 1.0;
    }

    // Invisible (start=end)
    if (abs(start - end) < 1e-6) {
        return 0.0;
    }

    if(len < 0.001) return 0.0;
    if(len > 0.999) return 1.0;

    float dist = mod(angle - start + 1.0, 1.0);
    float a = smoothstep(0.0, edgeAA, dist);
    float b = smoothstep(0.0, edgeAA, len - dist);
    return a * b;
}

// --------------------------
// Caps
float capSDF(vec2 p, float radius, float angle)
{
    vec2 capPos = vec2(cos(angle * 6.2831853), sin(angle * 6.2831853)) * radius;
    return length(p - capPos);
}

// --------------------------
void main()
{
    vec2 res = vec2(adsk_result_w, adsk_result_h);
    vec2 uv  = gl_FragCoord.xy / res;

    vec3 bg = texture2D(front, uv).rgb;

    float aspect = adsk_result_w / adsk_result_h;
    vec2 p = uv - Center;
    p.x *= aspect;

    // -----------------------------
    // Fill
    // -----------------------------
    float fillMask = 0.0;
    if(fillVisible){
        float sd = circleSDF(p, Radius);
        fillMask = clamp(0.5 - sd / fillAA, 0.0, 1.0);
    }

    // ▼ Reverse (important)
    float ProgressStartB = 1.0 - ProgressStart;
    float ProgressEndB   = 1.0 - ProgressEnd;

    // -----------------------------
    // Line (circle edge)
    // -----------------------------
    float lineMask = 0.0;
    if(lineVisible){

        // No arc
        if (ProgressStartB > ProgressEndB || abs(ProgressStartB - ProgressEndB) < 1e-6) {
            lineMask = 0.0;
        } else {

            float ang = atan(p.y, p.x) / (2.0 * 3.1415926535);
            if(ang < 0.0) ang += 1.0;

            ang += 0.75; // Upward direction (12 o'clock)

            float rot = Rotation / 360.0;
            ang = fract(ang - rot);

            float mask = angleMask(ang, ProgressStartB, ProgressEndB, lineAA);

            float d = circleEdgeSDF(p, Radius);
            float factor = pow(clamp(length(p)/Radius, 0.0, 1.0), 0.5);

            lineMask = (1.0 - smoothstep(LineWidth - lineAA*factor,
                                         LineWidth + lineAA*factor,
                                         d)) * mask;
        }
    }

    // -----------------------------
    // Caps
    // -----------------------------
    float capMask = 0.0;
    if(capVisible && lineVisible){

        // No arc
        if (ProgressStartB > ProgressEndB || abs(ProgressStartB - ProgressEndB) < 1e-6) {
            capMask = 0.0;
        } else {

            float rot = Rotation / 360.0;

            float angStart = fract(ProgressStartB + 0.25 - rot);
            float angEnd   = fract(ProgressEndB   + 0.25 - rot);

            float d1 = capSDF(p, Radius, angStart);
            float d2 = capSDF(p, Radius, angEnd);

            float factor = pow(clamp(length(p)/Radius, 0.0, 1.0), 0.5);

            capMask = 1.0 - smoothstep(LineWidth - lineAA*factor,
                                       LineWidth + lineAA*factor,
                                       min(d1, d2));
        }
    }

    // -----------------------------
    // Composite
    // -----------------------------
    float totalMask = max(lineMask, capMask);

    vec3 fillCol = fillMask * Fill_Color;
    vec3 lineCol = totalMask * Line_Color;
    float alpha = clamp(max(fillMask, totalMask), 0.0, 1.0);
    vec3 src = fillCol + lineCol;

    vec3 outCol;
    if(overlay){
        outCol = bg * (1.0 - alpha) + src;
    }else{
        outCol = src;
    }

    gl_FragColor = vec4(clamp(outCol,0.0,1.0),1.0);
}

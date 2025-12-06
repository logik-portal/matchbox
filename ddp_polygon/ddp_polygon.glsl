#version 120

uniform float adsk_result_w;
uniform float adsk_result_h;

uniform vec2 Center;       
uniform float Radius;      
uniform int Sides;         
uniform float LineWidth;   
uniform float ProgressStart; 
uniform float ProgressEnd;   
uniform vec3 Line_Color;   
uniform vec3 Fill_Color;
uniform bool overlay;   
uniform float lineAA;      
uniform float fillAA;      
uniform bool fillVisible;  
uniform bool lineVisible;  
uniform sampler2D front;   
uniform vec2 ScaleXY;      

// -----------------
// Generate polygon vertices
void polygonVerts(int n, float r, out vec2 verts[20]) {
    float TWO_PI = 6.2831853;
    float angleStep = TWO_PI / float(n);
    float offset = -angleStep*0.5 - 3.1415926*0.5; 
    for(int i=0;i<n;i++){
        float a = float(i) * angleStep + offset;
        verts[i] = vec2(cos(a), sin(a)) * r;
    }
}

// -----------------
// Distance field for line segment
float lineSDF(vec2 p, vec2 a, vec2 b) {
    vec2 pa = p - a;
    vec2 ba = b - a;
    float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
    return length(pa - ba * h);
}

// -----------------
void main() {
    vec2 res = vec2(adsk_result_w, adsk_result_h);
    vec2 uv = gl_FragCoord.xy / res;

    vec3 bg = texture2D(front, uv).rgb;

    float aspect = adsk_result_w / adsk_result_h;
    vec2 p = uv - Center;
    p.x *= aspect;

    int n = int(max(float(Sides), 3.0));
    vec2 verts[20];
    polygonVerts(n, Radius, verts);

    vec2 scaledVerts[20];
    for(int i=0;i<n;i++) scaledVerts[i] = verts[i] * ScaleXY;

    // --- Fill ---
    float minDist = 1e10;
    bool inside = false;

    for(int i=0;i<n;i++){
        int j = i + 1; 
        if (j >= n) j = 0;

        vec2 a = scaledVerts[i];
        vec2 b = scaledVerts[j];

        float d = lineSDF(p, a, b);
        if(d < minDist) minDist = d;

        if( ((a.y > p.y) != (b.y > p.y)) &&
            (p.x < (b.x - a.x)*(p.y - a.y)/(b.y - a.y) + a.x) )
            inside = !inside;
    }

    float signedDist = inside ? -minDist : minDist;
    float fillMask = fillVisible ? clamp(0.5 - signedDist/fillAA, 0.0, 1.0) : 0.0;

    // --- Line (progress-based) ---
    float mask = 0.0;

    if(lineVisible){
        float edgeLengths[20];
        float totalLength = 0.0;

        for(int i=0;i<n;i++){
            int j = i + 1;
            if(j >= n) j = 0;

            edgeLengths[i] = length(scaledVerts[j]-scaledVerts[i]);
            totalLength += edgeLengths[i];
        }

        float drawStart = ProgressEnd * totalLength;
        float drawEnd   = ProgressStart * totalLength;

        float accLength = 0.0;

        for(int i=0;i<n;i++){
            int j = i + 1; 
            if(j >= n) j = 0;

            float edgeLen = edgeLengths[i];

            float edgeStart = max(drawStart - accLength, 0.0);
            float edgeEnd   = clamp(drawEnd - accLength, 0.0, edgeLen);

            if(edgeEnd > edgeStart){
                vec2 dir = scaledVerts[j] - scaledVerts[i];
                vec2 a = scaledVerts[i] + dir * (edgeStart / edgeLen);
                vec2 b = scaledVerts[i] + dir * (edgeEnd   / edgeLen);

                float d = lineSDF(p, a, b);
                mask = max(mask, 1.0 - smoothstep(LineWidth - lineAA,
                                                  LineWidth + lineAA, d));
            }

            accLength += edgeLen;
            if(accLength > drawEnd) break;
        }
    }

    // --- Composite ---
    vec3 fillCol = fillMask * Fill_Color;
    vec3 lineCol = mask * Line_Color;

    float alpha = clamp(max(fillMask, mask), 0.0, 1.0);

    vec3 src = fillCol + lineCol;

    vec3 finalCol;
    if (overlay)
        finalCol = bg * (1.0 - alpha) + src;
    else
        finalCol = src;

    gl_FragColor = vec4(clamp(finalCol, 0.0, 1.0), 1.0);
}

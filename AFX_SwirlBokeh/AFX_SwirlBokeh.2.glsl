#version 430

// PASS 2: Kernel Blur
// Blurs each channel with swirl effect

layout( location = 0 ) out vec4 fragColor;

// System uniforms
layout( binding = 1 ) uniform AdskUniformBlock
{
    float adsk_result_w, adsk_result_h;
};

// User uniforms
layout( binding = 2 ) uniform UniformBlock
{
    // Column 0: Bokeh (order must match XML Pass 1)
    float blurAmount;
    float kernelSides;  // 3-12
    float baseRotation; // -180 to 180 degrees

    // Cat's Eye enhancement
    bool  catsEyeOn;
    float catsEyeStrength;   // 0..1

    // Column 1: Swirl (Squish)
    float squish;
    float falloffCurve;

};

// Previous pass result
layout( binding = 3 ) uniform sampler2D adsk_results_pass1;

// Constants
// UI blurAmount (0..100) maps to effective radius scaled by this factor
const float BLUR_SCALE = 1.5; // 0..100 → 0..150
// Set-and-forget center shrink amount (0=no shrink at center, 0.25 = 25%)
const float CENTER_SHRINK = 0.5;

// Helper function to get radial angle from center
float getRadialAngle(vec2 coords)
{
    vec2 center = vec2(0.5, 0.5);
    vec2 delta = coords - center;
    float angleRad = atan(delta.y, delta.x);
    float angleDeg = degrees(angleRad);
    
    // Convert to clockwise from positive X-axis (0-360°)
    angleDeg = -angleDeg;
    if (angleDeg < 0.0) angleDeg += 360.0;
    
    return angleDeg;
}

// Helper function to create rotation matrix
mat2 getRotationMatrix(float angleDeg)
{
    float angleRad = radians(angleDeg);
    float c = cos(angleRad);
    float s = sin(angleRad);
    return mat2(c, -s, s, c);
}

// Check if a point is inside a regular polygon
// Returns true if point (x, y) is inside a polygon with 'sides' sides and 'radius'
bool isInsidePolygon(float x, float y, int sides, float radius)
{
    // Early circle reject/accept
    float r2 = x * x + y * y;
    float radiusSq = radius * radius;
    if (sides > 10) {
        return r2 <= radiusSq;
    }
    if (r2 > radiusSq) {
        return false;
    }

    // Convert to polar coordinates
    float angle = atan(y, x);

    // Calculate the angle of one side
    float sideAngle = 2.0 * 3.14159265359 / float(sides);

    // Find which edge we're closest to
    float edgeAngle = mod(angle, sideAngle) - sideAngle * 0.5;

    // Distance from center to edge at this angle
    float edgeDistance = radius * cos(sideAngle * 0.5) / cos(edgeAngle);

    // Compare squared distances to avoid sqrt
    float edgeDistanceSq = edgeDistance * edgeDistance;
    return r2 <= edgeDistanceSq;
}

void main()
{
    vec2 coords = gl_FragCoord.xy / vec2(adsk_result_w, adsk_result_h);
    vec2 center = vec2(0.5, 0.5);
    
    // If blur amount is 0, just pass through
    if (blurAmount < 0.01) {
        fragColor = texture(adsk_results_pass1, coords);
        return;
    }
    
    // Calculate this pixel's distance and angle from image center
    vec2 delta = coords - center;
    float distanceFromCenter = length(delta);
    float pixelAngle = getRadialAngle(coords);
    
    // Calculate edge-dependent factors
    float edgeFactor = distanceFromCenter * 2.0;  // 0 at center, 1 at corners
    edgeFactor = min(edgeFactor, 1.0);
    // Cat's eye amount (used by multiple stages)
    float cats = (catsEyeOn) ? pow(edgeFactor, falloffCurve) * catsEyeStrength : 0.0;
    
    // Swirl rotation should always apply; Cat's Eye only affects shape/squish
    float swirlRotation = pixelAngle;
    
    // Squish will be applied via mask only (no offset scaling)
    float curvedEdgeFactor = pow(edgeFactor, falloffCurve);
    float squishMagnitude = (catsEyeOn) ? curvedEdgeFactor * abs(squish) : 0.0; // 0..1
    // Center shrink scale: smallest at center (cats≈0), fades to 1 toward edges
    float shrinkScale = mix(1.0 - CENTER_SHRINK, 1.0, cats);
    
    float totalRotation = baseRotation + swirlRotation;
    
    // Effective blur radius (scaled from UI)
    float blurR = blurAmount * BLUR_SCALE;
    int radius = int(ceil(blurR));
    mat2 rotMat = getRotationMatrix(totalRotation);
    
    // Pre-calculate inverse dimensions for performance
    vec2 invDimensions = vec2(1.0 / adsk_result_w, 1.0 / adsk_result_h);
    
    // Get kernel shape
    int sides = int(kernelSides);

    // Basis for cat's-eye (per pixel)
    vec2 u = vec2(1.0, 0.0);  // radial
    vec2 v = vec2(0.0, 1.0);  // tangential
    if (distanceFromCenter > 1e-6) {
        u = normalize(delta);
        v = vec2(-u.y, u.x);
    }
    
    // Cache expensive calculations outside the loop
    float blurRSq = blurR * blurR;
    float invBlurRSq = 1.0 / max(blurRSq, 1e-6);
    float shrinkScale2 = shrinkScale * shrinkScale;
    
    // Cache Cat's Eye calculations if needed
    float catR = 0.0, catD = 0.0, catEps = 0.0, catInvR2 = 0.0;
    if (cats > 0.0) {
        catR = blurR;
        const float POINTINESS = 0.8;
        catD = cats * POINTINESS * catR;
        catEps = 0.02;
        catInvR2 = 1.0 / max(catR * catR, 1e-6);
    }
    
    // Apply blur using dense grid sampling (accurate kernel)
    vec3 colorSum = vec3(0.0);
    float totalWeight = 0.0;
    
    for (int y = -radius; y <= radius; y++)
    {
        float fy = float(y);
        float rem = blurRSq - fy * fy;
        if (rem < 0.0) { continue; }
        int xMax = int(floor(sqrt(rem)));
        
        for (int x = -xMax; x <= xMax; x++)
        {
            float fx = float(x);
            float distSq = fx * fx + fy * fy;
            
            // Early circle reject before polygon test
            if (distSq > blurRSq) {
                continue;
            }
            
            // Polygon inclusion test at full radius
            if (!isInsidePolygon(fx, fy, sides, blurR)) {
                continue;
            }
            
            // Ellipse scaling and swirl rotation (apply center shrink)
            vec2 scaledOffset = vec2(fx, fy) * shrinkScale;
            vec2 rotatedOffset = rotMat * scaledOffset;
            
            // Weight from scaled distance so energy stays consistent
            float weight = 1.0 - (distSq * shrinkScale2) * invBlurRSq;
            if (weight <= 0.0) {
                continue;
            }
            
            // Compute L/T once for both trim and vesica
            float L = dot(rotatedOffset, u); // radial
            float T = dot(rotatedOffset, v); // tangential

            // One-sided rectangular cutoff (squish) first for early exit
            if (squishMagnitude > 0.0) {
                float epsR = 0.02 * blurR;
                float trim;
                if (squish > 0.0) {
                    float cutL = mix(-blurR, 0.0, squishMagnitude);
                    trim = smoothstep(cutL - epsR, cutL + epsR, L);
                } else {
                    float cutR = mix(blurR, 0.0, squishMagnitude);
                    trim = 1.0 - smoothstep(cutR - epsR, cutR + epsR, L);
                }
                if (trim <= 0.0) { continue; }
                weight *= trim;
                if (weight <= 0.0) { continue; }
            }
            
            // Optional Cat's Eye mask (vesica piscis: intersection of two circles)
            if (cats > 0.0) {
                // Use cached values
                // Distance^2 to each circle center (at L = ±catD)
                float dist1 = (L - catD) * (L - catD) + T * T;
                float dist2 = (L + catD) * (L + catD) + T * T;
                
                // Base vesica mask (two equal circles) with soft edge
                float m1 = 1.0 - smoothstep(1.0, 1.0 + catEps, dist1 * catInvR2);
                float m2 = 1.0 - smoothstep(1.0, 1.0 + catEps, dist2 * catInvR2);
                float catMask = m1 * m2; // intersection produces pointed caps
                
                if (catMask <= 0.0) {
                    continue;
                }
                weight *= catMask;
                if (weight <= 0.0) {
                    continue;
                }
            }
            
            // Convert to UVs and sample
            vec2 sampleUV = coords + rotatedOffset * invDimensions;
            colorSum += texture(adsk_results_pass1, sampleUV).rgb * weight;
            totalWeight += weight;
        }
    }
    
    // Normalize by total weight
    if (totalWeight > 0.0) {
        fragColor = vec4(colorSum / totalWeight, 1.0);
    } else {
        fragColor = texture(adsk_results_pass1, coords);
    }
}


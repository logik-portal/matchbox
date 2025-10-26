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

    // Cat's Eye enhancement
    bool  catsEyeOn;
    float catsEyeStrength;   // 0..1

    // Column 1: Swirl (Squish)
    float squish;
    float falloffCurve;

    // Column 3: Lens Mush (unused in this pass but kept for layout stability)
    bool  mushOn;
    float mushStrength;
    float mushSize;

    // Column 4: Vignette (unused here)
    bool  vignetteOn;
    float vignetteStrength;
    float vignetteSize;
    float vignetteFalloff;
};

// Previous pass result
layout( binding = 3 ) uniform sampler2D adsk_results_pass1;

// Constants
const float HORIZONTAL_SCALE = 1.0;
const float VERTICAL_SCALE = 1.0;
const float BASE_ROTATION = 0.0;

// No Poisson sampling for accurate kernel; we use dense grid sampling

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
    
    // Swirl follows Cat's Eye enable
    float swirlRotation = catsEyeOn ? pixelAngle : 0.0;
    
    // Apply swirl strength to horizontal scale (narrower at edges)
    float effectiveHorizontalScale = HORIZONTAL_SCALE;
    // Squish follows Cat's Eye enable
    if (catsEyeOn && squish > 0.0) {
        // Apply non-linear falloff curve to edge factor
        float curvedEdgeFactor = pow(edgeFactor, falloffCurve);
        
        // Reduce horizontal scale at edges (makes kernel narrower)
        float edgeNarrowing = 1.0 - (curvedEdgeFactor * squish);
        effectiveHorizontalScale = HORIZONTAL_SCALE * edgeNarrowing;
    }
    
    float totalRotation = BASE_ROTATION + swirlRotation;
    
    int radius = int(ceil(blurAmount));
    mat2 rotMat = getRotationMatrix(totalRotation);
    
    // Pre-calculate inverse dimensions for performance
    vec2 invDimensions = vec2(1.0 / adsk_result_w, 1.0 / adsk_result_h);
    
    // Pre-calculate for squared distance check (avoid sqrt in loop)
    float blurAmountSq = blurAmount * blurAmount;
    
    // Get kernel shape
    int sides = int(kernelSides);

    // Basis for cat's-eye (per pixel)
    vec2 u = vec2(1.0, 0.0);  // radial
    vec2 v = vec2(0.0, 1.0);  // tangential
    if (distanceFromCenter > 1e-6) {
        u = normalize(delta);
        v = vec2(-u.y, u.x);
    }
    // Use the existing edgeFactor computed above (0..1)
    float cats = (catsEyeOn) ? pow(edgeFactor, falloffCurve) * catsEyeStrength : 0.0;
    // Map UI sharpness (1..4) to a stronger exponent range near edges for crisper caps
    // pT grows with edge distance so center remains unchanged
    float superExp = mix(2.0, 8.0, cats);  // fixed mapping now that sharpness UI is removed
    
    // Apply blur using dense grid sampling (accurate kernel)
    vec3 colorSum = vec3(0.0);
    float totalWeight = 0.0;
    
    for (int y = -radius; y <= radius; y++)
    {
        for (int x = -radius; x <= radius; x++)
        {
            float fx = float(x);
            float fy = float(y);
            float distSq = fx * fx + fy * fy;
            
            // Early circle reject before polygon test
            if (distSq > blurAmountSq) {
                continue;
            }
            
            // Polygon inclusion test at full radius
            if (!isInsidePolygon(fx, fy, sides, blurAmount)) {
                continue;
            }
            
            // Distance-squared tent weight (no sqrt)
            float weight = 1.0 - distSq / blurAmountSq;
            if (weight <= 0.0) {
                continue;
            }
            
            // Ellipse scaling and swirl rotation
            vec2 scaledOffset = vec2(fx * effectiveHorizontalScale, fy * VERTICAL_SCALE);
            vec2 rotatedOffset = rotMat * scaledOffset;
            
            // Optional Cat's Eye mask (piecewise superellipse in radial/tangential basis)
            if (cats > 0.0) {
                float L = dot(rotatedOffset, u); // radial
                float T = dot(rotatedOffset, v); // tangential
                float R_out = blurAmount;
                float R_in  = blurAmount * (1.0 - cats);
                // Tangential radius symmetric now that skew is removed
                float T_rad = blurAmount;
                float R_side = (L >= 0.0) ? R_out : R_in;
                float lTerm = (abs(L) / max(R_side, 1e-6));
                float tTerm = (abs(T) / max(T_rad, 1e-6));
                float shapeVal = lTerm * lTerm + pow(tTerm, superExp);
                // soft interior mask around boundary to avoid aliasing
                float catMask = 1.0 - smoothstep(0.98, 1.02, shapeVal);
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


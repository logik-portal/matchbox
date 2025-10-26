#version 430

// PASS 1: Chromatic Aberration
// Separates and transforms R, G, B channels

layout( location = 0 ) out vec4 fragColor;

// System uniforms
layout( binding = 1 ) uniform AdskUniformBlock
{
    float adsk_result_w, adsk_result_h;
};

// User uniforms
layout( binding = 2 ) uniform UniformBlock
{
    bool chromaticOn;
    float redScale;
    float blueScale;
    float chromaticBlur;  // 0..1, maps to LOD for all channels
};

// Input texture
layout( binding = 0 ) uniform sampler2D frontTex;

void main()
{
    vec2 coords = gl_FragCoord.xy / vec2(adsk_result_w, adsk_result_h);
    vec2 center = vec2(0.5, 0.5);
    
    if (chromaticOn && (abs(redScale) > 0.001 || abs(blueScale) > 0.001 || chromaticBlur > 0.001))
    {
        // Scale UI values (-1 to +1) to actual chromatic values (-0.005 to +0.005)
        float actualRedScale = redScale * 0.005;
        float actualBlueScale = blueScale * 0.005;
        
        // Calculate chromatic scaling factors based on distance from center
        vec2 delta = coords - center;
        float distanceFromCenter = length(delta);
        float edgeFactor = distanceFromCenter * 2.0;  // 0 at center, 1 at corners
        edgeFactor = min(edgeFactor, 1.0);
        
        float chromaticFactor = pow(edgeFactor, 2.0);
        float redScaleFactor = 1.0 + (chromaticFactor * actualRedScale);
        float blueScaleFactor = 1.0 + (chromaticFactor * actualBlueScale);
        
        // Scale coordinates from center for red and blue channels
        vec2 redCoords = center + (coords - center) * redScaleFactor;
        vec2 blueCoords = center + (coords - center) * blueScaleFactor;
        
        // Edge-weighted mip LOD for subtle blur (0 at center, up to ~1.25 at corners)
        float lodAll = (pow(edgeFactor, 2.0)) * (chromaticBlur * 1.25);

        // Sample each channel at its scaled coordinates with per-channel LOD
        float red   = textureLod(frontTex, redCoords,  lodAll).r;
        float green = textureLod(frontTex, coords,     lodAll).g;
        float blue  = textureLod(frontTex, blueCoords, lodAll).b;
        
        fragColor = vec4(red, green, blue, 1.0);
    }
    else
    {
        // No chromatic aberration, pass through
        fragColor = texture(frontTex, coords);
    }
}


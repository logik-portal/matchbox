#version 430

// PASS 2: Chromatic Dispersion
// Applies simple chromatic aberration based on distortion

layout( location = 0 ) out vec4 fragColor;

// System uniforms
layout( binding = 1 ) uniform AdskUniformBlock
{
    float adsk_result_w, adsk_result_h;
    float adsk_time;
};

// User uniforms
layout( binding = 2 ) uniform UniformBlock
{
    // Noise controls
    float noiseFrequency;      // 0.1 - 10.0, controls noise complexity
    float noiseAmplitude;       // 0.0 - 1.0, controls noise strength
    float noiseScaleX;         // 0.1 - 5.0, horizontal noise scale
    float noiseScaleY;         // 0.1 - 5.0, vertical noise scale
    float noiseEvolution;       // 0.0 - 1.0, controls time evolution speed
    float flowDirection;        // Direction of noise flow (0-360 degrees)
    float flowSpeed;            // 0.0 - 5.0, speed of directional flow
    float speedMultiplier;      // 0.0 - 5.0, global speed multiplier
    float globalScale;          // 0.1 - 5.0, multiplies scale X/Y only
    bool previewNoise;          // Toggle to preview noise pattern
    
    // Fractal noise controls
    int noiseOctaves;           // 1 - 8, number of octaves for fractal noise
    float noiseLacunarity;      // 1.0 - 4.0, frequency multiplier per octave
    float noiseGain;            // 0.1 - 1.0, amplitude multiplier per octave
    
    // Distortion controls
    float distortionStrength;   // 0.0 - 1.0, controls warping amount
    float distortionDamping;   // 0.0 - 10.0, controls edge damping
    
    // Dispersion controls
    float dispersionStrength;   // 0.0 - 2.0, strength of wavelength separation
    float dispersionAngle;     // 0.0 - 360.0, angle of dispersion
    bool enableDispersion;    // Toggle dispersion on/off
    
    // Padding for alignment
    float _padding;
};

// Input textures
layout( binding = 3 ) uniform sampler2D front;           // Original image
layout( binding = 4 ) uniform sampler2D adsk_results_pass1; // Result from pass 1

// Constants
const float DISPERSION_SCALE = 0.005;     // Scale factor for dispersion

// Simplex noise implementation (same as Pass 1)
vec3 mod289(vec3 x) {
    return x - floor(x * (1.0 / 289.0)) * 289.0;
}

vec4 mod289(vec4 x) {
    return x - floor(x * (1.0 / 289.0)) * 289.0;
}

vec4 permute(vec4 x) {
    return mod289(((x*34.0)+1.0)*x);
}

vec4 taylorInvSqrt(vec4 r) {
    return 1.79284291400159 - 0.85373472095314 * r;
}

float snoise(vec3 v) {
    const vec2 C = vec2(1.0/6.0, 1.0/3.0);
    const vec4 D = vec4(0.0, 0.5, 1.0, 2.0);

    // First corner
    vec3 i = floor(v + dot(v, C.yyy));
    vec3 x0 = v - i + dot(i, C.xxx);

    // Other corners
    vec3 g = step(x0.yzx, x0.xyz);
    vec3 l = 1.0 - g;
    vec3 i1 = min(g.xyz, l.zxy);
    vec3 i2 = max(g.xyz, l.zxy);

    vec3 x1 = x0 - i1 + C.xxx;
    vec3 x2 = x0 - i2 + C.yyy;
    vec3 x3 = x0 - D.yyy;

    // Permutations
    i = mod289(i);
    vec4 p = permute(permute(permute(
                i.z + vec4(0.0, i1.z, i2.z, 1.0))
            + i.y + vec4(0.0, i1.y, i2.y, 1.0))
            + i.x + vec4(0.0, i1.x, i2.x, 1.0));

    // Gradients
    float n_ = 0.142857142857; // 1.0/7.0
    vec3 ns = n_ * D.wyz - D.xzx;

    vec4 j = p - 49.0 * floor(p * ns.z * ns.z);

    vec4 x_ = floor(j * ns.z);
    vec4 y_ = floor(j - 7.0 * x_);

    vec4 x = x_ *ns.x + ns.yyyy;
    vec4 y = y_ *ns.x + ns.yyyy;
    vec4 h = 1.0 - abs(x) - abs(y);

    vec4 b0 = vec4(x.xy, y.xy);
    vec4 b1 = vec4(x.zw, y.zw);

    vec4 s0 = floor(b0)*2.0 + 1.0;
    vec4 s1 = floor(b1)*2.0 + 1.0;
    vec4 sh = -step(h, vec4(0.0));

    vec4 a0 = b0.xzyw + s0.xzyw*sh.xxyy;
    vec4 a1 = b1.xzyw + s1.xzyw*sh.zzww;

    vec3 p0 = vec3(a0.xy, h.x);
    vec3 p1 = vec3(a0.zw, h.y);
    vec3 p2 = vec3(a1.xy, h.z);
    vec3 p3 = vec3(a1.zw, h.w);

    // Normalise gradients
    vec4 norm = taylorInvSqrt(vec4(dot(p0,p0), dot(p1,p1), dot(p2,p2), dot(p3,p3)));
    p0 *= norm.x;
    p1 *= norm.y;
    p2 *= norm.z;
    p3 *= norm.w;

    // Mix final noise value
    vec4 m = max(0.6 - vec4(dot(x0,x0), dot(x1,x1), dot(x2,x2), dot(x3,x3)), 0.0);
    m = m * m;
    return 42.0 * dot(m*m, vec4(dot(p0,x0), dot(p1,x1), dot(p2,x2), dot(p3,x3)));
}


void main()
{
    vec2 coords = gl_FragCoord.xy / vec2(adsk_result_w, adsk_result_h);
    
    if (previewNoise) {
        // Pass through noise preview from pass 1
        fragColor = texture(adsk_results_pass1, coords);
    } else if (enableDispersion) {
        // Calculate dispersion direction
        float dispersionRadians = radians(dispersionAngle);
        vec2 dispersionDir = vec2(cos(dispersionRadians), sin(dispersionRadians));
        
        // Generate the same noise pattern that drives the distortion
        // This ensures the dispersion animates with the water ripples
        float flowRadians = radians(flowDirection);
        vec2 flowDir = vec2(cos(flowRadians), sin(flowRadians));
        vec2 flowOffset = flowDir * (flowSpeed * speedMultiplier) * 0.1 * adsk_time;
        
        vec2 noiseCoords = coords * noiseFrequency / (vec2(noiseScaleX, noiseScaleY) * globalScale) + flowOffset;
        vec3 noisePos = vec3(noiseCoords, adsk_time * (noiseEvolution * speedMultiplier) * 0.05);
        
        // Generate noise for dispersion strength
        float noise = 0.0;
        float amplitude = 0.5;
        float frequency = 1.0;
        
        for (int i = 0; i < noiseOctaves; i++) {
            noise += amplitude * snoise(noisePos * frequency);
            amplitude *= noiseGain;
            frequency *= noiseLacunarity;
        }
        
        // Normalize noise to 0-1 range
        noise = noise * 0.5 + 0.5;
        noise = mix(0.5, noise, noiseAmplitude);
        
        // Use noise to modulate dispersion strength
        // Noise values 0-1, so we get dispersion strength from 0 to full strength
        float localDispersionStrength = dispersionStrength * noise;
        
        // Calculate noise-driven offsets
        float redOffset = localDispersionStrength * DISPERSION_SCALE;
        float blueOffset = -localDispersionStrength * DISPERSION_SCALE; // Opposite direction
        
        // Apply dispersion to coordinates
        vec2 redCoords = coords + dispersionDir * redOffset;
        vec2 blueCoords = coords + dispersionDir * blueOffset;
        
        // Clamp coordinates
        redCoords = clamp(redCoords, 0.0, 1.0);
        blueCoords = clamp(blueCoords, 0.0, 1.0);
        
        // Sample each channel from the DISTORTED result (pass 1), not original
        vec4 redSample = texture(adsk_results_pass1, redCoords);
        vec4 blueSample = texture(adsk_results_pass1, blueCoords);
        vec4 greenSample = texture(adsk_results_pass1, coords);  // Green stays centered
        
        float red = redSample.r;
        float green = greenSample.g;
        float blue = blueSample.b;
        float alpha = greenSample.a;
        
        fragColor = vec4(red, green, blue, alpha);
    } else {
        // No dispersion: pass through from pass 1
        fragColor = texture(adsk_results_pass1, coords);
    }
}

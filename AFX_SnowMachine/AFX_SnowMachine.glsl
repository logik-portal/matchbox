#version 430
layout ( location = 0 ) out vec4 fragColor;

// System uniforms per DOCS/glsl-basics.md
layout( binding = 1 ) uniform AdskUniformBlock
{
   float adsk_result_w, adsk_result_h;
   float adsk_time;
};

// User parameters
layout( binding = 2 ) uniform UniformBlock
{
   float flakeSize;
   float flakeSoftness;
   float clumpDistance;
   int   layers;
   float depthParallax;
   float foregroundCull;
   float gravity;
   float windDirDeg;
   float windStrength;
   float windSpeedNoise;
   float windNoise;
   float windNoiseFreq;
   float rotationSpeed;
   float turbulence;
   float turbulenceFreq;
   float particleSpeedVar;
   float depthFade;
   float brightnessVar;
   int   seed;
};

// Create a single snowflake with irregular edges
float createSnowFlake(vec2 center, float pSize, float softness, float irregularity) {
   vec2 s = abs(center);
   
   // Simple irregular noise for organic shape
   s += 0.01 * abs(2.0 * fract(10.0 * center.yx) - 1.0);
   s += 0.015 * abs(2.0 * fract(7.0 * center.xy + irregularity) - 1.0);
   s += 0.008 * abs(2.0 * fract(15.0 * center.yx + irregularity * 2.0) - 1.0);
   
   // Simplified distance field
   const float DIST_SCALE = 0.6;
   const float DIST_OFFSET = 0.01;
   float d = DIST_SCALE * max(s.x - s.y, s.x + s.y) + max(s.x, s.y) - DIST_OFFSET;
   
   // Softness controls edge gradient width (ensure defined smoothstep ordering)
   const float SOFTNESS_HALF = 0.5;
   float halfRange = max(pSize * softness * SOFTNESS_HALF, 1e-5);
   float t = smoothstep(pSize - halfRange, pSize + halfRange, d);
   return 1.0 - t;
}

void main()
{
   vec2 res = vec2(adsk_result_w, adsk_result_h);
   
   float iTime = adsk_time * 0.05;
   float accum = 0.0;
   
   // Hash constants for pseudo-random generation
   const float HASH_MULT = 43758.5453;
   const vec3 HASH_VEC1 = vec3(127.1, 311.7, 74.7);
   const vec3 HASH_VEC2 = vec3(269.5, 183.3, 246.1);
   const vec3 HASH_VEC3 = vec3(419.2, 371.9, 83.1);
   
   // Clump generation constants
   const float CLUMP_SEED_MULT = 2.718;
   const float CLUMP_ANGLE_MULT = 12.9898;
   const float CLUMP_DIST_MULT = 78.233;
   const float CLUMP_SIZE_MULT = 45.678;
   const float CLUMP_OFFSET_SCALE = 0.84; // reduce envelope slightly to avoid seam hits
   const float TURB_MAX_CLUMP_MULT = 4; // limit total flutter to ~4x clump size (safe cap)
   const float BOUNDARY_MARGIN = 0.01;   // safety margin from cell edges for damping
   const float TURB_BASE_GAIN = 12.0;    // base amplitude gain for turbulence
   
   // Rotation constant
   const float ROTATION_OFFSET = 6.28; // 2*PI
   
   // Flake shape constants
   const float FLAKE_NOISE_SCALE1 = 0.01;
   const float FLAKE_NOISE_SCALE2 = 0.015;
   const float FLAKE_NOISE_SCALE3 = 0.008;
   const float FLAKE_NOISE_FREQ1 = 10.0;
   const float FLAKE_NOISE_FREQ2 = 7.0;
   const float FLAKE_NOISE_FREQ3 = 15.0;
   const float FLAKE_DIST_SCALE = 0.6;
   const float FLAKE_DIST_OFFSET = 0.01;
   
   // Layer depth constants
   const float DEPTH_WEIGHT_SCALE = 0.1;
   const float MIN_CLUMPS = 8.0;   // true lower bound
   const float MAX_CLUMPS = 24.0;  // true upper bound
   
   // Wind noise constants
   const float WIND_NOISE_LAYER_PHASE = 0.3;
   const float WIND_NOISE_MAX_AMPLITUDE = 0.5;
   const float WIND_SPEED_NOISE_FREQ_MULT = 1.3;
   const float WIND_SPEED_NOISE_LAYER_PHASE = 0.5;
   
   // Remap UI flakeSize (0.1-1.0) to internal (0.5-0.8)
   float flakeSizeNorm = clamp((flakeSize - 0.1) / 0.9, 0.0, 1.0);
   float flakeSizeMapped = mix(0.5, 0.8, flakeSizeNorm);

   // Remap UI rotationSpeed (0-5) to internal rev/s (0.0-0.05)
   float rotSpeedNorm = clamp(rotationSpeed / 5.0, 0.0, 1.0);
   float rotationSpeedMapped = rotSpeedNorm * 0.05;

   // Remap gravity so UI 1.0 equals 0.25 internally
   float gravityMapped = gravity * 0.25;

   vec2 uv = (gl_FragCoord.xy / res) - vec2(0.5, 1.0);
   int nLayers = max(layers, 1);
   for (int i = 0; i < nLayers; ++i) {
      float fi = float(i);
      // Foreground cull: skip layers shallower than threshold
      // foregroundCull in [0..1] → cull up to that fraction of near layers
      if (foregroundCull > 0.0) {
         float layerNorm = fi / float(max(nLayers - 1, 1));
         if (layerNorm < foregroundCull) {
            continue;
         }
      }
      
      // Scale from UV center (0.0, -0.5)
      vec2 center = vec2(0.0, -0.5);
      vec2 q = (uv - center) * (1.0 + fi * depthParallax) + center;
      
      // Calculate wind vector (0° = straight up)
      float baseWindRad = radians(windDirDeg - 90.0);
      float windRad = baseWindRad;
      
      // Add per-layer wind direction noise
      if (windNoise > 0.0) {
         float noiseTime = iTime * windNoiseFreq;
         float directionNoise = sin(noiseTime + fi * WIND_NOISE_LAYER_PHASE) * windNoise * WIND_NOISE_MAX_AMPLITUDE;
         windRad += directionNoise;
      }
      
      // Calculate base wind vector
      vec2 windVec = vec2(cos(windRad), sin(windRad)) * windStrength;

      // Per-flake speed variation (drag): UI 0..1 mapped to 0..0.5, stable per layer/seed
      float speedVar = 1.0;
      if (particleSpeedVar > 0.0) {
         float rSpeed = fract(sin((fi + float(seed)) * HASH_VEC1.x) * HASH_MULT);
         float varMapped = particleSpeedVar * 0.5; // remap UI 0..1 -> 0..0.5
         speedVar = 1.0 + (rSpeed - 0.5) * varMapped * 2.0; // 1 +/- varMapped
         windVec *= speedVar;
      }
      
      // Add per-layer wind speed noise (modulates strength)
      if (windSpeedNoise > 0.0) {
         float speedNoise = 0.5 + 0.5 * sin(iTime * windNoiseFreq * WIND_SPEED_NOISE_FREQ_MULT + fi * WIND_SPEED_NOISE_LAYER_PHASE);
         float speedMultiplier = 1.0 + (speedNoise - 0.5) * windSpeedNoise;
         windVec *= speedMultiplier;
      }
      
      // Calculate motion
      vec2 motion = vec2(windVec.x * iTime, gravityMapped * iTime + windVec.y * iTime);
      
      // (Per-layer turbulence disabled in favor of per-flake turbulence)
      
      q += motion;
      
      // Hash for random flake properties
      vec3 n = vec3(floor(q), fi + float(seed));
      
      // Multi-component hash for better distribution
      vec3 r = vec3(
         fract(sin(dot(n, HASH_VEC1)) * HASH_MULT),
         fract(sin(dot(n, HASH_VEC2)) * HASH_MULT),
         fract(sin(dot(n, HASH_VEC3)) * HASH_MULT)
      );
      
      // Use fract with tiny bias to avoid snapping at integer boundaries
      vec2 flakeCenter = fract(q + 1e-6) - 0.5 + CLUMP_OFFSET_SCALE * r.xy - 0.42;
      
      // Create clumped snowflake
      float flakeShape = 0.0;
      int numClumps = int(mix(MIN_CLUMPS, MAX_CLUMPS, r.x));
      // Per-flake brightness variation (attenuation-only: [1-brightnessVar, 1])
      float flakeBrightness = mix(1.0 - clamp(brightnessVar, 0.0, 1.0), 1.0, r.y);
      
      // Pre-calculate rotation once per flake (mapped rev/sec)
      float rotAngle = adsk_time * rotationSpeedMapped * ROTATION_OFFSET + r.x * ROTATION_OFFSET;
      float cosRot = cos(rotAngle);
      float sinRot = sin(rotAngle);
      
      // Pre-calculate clump size once (use remapped flakeSize)
      float clumpSize = (0.005 + 0.05 * min(0.5 * abs(fi - 5.0), 1.0)) * flakeSizeMapped;

      // Per-flake turbulence (apply after clumping; limit displacement to avoid popping)
      vec2 flakeFlutter = vec2(0.0);
      if (turbulence > 0.0) {
         float angBase = r.x * ROTATION_OFFSET;
         float fA = max(0.01, turbulenceFreq * (0.5 + 0.8 * r.y));
         float fB = max(0.01, turbulenceFreq * (0.9 + 1.2 * r.z));
         float phA = r.z * ROTATION_OFFSET + fi * 0.17;
         float phB = r.y * ROTATION_OFFSET + fi * 0.29;
         float angle = angBase + 0.6 * sin(iTime * fA + phA) + 0.4 * sin(iTime * fB + phB);
         vec2 dir = vec2(cos(angle), sin(angle));
         float fAmp = max(0.01, turbulenceFreq * (0.7 + 1.1 * r.x));
         float phAmp = r.y * ROTATION_OFFSET + fi * 0.23;
         // Base strength with hard cap tied to clump size to avoid seam clipping
         float aBase = turbulence * TURB_BASE_GAIN * speedVar;
         float aMod = 0.6 + 0.4 * sin(iTime * fAmp + phAmp);
         float capSoft = clumpSize * mix(6.0, 24.0, clamp(turbulence, 0.0, 1.0));
         float capHard = clumpSize * TURB_MAX_CLUMP_MULT;
         float amp = min(aBase, min(capSoft, capHard));
         flakeFlutter = dir * (amp * aMod);

         // Boundary damping: smoothly reduce flutter as flake approaches cell edges
         float B = 0.5 - BOUNDARY_MARGIN;
         float rad = clumpSize;
         float mx = B - (abs(flakeCenter.x) + rad);
         float my = B - (abs(flakeCenter.y) + rad);
         float margin = max(min(mx, my), 0.0);
         float falloff = max(2.0 * rad, 1e-3);
         float damp = smoothstep(0.0, falloff, margin);
         flakeFlutter *= damp;
      }
      
      for (int c = 0; c < 13; c++) {
         if (c >= numClumps) break;
         
         float clumpSeed = float(c) * CLUMP_SEED_MULT + r.y * 10.0;
         float clumpAngle = fract(sin(clumpSeed * CLUMP_ANGLE_MULT) * HASH_MULT) * ROTATION_OFFSET;
         float clumpDist = fract(sin(clumpSeed * CLUMP_DIST_MULT) * HASH_MULT) * clumpDistance * 0.02;
         vec2 clumpOffset = vec2(cos(clumpAngle), sin(clumpAngle)) * clumpDist;
         
        // Rotate clump offset around flake center so the whole flake spins as one unit
        vec2 rotatedOffset = vec2(
           clumpOffset.x * cosRot - clumpOffset.y * sinRot,
           clumpOffset.x * sinRot + clumpOffset.y * cosRot
        );
        vec2 centerLocal = flakeCenter - rotatedOffset + flakeFlutter;

        // Screen-space clump culling removed to prevent mid-flight popping

        float clump = createSnowFlake(centerLocal, clumpSize, flakeSoftness, clumpSeed);
         
         // Screen blend for softer overlaps
         flakeShape = 1.0 - (1.0 - flakeShape) * (1.0 - clump);
      }
      
      // Apply per-flake brightness and depth-based opacity
      float weight = 1.0 / (1.0 + fi * DEPTH_WEIGHT_SCALE);
      float depthOpacity = 1.0 - (fi / float(nLayers)) * depthFade;
      accum += (flakeShape * flakeBrightness) * weight * depthOpacity;
   }

   fragColor = vec4(vec3(accum), 1.0);
}
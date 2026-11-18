// sv_Voronoi_Scatter
// Copyright (c) 2026 Sinan Vural. MIT License.
// https://github.com/SinanVural1/matchbox/tree/main/shaders/sv_Voronoi_Scatter

//*****************************************************************************/
//
// Filename: sv_Voronoi_Scatter.glsl
//
// Voronoi Texture Fill - Partitions screen into polygonal cells and fills them.
// Updated: Input coordinates now treated as Normalized UVs (0-1).
// Updated: Grid supersampling (1, 4, 9 or 16 samples) for smoother borders.
// Updated: Variation and Evolution are separate, per-cell source offset,
//          mirrored fill, and an even-width soft border.
// Updated: Edge lines, per-cell colour variation, and a matte output carrying
//          the edges, a concentric cell gradient, or both.
//
//*****************************************************************************/

uniform sampler2D front;
uniform float adsk_result_w;
uniform float adsk_result_h;

// Uniforms
uniform float grid_density;     // Controls cell size
uniform float scatter_amount;   // Jitter of seed
uniform float max_rotation;     // Degrees
uniform float seed;             // Evolution: animates the cell centres
uniform float variation;        // Reshuffles per-cell rotation, scale, offset and colour
uniform float scale_variance;   // Random scale per cell
uniform float source_offset;    // Random offset into the patch per cell
uniform vec2 selection_tl;      // Corner A (Normalized 0-1)
uniform vec2 selection_br;      // Corner B (Normalized 0-1)
uniform bool show_source;       // Debug: Show source patch rectangle
uniform float fill_scale;       // Texture fill scale
uniform int fill_mode;          // 0 mirror | 1 repeat
uniform float border_softness;  // Border soft blend, as a fraction of cell size
uniform int samples;            // Supersamples per pixel: 1, 4, 9 or 16

uniform bool draw_edges;        // Paint the edge lines into the image
uniform float edge_width;       // Full line width, as a fraction of cell size
uniform float edge_softness;    // Line edge falloff, as a fraction of cell size
uniform vec3 edge_colour;

uniform int matte_mode;         // 0 source alpha | 1 edges | 2 gradient | 3 both
uniform int gradient_shape;     // 0 follows the cell shape | 1 circular
uniform float gradient_falloff; // Exponent on the 0-1 gradient

uniform float hue_variation;        // Degrees
uniform float saturation_variation; // Fraction, either way
uniform float brightness_variation; // Fraction, either way

// Constants
const float PI = 3.14159265359;

// Random functions
float hash12(vec2 p) {
    vec3 p3  = fract(vec3(p.xyx) * .1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

vec2 hash22(vec2 p) {
    vec3 p3 = fract(vec3(p.xyx) * vec3(.1031, .1030, .0973));
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.xx+p3.yz)*p3.zy);
}

mat2 getRotMat(float deg) {
    float rad = radians(deg);
    float c = cos(rad);
    float s = sin(rad);
    return mat2(c, s, -s, c);
}

// Rotation about the grey axis: shifts hue while keeping the mean of the
// channels, without a round trip through HSV.
vec3 hueRotate(vec3 c, float deg) {
    float a = radians(deg);
    vec3 k = vec3(0.57735027);
    float ca = cos(a);
    return c * ca + cross(k, c) * sin(a) + k * dot(k, c) * (1.0 - ca);
}

// Mirrored tiling has no jump where one repeat meets the next, so a patch
// smaller than its cell repeats without hard seams.
vec2 tilePatch(vec2 x) {
    if (fill_mode == 1) {
        return fract(x);
    }
    return 1.0 - abs(mod(x, 2.0) - 1.0);
}

// Cell centres hash the grid ID alone, so only Scatter and Evolution move
// them. Variation only reaches the fill, through cellKey.
vec2 cellSeed(vec2 id, float cellSize) {
    vec2 phase = hash22(id) * 2.0 * PI;
    vec2 jitterUnit = vec2(sin(seed + phase.x), cos(seed + phase.y));
    return (id + 0.5) * cellSize + jitterUnit * 0.5 * scatter_amount * cellSize;
}

vec4 getCellColor(vec2 pixelPos, vec2 seedPixel, vec2 cellKey, vec2 patchMin, vec2 patchSizeUV, float cellSize) {
    vec2 diff = pixelPos - seedPixel;

    float randRot = hash12(cellKey + 100.0);
    float randScale = hash12(cellKey + 200.0);
    vec2 randOffset = hash22(cellKey + 300.0);

    float rotDeg = (randRot - 0.5) * 2.0 * max_rotation;
    mat2 rot = getRotMat(-rotDeg);
    vec2 localPos = rot * diff;

    float s = 1.0 + (randScale - 0.5) * scale_variance;
    float scaleFactor = cellSize * fill_scale * s;
    if(scaleFactor < 1.0) scaleFactor = 1.0;

    // Without an offset every cell starts from the same point in the patch,
    // which reads as one image stamped over and over.
    vec2 localUV = localPos / scaleFactor + 0.5 + randOffset * source_offset;
    vec2 patchSpaceUV = tilePatch(localUV);
    vec2 sampleUV = patchMin + patchSizeUV * patchSpaceUV;

    vec4 col = texture2D(front, sampleUV);

    // Per-cell colour shifts, each spread evenly either side of no change.
    vec3 rnd = vec3(hash12(cellKey + 400.0), hash12(cellKey + 500.0), hash12(cellKey + 600.0)) - 0.5;
    col.rgb = hueRotate(col.rgb, rnd.x * 2.0 * hue_variation);
    float luma = dot(col.rgb, vec3(0.2126, 0.7152, 0.0722));
    col.rgb = mix(vec3(luma), col.rgb, max(1.0 + rnd.y * 2.0 * saturation_variation, 0.0));
    col.rgb *= max(1.0 + rnd.z * 2.0 * brightness_variation, 0.0);

    return col;
}

// Core Logic per Sample. Returns the colour, with alpha set to the matte.
vec4 getSample(vec2 pixelPos, float cellSize, vec2 patchMin, vec2 patchSizeUV, vec2 varOffset) {
    vec2 gridID = floor(pixelPos / cellSize);

    // Pass 1: nearest cell centre. A centre can sit up to half a cell outside
    // its grid square at full Scatter, so a 5x5 search is needed to be sure.
    float dist1 = 1e9;
    vec2 seed1 = vec2(0.0);
    vec2 id1 = vec2(0.0);

    for(int y = -2; y <= 2; y++) {
        for(int x = -2; x <= 2; x++) {
            vec2 currentID = gridID + vec2(float(x), float(y));
            vec2 seedPixel = cellSeed(currentID, cellSize);
            float dist = distance(pixelPos, seedPixel);
            if(dist < dist1) {
                dist1 = dist;
                seed1 = seedPixel;
                id1 = currentID;
            }
        }
    }

    // Pass 2: distance to this cell's nearest border. Each neighbour defines
    // one edge, the perpendicular bisector between the two centres, and the
    // pixel's distance to it is (dj^2 - d1^2) / (2 * gap). The smallest is the
    // true border distance, which keeps edge lines and soft borders an even
    // width all the way round the cell.
    float edgeDist = 1e9;
    vec2 seedE = seed1;
    vec2 idE = id1;
    float minHalfGap = 1e9;

    for(int y = -2; y <= 2; y++) {
        for(int x = -2; x <= 2; x++) {
            if (x == 0 && y == 0) continue;
            vec2 currentID = id1 + vec2(float(x), float(y));
            vec2 seedPixel = cellSeed(currentID, cellSize);
            float gap = max(distance(seed1, seedPixel), 0.0001);
            float dj = distance(pixelPos, seedPixel);
            float e = (dj * dj - dist1 * dist1) / (2.0 * gap);
            if (e < edgeDist) {
                edgeDist = e;
                seedE = seedPixel;
                idE = currentID;
            }
            minHalfGap = min(minHalfGap, 0.5 * gap);
        }
    }

    float edgeN = edgeDist / cellSize;

    vec4 col = getCellColor(pixelPos, seed1, id1 + varOffset, patchMin, patchSizeUV, cellSize);

    if (border_softness > 0.0) {
        vec4 colE = getCellColor(pixelPos, seedE, idE + varOffset, patchMin, patchSizeUV, cellSize);
        float mixVal = smoothstep(0.0, border_softness, edgeN);
        col = mix(colE, col, 0.5 + 0.5 * mixVal);
    }

    // Each cell draws its own half of the line, so the two halves meet to make
    // the full Edge Width.
    float halfW = max(edge_width, 0.0) * 0.5;
    float line = 1.0 - smoothstep(halfW, halfW + max(edge_softness, 0.00001), edgeN);
    if (edge_width <= 0.0 && edge_softness <= 0.0) line = 0.0;

    if (draw_edges) {
        col.rgb = mix(col.rgb, edge_colour, line);
    }

    // Concentric gradient: 1 at the centre, 0 on the border. Measured against
    // the distances to centre and border, so the rings take the cell's shape
    // whatever its size. Circular uses the largest circle that fits the cell.
    float grad;
    if (gradient_shape == 1) {
        grad = 1.0 - clamp(dist1 / max(minHalfGap, 0.0001), 0.0, 1.0);
    } else {
        grad = edgeDist / max(edgeDist + dist1, 0.0001);
    }
    grad = pow(clamp(grad, 0.0, 1.0), max(gradient_falloff, 0.001));

    if (matte_mode == 1) {
        col.a = line;
    } else if (matte_mode == 2) {
        col.a = grad;
    } else if (matte_mode == 3) {
        col.a = grad * (1.0 - line);
    }

    return col;
}

void main() {
    float cellSize = max(adsk_result_w, adsk_result_h) / max(1.0, grid_density);
    vec2 srcTL = selection_tl;
    vec2 srcBR = selection_br;
    vec2 patchMin = min(srcTL, srcBR);
    vec2 patchMax = max(srcTL, srcBR);
    vec2 patchSizeUV = patchMax - patchMin;
    vec2 varOffset = vec2(variation * 127.1, variation * 311.7);

    // An n x n grid of sub-pixel positions. Random offsets per pixel left
    // grain along the borders; a fixed grid gives the same smooth result
    // everywhere. Float maths, as Flame's dialect lacks int clamp.
    float n = clamp(floor(sqrt(max(float(samples), 1.0)) + 0.5), 1.0, 4.0);

    vec4 accColor = vec4(0.0);

    for(int j = 0; j < 4; j++) {
        if (float(j) >= n) break;
        for(int i = 0; i < 4; i++) {
            if (float(i) >= n) break;
            vec2 subPixel = (vec2(float(i), float(j)) + 0.5) / n - 0.5;
            accColor += getSample(gl_FragCoord.xy + subPixel, cellSize, patchMin, patchSizeUV, varOffset);
        }
    }

    vec4 finalColor = accColor / (n * n);

    // Debug Selection (Overlay on top of everything)
    if (show_source) {
       vec2 uv = gl_FragCoord.xy / vec2(adsk_result_w, adsk_result_h);
       vec2 border = 1.0 / vec2(adsk_result_w, adsk_result_h);
       if (uv.x >= patchMin.x && uv.x <= patchMax.x && uv.y >= patchMin.y && uv.y <= patchMax.y) {
           if (uv.x < patchMin.x+border.x || uv.x > patchMax.x-border.x ||
               uv.y < patchMin.y+border.y || uv.y > patchMax.y-border.y) {
               finalColor = vec4(1.0, 0.0, 0.0, 1.0);
           }
       }
    }

    gl_FragColor = finalColor;
}

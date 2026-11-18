// sv_Triangle_Mosaic
// Copyright (c) 2026 Sinan Vural. MIT License.
// https://github.com/SinanVural1/matchbox/tree/main/shaders/sv_Triangle_Mosaic

//*****************************************************************************/
//
// Filename: sv_Triangle_Mosaic.glsl
//
// Triangle mosaic with per-tile transforms and a tile-by-tile transition
// from Front to Back, driven by a matte or a built-in wipe.
//
// Every tiling here is a square grid cut along a diagonal and then sheared:
// shear by half a cell for equilateral and isosceles triangles, no shear for
// right triangles. One code path covers all three shapes.
//
// Tiles can grow, turn, move and fold over onto their neighbours, so a pixel
// is not owned by one cell. For every sample the shader walks the nearby
// tiles, undoes each tile's motion to see whether it now covers the sample,
// and keeps the two highest. The higher one is drawn over the lower one,
// which gives anti-aliased borders and correct overlaps without a sort.
//
//*****************************************************************************/

uniform sampler2D front;
uniform sampler2D back;
uniform sampler2D matte;
uniform float adsk_result_w;
uniform float adsk_result_h;

// Grid
uniform int tri_shape;          // 0 equilateral | 1 isosceles | 2 right
uniform float stretch;          // Height multiplier, isosceles and right only
uniform int diagonal;           // Right only: 0 same | 1 alternating | 2 random | 3 four-way
uniform float tile_size;        // Pixels, ResDependent so it follows resolution
uniform float grid_rotation;    // Degrees
uniform vec2 grid_centre;       // 0-1, or Action pixels from centre
uniform bool action_coords;

// Tiles
uniform float tile_scale;
uniform float scale_variance;
uniform float rotation_variance;  // Degrees
uniform float offset_variance;    // Fraction of tile size
uniform float luma_scale;         // -1..1, size by brightness
uniform float variation;
uniform float evolution;
uniform float dropout;

// Look
uniform int fill_mode;          // 0 image | 1 flat
uniform float hue_variation;
uniform float saturation_variation;
uniform float brightness_variation;
uniform bool draw_edges;
uniform float edge_width;       // Fraction of tile size
uniform float edge_softness;
uniform vec3 edge_colour;
uniform float bevel_width;      // Fraction of tile size
uniform float bevel_amount;
uniform float light_angle;      // Degrees, 0 = from the right, 90 = from above
uniform float light_height;     // Degrees above the frame

// Transition
uniform int wipe_mode;          // 0 none | 1 matte | 2 matte wipe | 3 linear | 4 radial | 5 random
uniform float progress;
uniform float wipe_softness;
uniform float spread;
uniform float wipe_angle;       // Degrees
uniform vec2 wipe_centre;
uniform float tr_scale;
uniform float tr_fade;
uniform float tr_spin;          // Degrees
uniform int flip_mode;          // 0 off | 1 hinge | 2 card
uniform float flip_angle;       // Degrees
uniform int flip_direction;     // 0 follow wipe | 1 random | 2 against wipe
uniform float flip_shading;
uniform float highlight;
uniform float perspective;

// Output
uniform int matte_mode;         // 0 coverage | 1 edges | 2 gradient | 3 tile ID | 4 progress
uniform float gradient_falloff;
uniform int samples;
uniform int debug_mode;         // 0 off | 1 front | 2 back | 3 matte | 4 tile ID | 5 progress

const float PI = 3.14159265359;
const vec3 LUMA = vec3(0.2126, 0.7152, 0.0722);

// Per-frame values, set once in main().
vec2 gRes;
vec2 gA;            // Lattice basis, grid space, pixels
vec2 gB;
vec2 gCentre;       // Grid origin, pixels
mat2 gRot;          // Grid space to screen
mat2 gRotInv;
float gS;           // Tile size, pixels
float gReach;       // Furthest a tile can reach from its home centroid
float gTriCount;    // Triangles per grid cell: 2, or 4 for four-way
vec2 gVarOffset;
vec2 gWipeDir;
vec2 gWipeCentre;
float gWipeMax;
vec3 gLight;
vec2 gLight2D;
float gAA;          // Anti-aliasing width, pixels
int gMatteMode;

struct TileHit {
    float prio;     // Draw order: transition progress, plus a tiny tie-break
    float cov;      // Coverage of this sample, with Fade applied
    float t;        // Transition progress, 0-1
    float facing;   // 1 front face up, 0 the reverse
    vec2 frontPos;  // Where this point of the tile sits in Front, pixels
    vec2 backPos;   // Where this point lands at the end of a flip, pixels
    vec2 h0; vec2 h1; vec2 h2;  // Home triangle, for Flat fill of the front
    vec2 l0; vec2 l1; vec2 l2;  // Landed triangle, for Flat fill of the reverse
    float shade;
    float spec;
    float edgeN;    // Distance in from the tile's border, as a fraction of tile size
    float grad;     // 1 at the tile's centre, 0 on its border
    vec2 nOut;      // Outward normal of the nearest border, screen space
    vec2 key;
};

float hash12(vec2 p) {
    vec3 p3 = fract(vec3(p.xyx) * .1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

vec2 hash22(vec2 p) {
    vec3 p3 = fract(vec3(p.xyx) * vec3(.1031, .1030, .0973));
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.xx + p3.yz) * p3.zy);
}

float cross2(vec2 a, vec2 b) {
    return a.x * b.y - a.y * b.x;
}

mat2 rot2(float rad) {
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

vec2 toScreen(vec2 uv) {
    return gCentre + gRot * (uv.x * gA + uv.y * gB);
}

vec2 toLattice(vec2 s) {
    vec2 g = gRotInv * (s - gCentre);
    float v = g.y / gB.y;
    return vec2((g.x - v * gB.x) / gA.x, v);
}

// Which diagonal a grid cell is cut along. 0 runs from (1,0) to (0,1), the
// short diagonal of the sheared cell, which is what makes equilateral and
// isosceles triangles. Only right triangles may use the other one.
float cellDiagonal(vec2 cell) {
    if (tri_shape < 2) return 0.0;
    if (diagonal == 1) return mod(cell.x + cell.y, 2.0);
    if (diagonal == 2) return step(0.5, hash12(cell + 17.0));
    return 0.0;
}

void triVertsUV(vec2 cell, float k, out vec2 a, out vec2 b, out vec2 c) {
    vec2 c00 = cell;
    vec2 c10 = cell + vec2(1.0, 0.0);
    vec2 c01 = cell + vec2(0.0, 1.0);
    vec2 c11 = cell + vec2(1.0, 1.0);
    if (gTriCount > 2.5) {
        vec2 m = cell + vec2(0.5);
        if (k < 0.5)      { a = c00; b = c10; c = m; }
        else if (k < 1.5) { a = c10; b = c11; c = m; }
        else if (k < 2.5) { a = c11; b = c01; c = m; }
        else              { a = c01; b = c00; c = m; }
        return;
    }
    if (cellDiagonal(cell) < 0.5) {
        if (k < 0.5) { a = c00; b = c10; c = c01; }
        else         { a = c11; b = c01; c = c10; }
    } else {
        if (k < 0.5) { a = c00; b = c10; c = c11; }
        else         { a = c00; b = c11; c = c01; }
    }
}

// Signed distance to the triangle's border, positive inside. Inside a convex
// shape the nearest edge line gives the exact distance; outside it is close
// enough for the half-pixel anti-aliasing ramp. Also returns that edge's
// outward normal, for the bevel.
float triSDF(vec2 p, vec2 a, vec2 b, vec2 c, out vec2 nOut) {
    float o = sign(cross2(b - a, c - a));
    vec2 eab = normalize(b - a);
    vec2 ebc = normalize(c - b);
    vec2 eca = normalize(a - c);
    float dab = o * cross2(eab, p - a);
    float dbc = o * cross2(ebc, p - b);
    float dca = o * cross2(eca, p - c);
    // The outward normal of an edge is the edge direction turned away from
    // the interior.
    float d = dab;
    nOut = o * vec2(eab.y, -eab.x);
    if (dbc < d) { d = dbc; nOut = o * vec2(ebc.y, -ebc.x); }
    if (dca < d) { d = dca; nOut = o * vec2(eca.y, -eca.x); }
    return d;
}

float tileProgress(vec2 hc, vec2 key2) {
    if (wipe_mode == 0) return 0.0;
    float t;
    if (wipe_mode == 1) {
        // The matte is the progress: black untouched, white done.
        t = texture2D(matte, hc / gRes).r;
    } else {
        // How early this tile goes, 0-1. Progress sweeps a band of width
        // Softness across that range, starting fully before it and ending
        // fully after it, so Progress 0 and 1 are always clean.
        float d;
        if (wipe_mode == 2) {
            d = 1.0 - texture2D(matte, hc / gRes).r;
        } else if (wipe_mode == 3) {
            vec2 q = hc / gRes - 0.5;
            d = dot(q, gWipeDir) / (abs(gWipeDir.x) + abs(gWipeDir.y)) + 0.5;
        } else if (wipe_mode == 4) {
            d = distance(hc, gWipeCentre) / gWipeMax;
        } else {
            d = hash12(key2 + 800.0);
        }
        d = clamp(d, 0.0, 1.0);
        float w = max(wipe_softness, 0.001);
        t = (progress * (1.0 + w) - d) / w;
    }
    t = clamp(t, 0.0, 1.0);
    // Spread gives every tile its own start within the band, so the wipe
    // breaks up instead of moving as a clean line.
    if (spread > 0.0) {
        float r = hash12(key2 + 900.0);
        t = clamp((t - r * spread) / max(1.0 - spread, 0.001), 0.0, 1.0);
    }
    return t;
}

// The direction the wipe travels at this tile, used to choose which edge a
// tile folds over.
vec2 wipeDirection(vec2 hc, vec2 key2) {
    float ra = hash12(key2 + 1000.0) * 2.0 * PI;
    vec2 rnd = vec2(cos(ra), sin(ra));
    if (flip_direction == 1) return rnd;
    vec2 d = rnd;
    if (wipe_mode == 3) {
        d = gWipeDir;
    } else if (wipe_mode == 4) {
        vec2 r = hc - gWipeCentre;
        if (length(r) > 0.001) d = normalize(r);
    } else if (wipe_mode == 1 || wipe_mode == 2) {
        // The wave runs from bright to dark in the matte, against its gradient.
        vec2 e = vec2(0.5 * gS, 0.0);
        float gx = texture2D(matte, (hc + e.xy) / gRes).r - texture2D(matte, (hc - e.xy) / gRes).r;
        float gy = texture2D(matte, (hc + e.yx) / gRes).r - texture2D(matte, (hc - e.yx) / gRes).r;
        vec2 g = -vec2(gx, gy);
        if (length(g) > 0.0001) d = normalize(g);
    }
    if (flip_direction == 2) d = -d;
    return d;
}

// Reflects p through the turning axis: the point on the other side, the
// same oblique distance away. This is where p lands after a 180 degree flip.
vec2 mirrorThrough(vec2 p, vec2 O, vec2 U, vec2 V) {
    vec2 r = p - O;
    float base = cross2(U, V);
    float a = cross2(r, V) / base;
    float b = cross2(U, r) / base;
    return O + a * U - b * V;
}

bool evalTile(vec2 cell, float k, vec2 s, out TileHit h) {
    vec2 ua; vec2 ub; vec2 uc;
    triVertsUV(cell, k, ua, ub, uc);
    vec2 h0 = toScreen(ua);
    vec2 h1 = toScreen(ub);
    vec2 h2 = toScreen(uc);
    vec2 hc = (h0 + h1 + h2) / 3.0;
    if (distance(s, hc) > gReach) return false;

    vec2 key = vec2(cell.x * 4.0 + k, cell.y);
    vec2 key2 = key + gVarOffset;
    if (dropout > 0.0 && hash12(key2 + 700.0) < dropout) return false;

    // Per-tile randoms ride on sine waves, so Evolution animates them
    // smoothly while Variation picks a new set.
    vec2 ph = hash22(key2 + 100.0) * 2.0 * PI;
    vec2 ph2 = hash22(key2 + 200.0) * 2.0 * PI;
    float rs = sin(evolution + ph.x);
    float rr = sin(evolution + ph.y);
    vec2 ro = vec2(sin(evolution + ph2.x), cos(evolution + ph2.y));

    float sc = tile_scale * max(1.0 + rs * scale_variance, 0.0);
    if (luma_scale != 0.0) {
        float l = clamp(dot(texture2D(front, hc / gRes).rgb, LUMA), 0.0, 1.0);
        float f = luma_scale > 0.0 ? l : 1.0 - l;
        sc *= 1.0 - abs(luma_scale) * (1.0 - f);
    }
    float ang = radians(rr * rotation_variance);
    vec2 cs = hc + ro * 0.5 * offset_variance * gS;

    float t = tileProgress(hc, key2);
    sc *= max(1.0 - tr_scale * t, 0.0);
    ang += radians(tr_spin) * t;
    if (sc < 0.0001) return false;

    // Placed triangle: x = cs + Mr * sc * (home - hc).
    mat2 Mr = rot2(ang);
    vec2 s0 = cs + Mr * ((h0 - hc) * sc);
    vec2 s1 = cs + Mr * ((h1 - hc) * sc);
    vec2 s2 = cs + Mr * ((h2 - hc) * sc);

    vec2 xs = s;
    float facing = 1.0;
    float shade = 1.0;
    float spec = 0.0;
    float squash = 1.0;
    vec2 backPos = s;
    vec2 l0 = s0; vec2 l1 = s1; vec2 l2 = s2;

    if (flip_mode > 0 && t > 0.0) {
        float th = radians(flip_angle) * t;
        vec2 D = wipeDirection(hc, key2);

        // The tile turns about a line through O along U; V reaches from
        // that line to the part of the tile that lifts. A point O + aU + bV
        // goes to O + aU + b*cos(th)*V, raised b*sin(th)*hperp off the
        // frame. V is allowed to be oblique, so at 180 degrees the tile maps
        // onto a whole triangle: the neighbour across the edge for Hinge,
        // itself with two corners swapped for Card.
        vec2 O; vec2 U; vec2 V;
        vec2 m01 = 0.5 * (s0 + s1);
        vec2 m12 = 0.5 * (s1 + s2);
        vec2 m20 = 0.5 * (s2 + s0);
        if (flip_mode == 1) {
            // Hinge on the edge facing the way the wipe travels, so tiles
            // fall forward like dominoes.
            float d01 = dot(m01 - cs, D);
            float d12 = dot(m12 - cs, D);
            float d20 = dot(m20 - cs, D);
            if (d01 >= d12 && d01 >= d20) { O = m01; U = s1 - m01; V = s2 - m01; }
            else if (d12 >= d20)          { O = m12; U = s2 - m12; V = s0 - m12; }
            else                          { O = m20; U = s0 - m20; V = s1 - m20; }
        } else {
            // Card turns about a median, choosing the one whose swing lines
            // up best with the wipe.
            float c0 = abs(dot(normalize(s2 - m12), D));
            float c1 = abs(dot(normalize(s0 - m20), D));
            float c2 = abs(dot(normalize(s1 - m01), D));
            if (c0 >= c1 && c0 >= c2) { O = m12; U = s0 - m12; V = s2 - m12; }
            else if (c1 >= c2)        { O = m20; U = s1 - m20; V = s0 - m20; }
            else                      { O = m01; U = s2 - m01; V = s1 - m01; }
            if (dot(V, D) < 0.0) V = -V;
        }

        float hperp = abs(cross2(normalize(U), V));

        // Perspective. Each tile is seen from its own camera a few tile sizes
        // above it, so the effect is the same anywhere in frame and the tile
        // stays within the search reach. The camera is kept at least twice
        // the tile's height away, which caps the enlargement at 2x.
        float kk = 0.0;
        if (perspective > 0.0) {
            float F = max(3.0 * gS / perspective, 2.0 * hperp + 0.001);
            kk = sin(th) * hperp / F;
        }

        // Screen offset q from O, for plane point (a, b), satisfies
        // q * (1 - b*kk) = a*U + b*cos(th)*V, which is linear in a and b:
        // a*U + b*W = q with W = cos(th)*V + kk*q.
        vec2 q = s - O;
        vec2 W = cos(th) * V + kk * q;
        float det = cross2(U, W);
        float base = cross2(U, V);
        // Edge-on to the camera: nothing to draw.
        if (abs(det) < 0.0001 * abs(base)) return false;
        float a = cross2(q, W) / det;
        float b = cross2(U, q) / det;

        xs = O + a * U + b * V;
        // The winding flips once the tile has turned past edge-on.
        facing = det * base > 0.0 ? 1.0 : 0.0;
        // Where this point of the tile lies once the flip is complete. The
        // reverse face shows Back from there, so a finished flip shows Back
        // exactly in place.
        backPos = O + a * U - b * V;
        l0 = mirrorThrough(s0, O, U, V);
        l1 = mirrorThrough(s1, O, U, V);
        l2 = mirrorThrough(s2, O, U, V);
        // Foreshortening, so the anti-aliasing ramp stays about a pixel wide.
        squash = max(abs(det / base), 0.05);

        // Shade the turning tile. Its normal tilts away from the lifting side.
        vec2 Uh = normalize(U);
        vec2 pd = V - dot(V, Uh) * Uh;
        pd = length(pd) > 0.000001 ? normalize(pd) : vec2(0.0);
        vec3 nrm = vec3(-sin(th) * pd, cos(th));
        if (facing < 0.5) nrm = -nrm;
        // Divided by the flat tile's lighting, so a tile at rest is unchanged.
        float diff = max(dot(nrm, gLight), 0.0) / max(gLight.z, 0.05);
        shade = mix(1.0, diff, flip_shading);
        vec3 hv = normalize(gLight + vec3(0.0, 0.0, 1.0));
        spec = max(pow(max(dot(nrm, hv), 0.0), 40.0) - pow(hv.z, 40.0), 0.0) * highlight;
    }

    // Back from the placed triangle to the home triangle.
    vec2 xh = hc + (rot2(-ang) * (xs - cs)) / sc;
    vec2 nH;
    float sd = triSDF(xh, h0, h1, h2, nH);
    float cov = clamp(sd * sc * squash / gAA + 0.5, 0.0, 1.0);
    cov *= clamp(1.0 - tr_fade * t, 0.0, 1.0);
    if (cov <= 0.0) return false;

    // Inradius = 2 * area / perimeter.
    float area2 = abs(cross2(h1 - h0, h2 - h0));
    float perim = distance(h0, h1) + distance(h1, h2) + distance(h2, h0);
    float inr = area2 / max(perim, 0.0001);

    h.prio = t + 0.001 * hash12(key + 31.0);
    h.cov = cov;
    h.t = t;
    h.facing = facing;
    h.frontPos = xh;
    h.backPos = backPos;
    h.h0 = h0; h.h1 = h1; h.h2 = h2;
    h.l0 = l0; h.l1 = l1; h.l2 = l2;
    h.shade = shade;
    h.spec = spec;
    h.edgeN = sd / gS;
    h.grad = clamp(sd / max(inr, 0.0001), 0.0, 1.0);
    h.nOut = Mr * nH;
    h.key = key2;
    return true;
}

vec3 readTex(float which, vec2 pos) {
    vec2 uv = pos / gRes;
    if (which < 0.5) return texture2D(front, uv).rgb;
    return texture2D(back, uv).rgb;
}

// Image carries the picture with the tile. Flat averages seven points spread
// over the triangle: one centre pixel flickers on moving footage.
vec3 tileColour(float which, vec2 pos, vec2 a, vec2 b, vec2 c) {
    if (fill_mode == 0) return readTex(which, pos);
    vec2 m = (a + b + c) / 3.0;
    vec3 acc = readTex(which, m);
    acc += readTex(which, mix(m, a, 0.5));
    acc += readTex(which, mix(m, b, 0.5));
    acc += readTex(which, mix(m, c, 0.5));
    acc += readTex(which, mix(m, 0.5 * (a + b), 0.5));
    acc += readTex(which, mix(m, 0.5 * (b + c), 0.5));
    acc += readTex(which, mix(m, 0.5 * (c + a), 0.5));
    return acc / 7.0;
}

vec3 shadeHit(TileHit h, out float mv) {
    // Everything that belongs to the mosaic look fades out as the tile
    // transitions, so the last frame is a clean Back.
    float keep = 1.0 - h.t;
    vec3 c;
    if (h.facing > 0.5) {
        c = tileColour(0.0, h.frontPos, h.h0, h.h1, h.h2);
        vec3 rnd = vec3(hash12(h.key + 400.0), hash12(h.key + 500.0), hash12(h.key + 600.0)) - 0.5;
        c = hueRotate(c, rnd.x * 2.0 * hue_variation * keep);
        float l = dot(c, LUMA);
        c = mix(vec3(l), c, max(1.0 + rnd.y * 2.0 * saturation_variation * keep, 0.0));
        c *= max(1.0 + rnd.z * 2.0 * brightness_variation * keep, 0.0);
    } else {
        c = tileColour(1.0, h.backPos, h.l0, h.l1, h.l2);
        // Flat tiles resolve into the picture as they land, so a finished
        // transition is a clean Back in Flat mode too. The reverse face only
        // shows from halfway, hence the 0.5 start.
        if (fill_mode == 1) c = mix(c, readTex(1.0, h.backPos), smoothstep(0.5, 1.0, h.t));
    }

    // Bevel: the strip along each border is lit by how much that border
    // faces the light.
    if (bevel_amount != 0.0) {
        float bm = 1.0 - smoothstep(0.0, max(bevel_width, 0.0001), h.edgeN);
        c *= max(1.0 + bevel_amount * bm * dot(h.nOut, gLight2D) * keep, 0.0);
    }

    c = c * h.shade + vec3(h.spec);

    // Each tile draws its own half of the line, so neighbours meet to make
    // the full Edge Width.
    float halfW = max(edge_width, 0.0) * 0.5;
    float line = 1.0 - smoothstep(halfW, halfW + max(edge_softness, 0.00001), h.edgeN);
    if (edge_width <= 0.0 && edge_softness <= 0.0) line = 0.0;
    line *= keep;
    if (draw_edges) c = mix(c, edge_colour, line);

    if (gMatteMode == 1) {
        mv = line;
    } else if (gMatteMode == 2) {
        mv = pow(h.grad, max(gradient_falloff, 0.001));
    } else if (gMatteMode == 3) {
        mv = hash12(h.key + 1100.0);
    } else if (gMatteMode == 4) {
        mv = h.t;
    } else {
        mv = 1.0;
    }
    return c;
}

vec4 renderPoint(vec2 s, float ni, float nj) {
    vec2 cell0 = floor(toLattice(s));
    TileHit best;
    TileHit second;
    TileHit h;
    best.prio = -1.0;
    best.cov = 0.0;
    second.prio = -1.0;
    second.cov = 0.0;
    // Total coverage from every tile, not just the top two: where six
    // triangles meet at a corner, the top two alone leave a gap that would
    // show the background as a speck.
    float covSum = 0.0;

    for (int j = -3; j <= 3; j++) {
        if (abs(float(j)) > nj) continue;
        for (int i = -3; i <= 3; i++) {
            if (abs(float(i)) > ni) continue;
            for (int k = 0; k < 4; k++) {
                if (float(k) >= gTriCount) break;
                if (evalTile(cell0 + vec2(float(i), float(j)), float(k), s, h)) {
                    covSum += h.cov;
                    if (h.prio > best.prio) {
                        second = best;
                        best = h;
                    } else if (h.prio > second.prio) {
                        second = h;
                    }
                }
            }
        }
    }

    vec3 bg = texture2D(back, s / gRes).rgb;
    vec3 col = bg;
    float mv = 0.0;
    if (best.prio >= 0.0) {
        float mb;
        vec3 cb = shadeHit(best, mb);
        float cvb = best.cov;
        float cvs = 0.0;
        float ms = 0.0;
        vec3 c2 = vec3(0.0);
        if (second.prio >= 0.0) {
            c2 = shadeHit(second, ms);
            // Treat the two as side by side, not stacked: along a shared
            // border their coverages add to one, and stacking them would let
            // the background leak through as a dark seam.
            cvs = min(second.cov, 1.0 - cvb);
        }
        // The top two set the colour; the total sets how much of the
        // background shows.
        float covAll = clamp(max(covSum, cvb + cvs), 0.0, 1.0);
        float wsum = max(cvb + cvs, 0.0001);
        col = covAll * (cvb * cb + cvs * c2) / wsum + (1.0 - covAll) * bg;
        mv = covAll * (cvb * mb + cvs * ms) / wsum;
    }
    return vec4(col, mv);
}

void main() {
    gRes = vec2(adsk_result_w, adsk_result_h);
    vec2 uv0 = gl_FragCoord.xy / gRes;
    if (debug_mode == 1) { gl_FragColor = texture2D(front, uv0); return; }
    if (debug_mode == 2) { gl_FragColor = texture2D(back, uv0); return; }
    if (debug_mode == 3) { gl_FragColor = vec4(texture2D(matte, uv0).rrr, 1.0); return; }

    gS = max(tile_size, 2.0);
    float skew = tri_shape == 2 ? 0.0 : 0.5;
    float hgt = 0.8660254;
    if (tri_shape == 1) hgt = 0.8660254 * stretch;
    if (tri_shape == 2) hgt = stretch;
    gA = vec2(gS, 0.0);
    gB = vec2(skew * gS, max(hgt, 0.05) * gS);

    // Action tracker data is in pixels from the image centre.
    gCentre = action_coords ? grid_centre + 0.5 * gRes : grid_centre * gRes;
    gWipeCentre = action_coords ? wipe_centre + 0.5 * gRes : wipe_centre * gRes;
    float gr = radians(grid_rotation);
    gRot = rot2(gr);
    gRotInv = rot2(-gr);
    gTriCount = (tri_shape == 2 && diagonal == 3) ? 4.0 : 2.0;
    gVarOffset = vec2(variation * 127.1, variation * 311.7);

    float wa = radians(wipe_angle);
    gWipeDir = vec2(cos(wa), sin(wa));
    gWipeMax = max(max(length(gWipeCentre), length(gWipeCentre - vec2(gRes.x, 0.0))),
                   max(length(gWipeCentre - vec2(0.0, gRes.y)), length(gWipeCentre - gRes)));
    gWipeMax = max(gWipeMax, 1.0);

    float la = radians(light_angle);
    float le = radians(clamp(light_height, 1.0, 90.0));
    gLight = vec3(cos(la) * cos(le), sin(la) * cos(le), sin(le));
    gLight2D = vec2(cos(la), sin(la));
    gMatteMode = matte_mode;
    if (debug_mode == 4) gMatteMode = 3;
    if (debug_mode == 5) gMatteMode = 4;

    // How far a tile can reach from its home centroid. Hinge flips land on
    // the neighbour, and perspective can enlarge up to 2x, hence the 3x.
    float lmax = max(max(length(gA), length(gB)), max(length(gA + gB), length(gA - gB)));
    float scMax = max(tile_scale, 0.0) * (1.0 + max(scale_variance, 0.0)) * max(1.0, 1.0 - tr_scale);
    gReach = lmax * scMax * (flip_mode > 0 ? 3.0 : 1.0) + 0.5 * abs(offset_variance) * gS + 2.0;

    // Grid cells to search either side, from the spacing between grid
    // lines. Capped at 3 by the constant loop bounds.
    float cellArea = abs(cross2(gA, gB));
    float ni = min(3.0, ceil(gReach * length(gB) / cellArea));
    float nj = min(3.0, ceil(gReach * length(gA) / cellArea));

    // An n x n grid of sub-pixel positions, as in Voronoi Scatter. Float
    // maths, as Flame's dialect lacks int clamp.
    float n = clamp(floor(sqrt(max(float(samples), 1.0)) + 0.5), 1.0, 4.0);
    gAA = 1.0 / n;

    vec4 acc = vec4(0.0);
    for (int sj = 0; sj < 4; sj++) {
        if (float(sj) >= n) break;
        for (int si = 0; si < 4; si++) {
            if (float(si) >= n) break;
            vec2 sub = (vec2(float(si), float(sj)) + 0.5) / n - 0.5;
            acc += renderPoint(gl_FragCoord.xy + sub, ni, nj);
        }
    }
    acc /= n * n;

    if (debug_mode >= 4) {
        gl_FragColor = vec4(vec3(acc.a), acc.a);
        return;
    }
    gl_FragColor = acc;
}

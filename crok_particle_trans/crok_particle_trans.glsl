#version 120
// based on https://www.shadertoy.com/view/tlsyW7 zhilichen

uniform bool turn;

// --------[ Autodesk Uniforms start here ]---------- //
uniform float adsk_result_w, adsk_result_h, adsk_time;
uniform sampler2D iChannel0, iChannel1;
vec2 res = vec2(adsk_result_w, adsk_result_h);
// --------[ Autodesk Uniforms end here ]---------- //


// --------[ Shadertoy Globals start here ]---------- //
#define iTime adsk_time *.05
#define iResolution res
#define texture texture2D
#define fragCoord gl_FragCoord
#define fragColor gl_FragColor
#define iMouse vec3(0.0)
// --------[ Shadertoy Globals end here ]---------- //

uniform float period; // = 3.0;	// second  转场时间
uniform float particleSizeMin;  //= 10.0;	// 最小粒子大小（像素）
uniform float rotationRange; //= 30.0/180.0 * 3.1415926; // 旋转最大角度
float travelDistanceRatio = 1.0; // times image dim
uniform bool reverse = true; // true: particle to image, false: image to particle

float rand(vec2 co){
    return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

float pKernel(float r) {
	return 1.0 - smoothstep(0.9, 1.0, r);
}

float exponentialInOut(float t) {
  return t == 0.0 || t == 1.0
    ? t
    : t < 0.5
      ? +0.5 * pow(2.0, (20.0 * t) - 10.0)
      : -0.5 * pow(2.0, 10.0 - (t * 20.0)) + 1.0;
}

float quadraticInOut(float t) {
  float p = 2.0 * t * t;
  return t < 0.5 ? p : -p + (4.0 * t) - 1.0;
}

vec2 mirroredSample(vec2 uv0) {
    vec2 uv = uv0;
    if (uv0.x <= 0.0) {
        uv.x = -uv0.x;
    } else if (uv0.x >= 1.0) {
        uv.x = 2.0 - uv0.x;
    }
    if (uv0.y <= 0.0) {
        uv.y = -uv0.y;
    } else if (uv0.y >= 1.0) {
        uv.y = 2.0 - uv0.y;
    }
    return uv;
}


vec4 animatedColor(sampler2D tex0, sampler2D tex1, vec2 p, vec2 res, float t) {
	float st = quadraticInOut(t);

    float particleSizeInit = particleSizeMin;

    // particle numbers
    int numX = int(res.x / particleSizeInit);
    int numY = int(res.y / particleSizeInit);

    // current camera position
    float travelDistance = travelDistanceRatio * (res.x + res.y);
    float fx = travelDistance;
    vec3 cameraPos = vec3(res/2.0, -fx + travelDistance * 0.8 * st);

    // rotation
    float phi0 = rotationRange * st;


    // loop thru particles
    vec4 colorSum = vec4(0.0, 0.0, 0.0, 0.0);
    float weightSum = 0.0;

    const int maxNumOverlap = 10;
    int particleIdx[maxNumOverlap];
    vec3 particlePos0[maxNumOverlap];
    vec3 particleScreenPos[maxNumOverlap];

    // find overlap particles
    int numOverlap = 0;
    for (int i = 0; i < numX; i++) {
        for (int j = 0; j < numY; j++) {
            vec2 coordp = vec2(i, j) * particleSizeInit;
            float noise = rand(coordp);
            // position
            vec3 pos0;
            pos0.xy = coordp + 30.0 * noise;
            pos0.z = -(travelDistance * noise) * st * 0.5;

			// init radius
            float radius0 = particleSizeInit * noise * (0.5 + 1.0*st);

            vec3 screenPos = pos0 - cameraPos;
            if (screenPos.z > 0.0) {
                // perform rotation here
                screenPos.xy = vec2(screenPos.x * cos(-phi0) - screenPos.y * sin(-phi0),
                                   	screenPos.x * sin(-phi0) + screenPos.y * cos(-phi0));

                screenPos.xy = screenPos.xy * fx / screenPos.z;
                screenPos.xy += res / 2.0;
            	float screenRadius = radius0 * fx / screenPos.z;

                // in clip space
                if (screenPos.x > 0.0 && screenPos.x < res.x &&
                    screenPos.y > 0.0 && screenPos.y < res.y) {

                    // TODO sort

                    // see if pixel in particle range
                	vec2 dir = p - screenPos.xy;
                    float r = length(dir) / screenRadius;

                    if (r < 2.0) {
                        vec2 uv0 = pos0.xy / res;
        				vec4 color0 = texture(tex0, uv0);
        				vec4 color1 = texture(tex1, uv0);
                        vec4 colorP = mix(color0, color1, st);

                        float w = pKernel(r);
                        colorSum += colorP * w;
                        weightSum += w;
                    }
                }
            }
        }
    }

    if (weightSum > 0.0) {
        colorSum /= weightSum;
    }

    // blend with original images
    float scale0 = 1.0 / (1.0 + 0.6 * st);
    vec2 uv = fragCoord.xy - res / 2.0;
    vec2 uv0 = scale0 * vec2(uv.x * cos(phi0) - uv.y * sin(phi0),
                   uv.x * sin(phi0) + uv.y * cos(phi0)) / res + 0.5;
    float scale1 = 1.0/st;
    vec2 uv1 = scale1 * uv / res + 0.5;
    vec4 col0 = texture(tex0, mirroredSample(uv0));
    vec4 col1 = texture(tex1, mirroredSample(uv1));

    vec4 colBG = mix(col0, col1, exponentialInOut(t));

    float w = 0.0;
    if (t < 0.2) {
        w = smoothstep(0.0, 0.2, t);
    } else if (t < 0.8) {
        w = 1.0;
    } else {
        w = 1.0 - smoothstep(0.8, 1.0, t);
    }

    //vec4 col = mix(colBG, colorSum, w * colorSum.a);
    vec4 col = mix(colBG, colorSum, w * colorSum.a);


    return vec4(col.rgb, w * colorSum.a);
}


void main(void)
{
    float t = fract(iTime / period);
    t = clamp((t - 0.2)*1.3, 0.0, 1.0);
    vec4 col;
    if (reverse) {
        t = 1.0 - t;
        col = animatedColor(iChannel0, iChannel1, fragCoord.xy, iResolution.xy, t);
    }
    else {
        col = animatedColor(iChannel1, iChannel0, fragCoord.xy, iResolution.xy, t);
    }

    // Output to screen
    fragColor = col;
}

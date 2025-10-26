#version 120

uniform float adsk_result_w, adsk_result_h;
uniform sampler2D adsk_results_pass1;
uniform int amount;

float PI = radians(180.0);
float BSf = float(amount);

float basis1D(int k, int i)
{
    return k == 0 ? sqrt(1. / BSf) :
      sqrt(2. / BSf) * cos(float((2 * i + 1) * k) * PI / (2. * BSf));
}

float basis2D(ivec2 jk, ivec2 xy)
{
    return basis1D(jk.x, xy.x) * basis1D(jk.y, xy.y);
}

void main()
{
    vec2 uv = gl_FragCoord.xy;
    vec4 c = vec4(0.0);
    ivec2 coords = ivec2(uv);
    ivec2 inBlock = ivec2(0);
    inBlock.x = int(mod(coords.x, amount));
    inBlock.y = int(mod(coords.y, amount));
    ivec2 block = coords - inBlock;

    for (ivec2 xy = ivec2(0); xy.x < amount; xy.x++) {
        for (xy.y = 0; xy.y < amount; xy.y++) {
            c += texture2D(adsk_results_pass1, (vec2(block + xy) + vec2(0.5)) / vec2(adsk_result_w, adsk_result_h)) * basis2D(xy, inBlock);
        }
    }
    gl_FragColor = c;
}

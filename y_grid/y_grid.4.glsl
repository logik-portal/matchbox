

vec3  adsk_hsv2rgb( vec3 hsv );
float adsk_getLuminance( vec3 );

uniform sampler2D adsk_results_pass1;
uniform sampler2D adsk_results_pass2;
uniform sampler2D adsk_results_pass3;

uniform float adsk_result_frameratio;
uniform float adsk_result_w, adsk_result_h;
vec2 res = vec2(adsk_result_w, adsk_result_h);
vec2 texel = vec2(1.0) / res;

uniform int i_colorspace;
uniform bool usebg;

vec3 from_sRGB(vec3 col)
{
    if (col.r >= 0.0) {
         col.r = pow((col.r +.055)/ 1.055, 2.4);
    }

    if (col.g >= 0.0) {
         col.g = pow((col.g +.055)/ 1.055, 2.4);
    }

    if (col.b >= 0.0) {
         col.b = pow((col.b +.055)/ 1.055, 2.4);
    }

    return col;
}

vec3 from_rec709(vec3 col)
{
    if (col.r < .081) {
         col.r /= 4.5;
    } else {
         col.r = pow((col.r +.099)/ 1.099, 1.0 / .45);
    }

    if (col.g < .081) {
         col.g /= 4.5;
    } else {
         col.g = pow((col.g +.099)/ 1.099, 1.0 / .45);
    }

    if (col.b < .081) {
         col.b /= 4.5;
    } else {
         col.b = pow((col.b +.099)/ 1.099, 1.0 / .45);
    }

    return col;
}

vec3 to_rec709(vec3 col)
{
    if (col.r < .018) {
         col.r *= 4.5;
    } else if (col.r >= 0.0) {
         col.r = (1.099 * pow(col.r, .45)) - .099;
    }

    if (col.g < .018) {
         col.g *= 4.5;
    } else if (col.g >= 0.0) {
         col.g = (1.099 * pow(col.g, .45)) - .099;
    }

    if (col.b < .018) {
         col.b *= 4.5;
    } else if (col.b >= 0.0) {
         col.b = (1.099 * pow(col.b, .45)) - .099;
    }


    return col;
}

vec3 to_sRGB(vec3 col)
{
    if (col.r >= 0.0) {
         col.r = (1.055 * pow(col.r, 1.0 / 2.4)) - .055;
    }

    if (col.g >= 0.0) {
         col.g = (1.055 * pow(col.g, 1.0 / 2.4)) - .055;
    }

    if (col.b >= 0.0) {
         col.b = (1.055 * pow(col.b, 1.0 / 2.4)) - .055;
    }

    return col;
}

vec3 adjust_gamma(vec3 col, float gamma)
{
    col.r = pow(col.r, gamma);
    col.g = pow(col.g, gamma);
    col.b = pow(col.b, gamma);

    return col;
}

vec3 do_colorspace(vec3 front, int op)
{
    if (op == 0)
    {
        if (i_colorspace == 0) {
            front = from_rec709(front);
        } else if (i_colorspace == 1) {
            front = from_sRGB(front);
        } else if (i_colorspace == 2) {
            //linear
        } else if (i_colorspace == 3) {
            front = adjust_gamma(front, 2.2);
        } else if (i_colorspace == 4) {
            front = adjust_gamma(front, 1.8);
        }
    }
    else if (op == 1)
    {
        if (i_colorspace == 0) {
            front = to_rec709(front);
        } else if (i_colorspace == 1) {
            front = to_sRGB(front);
        } else if (i_colorspace == 2) {
            //linear
        } else if (i_colorspace == 3) {
            front = adjust_gamma(front, 2.2);
        } else if (i_colorspace == 4) {
            front = adjust_gamma(front, 1.8);
        }
    }

    return front;
}

void main(void) {
    vec2 st = gl_FragCoord.xy / res;

    vec4 front = texture2D(adsk_results_pass1, st);
    front.rgb = do_colorspace(front.rgb, 0);

    vec4 col1 = texture2D(adsk_results_pass2, st);
    col1.rgb = do_colorspace(col1.rgb, 0);

    vec3 col2 = texture2D(adsk_results_pass3, st).rgb;
    col2.rgb = do_colorspace(col2.rgb, 0);

    vec3 grid = mix(col2, col1.rgb, col1.a);
    float alpha = front.a;

    if (! usebg) {
        grid = mix(front.rgb, col1.rgb, col1.a);
        alpha = front.a * col1.a;
    }

    grid = mix(front.rgb, grid, front.a);

    grid = do_colorspace(grid, 1);

    gl_FragColor = vec4(grid, alpha);
}

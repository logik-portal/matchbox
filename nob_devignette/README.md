# nob devignette

**Author:** Unknown

**Shader Type:** Matchbox

**Action:** Yes

**Timeline:** Yes

**Transition:** No

**Minimum Flame Version:** 2024.1.0


## Description
This Matchbox shader compensates for vignetting.

Up to four reference points can be defined as radii and the respective gain compensation, optionally separate for red, green and blue colour channels. The vignetting centre is treated as an implicit fifth point with unchanged gain.
The shader calculates an even polynomial of eighth degree (in the radius from the vignetting centre) to interpolate those points.
This kind of interpolation may lead to undesired oscillations for higher numbers of data points. However with sensible spacing of radii and lens vignetting being a rather smooth function, so to say, oscillations or overshoot is hardly an issue.

Note that this shader does not perform any image scaling or reformatting, so the operation may be incorrect if the result image format does not match the input image format.
It is recommended to leave the canvas resolution as {Same As Input 1}.

This shader is licensed under the terms of the MIT license.

For questions contact:
nobbl211@gmail.com'
        

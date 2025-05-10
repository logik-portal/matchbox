# nob devignetting

**Author:** Unknown

**Shader Type:** Matchbox

**Action:** Yes

**Timeline:** Yes

**Transition:** No

**Minimum Flame Version:** 2024.1


## Description
This Matchbox shader compensates for vignetting.\n\nUp to four reference points can be defined as radii and the respective gain compensation, optionally separate for red, green, blue colour channels. The vignetting centre is treated as an implicit fifth point with unchanged gain.\nThe shader calculates an even polynomial of eighth degree (in the radius from the vignetting centre) to interpolate those points.\nThis kind of interpolation may lead to undesired oscillations for higher numbers data points. However with sensible spacing of radii and lens vignetting being a rather smooth function, so to say, oscillations or overshoot is hardly an issue.\n\nNote that this shader does not perform any image scaling or reformatting, so the operation may be incorrect if the result image format does not match the input image format.\nIt is recommended to leave the canvas resolution as Same As Input 1.

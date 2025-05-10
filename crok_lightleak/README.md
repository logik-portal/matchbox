# crok lightleak

**Author:** Ivar Beer

**Shader Type:** Matchbox

**Action:** No

**Timeline:** No

**Transition:** No

**Minimum Flame Version:** 


## Description
This Matchbox creates Light Leaks style effects.

Input:

    - Front: front clip
    - Matte: matte clip which will add to the luma key
    - Strength: will drive the Chromatic abberation amount

Setup:

    - Amount: amount of light leak applied
    - Softness: blur the lightleaks in x / y
    - Tint: tint colour for the light leaks
    - Saturation: dial in original saturation for the light leaks

    - Density: adjust the denisity of the flicker noise
    - Speed: adjust the speed of the flicker
    - Offset: offset the flicker in time

    - Min Input: min input of the luma key
    - Max Input: max input of the luma key

    - Light Leak Only: outputs the light leak only

    - Enable: Enable chromatic abberations
    - Amount: amount of chromatic abberations applied
    - Itterations: itterations steps for the abberations
    - Center: adjust the center of the chromatic abberations

    - Amount: adjust the noise amount of the atmosphere
    - Scale: adjust the scale of the noise
    - Speed: adjust the speed of the noise

    - Brightness: adjust noise brightness
    - Contrast: adjust contrast of the brightness

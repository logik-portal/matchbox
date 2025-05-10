# crok chroma warp

**Author:** Kyle Obley and Ivar Beer

**Shader Type:** Matchbox

**Action:** No

**Timeline:** No

**Transition:** No

**Minimum Flame Version:** 


## Description
Creates chromatic aberrations and a barrel distortion.

Input:

    - Front: source clip
    - Chromatic Aberration Strength: Chromatic Aberration Strength matte
    - Distortion Strength: Distortion Strength matte

Output:

    - Result: result clip
    - Matte: alpha channel

Setup:

    - Amount: blur amount
    - Iterations: number of steps to create the blur
    - Saturation: Blend in/out the chroma offset
    - Center: center of the effect
    - Add Distortion: enable additional distortion
    - Amount: amount of applied distortion

# crok ssao

**Author:** Ivar Beer

**Shader Type:** Matchbox

**Action:** No

**Timeline:** No

**Transition:** No

**Minimum Flame Version:** 


## Description
Simulates a SSAO look with just a Normal Map input.

Input:

    - Front: RGB Beauty pass
    - Back: background
    - Matte: matte
    - Normal Map: normal map pass

Setup:

    - Radius: radius of the ao effect
    - Blur: apply a post blur to the AO pass
    - Gamma: adjust the gamma of the AO only

Output:

    - SSAO only: output just the AO pass not the comped image
    - Alpha channel

# crok distort blur

**Author:** Ivar Beer and Lewis Saunders

**Shader Type:** Matchbox

**Action:** No

**Timeline:** No

**Transition:** No

**Minimum Flame Version:** 


## Description
Adds a blured lens distortion effect.

Input:

    - Front: source clip
    - Matte: region of interest
    - Displace: distortion clip
    - Strength: strength clip

Setup:

    - Distortion: overall distortion
    - Blur Distortion: softens the incoming displace matte
    - Blur: amount of blur applied to the Matte to get the directional blur effect
    - Samples: how many samples are used for the directional blur

AntiAliasing:

    - Enable FXAA: enables AntiAliasing

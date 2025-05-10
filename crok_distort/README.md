# crok distort

**Author:** Ivar Beer and Lewis Saunders

**Shader Type:** Matchbox

**Action:** No

**Timeline:** No

**Transition:** No

**Minimum Flame Version:** 


## Description
Adds a lens distortion effect. For all your glassy/watery/refrationy needs.

Input:

    - Front: source clip
    - Lens: distortion clip
    - Matte: region of interest
    - Strength: strength clip

Setup:

    - Amount: overall distortion
    - Displace: the displacement amount
    - Softness: amount of softness applied to the distortion
    - Rotate: offset the distortion

Filtering:

    - Blur Lens: softens incoming lens clip
    - Blur Strength: softens incoming strength clip
    - Strength Amount: blends in / out strength clip
    - FXAA Amount: amount of Antialiasing applied

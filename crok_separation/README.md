# crok separation

**Author:** Ivar Beer

**Shader Type:** Matchbox

**Action:** No

**Timeline:** No

**Transition:** No

**Minimum Flame Version:** 


## Description
Creates a low pass and high pass filter sometimes calles frequency separation

HINT: You need to combine both passes with a PS_LinearLight

Input:

    - Front: source clip

Output:

    - RGB: LowPass filter
    - Matte: HighPass filter

Setup:

    - Blur: adjust the softness of the LowPass Filter
    - Output HighPass as RGB: outputs the Higpass filter as an RGB image instead of a BW in the Matte output

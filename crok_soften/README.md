# crok soften

**Author:** Ivar Beer

**Shader Type:** Matchbox

**Action:** No

**Timeline:** No

**Transition:** No

**Minimum Flame Version:** 


## Description
This is a Flame sub pixel blur meant for creating natural looking edges.

Input:

    - Front: original front
    - Matte: original matte

Soften:

    - Size: amount of gaussian blur applied to the image
    - Strength: mix amount between original image and blurred one

Smoothness:

    - Amount: how much AA is applied to the image before it runs through the soften process

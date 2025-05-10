# crok beauty

**Author:** Lewis, Greg-Paul and Ivar Beer

**Shader Type:** Matchbox

**Action:** No

**Timeline:** No

**Transition:** No

**Minimum Flame Version:** 


## Description
Applies some freshness to the skin ;)

Input:

    - Front: original fg
    - Matte: external skin key

Skin:

    - Color: pick the skin color of the talent
    - Weights: adjust the tollerance values for the build in keyer
    - Enable External Matte: enable the use of the optional external skin matte
    - Soften: blurs the skin matte

Cleanup:

    - Amount: amount of softening applied to the image
    - Preserve Edges: amount of edge detection applied
    - Dark spots: cleanup dark areas of the skin
    - Highlights: clean up highlights on the skin

Restore Detail | Shine:

    - Amount: restore highfrequency details
    - Soften: soften the highpass filer
    - Shine amount: applied a little bit of shine to the skin
    - Blur Shine: soften the shine key

Color:

    - Saturation: amount of saturation applied to the shine
    - Hue Shift: amount of Hue shift applied to the image

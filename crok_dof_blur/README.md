# crok dof blur

**Author:** Ivar Beer

**Shader Type:** Matchbox

**Action:** No

**Timeline:** No

**Transition:** No

**Minimum Flame Version:** 


## Description
Simulates depth of field with bokeh.

Input:

    - Front: source clip
    - Depth Map: depth map

Setup:

    - Amount : how much blur is applied
    - Threshold : highlight threshold
    - Gain : highlight gain
    - Chromatic Abe. : highlight chromatic aberration
    - Dither : sample dithering amount
    - Rings : ring amount
    - Samples : how many samples are used for the bokeh
    - Noise : use noise instead of pattern for sample dithering
    - Pentagon Shape : use pentagon as bokeh shape
    - Feather Shape : pentagon shape feather
    - Range : focal range
    - Focal Depth : focal depth, if you use an external matte
    - Autofocus : use autofocus in shader
    - Depth Map Blur : blurs the depth buffer
    - Bias: bokeh edge bias

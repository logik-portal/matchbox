# Ls Dilate

**Author:** Lewis Saunders

**Shader Type:** Matchbox

**Action:** No

**Timeline:** No

**Transition:** No

**Minimum Flame Version:** 


## Description
Shrink or expand pixels based on brightness, or on closeness to a particular colour

The strength input modulates the effet and can also use negative colours to reverse the dilation into erosion, and vice-versa

When using colour weighting, the third input can set the colour to use per-pixel - using a clean greenscreen can let you spread edge colours inwards or outwards without having to pull a key to use with PixelSpread

Make sure input is 16fp rather than 8-bit!

Quick demo: https://www.youtube.com/watch?v=t2jISkR7fGc

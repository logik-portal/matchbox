# cb distort

**Author:** CB

**Shader Type:** Matchbox

**Action:** No

**Timeline:** No

**Transition:** No

**Minimum Flame Version:** 2017.0


## Description
UV pass distortion + Grid Distortion.

front
motion - Motion vector pass (R = X motion, G = Y motion)
strength - Strength of motion-based distortion
blurAmount - Amount of motion blur applied
caStrength - Strength of chromatic aberration effect
showMarkers - Show red cross markers (0 = off, 1 = on)
markerSize - Size of red cross markers
markerThickness - Thickness of cross arms relative to size
vertex0-15 - Displacement
resolution - Image resolution (width, height)
time - Animation time

Uses Motion Vector UVs (or anything) for distortion, also has vertex based grid distortion. 

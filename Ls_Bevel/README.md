# Ls Bevel

**Author:** Lewis Saunders and Sebastien Delecour

**Shader Type:** Matchbox

**Action:** No

**Timeline:** No

**Transition:** No

**Minimum Flame Version:** 


## Description
Cheap pseudo-bevel for text, using the Gaussian Distance Transform.  Can output normals to be fed into an Action normal map for more sophisticated lighting.  Sadly it is not possible to create a displacement map this way, so it's not a true 3D surface :(

Demo: https://www.youtube.com/watch?v=Y7dUx1An_30

Height map is the shape of the area to bevel, typically a black/white matte but images are possible too.
Back input gives colour to the beveled area.
Matte is used to limit the area which is comped over the back.

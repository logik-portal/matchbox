# Ls Stickon

**Author:** Lewis Saunders

**Shader Type:** Matchbox

**Action:** No

**Timeline:** No

**Transition:** No

**Minimum Flame Version:** 


## Description
Recursively warp an image by motion vectors, to stick it to something.  Make sure bit depth is 16-bit fp! Supply backward motion vectors to the vector input, i.e. the second output of Motion Analysis, or even better the backward channel from Nuke 9's VectorGenerator.  The front and matte inputs should normally be a still lined up on the Accumulate From frame.

Demo: https://www.youtube.com/watch?v=m27XZX7dtJU

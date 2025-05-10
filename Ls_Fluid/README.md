# Ls Fluid

**Author:** Lewis Saunders

**Shader Type:** Matchbox

**Action:** No

**Timeline:** No

**Transition:** No

**Minimum Flame Version:** 


## Description
A 2D fluid simulation. Make sure bit depth is 16-bit fp!

The vector input can be fed motion vectors to affect the fluid, and the obstacle input can be fed with a matte for areas which the fluid should move around.

The matte output works well as the Displacement input to BumpDisplace, or as a displacement map in Action.  The RGB output can be the front input image mapped onto the surface of the fluid, or various vector or UV outputs.

The simulation is based on Jos Stam's 'Stable Fluids', 1999.  The process also owes a debt to Theodor Groeneboom's Sprut gizmo for Nuke.

Remember to disable Adaptive Degradation on this node if viewing downstream!

Demo: https://www.youtube.com/watch?v=N6nIwt2BcMM

# crok logicop

**Author:** Ivar Beer

**Shader Type:** Matchbox

**Action:** No

**Timeline:** No

**Transition:** No

**Minimum Flame Version:** 


## Description
Recreates the Photoshop blending modes.

Input:

    - Front: front image
    - Back: background image
    - Matte: matte being used to apply effect

Output:

    - Clamp Color: clamps the color between 0.0 and 1.0

Setup:

    - Selection: select the logic operator to use
    - Blend: dissolve between bg and result

Function:

    - None: doesn't apply any function
    - Sinus: applies a sinus function to the blend
    - Smooth Saw: applies a smooth saw to the blend
    - Step Random: jumps randomly between diffeend blend values

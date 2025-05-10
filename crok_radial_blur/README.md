# crok radial blur

**Author:** Ivar Beer

**Shader Type:** Matchbox

**Action:** No

**Timeline:** No

**Transition:** No

**Minimum Flame Version:** 


## Description
This Matchbox shader creates radial blur.

Input:

    - Front : source clip

Setup:

    - Amount : blur strenth
    - Center : center of the blur
    - Gain : brightness of the picture
    - Steps : blur resolution

Updates:

    - Fixed a half-pixel offset causing an image shift and interpolation softness, changed the Center to an X/Y axis widget on-screen for easier manipulation

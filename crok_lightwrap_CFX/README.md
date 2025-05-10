# crok lightwrap CFX

**Author:** Ivar Beer

**Shader Type:** Matchbox

**Action:** Yes

**Timeline:** No

**Transition:** No

**Minimum Flame Version:** 


## Description
Applies a lightwrap to the image.

Input:

    - Comp: composed FG + BG without LightWrap
    - Back: BG only
    - Matte: FG matte

Setup:

    - Logic Op: blend mode applied
    - Size: amount of lightwrap
    - Blend: blend in / out lightwrap
    - Blur BG: amount of blur applied to the incomming BG plate

    - Gain: adjust gain of the lighwrap matte
    - Threshold: adjust lightwrap matte threshold

    - Gain: adjust gain of the edge matte
    - Threshold: adjust edge matte threshold
    - Size: size of the edge blur
    - Blur: blur the generated edge matte

    - Blur Amount: amount of edgeblur applied
    - Grain Amount: amount of grain applied

# crok uncomp

**Author:** Ivar Beer and Erwan Leroy

**Shader Type:** Matchbox

**Action:** No

**Timeline:** No

**Transition:** No

**Minimum Flame Version:** 


## Description
Uncompose a compositing scene into its original layer.

Input for Undo Blend:

    - Front: wrongly comped element
    - Back: clean BG without the element on it
    - Matte: alpha of the composed element

Input for Remove Logo:

    - Front: FG element which you want to remove
    - Back: original scene with the element on it
    - Matte: alpha channel of the element

Modus:

    - Undo Blend: remove wrongly comped element from BG needs original matte of the element
    - Remove Logo: removes semitransparent FG element from BG (needs a matte of the element)

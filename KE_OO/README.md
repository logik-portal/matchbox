# KE OO

**Author:** Ted Kuleshov

**Shader Type:** Matchbox

**Action:** No

**Timeline:** No

**Transition:** No

**Minimum Flame Version:** 2017.0.0


## Description
Object Obliterator in a node!

Requires a front and matte input.
Increase Blur until the black goes away.
For more blurring, use Blur After Divide.
Optionally, you can grab texture from a different part of the frame to cover the blurred area.
The retexturing is a simple subtract/add, similar to a regrain operation.

Note that the matte output is the matte AFTER the blurring.
So if you want to regrain, you should use your original matte, not the output of the node.

Based on Renees Object Obliterator:
https://forum.logik.tv/t/renee-tymns-object-obliterator/4049'
        

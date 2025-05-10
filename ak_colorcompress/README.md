# ak colorcompress

**Author:** Jan Klier

**Shader Type:** Matchbox

**Action:** No

**Timeline:** No

**Transition:** No

**Minimum Flame Version:** 2017.0


## Description
Color Compressor through hue rotation around reference point\n\t\n\tUse to pull hue, sat, and exposure of the entire image closer to the values of the reference\n\tcolor. Value of 0 is neutral. At maximum compression whole image will be solid of the reference\n\tcolor. It honors an input matte to enable keying and masking of the effect.\n\n\tThe curve can be used to bias the effect strenght closer or further from the target color.\n\t\n\tMost common use cases are to remove color variations in skin and products. Default target\n\tcolor is skintone for that reason.\n\t\n\tThis should look familiar to anyone who used Resolves Color Compressor.\n\t\n\tMatchbox shader by Jan Klier https://www.janklier.com

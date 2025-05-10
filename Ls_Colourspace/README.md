# Ls Colourspace

**Author:** Lewis Saunders

**Shader Type:** Matchbox

**Action:** No

**Timeline:** No

**Transition:** No

**Minimum Flame Version:** 


## Description
Converts between various colourspaces, mainly perceptual ones (ColorMgmt already handles most camera and display spaces)

All the spaces use illuminant/reference white D65 and are as follows:

linear sRGB: scene-referred (un-tonemapped) linear with sRGB/Rec709 primaries (you can convert to this space from most camera spaces with a Colour Mgmt node, by first converting to ACES and then using primaries/ACES_to_LinearRec709-sRGB.ctf)

XYZ: the classic CIE 1931 XYZ space with white at Y=1, again useful as an interchange space by using the various CIE-XYZ .ctf options in Colour Mgmt

xyY: the CIE 1931 xyY space where x and y are chromaticities in [0,1] and Y is brightness

L*a*b*: CIELAB 1976 where L* is perceptual lightness with white at 1, a* is broadly green/red and b* blue/yellow, both centred around 0.0 so likely using negatives

L*a*b* (0.5-centred chroma): as above but with a* and b* centred around 0.5, so easier to see and work with

LCHab: cylindrical version of L*a*b* where L* is as before, but C is colorfulness and H is hue

LUV: CIELUV 1976 space similar to L*a*b* but better suited for screens and emissive surfaces

LUV (0.5-centred chroma): as above but with u and v centred around 0.5

LCHuv: cylindrical version of LUV

Oklab: recent (2020) perceptual space designed to be similar to but faster and better behaved than the above CIE spaces

Oklab (0.5-centred chroma): as above but with a and b centred around 0.5

HSV: classic hue/saturation/value space used in CG and colour picking - we convert to BT1886 2.4 gamma before converting to HSV, rather than converting from linear colour directly, to better match other apps

HSL: similar to HSV but with higher L values tending towards white rather than saturated colours - we convert to BT1886 2.4 gamma before converting to HSL, rather than converting from linear colour directly, to match other apps (unlike Flame's Separate node which assumes the input is already in video space)

YCbCr: YUV space used in digital video with Y including head/footroom and Cb/Cr centred around 0.5

YPbPr: YUV space used in analog video with Pb/Pr centred around 0

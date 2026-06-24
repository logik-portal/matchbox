# nob_chromatic_adaptation

## Description

This Matchbox shader performs chromatic adaptation alongside linear colour-space conversion, optionally utilizing the perceptual CAM16.
The core method can be chosen via [CA Method], the following ones are implemented:
[Disable]: no chromatic adaptation, instead only transforms between input & output colour-spaces, also sometimes called absolute colourimetric;
[XYZ Scaling]: scales the source to the target white using a diagonal matrix applied in linear CIE XYZ colours;
[Bradford]: the traditional Bradford Transform (Luo et al., 1998), notably with its nonlinearity in the blue intermediate channel;
[Lin. Bradford]: a linear variant of the Bradford transformation; used, among other, for most of Flame's own internal transformation matrices;
[Lin. CAT02]: the full chromatic adaptation as described 
[CAM16]: implements the nonlinear CAM16 (extended to support negative achromatic responses symmetrically), with respect to individual source & target viewing conditions; and
[Lin. CAT16]: the full chromatic adaptation as described 
This shader's pipeline identifies input- & output colour-spaces (assumed scene-, or display-referred linear) 
The former can be chosen as a preset in [Colour Primaries], or selected [Custom], in which case the user is to define the coordinates for red green & blue primaries via [Primaries x] & [Primaries y] in the CIE xy chromaticity space.
Note that (and the controls for which are disabled). To convert from and/or to XYZ spaces with different virtual white points, use the overrides on the [CA Override] page. This is consistent with for example Flame's own CIE XYZ-D65 colour-space when setting the override to [HD D65].
In all other cases, choosing the white point is done 
[Native]: automatically chooses the white point corresponding to the primaries; note that this might be ambiguous or unintended for certain cases such as P3, for which one best selects another setting;
[Standard]: provides a selection of common white points in their usual (rounded) forms:
[ACES]: (0.32168, 0.33767) in CIE xy chromaticity space, as per ACES specification,
[ICC D50]: (0.9642, 1, 0.8249) in CIE XYZ, as per the ICC profile specification,
[HD D65]: (0.3127, 0.329) in CIE xy chromaticity space,
[DCI]: (0.314, 0.351) in CIE xy chromaticity space, as per SMPTE specification, and
[E]: equal energy white (1, 1, 1) in CIE XYZ;
[Temperature]: implements the Illuminant series D white, defined by:
[Temp]: the correlated colour temperature in Kelvin,
[Tint]: orthogonal tint to the daylight locus in CIE 1976 UCS, in units thereof, and
[Temperature shift]: since the definition of this illuminant series predates the fixing of the second radiation constant c₂, and (0.01438 m×K); and
[xy Coords]: CIE xy chromaticity space coordinates of the white point.
Note: for [Native], ACES primaries default to ACES white, [CIE XYZ] to E, and all others (including [Custom]) to [HD D65].
These controls are identical for the source & target colour-space.
Further, for using a white point different from the colour-space's innate one to adapt from and/or to, the [CA Override] page provides controls for such overrides. Those utilize the same methods and settings as the in- & output colour-space controls, except for [Native]; but additionally implement:
[Disable]: doesn't override the white point; and
[From Colour]: provides a colour selector to set the scene white to a colour with respect to the in, or output colour-space; the selected colour is internally normalized to CIE Y=1.
These controls are identical for the source & target white point override.
When using the CAM16, the following additional controls become available in the [Viewing Conditions] column (on page 1: [Controls] for 6 a column view, and page 2: [Target+Con] otherwise):
[Force Full CA]: (and back), the exact degree of which depending on the viewing conditions; this setting allows for instead forcing to use a full adaptation, for forward & backward transformation, respectively; as well as 
controls for the parametric source & target viewing conditions ([Source] & [Target]):
[S]: encodes the surround parameters, as linearly interpolated between the CAM16 values for Dark, Dim & Average corresponding to entries of -1, 0 and 1, respectively,
[L_W]: the luminance of the reference white in nits, and
[L_A]: the luminance of the adapting field in nits.
Generally, L_A×Y_W=L_W×Y_b, where Y_b is the luminance factor of the background and Y_W is the luminance factor of the reference white. This relation can be used to derive either L_W or L_A if the other and Y_b (as well as Y_W) are fixed instead.
For enhanced accuracy, intermediate matrices and values are always processed in double precision arithmetic; yet since instead of performing these computations for each pixel, an interposed data sampler is generated, the computational overhead is constant and insignificant.
If even higher accuracy is needed, [Double Precision Processing] can be enabled, at the cost of performance.
The CAM16 implementation used behaves as if forward-transforming to the triplet of hue angle h, correlate lightness J, and correlate colorfulness M; and back.
Mirroring the set of quantities from which CAM16-UCS is derived.
Note that this shader does not perform any image scaling or reformatting, so the operation may be incorrect if the result image format does not match the input image format.
It is recommended to leave the [Output Resolution] as [Same As Input 1] - however, for tagging the [Result] with different colour-space, [User Defined] must be chosen. Still, in such cases, the format (in pixels and aspect ratio) must match the [Front]'s.
Colour-spaces themselves are neither inferred from [Front] nor automatically tagged for [Result], the user shall take care to maintain a consistent colour-space journey either through the aforementioned Matchbox setting, or Colour Mgmt nodes.
Adaptive Degradation is supported 
This shader is licensed under the terms of the MIT license.
For questions contact:
nobbl211@gmail.com

## Flame Requirements

2026.2.1

## Supported Modes

- ✅ **Action**: Supported
- ❌ **Transition**: Not supported
- ✅ **Timeline**: Supported

## Shader Type

Matchbox

## Author

the CAM02/CAT02, for equal source & target viewing conditions;

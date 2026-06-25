# nob_trigrade

## Description

This Matchbox shader performs a linear - or perceptually linear - colour-grade, defined by up to three colour-vector mappings.
Each vector mapping is defined by a source-colour and exactly one of three possible methods for assigning a target-colour, as determined by the individual Vector Modes:
<Colour> maps the source colour to the specified target colour,
<Shift> determines the target colour through an additive offset to the source colour, and
<Gain> multiplies the source colour by a given triplet as the target colour.
Alternatively, if fewer than three vectors are required, each vector can be disabled individually.
In such cases, the orthogonal complement to the basis spanned by the active source colour vectors is mapped to itself. Note that in general, this orthogonal complement depends on the working colour-space, thus even if source and target colours for the active vector mappings are identical (in true colour, not value-triplets), the results may still differ.
However, if all three vector mappings are active and the source and target colours are kept consistent, the transformation yields the same result for any scene-linear working colour-space.
Each vector can optionally be normalised in luminance (active by default), which is calculated with the luma coefficients given by <W_R> and <W_B> (assuming ACEScg by default). This can be useful for shifting chromatics iso-luminance with the provided <Shift>- and <Gain>-modes.
When enabling <Perceptual Processing>, the shader operates according to the Oklab colour appearance model; most notably using the nonlinear response, and Euclidean perceptual colour-distances.
For correct transformations to this model, the working colour-space (of Front as well as Result) has to be set via <Working CS>.
By default, the target vector controls remain in working-space colourimetry, and results should be similar for small, well-conditioned adjustments. However, the Shift- and Gain controls can also be switched to Oklab Lab representation by activating <Perceptual Shift and Gain>. While <Shift> works mostly analogous to RGB-colour-shifts, <Gain> in Lab behaves noticeably differently for chromatic changes.
Colour selectors (for vector sources and targets) always are relative to the working colour-space.
Note that in perceptual processing, luminance normalization for vectors does not rely on the <W_R> and <W_B> coefficients but uses the Oklab lightness, and thus may produce slightly different results.
Finally, the image saturation can be adjusted via <Post-Saturation> - applied after the vector-based grade.
For native processing, the luma coefficients <W_R> and <W_B> are used to calculate saturation; while for perceptual mode, the adjustment is applied in nonlinear ab chromatics.
Internally, a single colour matrix is computed, comprising the entire grade. For ill-conditioned source-bases - that is: similar source colours - this matrix might also get ill-conditioned, leading to extreme colour-shifts for image colours further to source-vectors. Even for only slight adjustments in target colours.
Further, linearly-dependent source-colours lead to undefined results.
Conversely, if the source colours are spaced sensibly far apart, the entire transformation is well-conditioned.
For enhanced accuracy, this matrix and the intermediate values are always processed in double precision arithmetic; yet since instead of computing the matrix for each pixel, an interposed data sampler is used, the computational overhead is constant and insignificant.
If even higher accuracy is needed, <Double Precision Processing> can be enabled, at the cost of performance.
This causes the application of the colour matrix on a pixel-basis (as well as the perceptual transformations) to be processed in double precision.
While for real-world images and use cases, the rounding error is negligible for standard processing; full double-precision can be useful if correctly-rounded Float32 results are paramount.
Note that this shader does not perform any image scaling or reformatting, so the operation may be incorrect if the result and input image formats don't match.
It is recommended to leave the canvas resolution as <Same As Input 1>.
This shader is licensed under the terms of the MIT license.
For questions contact:
nobbl211@gmail.com

## Flame Requirements

2026.1.0

## Supported Modes

- ✅ **Action**: Supported
- ❌ **Transition**: Not supported
- ✅ **Timeline**: Supported

## Shader Type

Matchbox

## Author

nobbl211@gmail.com

# nob_luma_chroma_forward

## Description

This Matchbox shader performs forward luma/chroma (or RGB/XYZ) conversions for storage and compression.
The entries of the selectors for [Colour Primaries], [Transfer Function] & [Colourmatrix] correspond to their respective definitions as given 
Additionally, where applicable, the corresponding indices are given in parenthesis.
The available operations performed depend on the source colour-model, selected 
[Linear XYZ]: treats the input as display-referred linear CIE XYZ - transfer characteristic, all colourmatrices and range are accessible;
[Encoded]: the input is already encoded to destination colour primaries and transfer characteristic - only non-constant-luminance YCbCr colourmatrices and range are accessible;
[Luma/Chroma]: indicates the input is in luma/chroma representation itself - no further colour transformation is performed.
Note that chroma subsampling is available for all source colour-models.
[Colour Primaries] defines the colourspace to transform into, if [Source] is [Linear XYZ]; and serves as an indicator if [Source] is [Encoded].
[P3] refers to DCI white, which since Flame 2026 is no longer accommodated 
In the [Characteristics] column, [Transfer Function] denotes the encoding to apply for [Linear XYZ] sources.
Note that:
[Rec.709] represents the traditional piecewise linear transfer characteristic;
[Rec.1886] is a pure power function of exponent 1/2.4;
for [PQ] & [HLG], this shader follows Flame's convention of interpreting a linear code value of 1 as a luminance of 100 nits; and
the luminance of the reference white for [HLG] can be chosen via the parameter [L_W] (in nits).
Note that the selection of [Colourmatrix] is dependent on [Source] and may change with modifications to the latter.
[Range] controls the data encoding range, offering [SMPTE] & [Full] levels.
The exact range-transformation further depends on the target bit-depth, set 
Only formats with an equal number of bits per component for the luma and chroma planes are supported (as Flame is limited to writing such formats too).
The [Chroma Subsampling] column then provides parameters controlling just that.
[Type] defines the horizontal and vertical downsampling ratios, supporting the three formats: [4:2:0], [4:2:2] & [4:4:4].
For [4:2:0], this shader supports the chroma locations: [Left], [Centre] & [Top-left], controlled 
Note that [4:2:2] is always sampled left-anchored.
The downsampled chroma planes are stored bottom-left justified, padded with neutral values. In case of [Colourmatrix] equal to [Identity], R & B / X & Z planes are padded to range-adjusted black.
Note that if [Source] is [Luma/Chroma], padding is always done analogous to luma/chroma formats instead of RGB/XYZ.
Finally, this shader also supports the backwards transformation to reconstruct an image for preview. The resulting image uses the same representation as the source, that is: colour-model, and if applicable, primaries, transfer characteristic, …(See below for hints on monitoring display-referred linear CIE XYZ).
Toggled ([Clamp Preview]) and quantization ([Quantize Preview]). The latter two behaving analogous to how storing the original output in the integer format determined 
Further, [Upsampling Filter] determines the algorithm used for chroma-upsampling from [4:2:0] and [4:2:2] formats:
[Sharp] is effectively a set of point-filter, weighting the connecting samples equal on edges and vertices;
[Balanced] is the set of smallest footprint filters which have the property of co-located weighted centres with the target samples; and
[Soft] is a set of softer balanced filters, the reconstruction footprints of which are uniform.
Note that for a [Chromaloc] of [Centre], [Balanced] & [Soft] are identical, since the kernel footprints are symmetric 
Take care to deactivate the preview reconstruction prior to rendering the desired master.
This shader does a rudimentary conformance check on the chosen parameters, and if a dubious configuration is detected, it overlays the output with a repeating pattern of coloured exclamation marks.
However, said behaviour can be overridden 
It is recommended to use this option cautiously, the shader indeed always works precisely as formally requested - and every permutation of available input parameters is mathematically realizable. It never falls back to a 'closest sensible' state.
Configurations tripping the safeguard are:
narrow-gamut primaries ([Rec.709], [Rec.601 (PAL)] or [Rec.601 (NTSC)]) with an HDR [Transfer Function] ([PQ] or [HLG]),
primaries other than [XYZ] with [SMPTE ST 428-1] [Transfer Function],
mis-matching primaries with native colourmatrices,
primaries other than [Rec.2020] with [ICtCp (PQ)], [ICtCp (HLG)] or [IPT-C2] [Colourmatrix],
[Transfer Function] other than [PQ] with [ICtCp (PQ)], or [IPT-C2] [Colourmatrix],
[Transfer Function] other than [HLG] with the [ICtCp (HLG)] [Colourmatrix], and
[Identity] [Colourmatrix] with chroma subsampling [Type] other than [4:4:4].
This feature does NOT protect from mis-matching indicated input & actual input formats, and no such information is inferred from colourspace tags. Neither does it detect errors in prior colour management or tagging.
For [Colourmatrix] equal to [Identity], the shader maps RGB/XYZ planes to RGB/XYZ output; otherwise R stores Cr/Cp/T, G stores Y/I and B stores Cb/Ct/P (depending on the luma/chroma format).
This might be uncommon a layout of planes, yet it translates better to a perceptual context, where the respective channels are most strongly correlated with R, G & B (except for IPT-C2, where 
All operations of the forward transformation are performed unclamped. Specifically, the transfer characteristics are analytically continued for values greater than their nominal ranges, and mirrored for negative input values.
Note that this shader does not perform any image scaling or reformatting (other than chroma subsampling), so the operation may be incorrect if the result image format does not match the input image format.
It is recommended to leave the [Output Resolution] as [Same As Input 1].
For maximum flexibility (within the context of this shader), using a [Linear XYZ] source is preferable.
Such can be provided ({Custom} active):
the first entry removing the linear working colour space, via {Type}: {OCIO → Colour Spaces} and selecting the correct space in {Transform}, do not activate {Invert} here; and
the second entry being the RRT, via {Type}: {OCIO → View Transforms} and {Transform} set to the desired RRT instance, do not use invert here either.
To correctly monitor the output of this node, set {Tagged Colour Space} to {Utility → Linear → CIE XYZ-D65 - Scene-referred}, and the Viewport/Scopes {Viewing Transformation} to {Un-tone-mapped}.
For context: here, the colour space-journey goes from the working space to ACES2065-1 - both scene-referred with the first entry, and from scene-referred ACES2065-1 to display-referred CIE-XYZ with the second one.
In order to inspect the resulting luma/chroma-encoded image, the Flame Viewport and Scope colour management can be set to {Bypass}, allowing for probing raw values with the Colour Sampler, and displaying luma/chroma Waveform-Parades as RGB.
To show only select planes, use Flame's Source- or Display Isolation feature.
The result of this shader is designed to be stored entirely unprocessed, save for the rounding from the working 32fp precision down to the desired integer bit-depth (matching the setting of [Bit-Depth]) via Media Hub export or Write File node in Batch.
Because for most use-cases, lossy compression is to be applied externally, a mathematically lossless intermediate format is desirable; such as a packed DPX sequence, or RAW/R210 QuickTime formats (for 8/10 bit, respectively).
Since the resulting video stream encodes a potentially chroma-subsampled luma/format in an RGB image container, the tool importing it is to be configured manually to correctly interpret it.
Taking the default configuration of this shader as example, for FFmpeg, the 10-bit 4:2:0 encode (read as 'gbrp10le' pixel format) can be cast to the actual 'yuv420p10' data using the following video filtergraph ('-vf'): 'split=2[orig][tmp];[tmp]crop=in_w/2:in_h/2:0:in_h/2[crop];[orig][crop]mergeplanes=0x001112:yuv420p10'.
From there, it behaves like usual 4:2:0 content and can be directly encoded to (for example) H.265 using libx265.
The use of the '-noautoscale' option before the filtergraph is encouraged, since for mismatching formats it leads to FFmpeg throwing an error instead of silently (for default 'loglevel') reformatting the source at a loss of image information.
Note that FFmpeg internally stores planar RGB formats as GBR, in turn producing the GBR/YZX/YCbCr/ICtCp/IPT layout as indexed 
The appropriate colour tags can be set as options to '-x265-params', in this case: 'range=limited:colorprim=bt2020:transfer=bt2020-10:colormatrix=bt2020nc:chromaloc=2'.
The full FFmpeg prompt can be customized further.
This shader is licensed under the terms of the MIT license.
For questions contact:
nobbl211@gmail.com

## Flame Requirements

2027.0.0

## Supported Modes

- ✅ **Action**: Supported
- ❌ **Transition**: Not supported
- ✅ **Timeline**: Supported

## Shader Type

Matchbox

## Author

the code-points in ITU-T H.273 - except where stated otherwise.

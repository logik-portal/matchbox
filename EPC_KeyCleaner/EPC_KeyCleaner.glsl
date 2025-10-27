// EPG Green Cleaner v1.1
// Works on Mac
#version 120

// Image Resolution
uniform float adsk_result_w, adsk_result_h;

// Inputs

uniform sampler2D front, matte;

// Uniform Variables

// Define initial pre processing saturation on plate
uniform float preSaturation;
// Define our reference color picking for bg clean
uniform vec3 referenceColor;
// Define the contrast amount on each channel
uniform float contrastRed, contrastGreen, contrastBlue;

// Advanced Color Manipulation on the Channels
uniform float gainRed, offsetRed, gammaRed;
uniform float gainBlue, offsetBlue, gammaBlue;
uniform float gainGreen, offsetGreen, gammaGreen;

// Define amount to colour correct the intermediate matte
uniform float matteGain, matteOffset, matteContrast, matteGamma;

uniform bool multiplyMatte;
uniform bool cutoutMatte;
uniform bool screenType;

// Functions
vec3 saturate (vec3 color, float amount)
{
	// Set absolute gray
	vec3 gray = vec3 ( dot( vec3 (0.2126, 0.7152, 0.0722), color ) );
	// Find the difference between the gray and the color
	vec3 difference = color - gray;
	// Increase the difference by the amount
	difference *= amount;
	// Clamp the result
	vec3 saturatedImage = clamp (gray + difference, 0.0, 1.0);

	// Return the processed color
	return saturatedImage;
}

float contrastChannel (float value, float amount)
{
	return (value - 0.5) * amount + 0.5;
}

float contrastOffsetChannel (float value, float con, float offs)
{
	return (value) * con + offs;
}

float gainChannel (float value, float amount)
{
	return (1.0 + amount) * value;
}

float gammaChannel (float value, float amount)
{
	return (pow (value, amount));
}

float offsetChannel (float value, float amount)
{
	return value + amount;
}

// Main Loop
void main ( void )
{
	// Tell the shader which pixel we working on
	vec2 uv = gl_FragCoord.xy / vec2 ( adsk_result_w, adsk_result_h );

	// Get our inputs
	vec3 localFront = texture2D (front, uv).rgb;
	vec3 inputMatte = texture2D (matte, uv).rgb;

	// Apply pre saturation on front
	vec3 saturatedFront = saturate (localFront, preSaturation);

	// Separate the R G B channels
	float localRed = saturatedFront.r;
	float localGreen = saturatedFront.g;
	float localBlue = saturatedFront.b;

	// Contrast the R Channel
	localRed = contrastChannel (localRed, contrastRed);
	// Contrast the G Channel
	localGreen = contrastChannel (localGreen, contrastGreen);
	// Contrast the B Channel
	localBlue = contrastChannel (localBlue, contrastBlue);

	// Advanced channel manipulation
	localRed = gainChannel (localRed, gainRed);
	localRed = gammaChannel (localRed, gammaRed);
	localRed = offsetChannel (localRed, offsetRed);

	localGreen = gainChannel (localGreen, gainGreen);
	localGreen = gammaChannel (localGreen, gammaGreen);
	localGreen = offsetChannel (localGreen, offsetGreen);

	localBlue = gainChannel (localBlue, gainBlue);
	localBlue = gammaChannel (localBlue, gammaBlue);
	localBlue = offsetChannel (localBlue, offsetBlue);

	float maxLighten = 0.0;
	float intermediateResult = 0.0;

	// If screen is blue, apply calculations. If not, then it's green, then apply calculations.
	if ( screenType )
	{
		maxLighten = max (localRed, localGreen);
		intermediateResult = localBlue - maxLighten;
	}

	else

	{
		maxLighten = max (localRed, localBlue);
		intermediateResult = localGreen - maxLighten;
	}

	//Apply color correction on this intermediate result
	intermediateResult = gainChannel (intermediateResult, matteGain);
	intermediateResult = contrastOffsetChannel (intermediateResult, matteContrast, matteOffset);

	// Clamp Intermediate Matte
	intermediateResult = clamp(intermediateResult, 0.0, 1.0);
	intermediateResult = gammaChannel (intermediateResult, matteGamma);

	//Cutout the input matte from the intermediate matte
	if( cutoutMatte )
	{
		inputMatte.r = 1.0 - inputMatte.r;
		intermediateResult *= inputMatte.r;
	}

	// Comp the front over the reference color using this intermediate matte
	vec3 comp = referenceColor;
	comp = mix (comp, localFront, intermediateResult);

	// Subtract the above from the reference color
	vec3 colorDifference = referenceColor - comp;

	// Multiply this result by the intermediate matte
	if (multiplyMatte)
	{
		colorDifference *= intermediateResult;
	}
	// Add the above result to the front
	localFront += colorDifference;

	// Output result and intermediate matte
	gl_FragColor = vec4 (localFront, intermediateResult);
}

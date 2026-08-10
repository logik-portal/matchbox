uniform float adsk_time, adsk_result_w, adsk_result_h;

// "front" is unused - present only because Flame's Matchbox requires a Front
// input alongside any other texture input on a generator node.
uniform sampler2D front;
// Optional external sprite image (e.g. 1000x1000, with alpha) drawn in place
// of the procedural glow/core shape when Use External Input is on.
uniform sampler2D sprite;
uniform sampler2D spriteAlpha;     // dedicated alpha/matte feed for sprite, read as luminance
uniform bool UseSprite;
uniform float SpriteSize;
uniform sampler2D heroSprite;
uniform sampler2D heroSpriteAlpha; // dedicated alpha/matte feed for heroSprite
uniform bool HeroUseSprite;
uniform float HeroSpriteSize;

uniform int Count;
uniform float Seed;
uniform float EdgeMargin;
uniform float DriftSpeed;
uniform float DriftAmount;
uniform float FlashSpeed;
uniform float FlashRandomness;
uniform float FlashAttack;
uniform float FlashDecayPower;
uniform float FlashSparsity;
uniform float ColorR, ColorG, ColorB;
uniform float Brightness;
uniform float TwinkleVariation;
uniform float GlowSize;
uniform float CoreSize;
uniform float CoreBrightness;

uniform float ZSpeed;
uniform float ZNear;
uniform float ZFar;
uniform float Spread;
uniform float TargetX;
uniform float TargetY;
uniform float TargetLooseness;
uniform bool ShowTarget;

uniform bool HeroEnable;
uniform float HeroSpeed;
uniform float HeroWander;
uniform float HeroTargetX;
uniform float HeroTargetY;
uniform bool ShowHeroTarget;
uniform float HeroZSpeed;
uniform float HeroZNear;
uniform float HeroZFar;
uniform float HeroColorR, HeroColorG, HeroColorB;
uniform float HeroBrightness;
uniform float HeroGlowSize;
uniform float HeroCoreSize;
uniform float HeroCoreBrightness;
uniform float HeroPulseSpeed;
uniform float HeroPulseDepth;

vec2 iResolution = vec2(adsk_result_w, adsk_result_h);

float luminance(vec3 c)
{
	return dot(c, vec3(0.2126, 0.7152, 0.0722));
}

float hash11(float p)
{
	p = fract(p * 0.1031);
	p *= p + 33.33;
	p *= p + p;
	return fract(p);
}

vec2 hash21(float p)
{
	vec3 p3 = fract(vec3(p) * vec3(0.1031, 0.1030, 0.0973));
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.xx + p3.yz) * p3.zy);
}

float flashEnvelope(float cyclePos, float attack, float decayPower)
{
	float a = clamp(attack, 0.001, 0.999);
	if (cyclePos < a) {
		return cyclePos / a;
	}
	float decay = (cyclePos - a) / (1.0 - a);
	return pow(max(1.0 - decay, 0.0), max(decayPower, 0.001));
}

void main(void)
{
	vec2 fragPix = gl_FragCoord.xy;
	vec3 col = vec3(ColorR, ColorG, ColorB);
	vec3 acc = vec3(0.0);

	for (int i = 0; i < Count; i++) {
		float fi = float(i) + Seed * 1000.0;

		vec2 home = mix(vec2(EdgeMargin) * iResolution, vec2(1.0 - EdgeMargin) * iResolution, hash21(fi));

		// Depth: each firefly starts close/huge (z=ZNear, "out of camera")
		// and travels away to far/tiny (z=ZFar, "into the distance"), then
		// loops. zPhase staggers fireflies so they don't all reset in sync.
		float zPhase = hash11(fi * 17.3 + 9.0);
		float zCycle = fract(adsk_time * ZSpeed + zPhase);
		float zNear  = clamp(ZNear, 0.005, 1.0);
		float zFar   = max(ZFar, zNear + 0.01);
		float z      = mix(zNear, zFar, zCycle);
		float sizeMult = 1.0 / z;

		// Perspective sweep: project the home offset from a vanishing point
		// outward as sizeMult grows, so close/huge fireflies swoop toward
		// the edges while far/tiny ones cluster near the vanishing point.
		// Spread=0 keeps them anchored in place (only the size changes);
		// Spread=1 is a full perspective sweep.
		//
		// The vanishing point is Target +/- a per-firefly random jitter
		// (TargetLooseness) rather than one exact pixel - 0 looseness means
		// every firefly converges to precisely the same point (tight, like
		// a real single vanishing point), higher values scatter each
		// firefly's own convergence point loosely around Target instead.
		// Animate TargetX/TargetY to fake the trajectory implied by a
		// camera move.
		vec2 targetPoint = vec2(TargetX, TargetY) * iResolution;
		vec2 targetJitter = (hash21(fi + 91.0) * 2.0 - 1.0) * TargetLooseness * iResolution.y;
		vec2 vanishPoint = targetPoint + targetJitter;

		vec2 worldOffset = home - vanishPoint;
		vec2 projOffset = worldOffset * mix(1.0, sizeMult, clamp(Spread, 0.0, 2.0));
		vec2 depthHome = vanishPoint + projOffset;

		// Fade in/out right at the loop boundary so the near<-far reset
		// isn't a visible pop - it happens while fully transparent instead.
		float depthFade = smoothstep(0.0, 0.05, zCycle) * (1.0 - smoothstep(0.85, 1.0, zCycle));

		vec2 driftPhase = hash21(fi + 47.0) * 6.28318;
		float driftFreq = mix(0.6, 1.4, hash11(fi * 3.71 + 8.0));
		float driftRadiusPix = DriftAmount * iResolution.y;
		vec2 drift = driftRadiusPix * vec2(
			sin(adsk_time * DriftSpeed * driftFreq + driftPhase.x),
			cos(adsk_time * DriftSpeed * driftFreq * 0.85 + driftPhase.y)
		);

		vec2 pos = depthHome + drift;

		float freqVar = mix(1.0 - FlashRandomness, 1.0 + FlashRandomness, hash11(fi * 7.91 + 4.0));
		float phaseOffset = hash11(fi * 2.53 + 1.0);
		float cyclePos = adsk_time * FlashSpeed * freqVar + phaseOffset;
		float cycleIndex = floor(cyclePos);
		float cycleFrac = fract(cyclePos);

		float sparsityRoll = hash11(fi * 11.3 + cycleIndex * 3.7);
		float env = (sparsityRoll < FlashSparsity)
			? flashEnvelope(cycleFrac, FlashAttack, FlashDecayPower)
			: 0.0;

		float twinkle = mix(1.0 - TwinkleVariation, 1.0 + TwinkleVariation, hash11(fi * 5.13 + 2.0));

		float dist = length(fragPix - pos);
		float glowRadiusPix = max(GlowSize, 0.0001) * iResolution.y * sizeMult;
		float coreRadiusPix = max(CoreSize, 0.0001) * iResolution.y * sizeMult;

		float envelope = env * twinkle * Brightness * depthFade;

		if (UseSprite) {
			// Replace the procedural glow/core with the fed-in image, scaled
			// by the same GlowSize/depth sizing already used everywhere else
			// so it responds correctly to Size, Z depth and Spread. Sample
			// bounds are checked explicitly - outside the sprite's own square
			// footprint we contribute nothing, rather than letting
			// CLAMP_TO_EDGE smear the image's edge pixels across the frame.
			float spriteRadiusPix = glowRadiusPix * 1.6 * max(SpriteSize, 0.0001);
			vec2 localUV = (fragPix - pos) / (spriteRadiusPix * 2.0) + 0.5;
			if (localUV.x >= 0.0 && localUV.x <= 1.0 && localUV.y >= 0.0 && localUV.y <= 1.0) {
				vec4 spriteSample = texture2D(sprite, localUV);
				float spriteMask = luminance(texture2D(spriteAlpha, localUV).rgb);
				acc += envelope * spriteSample.rgb * spriteMask;
			}
		} else {
			float glow = exp(-(dist * dist) / (2.0 * glowRadiusPix * glowRadiusPix));
			float core = smoothstep(coreRadiusPix, coreRadiusPix * 0.25, dist);
			acc += envelope * col * (glow + core * CoreBrightness);
		}
	}

	// ── Hero firefly ─────────────────────────────────────────────────────
	// A single always-lit firefly that weaves organically in front of the
	// swarm - its own screen wander and depth wander, each built from three
	// sine terms at incommensurate frequencies so the path never feels like
	// an obvious repeating loop. Large enough wander can carry it briefly
	// off-screen and back.
	if (HeroEnable) {
		// Where the hero is roughly attracted to - its wander orbits this
		// point rather than always the dead centre of frame.
		vec2 heroCentre = vec2(HeroTargetX, HeroTargetY) * iResolution;

		float t = adsk_time * HeroSpeed;
		vec2 heroWander = vec2(
			sin(t * 0.90 + 1.3) * 0.5 + sin(t * 1.456 + 3.1) * 0.3 + sin(t * 2.170 + 5.7) * 0.2,
			cos(t * 0.80 + 2.0) * 0.5 + cos(t * 1.164 + 0.6) * 0.3 + cos(t * 0.700 + 4.2) * 0.2
		);
		vec2 heroPos = heroCentre + heroWander * HeroWander * iResolution.y;

		float zt = adsk_time * HeroZSpeed;
		float zWander = sin(zt * 0.70 + 0.4) * 0.5 + sin(zt * 1.30 + 2.1) * 0.3 + sin(zt * 0.45 + 4.4) * 0.2;
		float zNorm = clamp(zWander * 0.5 + 0.5, 0.0, 1.0);
		float heroZNear = clamp(HeroZNear, 0.005, 1.0);
		float heroZFar = max(HeroZFar, heroZNear + 0.01);
		float heroZ = mix(heroZNear, heroZFar, zNorm);
		float heroSizeMult = 1.0 / heroZ;

		// Gentle continuous breathing rather than sparse flashing - the
		// hero should stay reliably visible as the centre of attention.
		float heroPulse = 1.0 - HeroPulseDepth * 0.5 * (1.0 + sin(adsk_time * HeroPulseSpeed * 6.28318));

		float heroDist = length(fragPix - heroPos);
		float heroGlowRadius = max(HeroGlowSize, 0.0001) * iResolution.y * heroSizeMult;
		float heroCoreRadius = max(HeroCoreSize, 0.0001) * iResolution.y * heroSizeMult;

		float heroEnvelope = heroPulse * HeroBrightness;

		if (HeroUseSprite) {
			// Same convention as the swarm's Use External Input - replace the
			// procedural shape entirely, scaled by Hero Glow Size/depth, with
			// bounds checked explicitly so nothing smears past the sprite's
			// own footprint.
			float heroSpriteRadius = heroGlowRadius * 1.6 * max(HeroSpriteSize, 0.0001);
			vec2 heroLocalUV = (fragPix - heroPos) / (heroSpriteRadius * 2.0) + 0.5;
			if (heroLocalUV.x >= 0.0 && heroLocalUV.x <= 1.0 && heroLocalUV.y >= 0.0 && heroLocalUV.y <= 1.0) {
				vec4 heroSpriteSample = texture2D(heroSprite, heroLocalUV);
				float heroSpriteMask = luminance(texture2D(heroSpriteAlpha, heroLocalUV).rgb);
				acc += heroEnvelope * heroSpriteSample.rgb * heroSpriteMask;
			}
		} else {
			float heroGlow = exp(-(heroDist * heroDist) / (2.0 * heroGlowRadius * heroGlowRadius));
			float heroCore = smoothstep(heroCoreRadius, heroCoreRadius * 0.25, heroDist);
			vec3 heroCol = vec3(HeroColorR, HeroColorG, HeroColorB);
			acc += heroEnvelope * heroCol * (heroGlow + heroCore * HeroCoreBrightness);
		}
	}

	// ── Target crosshair guide ───────────────────────────────────────────
	// Setup aid only - drawn last, on top of everything, so it's always
	// visible while lining Target X/Y up against a plate's camera move.
	if (ShowTarget) {
		vec2 targetPoint = vec2(TargetX, TargetY) * iResolution;
		vec2 delta = fragPix - targetPoint;
		float dist = length(delta);

		float armLen = 0.035 * iResolution.y;
		float ringRadius = 0.012 * iResolution.y;
		float thickness = 1.5;

		bool onHorizontal = abs(delta.y) < thickness && abs(delta.x) < armLen && abs(delta.x) > ringRadius * 0.6;
		bool onVertical   = abs(delta.x) < thickness && abs(delta.y) < armLen && abs(delta.y) > ringRadius * 0.6;
		bool onRing       = abs(dist - ringRadius) < thickness;

		if (onHorizontal || onVertical || onRing) {
			acc = vec3(1.0, 0.15, 0.15);
		}
	}

	// ── Hero target crosshair guide ──────────────────────────────────────
	// Setup aid only - blue, to tell it apart from the swarm's red Target
	// guide. Independent of Hero Enable, so you can line it up before
	// switching the hero on.
	if (ShowHeroTarget) {
		vec2 heroTargetPoint = vec2(HeroTargetX, HeroTargetY) * iResolution;
		vec2 delta = fragPix - heroTargetPoint;
		float dist = length(delta);

		float armLen = 0.035 * iResolution.y;
		float ringRadius = 0.012 * iResolution.y;
		float thickness = 1.5;

		bool onHorizontal = abs(delta.y) < thickness && abs(delta.x) < armLen && abs(delta.x) > ringRadius * 0.6;
		bool onVertical   = abs(delta.x) < thickness && abs(delta.y) < armLen && abs(delta.y) > ringRadius * 0.6;
		bool onRing       = abs(dist - ringRadius) < thickness;

		if (onHorizontal || onVertical || onRing) {
			acc = vec3(0.2, 0.5, 1.0);
		}
	}

	gl_FragColor = vec4(acc, 1.0);
}

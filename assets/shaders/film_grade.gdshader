shader_type canvas_item;

uniform float vignette_strength : hint_range(0.0, 1.0) = 0.36;
uniform float grain_strength : hint_range(0.0, 0.15) = 0.025;
uniform vec4 tint_color : source_color = vec4(0.14, 0.09, 0.05, 0.06);

float rand_grain(vec2 uv, float t) {
	return fract(sin(dot(uv + vec2(t * 0.17, t * 0.31), vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	vec2 centered = UV - vec2(0.5);
	float dist = length(centered * vec2(1.15, 0.95));
	float vig = smoothstep(0.38, 0.96, dist) * vignette_strength;
	float grain = (rand_grain(UV * 420.0, floor(TIME * 24.0)) - 0.5) * grain_strength;

	vec3 col = mix(tint_color.rgb, vec3(0.02, 0.015, 0.01), clamp(vig * 1.5, 0.0, 1.0));
	col += vec3(grain);
	float alpha = clamp(tint_color.a + vig, 0.0, 0.65);
	COLOR = vec4(col, alpha);
}

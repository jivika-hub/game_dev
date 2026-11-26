shader_type spatial;
render_mode unshaded, cull_disabled, blend_add;

uniform vec3 outer_color : source_color = vec3(0.24, 0.78, 0.96);
uniform vec3 inner_color : source_color = vec3(0.98, 0.78, 0.36);
uniform float openness = 1.0;

void fragment() {
	vec2 p = (UV - vec2(0.5)) * 2.0;
	float r = length(p);
	float angle = atan(p.y, p.x);

	float swirl = sin(angle * 6.0 - TIME * 2.2 + r * 8.0) * 0.5 + 0.5;
	float rings = sin(r * 18.0 - TIME * 3.5) * 0.5 + 0.5;
	float core_mask = smoothstep(1.0, 0.12, r);
	float edge_ring = smoothstep(0.96, 0.68, r) * smoothstep(0.38, 0.72, r);

	vec3 col = mix(outer_color, inner_color, clamp(core_mask * 0.8 + swirl * 0.35, 0.0, 1.0));
	col *= (0.7 + 0.6 * rings);
	float alpha = (core_mask * 0.55 + edge_ring * 0.95) * openness;

	ALBEDO = col * 1.8;
	ALPHA = clamp(alpha, 0.0, 1.0);
}

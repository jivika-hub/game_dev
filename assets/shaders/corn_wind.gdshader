shader_type spatial;
render_mode cull_disabled, diffuse_burley, specular_schlick_ggx;

uniform vec3 base_color : source_color = vec3(0.46, 0.42, 0.22);
uniform vec3 tip_color : source_color = vec3(0.68, 0.56, 0.30);
uniform float wind_speed = 1.65;
uniform float wind_strength = 0.24;
uniform float gust_scale = 0.08;
uniform float stalk_height = 2.6;

varying float height_factor;

void vertex() {
	vec3 world_pos = (MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
	height_factor = clamp((VERTEX.y + stalk_height * 0.5) / max(stalk_height, 0.01), 0.0, 1.0);
	float bend = height_factor * height_factor;

	float phase = world_pos.x * gust_scale + world_pos.z * (gust_scale * 0.75);
	float gust = sin(TIME * wind_speed + phase) * 0.65 + sin(TIME * (wind_speed * 2.13) + phase * 1.9) * 0.35;
	float cross_sway = cos(TIME * (wind_speed * 0.85) + world_pos.z * 0.14) * 0.35;

	VERTEX.x += gust * wind_strength * bend;
	VERTEX.z += cross_sway * wind_strength * 0.55 * bend;
}

void fragment() {
	vec3 col = mix(base_color, tip_color, smoothstep(0.15, 0.95, height_factor));
	// Slight dusty darkening near base of stalk
	col *= mix(0.68, 1.05, height_factor);
	ALBEDO = col;
	ROUGHNESS = 0.88;
	METALLIC = 0.0;
	SPECULAR = 0.15;
}

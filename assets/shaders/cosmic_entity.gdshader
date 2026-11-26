shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, specular_schlick_ggx;

uniform vec3 core_color : source_color = vec3(0.03, 0.04, 0.08);
uniform vec3 rim_color_a : source_color = vec3(0.95, 0.72, 0.34);
uniform vec3 rim_color_b : source_color = vec3(0.35, 0.85, 0.96);
uniform float pulse_intensity = 1.6;
uniform float distortion_amp = 0.28;
uniform float distortion_freq = 2.4;

varying vec3 local_pos;

float hash3(vec3 p) {
	return fract(sin(dot(p, vec3(127.1, 311.7, 74.7))) * 43758.5453123);
}

void vertex() {
	local_pos = VERTEX;
	float t = TIME * 0.9;
	float wave_a = sin(VERTEX.x * distortion_freq + t) * cos(VERTEX.y * distortion_freq - t * 0.7);
	float wave_b = sin(VERTEX.z * (distortion_freq * 1.6) + t * 1.35);
	float displace = (wave_a + wave_b * 0.5) * distortion_amp;
	VERTEX += NORMAL * displace;
}

void fragment() {
	float fresnel = pow(1.0 - clamp(dot(normalize(NORMAL), normalize(VIEW)), 0.0, 1.0), 2.6);
	float shift = 0.5 + 0.5 * sin(TIME * 0.8 + local_pos.y * 2.5 + local_pos.x * 1.8);
	vec3 rim = mix(rim_color_a, rim_color_b, shift);
	float vein = smoothstep(0.65, 0.95, abs(sin(local_pos.y * 6.0 - TIME * 1.6) * cos(local_pos.x * 5.0 + TIME)));

	ALBEDO = core_color;
	METALLIC = 0.85;
	ROUGHNESS = 0.14;
	EMISSION = rim * (fresnel * 2.4 + vein * 0.9) * pulse_intensity;
}

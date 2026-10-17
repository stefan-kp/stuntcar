shader_type spatial;
uniform sampler2D ground_color : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D ground_normal : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D rock_color : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform bool snowy = false;
varying vec3 terrain_position;
varying vec3 terrain_normal;
void vertex() {
	terrain_position = VERTEX;
	terrain_normal = NORMAL;
}
void fragment() {
	vec3 p = terrain_position;
	vec3 weights = pow(abs(normalize(terrain_normal)), vec3(4.0));
	weights /= max(weights.x + weights.y + weights.z, 0.001);
	vec3 rock = texture(rock_color, p.zy / 11.0).rgb * weights.x
		+ texture(rock_color, p.xz / 11.0).rgb * weights.y
		+ texture(rock_color, p.xy / 11.0).rgb * weights.z;
	vec2 uv = p.xz / (snowy ? 5.0 : 4.5);
	vec3 ground = texture(ground_color, uv).rgb;
	float variation = sin(p.x * 0.031 + sin(p.z * 0.021)) * 0.035;
	float slope = 1.0 - normalize(terrain_normal).y;
	float exposed = smoothstep(snowy ? 0.24 : 0.18, snowy ? 0.58 : 0.48, slope);
	vec3 tint = snowy ? vec3(0.91, 0.96, 1.0) : vec3(1.0, 0.76, 0.48);
	ALBEDO = mix(ground * tint * (0.96 + variation), rock * (snowy ? vec3(0.65, 0.71, 0.78) : vec3(0.9, 0.72, 0.56)), exposed);
	NORMAL_MAP = texture(ground_normal, uv).rgb;
	NORMAL_MAP_DEPTH = (1.0 - exposed) * 0.32;
	ROUGHNESS = 0.93;
}

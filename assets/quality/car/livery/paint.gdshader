shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx, cull_disabled;

uniform sampler2D color_map : source_color, filter_linear_mipmap_anisotropic, repeat_disable;
uniform sampler2D flake_map : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform mat4 mesh_to_car;
varying vec2 livery_uv;

void vertex() {
	// All panels share the same car-space projection, independent of their UV islands.
	vec3 car_position = (mesh_to_car * vec4(VERTEX, 1.0)).xyz;
	livery_uv = vec2(car_position.x / 2.23603 + 0.5, (car_position.z + 1.940231) / 4.357386);
}

void fragment() {
	vec3 color = texture(color_map, livery_uv).rgb;
	float neutral = 1.0 - smoothstep(0.04, 0.25, max(color.r, max(color.g, color.b)) - min(color.r, min(color.g, color.b)));
	float silver = neutral * smoothstep(0.12, 0.5, dot(color, vec3(0.2126, 0.7152, 0.0722)));
	ALBEDO = color;
	METALLIC = mix(0.72, 0.95, silver);
	ROUGHNESS = mix(0.24, 0.21, silver);
	CLEARCOAT = 1.0;
	CLEARCOAT_ROUGHNESS = 0.1;
	NORMAL_MAP = texture(flake_map, UV * 30.0).rgb;
	NORMAL_MAP_DEPTH = 0.08;
}

shader_type spatial;
render_mode cull_disabled;
uniform sampler2D base_color : source_color, filter_linear_mipmap_anisotropic;
uniform sampler2D snow_color : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform bool foliage = false;
varying vec3 world_normal;
varying vec3 world_position;
void vertex() {
	world_normal = normalize(MODEL_NORMAL_MATRIX * NORMAL);
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}
void fragment() {
	vec4 base = texture(base_color, UV);
	if (foliage && base.a < 0.38) { discard; }
	float upward = dot(normalize(world_normal), vec3(0.0, 1.0, 0.0));
	float snow = foliage ? 0.30 + 0.65 * smoothstep(0.0, 0.75, abs(upward)) : smoothstep(0.25, 0.8, upward);
	vec3 white = texture(snow_color, world_position.xz * 0.6).rgb;
	ALBEDO = mix(base.rgb * (foliage ? vec3(0.6, 0.7, 0.7) : vec3(0.7, 0.78, 0.85)), white * vec3(0.91, 0.96, 1.0), snow * 0.95);
	ROUGHNESS = 0.94;
}

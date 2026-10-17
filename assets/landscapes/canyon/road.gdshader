shader_type spatial;
render_mode cull_disabled;
uniform sampler2D color_map : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D normal_map : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D arm_map : filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D gravel_map : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
void fragment() {
    vec3 aggregate = texture(color_map, UV).rgb;
    float gray = dot(aggregate, vec3(.299,.587,.114));
    float edge = abs(UV.x - 1.5) / 1.5;
    float patch = texture(gravel_map, UV * .19 + vec2(.7,1.2)).r;
    float dust = smoothstep(.73 + patch*.35, 1.04, edge);
    float wheel = exp(-pow((abs(UV.x-1.5)-.69)*11.0,2.0));
    vec3 asphalt = max(mix(aggregate, vec3(gray), .85)*2.0, vec3(.045)) * (1.0-wheel*.12);
    float lines = (1.0-smoothstep(.018,.026,abs(abs(UV.x-1.5)-.055)));
    float white_edge = 1.0-smoothstep(.021,.031,abs(abs(UV.x-1.5)-1.29));
    float wear = clamp(gray*12.0 + .48, .3, .9) * (1.0 - dust);
    asphalt = mix(asphalt, vec3(.57,.40,.115), lines*wear);
    asphalt = mix(asphalt, vec3(.59,.57,.51), white_edge*wear);
    vec3 gravel = texture(gravel_map,UV*.8).rgb * vec3(.72,.65,.55);
    ALBEDO = mix(asphalt,gravel,dust*.82);
    NORMAL_MAP = texture(normal_map,UV).rgb;
    NORMAL_MAP_DEPTH = .45;
    ROUGHNESS = clamp(texture(arm_map,UV).g + .18, .65, .98);
    SPECULAR = .25;
}

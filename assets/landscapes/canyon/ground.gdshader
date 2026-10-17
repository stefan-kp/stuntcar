shader_type spatial;
#include "surface_sampling.gdshaderinc"
uniform sampler2D color_map : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D normal_map : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D rough_map : filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D cliff_map : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
varying vec3 world_pos;
varying vec3 world_normal;
void vertex() {
    world_pos = (MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
    world_normal = normalize(MODEL_NORMAL_MATRIX*NORMAL);
}
void fragment() {
    vec2 uv = world_pos.xz/2.53;
    vec3 gravel = surface_sample(color_map,uv).rgb;
    float far_blend = smoothstep(25.0,120.0,length(VERTEX));
    vec3 distant_gravel = textureLod(color_map,uv*.15,8.0).rgb;
    gravel = mix(gravel,distant_gravel,far_blend);
    float variation = mix(.75,1.12,surface_noise(world_pos.xz*.038));
    vec3 weights = pow(abs(world_normal),vec3(4.0));
    weights /= max(weights.x+weights.y+weights.z,.001);
    vec3 p = world_pos/4.0;
    vec3 cliff = surface_sample(cliff_map,p.zy).rgb*weights.x + surface_sample(cliff_map,p.xz).rgb*weights.y + surface_sample(cliff_map,p.xy).rgb*weights.z;
    float slope = smoothstep(.36,.68,1.0-world_normal.y);
    // Keep shallow hills gravel-covered. Projected cliff strata made false contour bands.
    ALBEDO = mix(gravel*vec3(.82,.76,.68)*variation,cliff*vec3(.57,.43,.32),slope*.3*(1.0-far_blend));
    vec3 bump = surface_sample(normal_map,uv).xyz*2.0-1.0;
    float distance_fade = 1.0-smoothstep(20.0,95.0,length(VERTEX));
    vec3 n = normalize(world_normal+vec3(bump.x,0.0,bump.y)*.4*(1.0-slope)*distance_fade);
    NORMAL = normalize((VIEW_MATRIX*vec4(n,0.0)).xyz);
    ROUGHNESS = clamp(texture(rough_map,uv).r*.35+.6,.7,1.0);
    SPECULAR = .18;
}

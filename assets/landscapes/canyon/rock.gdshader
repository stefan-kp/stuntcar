shader_type spatial;
#include "surface_sampling.gdshaderinc"
uniform sampler2D color_map : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D rough_map : filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D normal_map : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform vec3 sandstone_tint : source_color = vec3(0.91, 0.81, 0.69);
varying vec3 world_pos;
varying vec3 world_normal;
void vertex() {
    world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
    world_normal = normalize(MODEL_NORMAL_MATRIX * NORMAL);
}
void fragment() {
    vec3 w = pow(abs(world_normal), vec3(5.0));
    w /= max(w.x+w.y+w.z, 0.001);
    vec3 p = world_pos / 2.7;
    vec3 rock = surface_sample(color_map,p.zy).rgb*w.x + surface_sample(color_map,p.xz).rgb*w.y + surface_sample(color_map,p.xy).rgb*w.z;
    vec3 macro = texture(color_map,p.zy*.17).rgb*w.x + texture(color_map,p.xz*.17).rgb*w.y + texture(color_map,p.xy*.17).rgb*w.z;
    float strata = sin(world_pos.y*.43 + sin(world_pos.x*.08)*.5 + sin(world_pos.z*.06)*.4);
    float broad = mix(.79,1.08,strata*.5+.5);
    float mineral = clamp(dot(macro,vec3(.333))*2.5,.68,1.12);
    ALBEDO = rock * sandstone_tint * broad * mineral;
    ROUGHNESS = clamp((texture(rough_map,p.zy).r*w.x + texture(rough_map,p.xz).r*w.y + texture(rough_map,p.xy).r*w.z)*.65+.3,.6,1.0);
    SPECULAR = .22;
    vec3 nx = surface_sample(normal_map,p.zy).xyz*2.0-1.0;
    vec3 ny = surface_sample(normal_map,p.xz).xyz*2.0-1.0;
    vec3 nz = surface_sample(normal_map,p.xy).xyz*2.0-1.0;
    vec3 detail = vec3(0.0,nx.y,nx.x)*w.x + vec3(ny.x,0.0,ny.y)*w.y + vec3(nz.x,nz.y,0.0)*w.z;
    NORMAL = normalize((VIEW_MATRIX*vec4(normalize(world_normal+detail*.65),0.0)).xyz);
}

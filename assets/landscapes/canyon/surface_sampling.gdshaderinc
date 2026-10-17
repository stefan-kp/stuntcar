vec2 surface_hash(vec2 p) {
    return fract(sin(vec2(dot(p,vec2(127.1,311.7)),dot(p,vec2(269.5,183.3))))*43758.5453);
}
float surface_noise(vec2 p) {
    vec2 cell = floor(p);
    vec2 f = fract(p);
    f = f*f*(3.0-2.0*f);
    return mix(mix(surface_hash(cell).x,surface_hash(cell+vec2(1,0)).x,f.x),
        mix(surface_hash(cell+vec2(0,1)).x,surface_hash(cell+vec2(1,1)).x,f.x),f.y);
}
vec4 surface_sample(sampler2D source, vec2 uv) {
    float selector = surface_noise(uv*.23)*7.0;
    float cell = floor(selector);
    vec2 dx = dFdx(uv);
    vec2 dy = dFdy(uv);
    vec4 a = textureGrad(source,uv+surface_hash(vec2(cell,2.0))*13.0,dx,dy);
    vec4 b = textureGrad(source,uv+surface_hash(vec2(cell+1.0,2.0))*13.0,dx,dy);
    return mix(a,b,smoothstep(.15,.85,fract(selector)));
}

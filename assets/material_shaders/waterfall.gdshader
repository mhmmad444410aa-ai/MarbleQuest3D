shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, blend_mix;
uniform float opacity : hint_range(0.0, 1.0) = 0.65;
void fragment() {
    float t = TIME * 1.5;
    float stripe = sin(UV.x * 77.0 + sin(UV.y * 13.0 - t) * 1.4);
    float wave = sin(UV.y * 38.0 - t * 7.0 + UV.x * 8.0);
    float foam = smoothstep(0.5, 0.98, stripe * 0.7 + wave * 0.3);
    float edge = smoothstep(0.0, 0.12, UV.x) * (1.0 - smoothstep(0.88, 1.0, UV.x));
    float fade = 1.0 - smoothstep(0.82, 1.0, UV.y);
    ALBEDO = mix(vec3(0.16,0.61,0.81),vec3(0.86,0.98,1.0),foam);
    ALPHA = opacity * edge * fade * (0.55 + foam * 0.45);
}

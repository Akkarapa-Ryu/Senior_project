shader_type spatial;
render_mode blend_add, depth_draw_always, unshaded;
uniform vec4 color : source_color = vec4(1.0, 1.0, 0.0, 0.0);
uniform float softness : hint_range(1.0, 10.0) = 9;

void fragment() {
	ALBEDO = color.rgb;
	//float base_alpha = (1.0 - softness);
	//ALPHA = mix(softness, base_alpha, 0.5);
}

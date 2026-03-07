//shader_type spatial;
//render_mode cull_disabled, depth_draw_always;
//
//varying vec3 local_pos;
//varying vec3 world_normal;
//varying vec2 tex_uv; // ส่งค่า UV จาก Vertex ไป Fragment
//
//group_uniforms Base_Material;
//uniform sampler2D main_texture : source_color; // <--- ใส่ Texture เดิมของผิวหนัง/สมองที่นี่
//uniform vec4 base_tint : source_color = vec4(1.0);
//
//group_uniforms Slicing;
//uniform int slice_axis : hint_range(0, 2) = 1;
//uniform float slice_height : hint_range(-1.0, 1.0, 0.01) = 0.0;
//uniform vec3 edge_color : source_color = vec3(0.0, 1.0, 0.5);
//uniform float edge_thickness : hint_range(0.0, 0.2) = 0.05;
//
//group_uniforms Interior;
//uniform vec3 inside_color : source_color = vec3(0.6, 0.2, 0.2);
//uniform sampler2D inside_noise_texture : hint_default_white, filter_linear_mipmap_anisotropic;
//uniform float noise_scale : hint_range(0.1, 10.0) = 2.0;
//
//vec4 triplanar_texture(sampler2D p_sampler, vec3 p_weights, vec3 p_triplanar_pos) {
	//vec4 samp=vec4(0.0);
	//samp+= texture(p_sampler,p_triplanar_pos.xy) * p_weights.z;
	//samp+= texture(p_sampler,p_triplanar_pos.xz) * p_weights.y;
	//samp+= texture(p_sampler,p_triplanar_pos.zy * vec2(-1.0,1.0)) * p_weights.x;
	//return samp;
//}
//
//void vertex() {
	//local_pos = VERTEX;
	//tex_uv = UV; // เก็บค่า UV เดิมของโมเดลไว้
	//world_normal = (MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz;
//}
//
//void fragment() {
	//float current_pos;
	//if (slice_axis == 0) current_pos = local_pos.x;
	//else if (slice_axis == 1) current_pos = local_pos.y;
	//else current_pos = local_pos.z;
//
	//// 1. การตัด (Discard) - ส่วนนี้ทำให้มองทะลุได้
	//if (current_pos > slice_height) {
		//discard;
	//}
//
	//vec3 normal = normalize(world_normal);
//
	//// 2. การระบายสี
	//if (!FRONT_FACING) {
		//// --- ด้านใน (Cross-section) ---
		//vec3 weights = abs(normal);
		//weights /= (weights.x + weights.y + weights.z);
		//vec3 world_pos = (MODEL_MATRIX * vec4(local_pos, 1.0)).xyz;
		//float noise_val = triplanar_texture(inside_noise_texture, weights, world_pos * noise_scale).r;
		//ALBEDO = inside_color * (0.5 + noise_val * 0.5);
	//} else {
		//// --- ด้านนอก (ผิวเดิมของโมเดล) ---
		//vec4 tex = texture(main_texture, tex_uv); // <--- ดึงสีจาก Texture เดิมมาใช้
		//ALBEDO = tex.rgb * base_tint.rgb;
	//}
//
	//// 3. ขอบเรืองแสง
	//if (current_pos > slice_height - edge_thickness && FRONT_FACING) {
		//float edge_intensity = 1.0 - (slice_height - current_pos) / edge_thickness;
		//EMISSION = edge_color * edge_intensity * 5.0;
	//}
//}

shader_type spatial;
render_mode cull_disabled, depth_draw_always, blend_mix;

varying vec3 local_pos;
varying vec3 world_normal;
varying vec2 tex_uv;

//////////////////////////////////////
// BASE MATERIAL
//////////////////////////////////////
group_uniforms Base_Material;
uniform sampler2D main_texture : source_color;
uniform vec4 base_tint : source_color = vec4(1.0);
uniform float skin_alpha : hint_range(0.0, 1.0) = 1.0;

//////////////////////////////////////
// SLICING
//////////////////////////////////////
group_uniforms Slicing;
uniform int slice_axis : hint_range(0, 2) = 1;
uniform float slice_height : hint_range(-1.0, 1.0, 0.01) = 0.0;
uniform vec3 edge_color : source_color = vec3(0.0, 1.0, 0.5);
uniform float edge_thickness : hint_range(0.0, 0.2) = 0.05;

//////////////////////////////////////
// INTERIOR
//////////////////////////////////////
group_uniforms Interior;
uniform vec3 inside_color : source_color = vec3(0.6, 0.2, 0.2);
uniform sampler2D inside_noise_texture : hint_default_white;
uniform float noise_scale : hint_range(0.1, 10.0) = 2.0;

//////////////////////////////////////
// TRIPLANAR
//////////////////////////////////////
vec4 triplanar_texture(sampler2D tex, vec3 w, vec3 pos) {
	vec4 col = vec4(0.0);
	col += texture(tex, pos.xy) * w.z;
	col += texture(tex, pos.xz) * w.y;
	col += texture(tex, pos.zy * vec2(-1.0,1.0)) * w.x;
	return col;
}

//////////////////////////////////////
// VERTEX
//////////////////////////////////////
void vertex() {
	local_pos = VERTEX;
	tex_uv = UV;
	world_normal = (MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz;
}

//////////////////////////////////////
// FRAGMENT
//////////////////////////////////////
void fragment() {

	// --- เลือกแกน slice ---
	float current_pos;
	if (slice_axis == 0) current_pos = local_pos.x;
	else if (slice_axis == 1) current_pos = local_pos.y;
	else current_pos = local_pos.z;

	// --- ตัด geometry จริง ---
	if (current_pos > slice_height) {
		discard;
	}

	vec3 normal = normalize(world_normal);

	// --- Interior ---
	if (!FRONT_FACING) {
		vec3 w = abs(normal);
		w /= (w.x + w.y + w.z);

		vec3 world_pos = (MODEL_MATRIX * vec4(local_pos, 1.0)).xyz;
		float n = triplanar_texture(
			inside_noise_texture,
			w,
			world_pos * noise_scale
		).r;

		ALBEDO = inside_color * (0.5 + n * 0.5);
		ALPHA = 1.0;
		ROUGHNESS = 0.85;
		SPECULAR = 0.0;
	}
	// --- Exterior (Skin / Brain surface) ---
	else {
		vec4 tex = texture(main_texture, tex_uv);
		ALBEDO = tex.rgb * base_tint.rgb;
		ALPHA = tex.a * skin_alpha; // ← Blend ทำงานตรงนี้
		ROUGHNESS = 0.5;
		SPECULAR = 0.2;
	}

	// --- Edge Glow ---
	if (FRONT_FACING && current_pos > slice_height - edge_thickness) {
		float edge = 1.0 - (slice_height - current_pos) / edge_thickness;
		EMISSION = edge_color * edge * 5.0;
	}
}

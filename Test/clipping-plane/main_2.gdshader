shader_type spatial;
// cull_disabled คือหัวใจสำคัญ ทำให้เห็นด้านในที่เคยกลวง
render_mode cull_disabled, depth_draw_always; 

varying vec3 local_pos; // เพิ่มตัวแปรส่งค่าพิกัด Local

group_uniforms Slicing;
uniform float slice_height : hint_range(-2.0, 7.0, 0.01) = 0.5;
uniform vec3 edge_color : source_color = vec3(0.0, 1.0, 0.5); // สีขอบเรืองแสง
uniform float edge_thickness : hint_range(0.0, 0.1) = 0.05;

group_uniforms Interior;
uniform vec3 inside_color : source_color = vec3(0.6, 0.2, 0.2); // สีเนื้อแดงๆ
uniform sampler2D inside_noise_texture : hint_default_white, filter_linear_mipmap_anisotropic; // ใส่ภาพ Noise ตรงนี้
uniform float noise_scale : hint_range(0.1, 10.0) = 2.0; // ปรับขนาดลายเนื้อ

// ฟังก์ชันสำหรับแปะ Texture แบบไม่ง้อ UV (Triplanar)
vec4 triplanar_texture(sampler2D p_sampler, vec3 p_weights, vec3 p_triplanar_pos) {
	vec4 samp=vec4(0.0);
	samp+= texture(p_sampler,p_triplanar_pos.xy) * p_weights.z;
	samp+= texture(p_sampler,p_triplanar_pos.xz) * p_weights.y;
	samp+= texture(p_sampler,p_triplanar_pos.zy * vec2(-1.0,1.0)) * p_weights.x;
	return samp;
}

void vertex() {
	local_pos = VERTEX; // เก็บพิกัด Local ไว้ตั้งแต่ขั้นตอนนี้
}

void fragment() {
	// ใช้พิกัด Local แทนการคำนวณ World Pos
	float current_y = local_pos.y;

	// --- การตัด (Slicing) ---
	if (current_y > slice_height) {
		discard;
	}

	if (!FRONT_FACING) {
		vec3 normal = normalize(NORMAL);
		vec3 weights = abs(normal);
		weights /= (weights.x + weights.y + weights.z);
		
		// สำหรับเนื้อใน ใช้ local_pos เพื่อให้ลายเนื้อเลื่อนตามโมเดล
		vec3 noise_pos = local_pos * noise_scale;
		float noise_value = triplanar_texture(inside_noise_texture, weights, noise_pos).r;
		vec3 final_inside_color = inside_color * (0.5 + noise_value * 0.5);
		
		ALBEDO = final_inside_color;
		ROUGHNESS = 0.8;
		SPECULAR = 0.0;
	} else {
		ALBEDO = vec3(0.7, 0.7, 0.8);
		ROUGHNESS = 0.5;
	}
	
	if (current_y > slice_height - edge_thickness && FRONT_FACING) {
		float edge_intensity = 1.0 - (slice_height - current_y) / edge_thickness;
		EMISSION = edge_color * edge_intensity * 5.0;
	}
}
shader_type spatial;
// cull_disabled คือหัวใจสำคัญ ทำให้เห็นด้านในที่เคยกลวง
render_mode cull_disabled, depth_draw_always; 

group_uniforms Slicing;
uniform float slice_height : hint_range(-2.0, 2.0, 0.01) = 0.5;
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

void fragment() {
	// คำนวณตำแหน่ง Y ในโลกจริง
	vec3 world_pos = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float current_y = world_pos.y;

	// --- ส่วนที่ 1: การตัด (Slicing) ---
	if (current_y > slice_height) {
		discard;
	}

	// --- ส่วนที่ 2: การจัดการด้านใน/ด้านนอก ---
	if (!FRONT_FACING) {
		// >>> นี่คือส่วนที่อยู่ข้างใน (Backface) <<<
		
		// คำนวณ Triplanar weights เพื่อให้ลาย texture แปะได้เนียนตามมุมมอง
		vec3 normal = normalize(NORMAL);
		vec3 weights = abs(normal);
		weights /= (weights.x + weights.y + weights.z);
		
		// ดึงค่าสีจาก Noise Texture ตามตำแหน่งในโลก (ทำให้ลายดูอยู่นิ่งๆ เป็นก้อน)
		vec3 noise_pos = world_pos * noise_scale;
		float noise_value = triplanar_texture(inside_noise_texture, weights, noise_pos).r;
		
		// ผสมสีเนื้อเข้ากับลาย Noise
		// ยิ่ง noise_value มาก ยิ่งเข้ม (ปรับแต่งสูตรนี้ได้ตามชอบ)
		vec3 final_inside_color = inside_color * (0.5 + noise_value * 0.5);
		
		ALBEDO = final_inside_color;
		
		// ปรับให้ด้านในดูด้านๆ ไม่สะท้อนแสงมาก
		ROUGHNESS = 0.8;
		SPECULAR = 0.0;
		
		// เทคนิคเสริม: ทำให้ด้านในมืดลงเล็กน้อยตามความลึก เพื่อหลอกตาให้ดูมีมิติ
		// ALBEDO *= clamp(1.0 - (slice_height - current_y) * 0.5, 0.5, 1.0);

	} else {
		// >>> ส่วนที่เป็นผิวด้านนอกปกติ <<<
		// ใส่สีหรือ Texture ปกติของโมเดลตรงนี้
		ALBEDO = vec3(0.7, 0.7, 0.8); // ตัวอย่างสีเทา
		ROUGHNESS = 0.5;
	}
	
	// --- ส่วนที่ 3: ขอบเรืองแสง (Scan Line) ---
	// เช็คว่าอยู่ใกล้รอยตัดไหม และต้องเป็นผิวด้านนอกเท่านั้นถึงจะเรืองแสง
	if (current_y > slice_height - edge_thickness && FRONT_FACING) {
		// ยิ่งใกล้ยิ่งสว่าง
		float edge_intensity = 1.0 - (slice_height - current_y) / edge_thickness;
		EMISSION = edge_color * edge_intensity * 5.0; // คูณ 5 เพื่อให้สว่างจ้า
	}
}
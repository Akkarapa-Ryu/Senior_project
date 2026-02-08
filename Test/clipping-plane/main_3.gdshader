shader_type spatial;
// cull_disabled คือหัวใจสำคัญ ทำให้เห็นด้านในที่เคยกลวง
render_mode cull_disabled, depth_draw_always;

varying vec3 local_pos; // เพิ่มตัวแปรส่งค่าพิกัด Local

group_uniforms Slicing;
uniform float slice_height : hint_range(-2.0, 15.0, 0.01) = 0.5;
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
	// 1. ดึงทิศทางของกล้อง (ใน World Space แล้วแปลงเข้า Local Space เพื่อความแม่นยำ)
	// INV_VIEW_MATRIX[3].xyz คือตำแหน่งกล้องใน World Space
	// MODEL_MATRIX คือ Matrix ของวัตถุ
	vec3 camera_pos_world = INV_VIEW_MATRIX[3].xyz;
	vec3 camera_pos_local = (inverse(MODEL_MATRIX) * vec4(camera_pos_world, 1.0)).xyz;
	vec3 cam_dir_local = normalize(camera_pos_local - local_pos);

	float current_pos;
	vec3 abs_dir = abs(cam_dir_local);

	// 2. เลือกแกนการตัดตามทิศที่กล้องมอง (Dynamic Axis Selection)
	if (abs_dir.x > abs_dir.y && abs_dir.x > abs_dir.z) {
		current_pos = local_pos.x;
	} else if (abs_dir.z > abs_dir.y) {
		current_pos = local_pos.z;
	} else {
		current_pos = local_pos.y;
	}

	// 3. การตัด (Slicing) - ใช้ current_pos แทน current_y
	if (current_pos > slice_height) {
		discard;
	}

	// 4. การวาดเนื้อใน (Interior)
	if (!FRONT_FACING) {
		vec3 normal = normalize(NORMAL);
		vec3 weights = abs(normal);
		weights /= (weights.x + weights.y + weights.z);

		vec3 noise_pos = local_pos * noise_scale;
		float noise_value = triplanar_texture(inside_noise_texture, weights, noise_pos).r;
		vec3 final_inside_color = inside_color * (0.5 + noise_value * 0.5);

		ALBEDO = final_inside_color;
		ROUGHNESS = 0.8;
		SPECULAR = 0.0;
	} else {
		// ผิวนอก (เปลี่ยนสีได้ตามต้องการ)
		ALBEDO = vec3(0.7, 0.7, 0.8);
		ROUGHNESS = 0.5;
	}

	// 5. ขอบเรืองแสง (Edge Glow) - ใช้ current_pos เพื่อให้ขอบวิ่งตามแกนที่ตัด
	if (current_pos > slice_height - edge_thickness && FRONT_FACING) {
		float edge_intensity = 1.0 - (slice_height - current_pos) / edge_thickness;
		EMISSION = edge_color * edge_intensity * 5.0;
	}
}
shader_type spatial;
render_mode cull_disabled; // ต้องเปิดไว้เพื่อให้เห็นเนื้อด้านใน

uniform float slice_threshold = 0.0;
uniform vec3 brain_surface_color : source_color = vec3(0.9, 0.85, 0.8); // สีสมองปกติ (ภายนอก)
uniform vec3 brain_inside_color : source_color = vec3(0.8, 0.2, 0.3);  // สีชมพู/แดง (เนื้อใน)
uniform float emission_strength = 2.0; // ความสว่างของสีเนื้อใน

varying vec3 world_pos;

void vertex() {
    world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
    // คำนวณระยะห่างจากกล้อง
    vec3 view_to_pos = world_pos - CAMERA_POSITION_WORLD;
    vec3 cam_forward = -VIEW_MATRIX[2].xyz; 
    float dist_from_cam = dot(view_to_pos, cam_forward);

    // การตัด (Slicing)
    if (dist_from_cam < slice_threshold) {
        discard;
    }

    if (!FRONT_FACING) {
        // --- ส่วนเนื้อในสมองที่โดนตัด (สีชมพู/แดง) ---
        ALBEDO = brain_inside_color;
        EMISSION = brain_inside_color * emission_strength;
    } else {
        // --- ส่วนผิวสมองภายนอก (สีขาว/เทา) ---
        ALBEDO = brain_surface_color;
        ROUGHNESS = 0.5;
    }
}
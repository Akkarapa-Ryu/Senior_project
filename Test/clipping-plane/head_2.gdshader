shader_type spatial;

// ปิด Backface Culling เพื่อให้มองเห็น "ผนังด้านใน" เวลาถูกตัด
render_mode cull_disabled;

uniform sampler2D albedo_texture : source_color;
uniform float slice_threshold = 0.0; // จุดตัด (ปรับตามตำแหน่งหน้ากล้อง)
uniform bool is_slicing = true;

varying vec3 world_pos;

void vertex() {
    // แปลงพิกัดจาก Local ของโมเดล ให้เป็นพิกัดโลกจริงๆ
    // แม้จะหมุน X 90 องศา world_pos ก็จะได้ตำแหน่งที่ถูกต้องใน Scene
    world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
    if (is_slicing) {
        // 1. หา Vector จากกล้องมองไปยัง Pixel นี้
        vec3 view_to_pos = world_pos - CAMERA_POSITION_WORLD;
        
        // 2. หา Camera Forward (ทิศทางที่กล้องชี้ไป) ใน World Space
        // ใช้ VIEW_MATRIX แถวที่ 2 (Z-axis) มาหาทิศทาง
        vec3 cam_forward = -VIEW_MATRIX[2].xyz; 

        // 3. คำนวณระยะห่างตามแนวสายตา (Depth relative to Camera Plane)
        // ใช้ Dot Product เพื่อหาว่าจุดนี้ "ลึก" เข้าไปจากหน้ากล้องเท่าไหร่
        float dist_from_cam = dot(view_to_pos, cam_forward);

        // ถ้าจุดนี้อยู่ใกล้กล้องเกินไป (หน้าส่วนที่ควรจะหายไป) ให้ discard
        // slice_threshold ใช้เลื่อนระยะการตัด (เข้า-ออก)
        if (dist_from_cam < slice_threshold) {
            discard;
        }
    }

    vec4 tex = texture(albedo_texture, UV);
    ALBEDO = tex.rgb;
    
    // ทริค: ถ้าเป็นด้านใน (Backface) ให้ทำให้สีเข้มขึ้นเพื่อให้ดูเหมือนมีโพรงข้างใน
    if (!FRONT_FACING) {
        ALBEDO *= 0.2; 
    }
}
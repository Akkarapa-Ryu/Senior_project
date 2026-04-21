shader_type spatial; // หรือ spatial

uniform float slice_offset : hint_range(-2.0, 2.0) = 0.0; // ระยะการตัด
uniform vec4 albedo_color : source_color = vec4(1.0);
uniform sampler2D texture_albedo : source_color;

varying vec3 world_pos;

void vertex() {
    // เก็บตำแหน่ง World Position เพื่อใช้คำนวณการตัดที่ไม่ขึ้นกับ Local Rotation
    world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
    // 1. หา Vector จากกล้องมายัง Pixel นี้
    vec3 view_dir = normalize(world_pos - CAMERA_POSITION_WORLD);
    
    // 2. ใช้ Camera Forward Vector (ทิศที่กล้องมองไป) เป็น Normal ของระนาบตัด
    // ใน Godot, กล้องมองไปทาง -Z ของ Camera Matrix
    vec3 cam_forward = -VIEW_MATRIX[2].xyz; 

    // 3. คำนวณระยะห่างตามแนวแกนกล้อง
    // หากค่า Dot Product เกินเกณฑ์ที่กำหนด ให้ตัดทิ้ง (มองทะลุ)
    float dot_prod = dot(world_pos - CAMERA_POSITION_WORLD, cam_forward);
    
    if (dot_prod < slice_offset) {
        discard;
    }

    // ส่วนแสดงผล Texture ปกติ
    vec4 tex = texture(texture_albedo, UV);
    ALBEDO = tex.rgb * albedo_color.rgb;
}
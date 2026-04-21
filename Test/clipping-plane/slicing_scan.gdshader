shader_type spatial;
// render_mode: เพิ่ม cull_disabled เพื่อให้เห็นผนังด้านในเวลาโมเดลโดนตัด
render_mode blend_add, depth_draw_always, unshaded, cull_disabled;

uniform vec4 scan_color : source_color = vec4(0.2, 0.7, 1.0, 1.0); 
uniform float intensity : hint_range(0.0, 10.0) = 4.0;
uniform float softness : hint_range(0.1, 10.0) = 0.8;

// --- ส่วนที่เพิ่มมาใหม่สำหรับ Slicing ---
uniform float slice_height : hint_range(-10.0, 10.0) = 0.0; // จุดที่ตัดโมเดล
uniform float line_width : hint_range(0.0, 0.5) = 0.05;    // ความหนาของเส้นสแกน
uniform float line_glow : hint_range(0.0, 5.0) = 2.0;     // ความสว่างของเส้นสแกน

varying float world_y; // ส่งค่าตำแหน่งแนวตั้งจาก Vertex ไป Fragment

void vertex() {
    // เก็บตำแหน่ง Y ในระดับ World Space หรือ Local Space
    // (MODEL_MATRIX * vec4(VERTEX, 1.0)).y คือ World Space
    world_y = (MODEL_MATRIX * vec4(VERTEX, 1.0)).y;
}

void fragment() {
    // 1. Slicing Logic: ถ้าตำแหน่ง Y สูงกว่า slice_height ให้ลบทิ้ง (โปร่งใส)
    if (world_y > slice_height) {
        discard;
    }

    // 2. Scan Line Logic: สร้างเส้นเรืองแสงตรงขอบที่โดนตัด
    float dist_to_slice = abs(world_y - slice_height);
    float scan_line = smoothstep(line_width, 0.0, dist_to_slice);

    // 3. Fresnel Logic (เดิม)
    float fresnel = pow(1.0 - dot(NORMAL, VIEW), softness);
    fresnel = max(0.2, fresnel);

    // 4. ผสมสี
    // รวมแสงจาก Fresnel และเส้น Scan Line เข้าด้วยกัน
    vec3 final_color = scan_color.rgb * intensity;
    float final_alpha = fresnel * 0.3; // ความโปร่งใสของตัว Body
    
    // เพิ่มความสว่างและ Alpha ตรงเส้นขอบสแกน
    final_color += scan_color.rgb * scan_line * line_glow;
    final_alpha += scan_line;

    ALBEDO = final_color;
    ALPHA = clamp(final_alpha, 0.0, 1.0);
}
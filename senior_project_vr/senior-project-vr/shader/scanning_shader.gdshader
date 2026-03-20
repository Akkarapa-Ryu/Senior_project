//shader_type spatial;
//// เปิด unshaded เพื่อให้แสงสว่างคงที่, unshaded ทำให้เงาและไฮไลท์จากแสงภายนอกไม่มีผล
//render_mode blend_add, depth_draw_always, unshaded;
//
//// ปรับสีได้ตามต้องการ (สีใน image_0.png คือโทนฟ้าอ่อน)
//uniform vec4 scan_color : source_color = vec4(0.2, 0.7, 1.0, 1.0);
//// ความสว่างโดยรวม
//uniform float intensity : hint_range(0.0, 10.0) = 4.0;
//// ความฟุ้งของขอบ (Fresnel Power) ยิ่งค่ามาก ขอบยิ่งคม ยิ่งค่าน้อย ขอบยิ่งฟุ้ง
//uniform float softness : hint_range(0.1, 10.0) = 0.8;
//// ความโปร่งแสงโดยรวม
//uniform float transparency_level : hint_range(0.0, 1.0) = 0.3;
//
//void fragment() {
    //// 1. คำนวณความสว่างพื้นฐานจาก Fresnel (ขอบสว่าง ตรงกลางมืดลงเล็กน้อย)
    //// แต่ปรับให้ Fresnel Power ต่ำ (softness) เพื่อให้ตรงกลางยังสว่างอยู่
    //float fresnel = pow(1.0 - dot(NORMAL, VIEW), softness);
//
    //// 2. ปรับ Fresnel ให้มีความสว่างเริ่มต้นที่ค่าหนึ่ง ไม่ให้ตรงกลางดำสนิท
    //fresnel = max(0.2, fresnel); // บังคับความสว่างขั้นต่ำที่ 20%
//
    //// 3. กำหนดสีและแสง
    //ALBEDO = scan_color.rgb * fresnel * intensity;
//
    //// 4. กำหนดความโปร่งแสง:
    //// ตรงกลางควรโปร่งกว่าขอบ, ใช้ 1.0 - fresnel เพื่อให้ผลลัพธ์กลับกัน
    //float base_alpha = (1.0 - fresnel);
    //// ผสมความโปร่งแสงพื้นฐานกับค่า transparency_level
    //ALPHA = mix(fresnel, base_alpha, 0.5) * transparency_level * intensity;
//
    //// ปรับลด Alpha เพิ่มเติมในส่วนที่มืดที่สุดของ Fresnel เพื่อให้ตรงกลางโปร่งขึ้นอีก
    //ALPHA = mix(ALPHA, 0.0, base_alpha * base_alpha);
//}

shader_type spatial;
render_mode blend_add, depth_draw_always, unshaded, cull_disabled;

uniform vec4 scan_color : source_color = vec4(0.1, 0.1, 0.1, 1.0);
uniform float intensity : hint_range(0.0, 10.0) = 4.0;
uniform float softness : hint_range(0.1, 10.0) = 0.8;
uniform float transparency_level : hint_range(0.0, 1.0) = 0.4;

// --- ส่วน Slicing แบบบางเฉียบ ---
uniform bool is_slicing = false;
uniform vec3 slice_normal = vec3(0.0, 1.0, 0.0);
uniform float slice_dist = 0.0;
// ปรับให้บางลง (0.005 คือประมาณ 5 มิลลิเมตรใน scale ปกติ)
uniform float edge_thickness : hint_range(0.0, 0.1) = 0.005;

varying vec3 local_pos;

void vertex() {
    local_pos = VERTEX;
}

void fragment() {
    float current_dist = dot(local_pos, slice_normal);

    // ตัดส่วนที่ยังสแกนไม่ถึงทิ้งไป
    if (is_slicing && current_dist > slice_dist) {
        discard;
    }

    // 1. เอฟเฟกต์ Fresnel สีฟ้าโปร่งแสง (ตัวเครื่องหลัก)
    float fresnel = pow(1.0 - dot(NORMAL, VIEW), softness);
    fresnel = max(0.2, fresnel);

    // 2. คำนวณสีและ ALPHA พื้นฐาน
    vec3 final_color = scan_color.rgb * fresnel * intensity;
    float base_alpha = (1.0 - fresnel);
    float final_alpha = mix(fresnel, base_alpha, 0.5) * transparency_level * intensity;
    final_alpha = mix(final_alpha, 0.0, base_alpha * base_alpha);

    // 3. เส้น Slice บางเฉียบ (Edge Glow)
    if (is_slicing && current_dist > slice_dist - edge_thickness) {
        // คำนวณความคมของเส้น (ยิ่งเลข pow สูง เส้นยิ่งบางและคม)
        float edge_mask = 1.0 - (slice_dist - current_dist) / edge_thickness;
        edge_mask = pow(edge_mask, 3.0);

        // เพิ่มความสว่างเฉพาะตรงจุดที่กำลังโดนปาด
        final_color += scan_color.rgb * edge_mask * 15.0;
        final_alpha = mix(final_alpha, 1.0, edge_mask);
    }

    ALBEDO = final_color;
    ALPHA = final_alpha;
}
shader_type spatial;
// 1. เพิ่ม depth_draw_always เพื่อให้มองเห็นทะลุไปด้านหลังได้ถูกต้อง
// 2. ใช้ blend_mix (มาตรฐาน) หรือ blend_add (ถ้าอยากให้สว่างขึ้นเมื่อซ้อนกัน)
render_mode unshaded, cull_disabled, depth_draw_always;

uniform vec4 bone_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float brightness : hint_range(0.0, 5.0) = 1.2;
// เพิ่มค่าความโปร่งแสงรวม
uniform float opacity : hint_range(0.0, 1.0) = 0.5; 

// --- ส่วน Slicing ---
uniform bool is_slicing = true;
uniform vec3 slice_normal = vec3(0.0, 1.0, 0.0);
uniform float slice_dist = 0.0;
uniform float edge_thickness : hint_range(0.0, 0.2) = 0.02;

varying vec3 local_pos;

void vertex() {
    local_pos = VERTEX;
}

void fragment() {
    float current_dist = dot(local_pos, slice_normal);

    if (is_slicing && current_dist > slice_dist) {
        discard;
    }

    // คำนวณ Fresnel: ให้ขอบสว่างและทึบ ตรงกลางจะโปร่งแสงกว่า
    float fresnel = pow(1.0 - dot(NORMAL, VIEW), 2.0);
    
    vec3 final_color = bone_color.rgb * brightness;
    
    // ปรับค่า Alpha: 
    // - ตรงกลางจะมีความใส (Opacity ต่ำ)
    // - ตรงขอบ (Fresnel) จะมีความทึบเพื่อให้เห็นโครงสร้างกระดูก
    float final_alpha = mix(opacity * 0.2, opacity, fresnel);

    // ทำเส้นขอบสว่างตรงรอยตัด (จุดที่เป็นหน้าตัดของกะโหลก)
    if (is_slicing && current_dist > slice_dist - edge_thickness) {
        float edge_mask = 1.0 - (slice_dist - current_dist) / edge_thickness;
        edge_mask = pow(edge_mask, 3.0);
        
        // ทำให้รอยตัดขาวทึบสนิท (เหมือนภาพ CT Scan จริง)
        final_color = mix(final_color, vec3(1.0, 1.0, 1.0) * 2.0, edge_mask);
        final_alpha = mix(final_alpha, 1.0, edge_mask);
    }

    ALBEDO = final_color;
    ALPHA = final_alpha;
}
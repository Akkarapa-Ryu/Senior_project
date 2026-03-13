shader_type spatial;
// เปิด unshaded เพื่อให้แสงสว่างคงที่, unshaded ทำให้เงาและไฮไลท์จากแสงภายนอกไม่มีผล
render_mode blend_add, depth_draw_always, unshaded;

// ปรับสีได้ตามต้องการ (สีใน image_0.png คือโทนฟ้าอ่อน)
uniform vec4 scan_color : source_color = vec4(0.2, 0.7, 1.0, 1.0); 
// ความสว่างโดยรวม
uniform float intensity : hint_range(0.0, 10.0) = 4.0;
// ความฟุ้งของขอบ (Fresnel Power) ยิ่งค่ามาก ขอบยิ่งคม ยิ่งค่าน้อย ขอบยิ่งฟุ้ง
uniform float softness : hint_range(0.1, 10.0) = 0.8;
// ความโปร่งแสงโดยรวม
uniform float transparency_level : hint_range(0.0, 1.0) = 0.3;

void fragment() {
    // 1. คำนวณความสว่างพื้นฐานจาก Fresnel (ขอบสว่าง ตรงกลางมืดลงเล็กน้อย)
    // แต่ปรับให้ Fresnel Power ต่ำ (softness) เพื่อให้ตรงกลางยังสว่างอยู่
    float fresnel = pow(1.0 - dot(NORMAL, VIEW), softness);
    
    // 2. ปรับ Fresnel ให้มีความสว่างเริ่มต้นที่ค่าหนึ่ง ไม่ให้ตรงกลางดำสนิท
    fresnel = max(0.2, fresnel); // บังคับความสว่างขั้นต่ำที่ 20%
    
    // 3. กำหนดสีและแสง
    ALBEDO = scan_color.rgb * fresnel * intensity;
    
    // 4. กำหนดความโปร่งแสง:
    // ตรงกลางควรโปร่งกว่าขอบ, ใช้ 1.0 - fresnel เพื่อให้ผลลัพธ์กลับกัน
    float base_alpha = (1.0 - fresnel);
    // ผสมความโปร่งแสงพื้นฐานกับค่า transparency_level
    ALPHA = mix(fresnel, base_alpha, 0.5) * transparency_level * intensity; 
    
    // ปรับลด Alpha เพิ่มเติมในส่วนที่มืดที่สุดของ Fresnel เพื่อให้ตรงกลางโปร่งขึ้นอีก
    ALPHA = mix(ALPHA, 0.0, base_alpha * base_alpha); 
}
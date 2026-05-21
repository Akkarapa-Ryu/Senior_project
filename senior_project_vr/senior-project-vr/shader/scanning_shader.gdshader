//shader_type spatial;
//render_mode blend_add, depth_draw_always, unshaded, cull_disabled;
//
//uniform vec4 scan_color : source_color = vec4(0.3, 0.3, 0.3, 1.0);
//uniform float intensity : hint_range(0.0, 10.0) = 4.0;
//uniform float softness : hint_range(0.1, 10.0) = 0.8;
//uniform float transparency_level : hint_range(0.0, 1.0) = 0.7;
//
//// --- ส่วน Slicing แบบบางเฉียบ ---
//uniform bool is_slicing = false;
//uniform vec3 slice_normal = vec3(0.0, 1.0, 0.0);
//uniform float slice_dist = 0.0;
//// ปรับให้บางลง (0.005 คือประมาณ 5 มิลลิเมตรใน scale ปกติ)
//uniform float edge_thickness : hint_range(0.0, 0.1) = 0.005;
//
//varying vec3 local_pos;
//
//void vertex() {
    //local_pos = VERTEX;
//}
//
//void fragment() {
    //float current_dist = dot(local_pos, slice_normal);
//
    //// ตัดส่วนที่ยังสแกนไม่ถึงทิ้งไป
    //if (is_slicing && current_dist > slice_dist) {
        //discard;
    //}
//
    //// 1. เอฟเฟกต์ Fresnel สีฟ้าโปร่งแสง (ตัวเครื่องหลัก)
    //float fresnel = pow(1.0 - dot(NORMAL, VIEW), softness);
    //fresnel = max(0.2, fresnel);
//
    //// 2. คำนวณสีและ ALPHA พื้นฐาน
    //vec3 final_color = scan_color.rgb * fresnel * intensity;
    //float base_alpha = (1.0 - fresnel);
    //float final_alpha = mix(fresnel, base_alpha, 0.5) * transparency_level * intensity;
    //final_alpha = mix(final_alpha, 0.0, base_alpha * base_alpha);
//
    //// 3. เส้น Slice บางเฉียบ (Edge Glow)
    //if (is_slicing && current_dist > slice_dist - edge_thickness) {
        //// คำนวณความคมของเส้น (ยิ่งเลข pow สูง เส้นยิ่งบางและคม)
        //float edge_mask = 1.0 - (slice_dist - current_dist) / edge_thickness;
        //edge_mask = pow(edge_mask, 3.0);
//
        //// เพิ่มความสว่างเฉพาะตรงจุดที่กำลังโดนปาด
        //final_color += scan_color.rgb * edge_mask * 15.0;
        //final_alpha = mix(final_alpha, 1.0, edge_mask);
    //}
//
    //ALBEDO = final_color;
    //ALPHA = final_alpha;
//}

shader_type spatial;
render_mode unshaded, cull_disabled;

uniform vec4 organ_color : source_color = vec4(0.4, 0.4, 0.4, 1.0);
uniform float noise_scale : hint_range(1.0, 50.0) = 25.0;
uniform float transparency : hint_range(0.0, 1.0) = 0.6;

// --- ส่วน Slicing ---
uniform bool is_slicing = true;
uniform vec3 slice_normal = vec3(0.0, 1.0, 0.0);
uniform float slice_dist = 0.0;
uniform float edge_thickness : hint_range(0.0, 0.1) = 0.01;

varying vec3 local_pos;

// Function Noise สำหรับลายเนื้อเยื่อ
float hash(float n) { return fract(sin(n) * 43758.5453); }
float noise(vec3 x) {
    vec3 p = floor(x);
    vec3 f = fract(x);
    f = f * f * (3.0 - 2.0 * f);
    float n = p.x + p.y * 57.0 + 113.0 * p.z;
    return mix(mix(mix(hash(n + 0.0), hash(n + 1.0), f.x),
                   mix(hash(n + 57.0), hash(n + 58.0), f.x), f.y),
               mix(mix(hash(n + 113.0), hash(n + 114.0), f.x),
                   mix(hash(n + 170.0), hash(n + 171.0), f.x), f.y), f.z);
}

void vertex() {
    local_pos = VERTEX;
}

void fragment() {
    float current_dist = dot(local_pos, slice_normal);

    if (is_slicing && current_dist > slice_dist) {
        discard;
    }

    // สร้างลายเนื้อเยื่อ
    float n = noise(local_pos * noise_scale);
    vec3 final_color = organ_color.rgb + (n * 0.15);
    float final_alpha = transparency;

    // ตรงรอยตัดของอวัยวะ ให้สว่างขึ้นเล็กน้อยแต่ไม่เท่ากระดูก
    if (is_slicing && current_dist > slice_dist - edge_thickness) {
        float edge_mask = 1.0 - (slice_dist - current_dist) / edge_thickness;
        final_color += organ_color.rgb * 0.5;
        final_alpha = mix(transparency, 1.0, edge_mask);
    }

    ALBEDO = final_color;
    ALPHA = final_alpha;
}
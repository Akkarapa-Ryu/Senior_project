shader_type spatial;
render_mode blend_add, depth_draw_always, unshaded, cull_disabled;

uniform vec4 scan_color : source_color = vec4(0.2, 0.7, 1.0, 1.0); 
uniform float intensity : hint_range(0.0, 10.0) = 4.0;
uniform float softness : hint_range(0.1, 10.0) = 0.8;

// --- Slicing ---
uniform float slice_height : hint_range(-10.0, 10.0) = 0.0;
uniform float line_width : hint_range(0.0, 0.5) = 0.05;
uniform float line_glow : hint_range(0.0, 5.0) = 2.0;

// --- ส่วนที่เพิ่มใหม่: Density Spot (จุดสีเข้ม/หนาแน่น) ---
uniform vec3 spot_location = vec3(0.0, 0.0, 0.0); // ตำแหน่งจุดในห้อง 3D
uniform float spot_size : hint_range(0.0, 2.0) = 0.3;    // ขนาดของจุด
uniform float spot_density : hint_range(0.0, 5.0) = 2.0; // ความเข้มของสีในจุดนั้น
uniform vec4 spot_color : source_color = vec4(0.0, 0.1, 0.3, 1.0); // สีที่เข้มขึ้น (เช่น น้ำเงินเข้ม)

varying vec3 world_pos; // เปลี่ยนจาก float world_y เป็น vec3

void vertex() {
    // เก็บตำแหน่ง XYZ ทั้งหมดในระดับ World Space
    world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
    // 1. Slicing Logic
    if (world_pos.y > slice_height) {
        discard;
    }

    // 2. Scan Line Logic
    float dist_to_slice = abs(world_pos.y - slice_height);
    float scan_line = smoothstep(line_width, 0.0, dist_to_slice);

    // 3. Fresnel Logic
    float fresnel = pow(1.0 - dot(NORMAL, VIEW), softness);
    fresnel = max(0.2, fresnel);

    // 4. Density Spot Logic (คำนวณระยะห่างจากจุดที่กำหนด)
    float dist_to_spot = distance(world_pos, spot_location);
    // สร้างวงกลมฟุ้งๆ (Mask)
    float spot_mask = smoothstep(spot_size, 0.0, dist_to_spot);

    // 5. ผสมสีและแสง
    vec3 base_color = scan_color.rgb * intensity;
    float base_alpha = fresnel * 0.3;
    
    // ผสมสีของจุดเข้มเข้าไป (ใช้ mix เพื่อเปลี่ยนสีในบริเวณนั้น)
    vec3 final_color = mix(base_color, spot_color.rgb * spot_density, spot_mask);
    float final_alpha = mix(base_alpha, spot_mask * spot_density, spot_mask);

    // เพิ่มเส้น Scan Line เข้าไปทีหลังเพื่อให้มันทับอยู่บนสุด
    final_color += scan_color.rgb * scan_line * line_glow;
    final_alpha += scan_line;

    ALBEDO = final_color;
    ALPHA = clamp(final_alpha, 0.0, 1.0);
}
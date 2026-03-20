shader_type spatial;
// unshaded = ไม่รับแสงจากไฟในฉาก, blend_add = แสงซ้อนกันแล้วสว่างขึ้น
render_mode unshaded, blend_add, cull_disabled, depth_draw_never;

uniform vec3 laser_color = vec3(0.0, 1.0, 0.0); // สีเขียว
uniform float intensity = 0.3;

void fragment() {
    // คำนวณความฟุ้งจากจุดศูนย์กลาง (เลเซอร์จะชัดตรงกลางและจางที่ขอบ)
    float mask = 1.0 - smoothstep(0.0, 0.5, length(UV - vec2(0.5)));
    
    ALBEDO = laser_color;
    //ALPHA = mask * intensity;
}
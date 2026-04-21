shader_type spatial;
render_mode cull_disabled;

uniform sampler2D albedo_texture : source_color;
uniform bool is_slicing = false; // เริ่มต้นให้เป็น false ไว้ก่อนเพื่อให้เห็นครบ
uniform vec3 slice_normal = vec3(1.0, 0.0, 0.0); 
uniform float slice_dist = 0.0;

varying vec3 local_pos; // เปลี่ยนจาก world_pos

void vertex() {
    local_pos = VERTEX; // ใช้พิกัด Local ของโมเดลโดยตรง
}

void fragment() {
    if (is_slicing) {
        // คำนวณในพิกัด Local ของตัวเอง
        float current_dist = dot(local_pos, normalize(slice_normal));
        
        if (current_dist > slice_dist) {
            discard;
        }
    }

    vec4 tex = texture(albedo_texture, UV);
    ALBEDO = tex.rgb;
    
    if (!FRONT_FACING) {
        ALBEDO *= 0.1; 
    }
}
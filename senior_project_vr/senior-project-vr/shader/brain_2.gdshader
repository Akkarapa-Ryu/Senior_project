shader_type spatial;
render_mode cull_disabled, depth_draw_always;

varying vec3 local_pos;
varying vec3 local_normal;

group_uniforms Slicing;
uniform bool is_slicing = false;
uniform vec3 slice_normal = vec3(1.0, 0.0, 0.0); 
uniform float slice_dist = 0.0;
uniform vec3 edge_color : source_color = vec3(1.0, 1.0, 1.0);
uniform float edge_thickness : hint_range(0.0, 0.2) = 0.02;

group_uniforms Interior;
uniform vec3 inside_color : source_color = vec3(0.05, 0.05, 0.05); // ดำเกือบสนิท
uniform sampler2D inside_noise_texture : hint_default_white;
uniform float noise_scale : hint_range(0.1, 10.0) = 4.0;

void vertex() {
    local_pos = VERTEX;
    local_normal = NORMAL;
}

void fragment() {
    if (is_slicing) {
        float current_dist = dot(local_pos, normalize(slice_normal));

        if (current_dist > slice_dist) {
            discard;
        }

        if (!FRONT_FACING) {
            // เนื้อในสีขาวดำ
            vec3 weights = abs(local_normal);
            weights /= (weights.x + weights.y + weights.z);
            vec3 noise_pos = local_pos * noise_scale;
            
            float noise_val = texture(inside_noise_texture, noise_pos.xy).r * weights.z +
                              texture(inside_noise_texture, noise_pos.xz).r * weights.y +
                              texture(inside_noise_texture, noise_pos.zy).r * weights.x;
            
            ALBEDO = inside_color + (noise_val * 0.1); 
        } else {
            // ผิวนอกเทาเข้ม
            ALBEDO = vec3(0.15, 0.15, 0.15); 
            
            // ขอบเรืองแสง
            float dist_to_plane = abs(current_dist - slice_dist);
            if (dist_to_plane < edge_thickness) {
                float intensity = 1.0 - (dist_to_plane / edge_thickness);
                EMISSION = edge_color * intensity * 2.5;
            }
        }
    } else {
        // ถ้าไม่ได้สั่ง Slice ให้โชว์เนื้อสมองปกติ (หรือสีที่เราต้องการ)
        ALBEDO = vec3(0.3, 0.3, 0.3);
    }
}
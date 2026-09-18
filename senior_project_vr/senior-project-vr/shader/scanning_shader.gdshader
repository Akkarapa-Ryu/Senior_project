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
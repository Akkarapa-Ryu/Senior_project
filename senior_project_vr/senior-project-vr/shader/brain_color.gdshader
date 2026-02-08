shader_type spatial;

group_uniforms Interior;
uniform vec3 inside_color : source_color = vec3(0.6, 0.2, 0.2); // สีเนื้อแดงๆ
uniform sampler2D inside_noise_texture : hint_default_white, filter_linear_mipmap_anisotropic; // ใส่ภาพ Noise ตรงนี้
uniform float noise_scale : hint_range(0.1, 10.0) = 2.0; // ปรับขนาดลายเนื้อ

vec4 triplanar_texture(sampler2D p_sampler, vec3 p_weights, vec3 p_triplanar_pos) {
	vec4 samp=vec4(0.0);
	samp+= texture(p_sampler,p_triplanar_pos.xy) * p_weights.z;
	samp+= texture(p_sampler,p_triplanar_pos.xz) * p_weights.y;
	samp+= texture(p_sampler,p_triplanar_pos.zy * vec2(-1.0,1.0)) * p_weights.x;
	return samp;
}

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	// Called for every pixel the material is visible on.
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}

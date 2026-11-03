shader_type spatial;

uniform sampler2D diffuse_texture : source_color, repeat_enable;
uniform sampler2D normal_texture : hint_normal, repeat_enable;
uniform sampler2D roughness_texture : repeat_enable;

uniform vec4 base_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

uniform vec2 texture_tiling = vec2(1.0, 1.0);
uniform float normal_strength : hint_range(0.0, 2.0) = 0.7;
uniform float roughness_strength : hint_range(0.0, 1.0) = 1.0;

void fragment() {
	vec2 tiled_uv = UV * texture_tiling;

	vec3 diffuse_sample = texture(diffuse_texture, tiled_uv).rgb;
	vec3 normal_sample = texture(normal_texture, tiled_uv).rgb;
	float roughness_sample = texture(roughness_texture, tiled_uv).r;

	ALBEDO = diffuse_sample * base_color.rgb;
	NORMAL_MAP = normal_sample;
	NORMAL_MAP_DEPTH = normal_strength;
	ROUGHNESS = roughness_sample * roughness_strength;
}
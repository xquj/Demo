shader_type spatial;
render_mode unshaded, cull_back;

uniform vec4 paper_color : source_color = vec4(0.9, 0.86, 0.78, 1.0);
uniform float fiber_scale = 90.0;
uniform float edge_wear = 0.15;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(41.7, 91.2))) * 43758.5453);
}

void fragment() {
	vec2 uv = UV;
	float fiber = hash(uv * fiber_scale);
	float wear = smoothstep(0.02, edge_wear, uv.x) * smoothstep(0.02, edge_wear, uv.y) *
		smoothstep(0.02, edge_wear, 1.0 - uv.x) * smoothstep(0.02, edge_wear, 1.0 - uv.y);
	vec3 color = paper_color.rgb * mix(0.92, 1.05, fiber);
	color = mix(color * 0.85, color, wear);
	ALBEDO = color;
}

shader_type spatial;
render_mode unshaded, cull_back;

uniform vec4 base_color : source_color = vec4(0.18, 0.11, 0.07, 1.0);
uniform float grain_scale = 30.0;
uniform float stain_strength = 0.2;
uniform float vignette_strength = 0.4;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	vec2 uv = UV;
	float grain = sin((uv.y + sin(uv.x * 2.0)) * grain_scale) * 0.06;
	float noise = hash(uv * 20.0);
	float stain = mix(1.0, 1.0 - stain_strength, noise);
	float vignette = smoothstep(0.9, 0.2, distance(uv, vec2(0.5)));
	vec3 color = base_color.rgb * (1.0 + grain) * stain;
	color *= mix(1.0, 1.0 - vignette_strength, vignette);
	ALBEDO = color;
}

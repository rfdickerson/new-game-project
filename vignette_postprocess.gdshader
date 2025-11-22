shader_type canvas_item;

uniform float vignette_intensity : hint_range(0.0, 2.0) = 1.0;
uniform vec2 vignette_center = vec2(0.5, 0.5);
uniform float vignette_radius : hint_range(0.0, 1.0) = 0.75;
uniform float vignette_smoothness : hint_range(0.0, 1.0) = 0.4;

void fragment() {
	vec2 offset = SCREEN_UV - vignette_center;
	float dist = length(offset) / max(vignette_radius, 0.0001);

	float v = smoothstep(1.0 - vignette_smoothness, 1.0, dist);
	float alpha = clamp(v * vignette_intensity, 0.0, 1.0);

	// Draw a black transparent overlay: fully transparent in center,
	// increasing opacity toward the edges.
	COLOR = vec4(0.0, 0.0, 0.0, alpha);
}



shader_type spatial;
render_mode cull_disabled, depth_draw_always, blend_mix;

uniform vec3 base_color = vec3(0.06, 0.35, 0.5);
uniform vec3 sky_color = vec3(0.38, 0.65, 0.88);
uniform float reflection_strength : hint_range(0.0, 1.0) = 0.65;
uniform float fresnel_power : hint_range(0.5, 5.0) = 2.5;
uniform float alpha : hint_range(0.0, 1.0) = 0.85;

void fragment() {
    vec3 normal = normalize(NORMAL);
    vec3 view_dir = normalize(-VIEW);
    
    // Calculate fresnel for edge reflection
    float fresnel = pow(clamp(1.0 - dot(view_dir, normal), 0.0, 1.0), fresnel_power);
    
    // Use base color as foundation
    vec3 final_color = base_color;
    
    // Blend with sky color based on fresnel (this simulates sky reflection)
    final_color = mix(final_color, sky_color, fresnel * reflection_strength);
    
    ALBEDO = final_color;
    // Set metallic and roughness for PBR reflections to work
    // Lower roughness = more mirror-like, allowing reflection probes to show through
    METALLIC = 0.15;
    ROUGHNESS = 0.05;  // Very smooth surface for clear reflections
    ALPHA = alpha;
}


shader_type spatial;

uniform sampler2D emission_texture : source_color;
uniform vec2 scroll_speed = vec2(0.5, 0.0);
uniform float emission_energy : hint_range(0.0, 16.0) = 1.0;

// Pseudo-random helper function using world position
float random(vec3 p) {
    return fract(sin(dot(p, vec3(12.9898, 78.233, 45.5432))) * 43758.5433);
}

void fragment() {
    // Generate a unique random time offset for each mesh instance based on its placement
    float instance_offset = random(NODE_POSITION_WORLD) * 100.0;
    
    // Offset the UV coordinates over time, staggered by the unique instance offset
    vec2 shifted_uv = UV + (scroll_speed * (TIME + instance_offset));
    
    // Keep the base albedo black and apply the scrolling texture to Emission
    ALBEDO = vec3(0.0);
    EMISSION = texture(emission_texture, shifted_uv).rgb * emission_energy;
}
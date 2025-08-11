shader_type spatial;

// Base albedo and scary rim-emission
uniform vec3 base_color : source_color = vec3(0.05, 0.02, 0.06);
uniform vec3 rim_color : source_color = vec3(0.95, 0.06, 0.06);

// Effect controls
uniform float pulse_speed : hint_range(0.0, 10.0) = 2.2;
uniform float rim_power : hint_range(0.5, 8.0) = 2.8;
uniform float emissive_strength : hint_range(0.0, 10.0) = 2.5;
uniform float distort_amount : hint_range(0.0, 0.2) = 0.02;

// Material properties
uniform float roughness : hint_range(0.0, 1.0) = 0.65;
uniform float metallic : hint_range(0.0, 1.0) = 0.0;

void vertex() {
    // Subtle organic wobble to make the silhouette uneasy
    float wobble = sin(TIME * 3.0 + VERTEX.y * 4.0 + VERTEX.x * 2.0) * 0.5
                 + cos(TIME * 2.2 + VERTEX.z * 3.0) * 0.5;
    VERTEX += NORMAL * wobble * distort_amount;
}

void fragment() {
    // Base dark albedo
    ALBEDO = base_color;

    // Pulsating fresnel rim for an ominous glow
    float view_dot = clamp(dot(NORMAL, VIEW), -1.0, 1.0);
    float fresnel = pow(1.0 - view_dot, rim_power);
    float pulse = 0.5 + 0.5 * sin(TIME * pulse_speed);
    EMISSION = rim_color * fresnel * (0.75 + 0.25 * pulse) * emissive_strength;

    ROUGHNESS = roughness;
    METALLIC = metallic;
}


shader_type spatial;
render_mode cull_disabled, unshaded, blend_mix;

uniform float wave_speed : hint_range(0.5, 3.0) = 1.0;
uniform int wave_count : hint_range(3, 12) = 6;
uniform float wave_sharpness : hint_range(1.0, 10.0) = 4.0;
uniform vec4 wave_color : source_color = vec4(0.0, 1.0, 0.3, 1.0);
uniform vec4 background_color : source_color = vec4(0.0, 0.4, 0.1, 0.3);
uniform float glow_intensity : hint_range(0.5, 3.0) = 1.5;

void fragment() {
    vec3 world_pos = VERTEX;
    float time = TIME;
    
    // Coordonnées sphériques pour les vagues qui montent
    float height = world_pos.y;
    float angle = atan(world_pos.z, world_pos.x);
    
    // Vagues d'énergie verticales clairement découpées
    float wave_pattern = sin((height * float(wave_count) + time * wave_speed) * 3.14159);
    
    // Rendre les vagues plus nettes avec une fonction step modifiée
    float sharp_waves = smoothstep(-1.0 / wave_sharpness, 1.0 / wave_sharpness, wave_pattern);
    
    // Rotation légère des vagues
    float rotation = sin(angle * 2.0 + time * wave_speed * 0.3) * 0.1;
    sharp_waves += rotation;
    
    // Clamper pour garder des bandes nettes
    sharp_waves = clamp(sharp_waves, 0.0, 1.0);
    
    // Couleur finale basée sur les vagues
    vec3 final_color = mix(background_color.rgb, wave_color.rgb, sharp_waves);
    
    // Émission pour l'effet lumineux
    float emission_strength = sharp_waves * glow_intensity;
    
    ALBEDO = final_color;
    EMISSION = wave_color.rgb * emission_strength;
    ALPHA = mix(background_color.a, wave_color.a, sharp_waves);
}
shader_type spatial;

// Couleurs de base au lieu de textures
uniform vec3 dirt_color : source_color = vec3(0.35, 0.25, 0.15);
uniform vec3 grass_color : source_color = vec3(0.15, 0.4, 0.08);

// Paramètres de mélange
uniform float grass_threshold : hint_range(0.0, 1.0) = 0.4;
uniform float blend_sharpness : hint_range(0.1, 10.0) = 2.0;

// Paramètres de bruit pour la variation
uniform float noise_scale : hint_range(0.1, 10.0) = 1.0;
uniform float noise_strength : hint_range(0.0, 1.0) = 0.5;

// Paramètres de matériau
uniform float dirt_roughness : hint_range(0.0, 1.0) = 0.8;
uniform float grass_roughness : hint_range(0.0, 1.0) = 0.9;

varying vec3 world_position;
varying vec3 world_normal;

// Fonction de bruit simple
float random(vec2 uv) {
    return fract(sin(dot(uv, vec2(12.9898, 78.233))) * 43758.5453);
}

// Bruit de Perlin simplifié
float noise(vec2 uv) {
    vec2 i = floor(uv);
    vec2 f = fract(uv);
    
    float a = random(i);
    float b = random(i + vec2(1.0, 0.0));
    float c = random(i + vec2(0.0, 1.0));
    float d = random(i + vec2(1.0, 1.0));
    
    vec2 u = f * f * (3.0 - 2.0 * f);
    
    return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

// Fonction de mélange smooth
float smooth_mix(float value, float threshold, float sharpness) {
    return smoothstep(threshold - 1.0/sharpness, threshold + 1.0/sharpness, value);
}

void vertex() {
    world_position = VERTEX;
    world_normal = NORMAL;
}

void fragment() {
    // Calcul du facteur de mélange basé sur la pente et le bruit
    float slope = 1.0 - abs(dot(world_normal, vec3(0.0, 1.0, 0.0)));
    
    // Ajout de variation avec du bruit
    vec2 noise_uv = world_position.xz * noise_scale;
    float noise_value = noise(noise_uv) * noise_strength;
    
    // Facteur de mélange combiné
    float blend_factor = slope + noise_value;
    
    // Calcul des poids de mélange (seulement herbe et terre)
    float grass_weight = 1.0 - smooth_mix(blend_factor, grass_threshold, blend_sharpness);
    float dirt_weight = 1.0 - grass_weight;
    
    // Mélange final des couleurs
    vec3 final_color = dirt_color * dirt_weight + grass_color * grass_weight;
    
    // Calcul de la rugosité finale
    float final_roughness = dirt_roughness * dirt_weight + grass_roughness * grass_weight;
    
    // Assombrissement des zones en pente pour plus de réalisme
    float shadow_factor = 1.0 - slope * 0.2;
    final_color *= shadow_factor;
    
    // Ajout de variation de couleur avec le bruit pour plus de détails
    vec2 detail_uv = world_position.xz * noise_scale * 3.0;
    float detail_noise = noise(detail_uv) * 0.15;
    final_color *= (1.0 + detail_noise);
    
    // Variation supplémentaire pour l'herbe
    if (grass_weight > 0.5) {
        float grass_variation = noise(world_position.xz * 8.0) * 0.1;
        final_color += vec3(0.0, grass_variation, -grass_variation * 0.5);
    }
    
    ALBEDO = final_color;
    ROUGHNESS = final_roughness;
    METALLIC = 0.0;
}
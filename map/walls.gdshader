shader_type spatial;

// Couleurs du mur
uniform vec3 base_color : source_color = vec3(0.6, 0.5, 0.4);
uniform vec3 mortar_color : source_color = vec3(0.3, 0.25, 0.2);
uniform vec3 highlight_color : source_color = vec3(0.8, 0.7, 0.5);

// Paramètres des briques
uniform float brick_width : hint_range(0.1, 2.0) = 0.8;
uniform float brick_height : hint_range(0.1, 1.0) = 0.4;
uniform float mortar_width : hint_range(0.01, 0.2) = 0.05;

// Effets visuels
uniform float glow_intensity : hint_range(0.0, 2.0) = 0.3;
uniform float time_speed : hint_range(0.0, 5.0) = 1.0;
uniform float roughness_variation : hint_range(0.0, 1.0) = 0.4;

// Paramètres de matériau
uniform float base_roughness : hint_range(0.0, 1.0) = 0.7;
uniform float base_metallic : hint_range(0.0, 1.0) = 0.1;

varying vec3 world_position;
varying vec2 world_uv;

// Fonction de bruit
float random(vec2 uv) {
    return fract(sin(dot(uv, vec2(12.9898, 78.233))) * 43758.5453);
}

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

// Fonction pour créer un motif de briques
vec2 brick_pattern(vec2 uv) {
    // Décalage pour effet de briques
    float row = floor(uv.y / brick_height);
    float offset = 0.5 * mod(row, 2.0);
    
    vec2 brick_uv = vec2(
        mod(uv.x + offset * brick_width, brick_width),
        mod(uv.y, brick_height)
    );
    
    return brick_uv;
}

void vertex() {
    world_position = VERTEX;
    world_uv = UV;
}

void fragment() {
    // Échelle des UV pour les briques
    vec2 scaled_uv = world_uv * 8.0;
    
    // Motif de briques
    vec2 brick_uv = brick_pattern(scaled_uv);
    
    // Déterminer si on est sur la brique ou le mortier
    bool is_mortar = (brick_uv.x < mortar_width || brick_uv.x > brick_width - mortar_width ||
                      brick_uv.y < mortar_width || brick_uv.y > brick_height - mortar_width);
    
    // Couleur de base
    vec3 final_color;
    float final_roughness;
    
    if (is_mortar) {
        final_color = mortar_color;
        final_roughness = base_roughness + 0.2;
    } else {
        // Variation de couleur sur les briques
        float brick_noise = noise(floor(scaled_uv / vec2(brick_width, brick_height)) * 3.0);
        final_color = mix(base_color, highlight_color, brick_noise * 0.3);
        final_roughness = base_roughness + (brick_noise - 0.5) * roughness_variation;
    }
    
    // Effet de brillance subtile avec le temps
    float time_factor = sin(TIME * time_speed + world_position.x * 0.1 + world_position.z * 0.1) * 0.5 + 0.5;
    float glow = time_factor * glow_intensity;
    
    // Ajouter de la variation de couleur avec le bruit
    vec2 detail_uv = scaled_uv * 4.0;
    float detail_noise = noise(detail_uv) * 0.1;
    final_color += vec3(detail_noise);
    
    // Effet de usure sur les bords
    float edge_wear = 1.0 - smoothstep(0.0, 0.1, min(min(brick_uv.x, brick_width - brick_uv.x), 
                                                     min(brick_uv.y, brick_height - brick_uv.y)));
    if (!is_mortar) {
        final_color = mix(final_color, mortar_color, edge_wear * 0.2);
    }
    
    // Éclat subtil
    final_color += vec3(glow * 0.1);
    
    ALBEDO = final_color;
    ROUGHNESS = clamp(final_roughness, 0.0, 1.0);
    METALLIC = base_metallic;
    
    // Léger effet d'émission pour le glow
    EMISSION = final_color * glow * 0.05;
}

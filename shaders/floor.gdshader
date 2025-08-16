shader_type spatial;

// Couleurs cartoon
uniform vec3 grass_color : source_color = vec3(0.3, 0.8, 0.2);
uniform vec3 dirt_color : source_color = vec3(0.6, 0.4, 0.2);
uniform vec3 accent_color : source_color = vec3(0.2, 0.6, 0.1);

// Paramètres simples
uniform float tile_scale : hint_range(1.0, 10.0, 0.1) = 4.0;
uniform float grass_coverage : hint_range(0.0, 1.0, 0.1) = 0.7;
uniform float pattern_size : hint_range(0.5, 3.0, 0.1) = 1.5;
uniform float cartoon_smoothness : hint_range(0.01, 0.3, 0.01) = 0.1;

varying vec3 world_position;

// Fonction de bruit simple et efficace
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

// Fonction pour créer des formes organiques simples
float organic_shape(vec2 uv) {
    // Plusieurs couches de bruit pour créer des formes naturelles
    float shape1 = noise(uv * pattern_size);
    float shape2 = noise(uv * pattern_size * 2.0 + vec2(100.0)) * 0.5;
    float shape3 = noise(uv * pattern_size * 4.0 + vec2(200.0)) * 0.25;
    
    return shape1 + shape2 + shape3;
}

void vertex() {
    world_position = VERTEX;
}

void fragment() {
    // UV de base
    vec2 base_uv = world_position.xz * tile_scale;
    
    // Créer des zones d'herbe et de terre avec des formes organiques
    float terrain_shape = organic_shape(base_uv);
    
    // Déterminer si c'est de l'herbe ou de la terre (style cartoon avec transitions nettes)
    float grass_mask = smoothstep(1.0 - grass_coverage - cartoon_smoothness, 
                                  1.0 - grass_coverage + cartoon_smoothness, 
                                  terrain_shape);
    
    // Couleur de base de la terre
    vec3 dirt = dirt_color;
    
    // Variation de la terre
    float dirt_variation = noise(base_uv * 3.0);
    dirt = mix(dirt, dirt * 1.2, dirt_variation * 0.3);
    
    // Ajouter des petites pierres dans la terre
    float pebbles = noise(base_uv * 8.0);
    pebbles = smoothstep(0.7, 0.9, pebbles);
    dirt = mix(dirt, dirt * 0.8, pebbles * 0.4);
    
    // Couleur de base de l'herbe
    vec3 grass = grass_color;
    
    // Variation de l'herbe avec des zones plus claires et plus sombres
    float grass_variation = noise(base_uv * 2.0);
    grass = mix(grass, accent_color, grass_variation * 0.4);
    
    // Ajouter des "touffes" d'herbe plus dense
    float grass_tufts = noise(base_uv * 6.0);
    grass_tufts = smoothstep(0.6, 0.8, grass_tufts);
    grass = mix(grass, grass * 1.3, grass_tufts * 0.5);
    
    // Ajouter des détails fins à l'herbe
    float grass_detail = noise(base_uv * 12.0) * 0.1;
    grass += vec3(0.0, grass_detail, grass_detail * 0.5);
    
    // Transition entre herbe et terre
    vec3 final_color = mix(dirt, grass, grass_mask);
    
    // Ajouter une variation globale de luminosité pour le style cartoon
    float global_brightness = noise(base_uv * 0.5) * 0.1 + 0.95;
    final_color *= global_brightness;
    
    // Saturation légèrement augmentée pour l'effet cartoon
    final_color = mix(vec3(dot(final_color, vec3(0.299, 0.587, 0.114))), final_color, 1.2);
    
    ALBEDO = final_color;
    ROUGHNESS = mix(0.98, 0.95, grass_mask); // Terre et herbe très mates, pas de brillance
    METALLIC = 0.0;
}
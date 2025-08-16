shader_type spatial;

// Couleurs d'herbe
uniform vec3 grass_light : source_color = vec3(0.2, 0.6, 0.1);
uniform vec3 grass_dark : source_color = vec3(0.1, 0.3, 0.05);

// Paramètres simples
uniform float tile_scale : hint_range(1.0, 16.0, 0.1) = 6.0;
uniform float wind_strength : hint_range(0.0, 0.5, 0.01) = 0.1;
uniform float variation_strength : hint_range(0.0, 1.0, 0.1) = 0.3;

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

void vertex() {
    world_position = VERTEX;
}

void fragment() {
    // UV avec échelle
    vec2 grass_uv = world_position.xz * tile_scale;
    
    // Bruit de base pour la variation d'herbe
    float grass_noise = noise(grass_uv);
    
    // Effet de vent subtil avec le temps
    vec2 wind_uv = grass_uv + vec2(TIME * 0.3, TIME * 0.1) * wind_strength;
    float wind_noise = noise(wind_uv) * 0.3;
    
    // Mélange des couleurs d'herbe
    float grass_variation = (grass_noise + wind_noise) * variation_strength;
    vec3 final_color = mix(grass_dark, grass_light, 0.5 + grass_variation);
    
    // Détails fins pour plus de réalisme
    float detail = noise(grass_uv * 4.0) * 0.1;
    final_color += vec3(0.0, detail, detail * 0.5);
    
    // Variation de brillance selon les zones
    float brightness_variation = noise(grass_uv * 0.5) * 0.2 + 0.9;
    final_color *= brightness_variation;
    
    ALBEDO = final_color;
    ROUGHNESS = 0.85;
    METALLIC = 0.0;
}
shader_type spatial;
render_mode specular_schlick_ggx;

// Couleur principale du métal
uniform vec4 metal_color : source_color = vec4(0.7, 0.75, 0.8, 1.0);
uniform float metallic_value : hint_range(0.0, 2.0) = 1.2;
uniform float roughness_value : hint_range(0.0, 1.0) = 0.15;

// Effets d'usure subtile
uniform float edge_darkening : hint_range(0.0, 1.0) = 0.3;
uniform float detail_scale : hint_range(1.0, 20.0) = 8.0;

varying vec3 world_position;
varying vec3 local_position;
varying vec3 world_normal;

// Fonction de bruit simple pour détails
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

// Calcul simple de distance aux arêtes
float edge_distance(vec3 pos) {
    vec3 abs_pos = abs(pos - 0.5);
    vec3 edge_dist = 0.5 - abs_pos;
    return min(min(edge_dist.x, edge_dist.y), edge_dist.z);
}

void vertex() {
    world_position = VERTEX;
    local_position = VERTEX;
    world_normal = NORMAL;
}

void fragment() {
    // UV selon la face pour détails subtils
    vec2 detail_uv;
    if (abs(world_normal.y) > 0.5) {
        detail_uv = local_position.xz * detail_scale;
    } else if (abs(world_normal.x) > 0.5) {
        detail_uv = local_position.zy * detail_scale;
    } else {
        detail_uv = local_position.xy * detail_scale;
    }
    
    // Couleur de base du métal (inspiré du premier shader)
    vec3 base_color = metal_color.rgb;
    
    // Assombrissement subtil des arêtes
    float edge_dist = edge_distance(local_position);
    float edge_factor = smoothstep(0.0, 0.15, edge_dist);
    edge_factor = mix(1.0 - edge_darkening, 1.0, edge_factor);
    
    // Variation très subtile pour casser l'uniformité
    float subtle_variation = noise(detail_uv) * 0.05;
    base_color *= (edge_factor + subtle_variation);
    
    // Micro-détails très fins
    float micro_noise = noise(detail_uv * 3.0) * 0.02;
    base_color += vec3(micro_noise);
    
    // Application des valeurs (inspiré du style des shaders de référence)
    ALBEDO = base_color;
    METALLIC = metallic_value;
    ROUGHNESS = roughness_value;
}

precision lowp float;
#define PI 3.141592653589793
#define HASHSCALE 0.1031
#define NUM_SHAPES 14

in vec2 v_Uv;

out vec4 f_Color;

uniform float u_Time;
uniform float u_WindowWidth;
uniform float u_WindowHeight;
uniform mat4 u_InvProjection;
uniform mat4 u_CameraToWorld;
uniform vec3 u_CameraPosition;
uniform samplerCube u_CubeMapTex;

struct Shape {
    vec3 position;
    vec3 size;
    vec4 color;
    int type;
};

struct SceneInfo {
    vec3 color;
    vec4 normal;
    float distance;
};

struct Ray {
    vec3 origin;
    vec3 direction;
};

float epsilonNorm = 0.001;
float epsilon = 0.01;

Shape shapes[NUM_SHAPES];

float hash(float p) {
    return fract(sin(p) * 43758.5453123);
}

float fade(float t) {
    return t * t * t * (t * (6. * t - 15.) + 10.);
}

float grad(float hash, float p) {
    int i = int(1e4 * hash);
    return (i & 1) == 0 ? p : -p;
}

float noise(float p) {
    float pi = floor(p), pf = p - pi, w = fade(pf);
    return mix(grad(hash(pi), pf), grad(hash(pi + 1.0), pf - 1.0), w) * 2.0;
}

Ray createRay(vec3 origin, vec3 direction) {
    Ray r;
    r.origin = origin;
    r.direction = direction;
    return r;
}

Ray createRayFromCamera(vec2 uv) {
    vec3 cameraOrigin = (u_CameraToWorld * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
    vec3 direction = (u_InvProjection * vec4(uv, 0.0, 1.0)).xyz;
    direction = (u_CameraToWorld * vec4(direction, 0.0)).xyz;
    return createRay(cameraOrigin, normalize(direction));
}

vec3 getColor(vec3 color, vec3 position, vec3 normal) {
    vec3 camPos = u_CameraPosition;
    // vec3 lightPos = vec3(-u_CameraPosition);
    vec3 lightPos = vec3(-u_CameraPosition);
    vec3 lightDir = normalize(position - lightPos);

    // ambient
    vec3 ambientColor = vec3(1.0, 1.0, 1.0);
    float ambientStrength = 0.15;
    vec3 ambient = ambientStrength * ambientColor;

    // Diffuse
    normal = normalize(normal);
    float diff = max(dot(normal, lightDir), 0.0);
    vec3 diffuse = diff * color;

    // Specular
    float specularStrength = 0.9999;

    vec3 viewDir = normalize(camPos);
    vec3 reflectDir = reflect(-lightDir, normal);
    float spec = pow(max(dot(viewDir, reflectDir), 0.0), 32.0);
    vec3 specular = specularStrength * spec * color;  

    // Reflection
    vec3 eyeToSurfaceDir = normalize(position - camPos);
    vec3 reflectionDir = reflect(eyeToSurfaceDir, normal);

    vec3 finalColor = (ambient + diffuse + specular) * color * 0.1 + 2.0 * (ambient + diffuse + specular) * texture(u_CubeMapTex, reflectionDir).xyz;
    // vec3 finalColor = 1.5 * (ambient + diffuse + specular ) * texture(u_CubeMapTex, reflectionDir).xyz;
    return finalColor;
}

float sphereDistance(vec3 eye, vec3 center, float radius) {
    return distance(eye, center) - radius;
}
float cubeDistance(vec3 eye, vec3 centre, vec3 size) {
    vec3 o = abs(eye - centre) - size;
    float ud = length(max(o, 0.0));
    float n = max(max(min(o.x, 0.0), min(o.y, 0.0)), min(o.z, 0.0));
    return ud + n;
}

float getShapeDist(vec3 origin, Shape shape) {
    float distance = 0.0;
    if(shape.type == 1) {
        distance = sphereDistance(origin, shape.position, shape.size.x);
    } else if(shape.type == 2) {
        distance = cubeDistance(origin, shape.position, shape.size);
    }
    return distance;
}

vec4 smoothBlend(float a, float b, vec3 colA, vec3 colB, float k) {
    float h = clamp(0.5 + 0.5 * (b - a) / k, 0.0, 1.0);
    float blendDst = mix(b, a, h) - k * h * (1.0 - h);
    vec3 blendCol = mix(colB, colA, h);
    return vec4(blendCol, blendDst);
}

SceneInfo getRaySceneInfo(vec3 origin) {
    SceneInfo info;
    info.distance = 100000000.0;
    // info.distance =  mandelbulbDistance(origin);
    info.color = vec3(1.0);
    for(int i = 0; i < NUM_SHAPES; i++) {
        vec4 b = smoothBlend(info.distance, getShapeDist(origin, shapes[i]), info.color.xyz, shapes[i].color.xyz, 2.0);
        info.distance = b.w;
        info.color = b.xyz;
      // info.distance = min(info.distance, getShapeDist(origin, shapes[i]));
      // info.color = shapes[i].color.xyz;
    }
    return info;
}

vec3 estimateNormal(vec3 p) {
    float x = getRaySceneInfo(vec3(p.x + epsilonNorm, p.y, p.z)).distance - getRaySceneInfo(vec3(p.x - epsilonNorm, p.y, p.z)).distance;
    float y = getRaySceneInfo(vec3(p.x, p.y + epsilonNorm, p.z)).distance - getRaySceneInfo(vec3(p.x, p.y - epsilonNorm, p.z)).distance;
    float z = getRaySceneInfo(vec3(p.x, p.y, p.z + epsilonNorm)).distance - getRaySceneInfo(vec3(p.x, p.y, p.z - epsilonNorm)).distance;
    return normalize(vec3(x, y, z));
}

void main() {
    shapes = Shape[NUM_SHAPES](Shape(vec3(noise(u_Time * 0.15 + 9000.0) * 5.0, noise(u_Time * 0.12 + 1000.0) * 4.5, noise(u_Time * 0.11 + 3000.0) * 6.0), vec3(2.0), vec4(1.0, 0.0, 0.0, 1.0), 1), Shape(vec3(noise(u_Time * 0.18 + 5000.0) * 5.0, noise(u_Time * 0.16 + 9000.0) * 4.5, noise(u_Time * 0.10 + 1000.0) * 6.0), vec3(2.0), vec4(0.0, 0.5, 1.0, 1.0), 1), Shape(vec3(noise(u_Time * 0.12 - 5000.0) * 5.0, noise(u_Time * 0.15 - 3000.0) * 4.5, noise(u_Time * 0.12 - 3000.0) * 6.0), vec3(2.0), vec4(1.0, 0.0, 1.0, 1.0), 1), Shape(vec3(noise(u_Time * 0.13 + 7000.0) * 5.0, noise(u_Time * 0.14 + 1000.0) * 4.5, noise(u_Time * 0.15 + 6000.0) * 6.0), vec3(2.0), vec4(0.0, 1.0, 1.0, 1.0), 1), Shape(vec3(noise(u_Time * 0.14 - 7000.0) * 5.0, noise(u_Time * 0.13 - 5000.0) * 4.5, noise(u_Time * 0.13 - 1000.0) * 6.0), vec3(2.0), vec4(1.0, 1.0, 0.0, 1.0), 1), Shape(vec3(noise(u_Time * 0.18 + 3000.0) * 5.0, noise(u_Time * 0.10 + 1500.0) * 4.5, noise(u_Time * 0.19 + 9000.0) * 6.0), vec3(2.0), vec4(1.0, 0.6, 0.2, 1.0), 1), Shape(vec3(noise(u_Time * 0.16 - 2000.0) * 5.0, noise(u_Time * 0.12 - 4500.0) * 4.5, noise(u_Time * 0.16 - 2000.0) * 6.0), vec3(2.0), vec4(0.1, 1.0, 0.2, 1.0), 1), Shape(vec3(noise(u_Time * 0.12 + 4000.0) * 5.0, noise(u_Time * 0.11 + 2200.0) * 4.5, noise(u_Time * 0.17 + 3200.0) * 6.0), vec3(2.0), vec4(1.0, 0.0, 0.0, 1.0), 1), Shape(vec3(noise(u_Time * 0.13 + 3000.0) * 5.0, noise(u_Time * 0.13 + 1600.0) * 4.5, noise(u_Time * 0.42 + 2700.0) * 6.0), vec3(2.0), vec4(0.0, 0.5, 1.0, 1.0), 1), Shape(vec3(noise(u_Time * 0.15 - 7900.0) * 5.0, noise(u_Time * 0.16 - 8800.0) * 4.5, noise(u_Time * 0.15 - 6400.0) * 6.0), vec3(2.0), vec4(1.0, 0.0, 1.0, 1.0), 1), Shape(vec3(noise(u_Time * 0.18 + 1300.0) * 5.0, noise(u_Time * 0.18 + 4200.0) * 4.5, noise(u_Time * 0.13 + 7100.0) * 6.0), vec3(2.0), vec4(0.0, 1.0, 1.0, 1.0), 1), Shape(vec3(noise(u_Time * 0.11 - 6400.0) * 5.0, noise(u_Time * 0.14 - 2800.0) * 4.5, noise(u_Time * 0.12 - 3200.0) * 6.0), vec3(2.0), vec4(1.0, 1.0, 0.0, 1.0), 1), Shape(vec3(noise(u_Time * 0.12 + 3400.0) * 5.0, noise(u_Time * 0.12 + 2100.0) * 4.5, noise(u_Time * 0.10 + 2400.0) * 6.0), vec3(2.0), vec4(1.0, 0.6, 0.2, 1.0), 1), Shape(vec3(noise(u_Time * 0.13 - 5030.0) * 5.0, noise(u_Time * 0.11 - 6900.0) * 4.5, noise(u_Time * 0.11 - 1500.0) * 6.0), vec3(2.0), vec4(0.1, 1.0, 0.2, 1.0), 1));

    vec2 uv = gl_FragCoord.xy / vec2(u_WindowWidth, u_WindowHeight) * 2.0 - 1.0;
    Ray ray = createRayFromCamera(uv);
    float maxDistance = 50.0;
    float marchedDist = 0.0;

    f_Color = vec4(0.0, 0.0, 0.0, 1.0);
    int maxStepCount = 200;
    int marchSteps = 0;
    while(marchedDist < maxDistance && marchSteps < maxStepCount) {
        marchSteps++;
        SceneInfo info = getRaySceneInfo(ray.origin);
        if(info.distance <= epsilon) {
            vec3 normal = estimateNormal(ray.origin);
            vec3 color = getColor(info.color, ray.origin, normal);
            f_Color = vec4(color, 1.0);
            break;
        }
        ray.origin += ray.direction * info.distance;
        marchedDist += info.distance;
    }
}

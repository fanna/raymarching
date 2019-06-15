precision mediump float;

uniform vec2 resolution;
uniform vec3 cameraPosition;
uniform float time;

#define MAX_STEPS 100
#define MAX_DIST 100.
#define SURF_DIST .01

const float EPSILON = 0.0001;

float sphereSDF(vec3 p, vec3 s) {
    return length(p - s.xyz) - 1.0;
}

float cubeSDF(vec3 p, vec3 c) {
    vec3 d = abs(p - c) - vec3(1.0, 1.0, 1.0);
    float insideDistance = min(max(d.x, max(d.y, d.z)), 0.0);
    float outsideDistance = length(max(d, 0.0));
    
    return insideDistance + outsideDistance;
}

float torusSDF(vec3 p, vec3 t) {
  vec2 q = vec2(length(p.xz - t.xz)-1.0,p.y - t.y);
  return length(q)-0.5;
}

float sceneSDF(vec3 p) {
	vec3 s = vec3(0, 1, 6);
	vec3 t = vec3(2, 1, 6);
	vec3 c = vec3(4, 1, 6);
    
    float torusDist = torusSDF(p, t);
    float sphereDist = sphereSDF(p, s);
    float cubeDist = cubeSDF(p, c);
    float planeDist = p.y;
    
    float d = min(torusDist, planeDist);
    d = min(d, sphereDist);
    d = min(d, cubeDist);
    return d;
}

float rayMarch(vec3 ro, vec3 rd) {
	float dO=0.;
    
    for(int i=0; i<MAX_STEPS; i++) {
    	vec3 p = ro + rd*dO;
        float dS = sceneSDF(p);
        dO += dS;
        if(dO>MAX_DIST || dS<SURF_DIST) break;
    }
    
    return dO;
}

vec3 estimateNormal(vec3 p) {
    return normalize(vec3(
        sceneSDF(vec3(p.x + EPSILON, p.y, p.z)) - sceneSDF(vec3(p.x - EPSILON, p.y, p.z)),
        sceneSDF(vec3(p.x, p.y + EPSILON, p.z)) - sceneSDF(vec3(p.x, p.y - EPSILON, p.z)),
        sceneSDF(vec3(p.x, p.y, p.z  + EPSILON)) - sceneSDF(vec3(p.x, p.y, p.z - EPSILON))
    ));
}

vec3 phongContribForLight(vec3 kd, vec3 ks, float alpha, vec3 p, vec3 eye, vec3 lightPos, vec3 lightIntensity) {
    vec3 N = estimateNormal(p);
    vec3 L = normalize(lightPos - p);
    vec3 V = normalize(eye - p);
    vec3 R = normalize(reflect(-L, N));
    
    float dotLN = dot(L, N);
    float dotRV = dot(R, V);
    
    float d = rayMarch(p + N * SURF_DIST * 2.0, L);
    if(d < length(lightPos-p)) {
        lightIntensity *= .1;
    }

    if (dotLN < 0.0) {
        return vec3(0.0, 0.0, 0.0);
    } 
    
    if (dotRV < 0.0) {
        return lightIntensity * (kd * dotLN);
    }
    return lightIntensity * (kd * dotLN + ks * pow(dotRV, alpha));
}

vec3 phongIllumination(vec3 ka, vec3 kd, vec3 ks, float alpha, vec3 p, vec3 eye) {
    const vec3 ambientLight = 0.5 * vec3(1.0, 1.0, 1.0);
    vec3 color = ambientLight * ka;
    
    vec3 lightPos = vec3(4.0, 10.0, 4.0);
    vec3 lightIntensity = vec3(0.6, 0.6, 0.6);
    
    color += phongContribForLight(kd, ks, alpha, p, eye, lightPos, lightIntensity);
    return color;
}

void main() {
    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;

    vec3 col = vec3(0);
    
    vec3 ro = vec3(cameraPosition);
    vec3 rd = normalize(vec3(uv.x, uv.y, 1));

    float d = rayMarch(ro, rd);
    
    vec3 p = ro + rd * d;

    vec3 Ka = vec3(0.2, 0.2, 0.2);
    vec3 Kd = vec3(0.298, 0.698, 0.2);
    vec3 Ks = vec3(1.0, 1.0, 1.0);
    float shininess = 10.0;
    
    col = phongIllumination(Ka, Kd, Ks, shininess, p, ro); 
    
    gl_FragColor = vec4(col,1.0);
}
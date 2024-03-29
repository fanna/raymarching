precision mediump float;

uniform vec2 resolution;
uniform vec3 cameraPosition;
uniform float time;

#define MAX_STEPS 100
#define MAX_DIST 100.
#define SURF_DIST .01

const float EPSILON = .0001;

float smin( float a, float b, float k ) {
    float h = clamp( 0.5+0.5*(b-a)/k, 0., 1. );
    return mix( b, a, h ) - k*h*(1.0-h);
}

float planeSDF(vec3 p){
    return p.y;
}

float sphereSDF(vec3 p,vec3 s){
    return length(p-s.xyz)-1.;
}

float cubeSDF(vec3 p,vec3 c){
    vec3 d=abs(p-c)-vec3(1.,1.,1.);
    float insideDistance=min(max(d.x,max(d.y,d.z)),0.);
    float outsideDistance=length(max(d,0.));
    
    return insideDistance+outsideDistance;
}

float torusSDF(vec3 p,vec3 t){
    vec2 q=vec2(length(p.xz-t.xz)-1.,p.y-t.y);
    return length(q)-.5;
}

float sceneSDF(vec3 p){
    vec3 s=vec3(0,1,6);
    vec3 t=vec3(2,1,6);
    vec3 c=vec3(4,1,6);
    
    float torusDist=torusSDF(p,t);
    float sphereDist=sphereSDF(p,s);
    float cubeDist=cubeSDF(p,c);
    float planeDist=planeSDF(p);
    
    float d=smin(torusDist,planeDist, 2.0);
    d=smin(d,sphereDist, 2.0);
    d=smin(d,cubeDist, 2.0);
    return d;
}

float rayMarch(vec3 ro,vec3 rd){
    float dO=0.;
    
    for(int i=0;i<MAX_STEPS;i++){
        vec3 p=ro+rd*dO;
        float dS=sceneSDF(p);
        dO+=dS;
        if(dO>MAX_DIST||dS<SURF_DIST)break;
    }
    
    return dO;
}

vec3 estimateNormal(vec3 p){
    return normalize(vec3(
            sceneSDF(vec3(p.x+EPSILON,p.y,p.z))-sceneSDF(vec3(p.x-EPSILON,p.y,p.z)),
            sceneSDF(vec3(p.x,p.y+EPSILON,p.z))-sceneSDF(vec3(p.x,p.y-EPSILON,p.z)),
            sceneSDF(vec3(p.x,p.y,p.z+EPSILON))-sceneSDF(vec3(p.x,p.y,p.z-EPSILON))
    ));
}
    
vec3 phongContribForLight(vec3 kd,vec3 ks,float alpha,vec3 p,vec3 eye,vec3 lightPos,vec3 lightIntensity){
    vec3 N=estimateNormal(p);
    vec3 L=normalize(lightPos-p);
    vec3 V=normalize(eye-p);
    vec3 R=normalize(reflect(-L,N));
    
    float dotLN=dot(L,N);
    float dotRV=dot(R,V);
    
    float d=rayMarch(p+N*SURF_DIST*2.,L);
    if(d<length(lightPos-p)){
        lightIntensity*=.2;
    }
    
    if(dotLN<0.){
        return vec3(0.,0.,0.);
    }
    
    if(dotRV<0.){
        return lightIntensity*(kd*dotLN);
    }
    return lightIntensity*(kd*dotLN+ks*pow(dotRV,alpha));
}
    
vec3 phongIllumination(vec3 ka,vec3 kd,vec3 ks,float alpha,vec3 p,vec3 eye){
    const vec3 ambientLight=.5*vec3(1.,1.,1.);
    vec3 color=ambientLight*ka;
    
    vec3 lightPos=vec3(4.,10.,4.);
    vec3 lightIntensity=vec3(.6,.6,.6);
    
    color+=phongContribForLight(kd,ks,alpha,p,eye,lightPos,lightIntensity);
    return color;
}
    
void main(){
    vec2 uv=(gl_FragCoord.xy-.5*resolution.xy)/resolution.y;
    
    vec3 col=vec3(0);
    
    vec3 ro=vec3(cameraPosition);
    vec3 rd=normalize(vec3(uv.x,uv.y,1));
    
    float d=rayMarch(ro,rd);
    
    vec3 p=ro+rd*d;
    
    vec3 Ka=vec3(.2,.2,.2);
    vec3 Kd= estimateNormal(p) / cameraPosition;
    vec3 Ks=vec3(.2,.2,.2);
    float shininess=10.;
    
    col=phongIllumination(Ka,Kd,Ks,shininess,p,ro);
    
    gl_FragColor=vec4(col,1.);
}
#version 460 core
#include <flutter/runtime_effect.glsl>

uniform vec2 u_resolution;
uniform vec2 u_tilt;
uniform float u_press;

out vec4 fragColor;

// 抗锯齿等级：2.0 代表 2x2 采样（共4次采样）
#define AA 8.0 

mat2 rot(float a) {
    float s = sin(a), c = cos(a);
    return mat2(c, -s, s, c);
}

float hash(vec2 p) {
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

float sdBox(vec3 p, vec3 b) {
    vec3 q = abs(p) - b;
    return length(max(q, 0.0)) + min(max(q.x, max(q.y, q.z)), 0.0);
}

// 2D 三角形 SDF (用于绘制表面图案)
float sdTriangle(vec2 p, float r) {
    const float k = sqrt(3.0);
    p.x = abs(p.x) - r;
    p.y = p.y + r/k;
    if( p.x+k*p.y>0.0 ) p = vec2(p.x-k*p.y,-k*p.x-p.y)/2.0;
    p.x -= clamp( p.x, -2.0*r, 0.0 );
    return -length(p)*sign(p.y);
}

// 物理变换函数
vec3 transform(vec3 p) {
    vec3 pivot = vec3(0.0, 0.0, 0.1);
    p -= pivot;
    float tiltAmount = 0.28; 
    p.xz *= rot(u_tilt.x * -tiltAmount); 
    p.yz *= rot(u_tilt.y * -tiltAmount);
    p.z += u_press * 0.08; 
    p += pivot;
    return p;
}

float getDist(vec3 p) {
    p = transform(p);

    float armLen = 0.95;
    float armWidth = 0.22;
    float baseThickness = 0.08;
    float slopeFactor = 0.18; 

    // 十字键主体计算
    vec3 ph = p; ph.z += abs(p.x) * slopeFactor; 
    float hBox = sdBox(ph, vec3(armLen, armWidth, baseThickness)) - 0.1;
    
    vec3 pv = p; pv.z += abs(p.y) * slopeFactor;
    float vBox = sdBox(pv, vec3(armWidth, armLen, baseThickness)) - 0.1;
    
    return min(hBox, vBox);
}

vec3 getNormal(vec3 p) {
    float d = getDist(p);
    vec2 e = vec2(0.002, 0);
    vec3 n = d - vec3(getDist(p-e.xyy), getDist(p-e.yxy), getDist(p-e.yyx));
    return normalize(n);
}

vec4 render(vec2 uv) {
    vec3 ro = vec3(0, 0, -4.5); 
    vec3 rd = normalize(vec3(uv, 1.8));

    float dO = 0.0;
    bool hit = false;
    
    for(int i=0; i<80; i++) {
        float dS = getDist(ro + rd * dO);
        if(dS < 0.001) {
            hit = true;
            break;
        }
        dO += dS;
        if(dO > 10.0) break;
    }

    if(!hit) return vec4(0.0, 0.0, 0.0, 0.0); 

    vec3 p_world = ro + rd * dO;
    vec3 p_local = transform(p_world); // 获取局部坐标用于图案绘制
    
    // --- 表面图案计算 ---
    float triSize = 0.12;
    float triPos = 0.72;
    float thickness = 0.02; // 线条粗细
    
    // 计算四个方向的 2D 三角形
    float dUp = sdTriangle(p_local.xy - vec2(0, triPos), triSize);
    float dDown = sdTriangle(vec2(p_local.x, -p_local.y - triPos), triSize);
    float dLeft = sdTriangle(vec2(p_local.y, -p_local.x - triPos), triSize);
    float dRight = sdTriangle(vec2(-p_local.y, p_local.x - triPos), triSize);
    
    float minDist = min(min(dUp, dDown), min(dLeft, dRight));
    
    // 使用 abs(dist) < thickness 来创建一个“框”
    // 使用 smoothstep 来抗锯齿边缘
    float pattern = smoothstep(thickness, thickness - 0.01, abs(minDist));

    vec3 n = getNormal(p_world);
    n = normalize(n + hash(p_world.xy * 350.0) * 0.008); 
    
    vec3 r = reflect(rd, n);
    // 主光源：左上方稍微偏前，增强立体感
    vec3 l = normalize(vec3(-2.0, -4.0, -3.0) - p_world);
    // 补光：右下方微弱冷光，勾勒轮廓
    vec3 l2 = normalize(vec3(3.0, 2.0, -2.0) - p_world);

    vec3 gold = vec3(1.0, 0.8, 0.0);
    vec3 black = vec3(0.07, 0.07, 0.08);
    
    // 混合表面颜色：金色基底 + 黑色线框
    vec3 baseColor = mix(gold, black, pattern);

    // 主光照
    float dif = clamp(dot(n, l), 0.0, 1.0);
    // 降低高光指数使光斑更宽更亮
    float specPower = mix(45.0, 12.0, pattern);
    float spec = pow(clamp(dot(r, l), 0.0, 1.0), specPower);
    
    // 补光照
    float dif2 = clamp(dot(n, l2), 0.0, 1.0);
    
    float fresnel = pow(1.0 + dot(rd, n), 3.0); // 增强菲涅尔效应
    
    // 混合光照
    vec3 col = baseColor * (dif * 0.9 + 0.15); // 提高主光强度和环境光底色
    col += baseColor * dif2 * 0.2; // 添加补光漫反射
    
    // 仅在非线框区域增加强烈高光
    float specMask = 1.0 - pattern;
    col += vec3(0.9, 0.95, 1.0) * fresnel * 0.5 * specMask; // 增强边缘反光
    col += vec3(1.0, 0.98, 0.9) * spec * 1.2 * specMask; // 显著增强高光强度
    
    // 黑色区域微弱高光
    col += spec * 0.15 * pattern;
    
    // 环境遮蔽
    col *= (smoothstep(0.7, -0.5, p_local.z) * 0.4 + 0.6);

    return vec4(col, 1.0);
}

void main() {
    vec4 finalCol = vec4(0.0);
    
    for(float m=0.0; m<AA; m++) {
        for(float n=0.0; n<AA; n++) {
            vec2 offset = (vec2(m, n) / AA) - 0.5;
            vec2 uv = (FlutterFragCoord().xy + offset - 0.5 * u_resolution.xy) / min(u_resolution.y, u_resolution.x);
            finalCol += render(uv);
        }
    }
    finalCol /= (AA * AA);

    fragColor = vec4(pow(finalCol.rgb, vec3(0.4545)), finalCol.a);
}
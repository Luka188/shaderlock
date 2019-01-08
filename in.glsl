float nrand(float x, float y)
{
    return fract(sin(dot(vec2(x, y), vec2(12.9898, 78.233))) * 43758.5453);
}
float GlitchAmount = 0.8;

vec4 posterize(vec4 color, float numColors)
{
    return floor(color * numColors - 0.5) / numColors;
}

vec2 quantize(vec2 v, float steps)
{
    return floor(v * steps) / steps;
}

float dist(vec2 a, vec2 b)
{
    return sqrt(pow(b.x - a.x, 2.0) + pow(b.y - a.y, 2.0));
}

vec2 _ScanLineJitter = vec2(0.1,0.8); // (displacement, threshold)
vec2 _VerticalJump = vec2(0.0,1);   // (amount, time)
float _HorizontalShake = 1.;
vec2 _ColorDrift = vec2(0.2,1); // (amount, time)
void mainImage(out vec4 fragColor, in vec2 fragCoord) {
   vec2 st = -fragCoord.xy/iResolution.xy;
    float u = st.x;
    float v = st.y;
    float jitter = nrand(v, fract(iGlobalTime)) * 2. - 1.;
    jitter *= step(_ScanLineJitter.y, abs(jitter)) * _ScanLineJitter.x;
    float jump = mix(v, fract(v + _VerticalJump.y), _VerticalJump.x);
    float shake = (nrand(iGlobalTime, 2) - 0.5) * _HorizontalShake;
    float drift = sin(jump + _ColorDrift.y) * _ColorDrift.x;
    vec4 src1 = texture(iChannel0, fract(vec2(u + jitter + shake, jump)));
    vec4 src2 = texture(iChannel0, fract(vec2(u + jitter + shake + drift, jump)));
    fragColor.rgba = vec4(src1.r, src2.g, src1.b, 1);
    vec2 uv = vec2(st.x,st.y);
    float amount = pow(GlitchAmount, 2.0);
    vec2 pixel = 1.0 / iResolution.xy;
    vec4 color = texture(iChannel0, uv);
    if (fragCoord.x < iMouse.x)
    {
        fragColor = color;
        return;
    }
    float t = mod(mod(iGlobalTime, amount * 100.0 * (amount - 0.5)) * 109.0, 1.0);
    vec4 postColor = posterize(color, 16.0);
    vec4 a = posterize(texture(iChannel0, quantize(uv, 64.0 * t) + pixel * (postColor.rb - vec2(.5)) * 100.0), 5.0).rbga;
    vec4 b = posterize(texture(iChannel0, quantize(uv, 32.0 - t) + pixel * (postColor.rg - vec2(.5)) * 1000.0), 4.0).gbra;
    vec4 c = posterize(texture(iChannel0, quantize(uv, 16.0 + t) + pixel * (postColor.rg - vec2(.5)) * 20.0), 16.0).bgra;
    fragColor = (fragColor + mix(
        			texture(iChannel0,
                              uv + amount * (quantize((a * t - b + c - (t + t / 2.0) / 10.0).rg, 16.0) - vec2(.5)) * pixel * 100.0),
                    (a + b + c) / 3.0,
                    (0.5 - (dot(color, postColor) - 1.5)) * amount)) /2;
}
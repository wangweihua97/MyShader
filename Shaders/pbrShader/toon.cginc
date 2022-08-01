#include "core.cginc"
#include "toonInput.cginc"

struct EyeVInput {
    float4 vertex : POSITION;
    float3 normal : NORMAL;
    float4 tangent : TANGENT;
    float2 texcoord0 : TEXCOORD0;
}; 

struct EyeVOutput {
    float4 pos : SV_POSITION;
    float2 uv0 : TEXCOORD0;
    float4 posWorld : TEXCOORD1;
    float3 normalDir : TEXCOORD2;
    float3 tangentDir : TEXCOORD3;
    float3 bitangentDir : TEXCOORD4;
    float4 ambientOrLightmapUV : TEXCOORD5;
    LIGHTING_COORDS(5,6)
    UNITY_FOG_COORDS(7)
    float isNear1 : TEXCOORD7;
    float3 pupilWorldPosition : TEXCOORD8;
};

fOut ToonSkinFragForwardBase(VOutput i) : SV_Target
{
    fOut o;
    float3 mainColor = tex2D(_MainTex,TRANSFORM_TEX(i.uv0, _MainTex));
    float3x3 tangentTransform = float3x3( i.tangentDir, i.bitangentDir, i.normalDir);
    float3 _NormalMap_var = UnpackScaleNormal(tex2D(_Normal_M, i.uv0),1);
    float3 v = normalize(_WorldSpaceCameraPos.xyz - i.posWorld.xyz);
    float3 n = normalize(mul(_NormalMap_var.rgb, tangentTransform).rgb);
    float3 l = normalize(_WorldSpaceLightPos0.xyz);
    float3 h = normalize(v+l);
    
    float nl = dot(n,l)*0.5 + 0.5;
    float3 ramp = tex2D(_ColorRamp,TRANSFORM_TEX(float2(nl ,0.5), _ColorRamp));
    float4 finalColor = float4(mainColor * ramp ,1);
    o.col = finalColor;
    //float3 worldPos = half3(i.posWorld.x*0.5/_X_Range + 0.5,i.posWorld.y*0.5/_Y_Range + 0.5,i.posWorld.z*0.5/_Z_Range + 0.5);
    o.worldPos_r = float4(i.posWorld.xyz ,1);
    float3 worldNor= n*0.5+float3(0.5,0.5,0.5);
    o.worldNor_s = float4(n,0);
    return o;
}

fOut ToonEyebrowForwardBase(VOutput i) : SV_Target
{
    fOut o;
    float3 n = normalize(i.normalDir);
    float3 l = normalize(_WorldSpaceLightPos0.xyz);
    
    float3 mainColor = tex2D(_MainTex,TRANSFORM_TEX(i.uv0, _MainTex)).rgb;
    
    float nl = max(dot(n,l) ,0.0);
    float atten = saturate((nl - _BaseColor_Step)/_BaseShade_Feather);
    float3 finalColor = lerp(mainColor * _ShadeColor ,mainColor * _BaseColor ,atten);
    
    o.col = float4(finalColor ,1.0);
    o.worldPos_r = float4(i.posWorld.xyz ,1);
    float3 worldNor= n*0.5+float3(0.5,0.5,0.5);
    o.worldNor_s = float4(n,0);
    return o;
}

fOut ToonHairForwardBase(VOutput i) : SV_Target
{
    fOut o;
    float3 n = i.posWorld.xyz - _HairCenter.xyz;
    n.y = max(n.y ,0.0);
    n = normalize(n);
    float3 l = normalize(_WorldSpaceLightPos0.xyz);
    
    float3 mainColor = tex2D(_MainTex,TRANSFORM_TEX(i.uv0, _MainTex)).rgb;
    
    float nl = max(dot(n,l) ,0.0);
    float atten = saturate((nl - _BaseColor_Step)/_BaseShade_Feather);
    float3 finalColor = lerp(mainColor * _ShadeColor ,mainColor * _BaseColor ,atten);
    
#ifdef _BlendHair
    o.col = float4(finalColor ,0.5);
#else
    o.col = float4(finalColor ,1.0);
#endif
    o.worldPos_r = float4(i.posWorld.xyz ,1);
    float3 worldNor= n*0.5+float3(0.5,0.5,0.5);
    o.worldNor_s = float4(n,0);
    return o;
}

fOut ToonFaceForwardBase(VOutput i) : SV_Target
{
    fOut o;
    float isRightFace = step(0, dot(i.posWorld.xyz - _NoseWorldPosition.xyz, _NoseWorldRightDir.xyz));
    float3 n = normalize(i.normalDir);
    float3 l = normalize(_WorldSpaceLightPos0.xyz);
    
    float3 mainColor = tex2D(_MainTex,TRANSFORM_TEX(i.uv0, _MainTex)).rgb;
    float isSahdow = 0;
    float2 uv = isRightFace * i.uv0 + (1 - isRightFace)*float2(1 - i.uv0.x ,i.uv0.y);
    half4 leftSdfTex = tex2D(_Left_Sdf, uv);
    half4 rightSdfTex = tex2D(_Right_Sdf, uv);
    float3 right = normalize(float3(_NoseWorldRightDir.x,0,_NoseWorldRightDir.z));
    float3 Front = normalize(float3(_NoseWorldForwardDir.x,0,_NoseWorldForwardDir.z));
    float ctrl = 1 - clamp(0, 1, dot(Front, l) * 0.5 + 0.5);
    float ilm = dot(l, right) > 0 ? rightSdfTex.r : leftSdfTex.r;
    isSahdow = step(ilm, ctrl);
    float bias = smoothstep(0, _LerpMax, abs(ctrl - ilm));
    float Set_FinalShadowMask = bias * isSahdow;
    float3 finalColor = lerp(mainColor * _BaseColor , mainColor * _ShadeColor ,Set_FinalShadowMask);
    
    o.col = float4(finalColor ,1.0);
    o.worldPos_r = float4(i.posWorld.xyz ,1);
    float3 worldNor= n*0.5+float3(0.5,0.5,0.5);
    o.worldNor_s = float4(n,0);
    return o;
}

EyeVOutput EyeVertexForwardBase(EyeVInput v)
{
    EyeVOutput o;
    
    o.uv0 = v.texcoord0;
    o.normalDir = UnityObjectToWorldNormal(v.normal);
    o.tangentDir = normalize( mul( unity_ObjectToWorld, float4( v.tangent.xyz, 0.0 ) ).xyz );
    o.bitangentDir = normalize(cross(o.normalDir, o.tangentDir) * v.tangent.w);
    o.posWorld = mul(unity_ObjectToWorld, v.vertex);
    o.posWorld /= o.posWorld.w;
    o.pos = UnityObjectToClipPos( v.vertex );
    UNITY_TRANSFER_FOG(o,o.pos);
    TRANSFER_VERTEX_TO_FRAGMENT(o);
    float3 pupil1Distance =  _Pupil1WorldPosition.xyz - o.posWorld;
    float3 pupil2Distance =  _Pupil2WorldPosition.xyz - o.posWorld;
    o.isNear1 = step(pupil1Distance.x*pupil1Distance.x + pupil1Distance.y*pupil1Distance.y + pupil1Distance.z*pupil1Distance.z ,
                                     pupil2Distance.x*pupil2Distance.x + pupil2Distance.y*pupil2Distance.y + pupil2Distance.z*pupil2Distance.z );
    o.pupilWorldPosition = o.isNear1*_Pupil1WorldPosition.xyz + (1 - o.isNear1)*_Pupil2WorldPosition.xyz;
    return o;
}


fOut ToonEyeFragForwardBase(EyeVOutput i) : SV_Target
{
    fOut o;
    UNITY_LIGHT_ATTENUATION(atten,i,i.posWorld);
    float3 worldL = WorldSpaceLightDir(float4(i.posWorld.xyz ,1)).xyz;
    worldL = normalize(float3(worldL.x ,0 ,worldL.z));
    float3 worldNormal = normalize(i.posWorld - i.pupilWorldPosition.xyz);
    float NdotL = saturate(dot(worldL ,i.normalDir));
    
    
    //--------------------------
    float3x3 tangentTransform = float3x3( i.tangentDir, i.bitangentDir, i.normalDir);
    float4x4 W2L_mat = i.isNear1 * _WorldToLocalMatrixMat1 + (1 - i.isNear1)*_WorldToLocalMatrixMat2;
    float3 localPos = mul(W2L_mat ,float4(i.posWorld.xyz,1)).xyz;
    float3 V = normalize(_WorldSpaceCameraPos.xyz -  i.posWorld);
    V = normalize(refract(-V, worldNormal, 0.6));
    //float3 localV = -normalize(mul(W2L_mat ,float4(V,1)).xyz);
    float3 localV = mul(V ,transpose(tangentTransform));
    float rd = saturate(sqrt(localPos.x *localPos.x+localPos.y*localPos.y) /_Radius);
    float ch = sqrt(1 - rd*rd);
    float ph = 0;
    float deep = 0;
    float2 cPos = float2(localPos.x,localPos.y);
    while(ch > deep)
    {
        deep += 0.2;
        cPos += 0.2*_Radius*float2(localV.x,localV.y)/localV.z;
        float cd = saturate(length(float2(cPos.x,cPos.y)) /_Radius);
        ph = ch;
        ch = sqrt(1 - cd*cd);
    }
    float temp = (ph -deep +0.2)/(deep -ch);
    ch = deep-0.2/(1 + temp);
    
    float3 bitangentV = mul(V ,transpose(tangentTransform));
    float2 uvOffset = float2(localV.x,localV.y)/localV.z*ch*_Height2UV_Factor;
    
    float4 baseColor = tex2D(_MainTex, i.uv0 - uvOffset)*_BaseColor;
    
    float4 shadowColor = tex2D(_MainTex, i.uv0 - uvOffset)*_ShadeColor;
    float4 diffuse = lerp(shadowColor ,baseColor ,NdotL*atten);
    float4 color = diffuse;
    
    float3 viewPos = UnityWorldSpaceViewDir(float4(i.posWorld.xyz ,1));
    float3 r = reflect(viewPos, worldNormal);
    r = normalize(r);
    float m = 2.0 * sqrt(r.x * r.x + r.y * r.y + (r.z + 1) * (r.z + 1));
    fixed4 mat = tex2Dlod(_MatCap_Sampler,float4( r.xy / m + 0.5,0,_BlurLevelMatcap)) * _MatCapColor * _MatCapIntensity;
#ifdef _ALPHA
    float4 final = float4(color.rgb + mat.rgb,color.a);
#else
    float4 final = float4(color.rgb + mat.rgb,1);
#endif
    
    UNITY_APPLY_FOG(i.fogCoord, final);
    o.col = final;
    o.worldPos_r = float4(i.posWorld.xyz ,0);
    float3 worldNor= worldNormal*0.5+float3(0.5,0.5,0.5);
    o.worldNor_s = float4(worldNormal,0);
    return o;
}
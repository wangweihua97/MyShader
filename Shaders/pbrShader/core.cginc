#include "input.cginc"
#include "UnityStandardCore.cginc"
#include "AutoLight.cginc"
#include "UnityPBSLighting.cginc"
#include "brdf.cginc"

struct VInput {
    float4 vertex : POSITION;
    float3 normal : NORMAL;
    float4 tangent : TANGENT;
    float2 texcoord0 : TEXCOORD0;
    float2 uv1      : TEXCOORD1;
#if defined(DYNAMICLIGHTMAP_ON) || defined(UNITY_PASS_META)
    float2 uv2      : TEXCOORD2;
#endif
}; 

struct VOutput {
    float4 pos : SV_POSITION;
    float2 uv0 : TEXCOORD0;
    float4 posWorld : TEXCOORD1;
    float3 normalDir : TEXCOORD2;
    float3 tangentDir : TEXCOORD3;
    float3 bitangentDir : TEXCOORD4;
    float4 ambientOrLightmapUV : TEXCOORD5;
    LIGHTING_COORDS(5,6)
    UNITY_FOG_COORDS(7)
};

struct fOut
{
    half4 col :COLOR;
    float4 worldPos_r;
    half4 worldNor_s;
};

inline half4 VertexGIForward(VInput v, float3 posWorld, half3 normalWorld)
{
    half4 ambientOrLightmapUV = 0;
    // Static lightmaps
    #ifdef LIGHTMAP_ON
        ambientOrLightmapUV.xy = v.uv1.xy * unity_LightmapST.xy + unity_LightmapST.zw;
        ambientOrLightmapUV.zw = 0;
    // Sample light probe for Dynamic objects only (no static or dynamic lightmaps)
    #elif UNITY_SHOULD_SAMPLE_SH
        #ifdef VERTEXLIGHT_ON
            // Approximated illumination from non-important point lights
            ambientOrLightmapUV.rgb = Shade4PointLights (
                unity_4LightPosX0, unity_4LightPosY0, unity_4LightPosZ0,
                unity_LightColor[0].rgb, unity_LightColor[1].rgb, unity_LightColor[2].rgb, unity_LightColor[3].rgb,
                unity_4LightAtten0, posWorld, normalWorld);
        #endif

        ambientOrLightmapUV.rgb = ShadeSHPerVertex (normalWorld, ambientOrLightmapUV.rgb);
    #endif

    #ifdef DYNAMICLIGHTMAP_ON
        ambientOrLightmapUV.zw = v.uv2.xy * unity_DynamicLightmapST.xy + unity_DynamicLightmapST.zw;
    #endif

    return ambientOrLightmapUV;
}

VOutput VertexForwardBase(VInput v)
{
    VOutput o;
    
    o.uv0 = v.texcoord0;
    o.normalDir = UnityObjectToWorldNormal(v.normal);
    o.tangentDir = normalize( mul( unity_ObjectToWorld, float4( v.tangent.xyz, 0.0 ) ).xyz );
    o.bitangentDir = normalize(cross(o.normalDir, o.tangentDir) * v.tangent.w);
    o.posWorld = mul(unity_ObjectToWorld, v.vertex);
    o.posWorld /= o.posWorld.w;
    o.ambientOrLightmapUV = VertexGIForward(v, o.posWorld , o.normalDir);
    o.pos = UnityObjectToClipPos( v.vertex );
    UNITY_TRANSFER_FOG(o,o.pos);
    TRANSFER_VERTEX_TO_FRAGMENT(o);
    return o;
}

fOut FragForwardBase(VOutput i) : SV_Target
{
    fOut o;
    float3x3 tangentTransform = float3x3( i.tangentDir, i.bitangentDir, i.normalDir);
    float3 _Main_var = tex2D( _Main_M,i.uv0).rgb;
    float3 main_Color =  _Main_var*_Main_Color.rgb;
    float3 _NormalMap_var = UnpackScaleNormal(tex2D(_Normal_M, i.uv0),1);
    float3 _RMO_var = tex2D( _RMO_M,i.uv0).rgb;
    float smoothness = 1 - _RMO_var.r;
    float3 v = normalize(_WorldSpaceCameraPos.xyz - i.posWorld.xyz);
    float3 n = normalize(mul(_NormalMap_var.rgb, tangentTransform).rgb);
    float3 l = _WorldSpaceLightPos0.xyz;
    float3 h = normalize(v+l);
    UNITY_LIGHT_ATTENUATION(atten, i, i.posWorld.xyz);
    UnityLight light;
    light.color = _LightColor0.rgb;
    light.dir = l;
    float oneMinusReflectivity;
    float3 specColor;
    float3 albedo = DiffuseAndSpecularFromMetallic (main_Color, _RMO_var.g, /*out*/ specColor, /*out*/ oneMinusReflectivity);
#ifdef _USE_SHADOW_COLOR
    atten = saturate((0.5*dot(l,n) + 0.5 - _BaseColor_Step)/_BaseShade_Feather);
    albedo = lerp(albedo * _ShadowDiffColor.rgb ,albedo ,atten);
    specColor = lerp(specColor * _ShadowSpecColor.rgb,specColor ,atten);
#endif
    //float oneMinusReflectivity = OneMinusReflectivityFromMetallic(_RMO_var.g);
    //float3 specColor = lerp(unity_ColorSpaceDielectricSpec.rgb, main_Color, _RMO_var.g);
    FragmentCommonData s;
    s.smoothness = 1 - _RMO_var.r;
    s.eyeVec = -v;
    s.normalWorld = n;
    //s.reflUVW = n;
    s.diffColor = albedo;
    s.specColor = specColor;
    s.oneMinusReflectivity = oneMinusReflectivity;

               /*UnityGI    gi = (UnityGI)0;
               gi.light = light;
               gi.light.color *= atten;
#if UNITY_SHOULD_SAMPLE_SH
               gi.indirect.diffuse =  ShadeSHPerPixel(n, half3(0, 0, 0), i.posWorld);
#endif
               gi.indirect.specular =  unity_IndirectSpecColor.rgb;
               
                UnityGIInput d;
                d.light = light;
                d.worldPos = i.posWorld;
                d.worldViewDir = v;
                d.atten = atten; 
                d.ambient = half3(0, 0, 0);//ShadeSHPerVertex(_NormalMap_var, half3(0, 0, 0));
                d.lightmapUV = 0; 


                d.probeHDR[0] = unity_SpecCube0_HDR;
                d.probeHDR[1] = unity_SpecCube1_HDR;
                d.boxMin[0] = unity_SpecCube0_BoxMin; // .w holds lerp value for blending
#ifdef UNITY_SPECCUBE_BOX_PROJECTION
                d.boxMax[0] = unity_SpecCube0_BoxMax;
                d.probePosition[0] = unity_SpecCube0_ProbePosition;
                d.boxMax[1] = unity_SpecCube1_BoxMax;
                d.boxMin[1] = unity_SpecCube1_BoxMin;
                d.probePosition[1] = unity_SpecCube1_ProbePosition;
#endif
                //if (reflections)
                //{
                Unity_GlossyEnvironmentData g = UnityGlossyEnvironmentSetup(s.smoothness, v, n, half3(0, 0, 0));//specColor
                  //   Replace the reflUVW if it has been compute in Vertex shader. Note: the compiler will optimize the calcul in UnityGlossyEnvironmentSetup itself
  
                gi =  UnityGlobalIllumination(d,  _RMO_var.b, n, g);*/
    
    UnityGI gi = FragmentGI (s, _RMO_var.b, i.ambientOrLightmapUV,  atten,  light, true);
    //gi.indirect.diffuse = ShadeSHPerPixel(n, float3(0,0,0), i.posWorld.xyz);
    gi.indirect.diffuse = ShadeSH9(float4(n ,1));
    //o.col = float4(ShadeSH9(float4(n ,1)) ,1);
    //o.col = float4(gi.indirect.specular.rgb ,1);
    //o.col = float4(t,1);
    //return o; 
    #if _ANIO
                half4 c = HAIR_PBS(albedo, specColor, oneMinusReflectivity, smoothness, n, v, gi.light, gi.indirect, i.tangentDir,cross(_NormalMap_var,i.tangentDir), _Anio);
    #elif _CLOTH
        half4 c;
        if(smoothness > 0.4)
                c = HAIR_PBS(albedo, specColor, oneMinusReflectivity, smoothness, n, v, gi.light, gi.indirect,i.tangentDir,cross(_NormalMap_var,i.tangentDir), 0.92);
        else
                c = Cloth_PBS(albedo, specColor, oneMinusReflectivity, smoothness, n, v, gi.light, gi.indirect);
    #elif _CLEARCOAT
                UnityGIInput d;
                d.light = light;
                d.worldPos = i.posWorld;
                d.worldViewDir = v;
                d.atten = atten; 
                d.ambient = half3(0, 0, 0);//ShadeSHPerVertex(_NormalMap_var, half3(0, 0, 0));
                d.lightmapUV = 0; 


                d.probeHDR[0] = unity_SpecCube0_HDR;
                d.probeHDR[1] = unity_SpecCube1_HDR;
       #if defined(UNITY_SPECCUBE_BLENDING) || defined(UNITY_SPECCUBE_BOX_PROJECTION)
                d.boxMin[0] = unity_SpecCube0_BoxMin; // .w holds lerp value for blending
       #endif
       #ifdef UNITY_SPECCUBE_BOX_PROJECTION
                d.boxMax[0] = unity_SpecCube0_BoxMax;
                d.probePosition[0] = unity_SpecCube0_ProbePosition;
                d.boxMax[1] = unity_SpecCube1_BoxMax;
                d.boxMin[1] = unity_SpecCube1_BoxMin;
                d.probePosition[1] = unity_SpecCube1_ProbePosition;
       #endif
                Unity_GlossyEnvironmentData g_clearcoat = UnityGlossyEnvironmentSetup(_ReflectionGlossiness, v, n, half3(0, 0, 0));//specColor
                UnityGI gi_clearcoat = UnityGlobalIllumination(d, 1, n ,g_clearcoat);
                half4 c = CLEARCOAT_PBS(albedo, specColor, oneMinusReflectivity, smoothness, n, v, gi.light, gi.indirect, _NormalMap_var, gi_clearcoat.indirect);
    #else
                half4 c = UNITY_BRDF_PBS(albedo, specColor, oneMinusReflectivity, smoothness, n, v, gi.light, gi.indirect);
    #endif
    o.col = c;
    //float3 worldPos = half3(i.posWorld.x*0.5/_X_Range + 0.5,i.posWorld.y*0.5/_Y_Range + 0.5,i.posWorld.z*0.5/_Z_Range + 0.5);
    o.worldPos_r = float4(i.posWorld.xyz ,_RMO_var.r);
    float3 worldNor= n*0.5+float3(0.5,0.5,0.5);
    o.worldNor_s = float4(worldNor,_SSR_S);
    return o;
}
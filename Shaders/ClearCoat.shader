Shader "Pbr/ClearCoat"
{
    Properties
    {
        [Toggle(_USE_SHADOW_COLOR)] _Use_ShadowColor("使用阴影二阶色", Float) = 0.0
        _Main_M("_Main_M", 2D) = "white" {}
        _BaseColor_Step ("阴影色范围", Range(0, 1)) = 0.5
        _BaseShade_Feather ("阴影色羽化", Range(0.0001, 0.5)) = 0.0001
        _Main_Color("_Main_Color",Color) = (1,1,1,1)
        _ShadowDiffColor("阴影漫反射颜色",Color) = (0.8,0.8,0.8,1)  
        _ShadowSpecColor("阴影高光颜色",Color) = (0.8,0.8,0.8,1)  
        _Normal_M("_Normal_M", 2D) = "white" {}
        _RMO_M("_RMO_M", 2D) = "white" {}
        
        [Toggle(_USE_EMI)] _Use_Emission("使用自发光", Float) = 0.0
        _Emission_M("_Emission_M", 2D) = "white" {}
        _SSR_S("SSR反射系数", Range(0, 1)) = 0
        _ReflectionGlossiness("清漆反射粗糙度",Range(0,1)) = 0.5
        _ReflectionSpecular("清漆反射颜色", Color) = (1, 1, 1, 1)
        _ReflectionStrength("清漆反射强度", Range(0,1)) = 0.5
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100
        CGINCLUDE
		#define _CLEARCOAT 1

		ENDCG
        Pass
        {
            Name "FORWARD"
			Tags{ "LightMode" = "ForwardBase" }
			Blend SrcAlpha OneMinusSrcAlpha
            CGPROGRAM
            #pragma vertex VertexForwardBase
            #pragma fragment FragForwardBase
            // make fog work
            #pragma multi_compile_fog
            #pragma shader_feature _USE_EMI
            #pragma shader_feature _USE_SHADOW_COLOR

            #include "pbrShader/core.cginc"
            ENDCG
        }
    }
}

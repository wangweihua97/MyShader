Shader "Unlit/ToonEye"
{
    Properties
    {
        [Toggle(_ALPHA)] _Alpha("开启透明", Float) = 0.0
        [Enum(UnityEngine.Rendering.BlendMode)] _SrcBlend("混合模式-源", Float) = 5
		[Enum(UnityEngine.Rendering.BlendMode)] _DstBlend("混合模式-目标", Float) = 10
        _MainTex ("Texture", 2D) = "white" {}
        _BaseColor ("基础图颜色调整", Color) = (1,1,1,1)
        _ShadeColor ("浅影颜色调整", Color) = (1,1,1,1)
        
        _MatCap_Sampler ("MatCap_Sampler", 2D) = "black" {}
        _BlurLevelMatcap ("MatCap模糊等级", Range(0, 10)) = 0
        _MatCapColor ("MatCap颜色", Color) = (1,1,1,1)
        _MatCapIntensity ("MatCap强度", Range(0 ,1)) = 0.5
        
        _Height2UV_Factor("高度对UV系数", Range(0, 1)) = 0.1
        [HideInInspector]_Radius ("半径" ,Range(0, 0.03)) = 0.0116
        _Pupil1WorldPosition ("Pupil_1 world position" ,Vector) = (1,1,1,1)
        _Pupil2WorldPosition ("Pupil_1 world position" ,Vector) = (1,1,1,1)
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "Queue"="Transparent"}
        LOD 100
        Blend [_SrcBlend] [_DstBlend]
        Pass
        {
            Stencil
            {
                Ref 1
                Comp Always
                Pass replace
            }
            CGPROGRAM
            #pragma vertex EyeVertexForwardBase
            #pragma fragment ToonEyeFragForwardBase
            #pragma shader_feature _ALPHA
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"
            #include "pbrShader/toon.cginc"

            
            ENDCG
        }
    }
}

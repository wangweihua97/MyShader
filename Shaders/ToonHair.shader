Shader "Unlit/ToonHair"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
       _BaseColor("MainColor",Color) = (1,1,1,1)
       _ShadeColor("阴影色",Color) = (1,1,1,1)
       _BaseColor_Step ("阴影色范围", Range(0, 1)) = 0.5
       _BaseShade_Feather ("阴影色羽化", Range(0.0001, 0.5)) = 0.0001
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "Queue"="Transparent"}

        Pass
        {
            Stencil
            {
                Ref 0
                Comp Equal
                Pass Keep
            }
            CGPROGRAM
            #pragma vertex VertexForwardBase
            #pragma fragment ToonHairForwardBase
            // make fog work
            #pragma multi_compile_fog
          
            #include "UnityCG.cginc"
            #include "pbrShader/toon.cginc"
            ENDCG
        }
        
        Tags { "RenderType"="Opaque" "Queue"="Transparent"}
        Pass
        {
            Stencil
            {
                Ref 1
                Comp Equal
                Pass Keep
            }
            Blend SrcAlpha OneMinusSrcAlpha 
            CGPROGRAM
            #define _BlendHair 1
            #pragma vertex VertexForwardBase
            #pragma fragment ToonHairForwardBase
            // make fog work
            #pragma multi_compile_fog
          
            #include "UnityCG.cginc"
            #include "pbrShader/toon.cginc"
            ENDCG
        }
    }
}

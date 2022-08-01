Shader "Unlit/ToonSkin"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _ColorRamp ("Color Ramp", 2D) = "white" {}
        _Normal_M("_Normal_M", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            
            #pragma vertex VertexForwardBase
            #pragma fragment ToonSkinFragForwardBase
            // make fog work
            #pragma multi_compile_fog
          
            #include "UnityCG.cginc"
            #include "pbrShader/toon.cginc"

            
            ENDCG
        }
    }
}

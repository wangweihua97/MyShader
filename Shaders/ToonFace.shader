Shader "Unlit/ToonFace"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Left_Sdf("左边sdf图", 2D) = "white" {}
        _Right_Sdf("右边sdf图", 2D) = "white" {}
       _BaseColor("MainColor",Color) = (1,1,1,1)
       _ShadeColor("阴影色",Color) = (1,1,1,1)
       _LerpMax ("阴影色范围", Range(0, 1)) = 0.5
       
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex VertexForwardBase
            #pragma fragment ToonFaceForwardBase
            // make fog work
            #pragma multi_compile_fog
          
            #include "UnityCG.cginc"
            #include "pbrShader/toon.cginc"
            ENDCG
        }
    }
}

Shader "Unlit/SSR"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _CubeMap ("CubeMap", Cube) = "white" {}
        _A1("" ,Range(0,0.001)) = 0.0005
        _A2("" ,Range(0,0.00001)) = 0.00001
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment FragSSR
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"
            #include "SSR.cginc"
            

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                //o.posWorld = mul(unity_ObjectToWorld, v.vertex);
                //o.posWorld /= o.posWorld.w;
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }
            ENDCG
        }
    }
}

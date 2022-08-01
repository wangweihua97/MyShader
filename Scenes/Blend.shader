Shader "Unlit/Blend"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _CubeMap ("CubeMap", Cube) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            sampler2D _SSR_Tex;
            sampler2D _WorldPos_R_Tex;
            sampler2D _WorldNor_S_Tex;
            samplerCUBE  _CubeMap;
            float4 _MainTex_ST;
            float3 _UpperLeft;
            float3 _UpperRight;
            float3 _LowerLeft;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);
                float3 wordPos = _LowerLeft + i.uv.x *(_UpperRight - _UpperLeft) + i.uv.y *(_UpperLeft - _LowerLeft);
                float3 vPixel = normalize(wordPos - _WorldSpaceCameraPos.xyz);
                if(col.a < 0.01)
                {
                    col = texCUBE(_CubeMap,vPixel);
                }
                float s = tex2D(_WorldNor_S_Tex,i.uv).a;
                if (step(0.01 ,s)< 0.01)
                {
                    UNITY_APPLY_FOG(i.fogCoord, col);
                    return col;
                }
                float3 r = float4(tex2Dlod(_SSR_Tex, float4(i.uv,0,tex2D(_WorldPos_R_Tex,i.uv).a*5)).rgb*1,1).xyz;
                col.xyz =s * r.xyz + (1 - s)* col.xyz;
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}

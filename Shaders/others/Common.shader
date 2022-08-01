Shader "Unlit/Common"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "Queue" = "AlphaTest" "RenderType"="Opaque" }
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
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 posWorld : TEXCOORD1;
                float3 normalDir : TEXCOORD2;
                UNITY_FOG_COORDS(3)
                float4 vertex : SV_POSITION;
            };
            
            struct fOut
            {
                half4 col :COLOR;
                float4 worldPos_r;
                half4 worldNor_s;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                o.normalDir = UnityObjectToWorldNormal(v.normal);
                o.posWorld = mul(unity_ObjectToWorld, v.vertex);
                o.posWorld /= o.posWorld.w;
                return o;
            }

            fOut frag (v2f i) : SV_Target
            {
                fOut o;
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                
                o.col = col;
                //half3 worldPos = half3(i.posWorld.x*0.5/_X_Range + 0.5,i.posWorld.y*0.5/_Y_Range + 0.5,i.posWorld.z*0.5/_Z_Range + 0.5);
                o.worldPos_r = half4(i.posWorld.xyz ,0);
                float3 worldNor= i.normalDir*0.5+float3(0.5,0.5,0.5);
                o.worldNor_s = float4(worldNor,0);
                return o;
            }
            ENDCG
        }
    }
}

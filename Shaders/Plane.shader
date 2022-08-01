// Upgrade NOTE: replaced tex2D unity_Lightmap with UNITY_SAMPLE_TEX2D

Shader "Unlit/Plane"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _SSR_S("SSR反射系数", Range(0, 1)) = 0
        _SSR_R("SSR反射粗糙度", Range(0, 1)) = 0
        _ShallowWaveResolution("ShallowWaveResolution", Vector) = (512,512,0,0)
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
            #include "UnityStandardUtils.cginc"
		    #include "UnityShaderVariables.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
                float4 uv2 : TEXCOORD1;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float2 uv2:TEXCOORD1;
                float4 posWorld : TEXCOORD2;
                float3 normalDir : TEXCOORD3;
                UNITY_FOG_COORDS(4)
                float4 vertex : SV_POSITION;
            };
            
            struct fOut
            {
                half4 col :COLOR;
                float4 worldPos_r;
                half4 worldNor_s;
            };


            sampler2D _MainTex;
            sampler2D _ShallowWaveBuffer;
            uniform float2 _ShallowWaveResolution;
            float4 _MainTex_ST;
            float _SSR_S;
            float _SSR_R;
            float _X_Range;
            float _Y_Range;
            float _Z_Range;
            
            float3 ShallowWaveNormals7_g1( float2 resolution , sampler2D tex , float2 uv , float normalStrength )
		   {
			float3 e = float3(float2(1.0, 1.0) / resolution.xy, 0.0);
			float p10 = tex2Dlod(tex, float4(uv - e.zy, 0, 0)).x;
			float p01 = tex2Dlod(tex, float4(uv - e.xz, 0, 0)).x;
			float p21 = tex2Dlod(tex, float4(uv + e.xz, 0, 0)).x;
			float p12 = tex2Dlod(tex, float4(uv + e.zy, 0, 0)).x;
			// Totally fake displacement and shading:
			float3 grad = normalize(float3((p21 - p01) * normalStrength, (p12 - p10) * normalStrength, 1.0));
			return grad;
		    }

            v2f vert (appdata v)
            {
                v2f o;
                float4 vPos = v.vertex + float4(0,0,0.1*(tex2Dlod(_ShallowWaveBuffer, float4(v.uv, 0, 0)).x - 0.5),0);
                o.vertex = UnityObjectToClipPos(vPos);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                o.uv2 = v.uv2.xy * unity_LightmapST.xy + unity_LightmapST.zw;
                o.normalDir = UnityObjectToWorldNormal(v.normal);
                o.posWorld = mul(unity_ObjectToWorld, vPos);
                o.posWorld /= o.posWorld.w;
                return o;
            }

            fOut frag (v2f i) : SV_Target
            {
                fOut o;
                //float3 n = normalize(i.normalDir);
                float3 n = ShallowWaveNormals7_g1(_ShallowWaveResolution ,_ShallowWaveBuffer,i.uv ,1);
                n = BlendNormals(i.normalDir ,n );
                float3 l = _WorldSpaceLightPos0.xyz;
                fixed4 col = tex2D(_MainTex, i.uv);
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                float3 lm = DecodeLightmap (UNITY_SAMPLE_TEX2D(unity_Lightmap,i.uv2)) * 2;
                o.col = half4(lm ,1);
                //half3 worldPos = half3(i.posWorld.x*0.5/_X_Range + 0.5,i.posWorld.y*0.5/_Y_Range + 0.5,i.posWorld.z*0.5/_Z_Range + 0.5);
                o.worldPos_r = half4(i.posWorld.xyz ,_SSR_R);
                float3 worldNor= n*0.5+float3(0.5,0.5,0.5);
                o.worldNor_s = float4(worldNor,_SSR_S);
                return o;
            }
            ENDCG
        }
    }
}

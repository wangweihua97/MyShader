#include "SSRInput.cginc"
#include "UnityStandardCore.cginc"
#include "AutoLight.cginc"
#include "UnityPBSLighting.cginc"
struct appdata
{
    float4 vertex : POSITION;
    float2 uv : TEXCOORD0;
};

struct v2f
{
    float2 uv : TEXCOORD0;
    float4 posWorld : TEXCOORD1;
    UNITY_FOG_COORDS(1)
    float4 vertex : SV_POSITION;
};

float4 world2screen(float3 pos)
{
    float4 screenuv = mul(_ViewToScreenUv, float4(pos ,1));
    //return (screenuv.xy / screenuv.w)*0.5 + 0.5;
    return screenuv;
}

float3 HitUV(float3 start, float3 end,float time)
{
     float2 huv;
     //float4 hScreen = world2screen(end);
     //huv = (hScreen.xy / hScreen.w)*0.5 + 0.5;
     //return float3(huv ,0.000001);
     uint i;
     float isHit;
     UNITY_LOOP
     for(i = 0 ; i < 32 ;i++)
     {
         float3 h = 0.5*(start + end);
         float4 hScreen = world2screen(h);
         huv = (hScreen.xy / hScreen.w)*0.5 + 0.5;
         //float3 hView = h - _WorldSpaceCameraPos;
         //float hDeep = mul(UNITY_MATRIX_P ,float4(h,1.0)).z*0.5 + 0.5;
         float hDeep = 1 - (0.5*hScreen.z / hScreen.w+0.5);
         isHit = Linear01Depth(hDeep) - Linear01Depth(tex2D(_Deep_Tex ,huv).r) ;
         /*if(isHit > 0)
         {
             end = h;
         }
         else
         {
             start = h;
         }*/
         float stepIsHit = step(0,isHit);
         end = stepIsHit*h + (1-stepIsHit)*end;
         start = (1-stepIsHit)*h + stepIsHit*start;
     }
     //float4 endScreen = world2screen(end);
     //huv = (endScreen.xy / endScreen.w)*0.5 + 0.5;
     return float3( huv,isHit);
}

fixed4 FragSSR (v2f i) : SV_Target
{
    // sample the texture
    fixed4 col = tex2D(_Main_Tex, i.uv);
    float3 worldPosition = tex2D(_WorldPos_R_Tex, i.uv).rgb;
     
    /*float4 t = world2screen(worldPosition);
    float de =  1 - (t.z/t.w *  0.5 + 0.5);
    float de2 = tex2D(_Deep_Tex ,i.uv).r;
    return float4(abs(de - de2)*10 ,0,0,1);*/
	float distanceToCamera = distance(worldPosition,_WorldSpaceCameraPos);
    float s = tex2D(_WorldNor_S_Tex,i.uv).a;
    if (step(0.01 ,s)-step(50 ,distanceToCamera) < 0.01)
    {
        //UNITY_APPLY_FOG(i.fogCoord, col);
        //return col;
        return float4(0.7,0.7,0.7,1);
    }
    float3 viewDir=normalize(_WorldSpaceCameraPos - worldPosition);
    float3 n = normalize(tex2D(_WorldNor_S_Tex, i.uv).rgb * 2.0 - 1.0);
    float3 l = normalize(_WorldSpaceLightPos0.xyz);
    float3 h = normalize(viewDir+l);
    float3 ref = reflect(-viewDir, n);
	float3 dir = ref*_StepDistance;
	//dir = normalize(float3(0,1,1));
	float3 pos = dir + worldPosition;
    
    float2 stepuv;
    float2 resultUV = float2(-1,-1);
    uint j;
    UNITY_LOOP
    for (j = 0; j < 128; j++) //sample count
    {
        float4 stepScreen =  world2screen(pos);
        stepuv = (stepScreen.xy / stepScreen.w)*0.5 + 0.5;
        if (any(floor(stepuv.xy)!=float2(0,0)))
	{
	    break;
	}
        //float3 posView = pos - _WorldSpaceCameraPos;
        //float posDeep = mul(UNITY_MATRIX_P ,float4(posView,1.0)).z*0.5 + 0.5;
        //float posDeep = ((1 - stepScreen.z) / stepScreen.w)*0.5 + 0.5;
        float posDeep = 1 - (0.5*stepScreen.z / stepScreen.w+0.5);
        float isHit = Linear01Depth(posDeep) - Linear01Depth(tex2D(_Deep_Tex ,stepuv).r) ;
        if(isHit > 0 && isHit < _A1)
        {
            float3 result = HitUV(pos - dir ,pos ,_SubdivideTime);
            if(abs(result.z) < _A2)
            {
                 resultUV =  result.xy;
                 break;
            }
            else
                 break;
        }
        pos += dir;
    }
    float4 SSRValue;
    if (any(floor(resultUV.xy)!=float2(0,0)))
	{
	    //return float4(0,0.6974547,1,1);
	    SSRValue = texCUBE(_CubeMap,ref);
	}
	else
	{
	    SSRValue = float4(tex2Dlod(_Main_Tex, float4(resultUV.xy,0,1)).rgb,1);
	   
	}
	SSRValue = float4(SSRValue.xyz + pow(max(dot(n,h),0) ,32) * _LightColor0.rgb ,1);
	//SSRValue = float4(SSRValue.xyz ,1);
    //col.xyz =s * (SSRValue.xyz + pow(max(dot(n,h),0) ,8) * _LightColor0.rgb) + (1 - s)* col.xyz;
    //UNITY_APPLY_FOG(i.fogCoord, col);
    return SSRValue;
}
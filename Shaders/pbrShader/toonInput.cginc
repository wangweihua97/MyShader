sampler2D _ColorRamp;
float4 _ColorRamp_ST;

float4 _BaseColor;
float4 _ShadeColor;

sampler2D _MatCap_Sampler;
float _BlurLevelMatcap;
float4 _MatCapColor;
float _MatCapIntensity;
float _RefractRatio;
float _Height2UV_Factor;

float4 _Pupil1WorldPosition;
float4 _Pupil2WorldPosition;
float4x4 _WorldToLocalMatrixMat1;
float4x4 _WorldToLocalMatrixMat2;
float _Radius;

float4 _HairCenter;

sampler2D _Left_Sdf;
sampler2D _Right_Sdf;
float _LerpMax;
float4 _NoseWorldPosition;
float4 _NoseWorldRightDir;
float4 _NoseWorldForwardDir;
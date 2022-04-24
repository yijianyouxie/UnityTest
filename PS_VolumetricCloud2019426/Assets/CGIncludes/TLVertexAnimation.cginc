#ifndef TL_VERTEXANIMATION
#define TL_VERTEXANIMATION


#if defined(_LEAF_ON)

float4 _WindZoneParams;						//解决IOS上植被抖动的问题（因为在移动端 16bitfloat 的浮点精度不够，导致cosin函数计算振幅数据精度不够而导致的抖动现象）

float4 _WindZoneDir;

float _EdgeFlutterFactor, _BendingFactor, _EdgeFlutterFreqScale;
float _MinBendingHeight;
float _BendingRange;

float4 _PlayerCollisionPos;
float _StepForce;
float _DistanceRange;
float _BranchFactor;
float _BranchRange;

float4 SmoothCurve( float4 x ) {
	return x * x *( 3.0 - 2.0 * x );
}
float4 TriangleWave( float4 x ) {
	return abs( frac( x + 0.5 ) * 2.0 - 1.0 );
}
float4 SmoothTriangleWave( float4 x ) {
	return SmoothCurve( TriangleWave( x ) );
}

inline float4 AnimateVertexWorldPos(float4 vertex, float3 normal, float2 animParams)
{
	// animParams stored in color
    // animParams.x = branch phase
    // animParams.y = secondary factor
	//需要将WindParams算出来
	//float time = _Time.y;
	float windPhase = 1 * 3.14f * _WindZoneParams.w + unity_ObjectToWorld[0].w * 0.1f + unity_ObjectToWorld[2].w * 0.1f;
	float pulse = (cos(windPhase) + cos(windPhase * 0.375f) + cos(windPhase * 0.05f)) * 0.333f;
	pulse = 1.0f + (pulse * _WindZoneParams.z);
	float power = pulse;
	float3 forward = _WindZoneDir.xyz;
	float4 wind = float4(forward.x * _WindZoneParams.x * power, forward.y * _WindZoneParams.x * power,
		forward.z * _WindZoneParams.x * power, _WindZoneParams.y * power);

	float4 windParams = wind;

	float windLength = length(windParams.xyz);
	float3 windDir = UnityWorldToObjectDir(windParams) * windLength;

	float4 pos = vertex;
 	float blendDistFactor = clamp((pos.y - _MinBendingHeight) / _BendingRange, 0, 1);
	blendDistFactor = smoothstep(0, 1, blendDistFactor);
	float blendFactor = blendDistFactor * _BendingFactor;

    float fDetailAmp = 0.1f;
    float fBranchAmp = 0.3f;

    // Phases (object, vertex, branch)
    float fObjPhase = dot(unity_ObjectToWorld._14_24_34, 1);
    float fBranchPhase = fObjPhase + animParams.x;

    float fVtxPhase = dot(pos.xyz, _EdgeFlutterFactor + fBranchPhase);

    // x is used for edges; y is used for branches
    float2 vWavesIn = _Time.yy * _EdgeFlutterFreqScale + float2(fVtxPhase, fBranchPhase );

    // 1.975, 0.793, 0.375, 0.193 are good frequencies
    float4 vWaves = (frac( vWavesIn.xxyy * float4(1.975, 0.793, 0.375, 0.193) ) * 2.0 - 1.0);

    vWaves = SmoothTriangleWave( vWaves );
    float2 vWavesSum = vWaves.xz + vWaves.yw;
	float3 newPos = pos;
	//float3 windDir = normalize(_WindParam);
	float3 bend = _EdgeFlutterFactor * fDetailAmp * windDir.xyz;
	animParams.y = max(animParams.y - _BranchRange, 0);
	animParams.y *= _BranchFactor;
    bend.y = animParams.y * fBranchAmp;
    newPos.xyz += ((vWavesSum.xyx * bend) + (windDir * vWavesSum.y * animParams.y)) * windParams.w;

	newPos.xyz += blendFactor * windDir;

	float dist = length(pos.xyz);
	pos.xyz = normalize(newPos.xyz) * dist;


	float4 worldPos = mul(unity_ObjectToWorld, pos);

	return worldPos;
}

//	带有碰撞的顶点动画
inline float4 AnimateVertex(float4 vertex, float3 normal, float2 animParams)
{
	float4 worldPos = AnimateVertexWorldPos(vertex, normal, animParams);

	float3 distToPlayer = (_PlayerCollisionPos.xyz - worldPos);
	float distFactor = clamp (((_DistanceRange - sqrt(dot (distToPlayer, distToPlayer))) / (_DistanceRange / 2.0)), 0.0, 1.0);
	distFactor = (distFactor * (distFactor * (3.0 - (2.0 * distFactor))));

	float2 moveFactor = ((normalize((worldPos.xz - _PlayerCollisionPos.xz)) * distFactor) * _StepForce);
	float3 vertMove = float3(moveFactor.x, 0, moveFactor.y);

	worldPos.xyz = (worldPos.xyz + ((vertMove * 0.2) * 1));

	float4 pos = mul(unity_WorldToObject, worldPos);

	return pos;
}

//	没有碰撞的顶点动画
inline float4 NoCollisionAnimateVertex(float4 vertex, float3 normal, float2 animParams)
{
	float4 worldPos = AnimateVertexWorldPos(vertex, normal, animParams);

	float4 pos = mul(unity_WorldToObject, worldPos);

	return pos;
}


#endif


#endif

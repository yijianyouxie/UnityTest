Shader "PA/LiquidSphere"
{
	Properties
	{
		_Tint("Tint", Color) = (1,1,1,1)
		_MainTex("Texture", 2D) = "white" {}
		_MainTex2("Texture2", 2D) = "white" {}
	
    	_FillAmount("Fill Amount", Range(0,1)) = 0.0
		_Fill2Amount ("Fill2 Amount", Range(0, 1)) = 0.6
		_Fill2Smooth("Fill2 Smooth", Range(0, 0.3)) = 0.2
		
		_WobbleX("WobbleX", Range(-1,1)) = 0.0
		_WobbleZ("WobbleZ", Range(-1,1)) = 0.0
		//_TopColor("Top Color", Color) = (1,1,1,1)
		_FoamColor("Foam Line Color", Color) = (1,1,1,1)
		_Rim("Foam Line Width", Range(0,0.01)) = 0.0

		_WaterLev("WaterLev", Range(0,1)) = 0.1
		_WaterWave("WaterWave", Range(0,1)) = 0.2
		
	}

	SubShader
	{
		Tags{
			"Queue" = "Transparent"
			"RenderType" = "Transparent"
			"ShadowProjector" = "true"
		}
		LOD 150


	
		Pass
		{
			Zwrite On
			Cull Front
				//Cull Off
			//AlphaToMask On 
			Blend SrcAlpha OneMinusSrcAlpha

			CGPROGRAM
			#pragma skip_variants FOG_EXP


			#pragma vertex vert
			#pragma fragment frag
				// make fog work
			#pragma multi_compile FOG_EXP2 FOG_LINEAR

			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
				float3 normal : NORMAL;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				UNITY_FOG_COORDS(1)
					float4 vertex : SV_POSITION;
				float3 viewDir : COLOR;
				float3 normal : COLOR2;
				float fillEdge : TEXCOORD2;
				float2 cap   : TEXCOORD3;
			};

			sampler2D _MainTex,_MainTex2;
			float4 _MainTex_ST;


			float _FillAmount, _WobbleX, _WobbleZ,_Fill2Smooth,_Fill2Amount;
			float4  _FoamColor, _Tint;
			float _Rim ,_WaterLev,_WaterWave;



			float4 RotateAroundYInDegrees(float4 vertex, float degrees)
			{
				float alpha = degrees * UNITY_PI / 180;
				float sina, cosa;
				sincos(alpha, sina, cosa);
				float2x2 m = float2x2(cosa, sina, -sina, cosa);
				return float4(vertex.yz , mul(m, vertex.xz)).xzyw;
			}

			//先增加一个柏林噪声函数
			fixed2 randVec(fixed2 value)
			{
				fixed2 vec = fixed2(dot(value, fixed2(127.1, 337.1)), dot(value, fixed2(269.5, 183.3)));
				vec = -1 + 2 * frac(sin(vec) * 43758.5453123);
				return vec;
			}

			float perlinNoise(float2 uv)
			{
				float a, b, c, d;
				float x0 = floor(uv.x);
				float x1 = ceil(uv.x);
				float y0 = floor(uv.y);
				float y1 = ceil(uv.y);
				fixed2 pos = frac(uv);
				a = dot(randVec(fixed2(x0, y0)), pos - fixed2(0, 0));
				b = dot(randVec(fixed2(x0, y1)), pos - fixed2(0, 1));
				c = dot(randVec(fixed2(x1, y1)), pos - fixed2(1, 1));
				d = dot(randVec(fixed2(x1, y0)), pos - fixed2(1, 0));
				float2 st = 6 * pow(pos, 5) - 15 * pow(pos, 4) + 10 * pow(pos, 3);
				a = lerp(a, d, st.x);
				b = lerp(b, c, st.x);
				a = lerp(a, b, st.y);
				return a;
			}



			v2f vert(appdata v)
			{
				v2f o;

				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				UNITY_TRANSFER_FOG(o,o.vertex);
				// get world position of the vertex
				float3 worldPos = mul(unity_ObjectToWorld, v.vertex.xyz);
				// rotate it around XY
				float3 worldPosX = RotateAroundYInDegrees(float4(worldPos,0),360);
				// rotate around XZ
				float3 worldPosZ = float3 (worldPosX.y, worldPosX.z, worldPosX.x);
				// combine rotations with worldPos, based on sine wave from script
				float3 worldPosAdjusted = worldPos + (worldPosX  * _WobbleX) + (worldPosZ* _WobbleZ);

				////使用了顶点的世界坐标做随机项也可以使用UV，顶点色，顶点ID......
				float noiseValue = 0.5 * abs(frac(worldPos.xz / _WaterWave + worldPos.zx / _WaterWave + float2(_Time.y / 2, _Time.y / 1)) - 0.5);
				float waterLevel = _WaterLev * perlinNoise(noiseValue);

				// how high up the liquid is
				//o.fillEdge = worldPosAdjusted.y + (1-((_FillAmount*2-1))) + waterLevel/2;
				o.fillEdge = worldPosAdjusted.y + (1 - ((_FillAmount*0.3 + 0.35))) + waterLevel / 2;

				o.viewDir = normalize(ObjSpaceViewDir(v.vertex));


				o.normal = v.normal;
				//o.viewDir = normalize(ObjSpaceViewDir(v.vertex));

				float3 worldNorm = normalize(unity_WorldToObject[0].xyz * v.normal.x + unity_WorldToObject[1].xyz * v.normal.y + unity_WorldToObject[2].xyz * v.normal.z);
				worldNorm = mul((float3x3)UNITY_MATRIX_V, worldNorm);
				o.cap.xy = worldNorm.xy * 0.5 + 0.5;


				return o;
			}

			fixed4 frag(v2f i, fixed facing : VFACE) : SV_Target
			{
				// sample the texture
				fixed4 col = tex2D(_MainTex, i.cap) * _Tint;
				fixed4 col2 = tex2D(_MainTex2, i.cap);
				half ramp = smoothstep(0, _Fill2Smooth, i.cap.y - (_Fill2Amount*1.2 - 0.2));

				// apply fog
				UNITY_APPLY_FOG(i.fogCoord, col);


				// foam edge
				float4 foam = (step(i.fillEdge, 0.5) - step(i.fillEdge, (0.5 - _Rim)));
				float4 foamColored = foam * (_FoamColor * 0.9);
				// rest of the liquid
				float4 result = step(i.fillEdge, 0.5) - foam;
				float4 resultColored = result * col;




				// both together, with the texture
				float4 finalResult = resultColored + foamColored;

				// color of backfaces/ top
				float4 topColor = _Tint * (foam + result);
				//VFACE returns positive for front facing, negative for backfacing
				float4 finalB = facing > 0 ? finalResult : topColor;
				float4 finalO = col2 *(1 - ramp);
				fixed4 fi = finalO + finalB*(ramp);
				//clip(fi.a - 0.00001);
				return fi;
			}
			ENDCG
		}

		Pass
	{
		Zwrite On
		Cull Back 
		//AlphaToMask On 
		Blend SrcAlpha OneMinusSrcAlpha

		CGPROGRAM


		#pragma vertex vert
		#pragma fragment frag
		// make fog work
		#pragma multi_compile FOG_EXP2 FOG_LINEAR

		#include "UnityCG.cginc"

		struct appdata
	{
		float4 vertex : POSITION;
		float2 uv : TEXCOORD0;
		float3 normal : NORMAL;
	};

	struct v2f
	{
		float2 uv : TEXCOORD0;
		UNITY_FOG_COORDS(1)
		float4 vertex : SV_POSITION;
		float3 viewDir : COLOR;
		float3 normal : COLOR2;
		float fillEdge : TEXCOORD2;
		float2 cap   : TEXCOORD3;
	};

	sampler2D _MainTex,_MainTex2;
	float4 _MainTex_ST;
	

	float _FillAmount, _WobbleX, _WobbleZ,_Fill2Smooth,_Fill2Amount;
	float4  _FoamColor, _Tint;
	float _Rim ,_WaterLev,_WaterWave;



	float4 RotateAroundYInDegrees(float4 vertex, float degrees)
	{
		float alpha = degrees * UNITY_PI / 180;
		float sina, cosa;
		sincos(alpha, sina, cosa);
		float2x2 m = float2x2(cosa, sina, -sina, cosa);
		return float4(vertex.yz , mul(m, vertex.xz)).xzyw;
	}

	//先增加一个柏林噪声函数
	fixed2 randVec(fixed2 value)
	{
		fixed2 vec = fixed2(dot(value, fixed2(127.1, 337.1)), dot(value, fixed2(269.5, 183.3)));
    	vec = -1 + 2 * frac(sin(vec) * 43758.5453123);
    	return vec;
	}

	float perlinNoise(float2 uv)
	{
    	float a, b, c, d;
    	float x0 = floor(uv.x);
    	float x1 = ceil(uv.x);
    	float y0 = floor(uv.y);
    	float y1 = ceil(uv.y);
    	fixed2 pos = frac(uv);
    	a = dot(randVec(fixed2(x0, y0)), pos - fixed2(0, 0));
    	b = dot(randVec(fixed2(x0, y1)), pos - fixed2(0, 1));
    	c = dot(randVec(fixed2(x1, y1)), pos - fixed2(1, 1));
    	d = dot(randVec(fixed2(x1, y0)), pos - fixed2(1, 0));
    	float2 st = 6 * pow(pos, 5) - 15 * pow(pos, 4) + 10 * pow(pos, 3);
    	a = lerp(a, d, st.x);
    	b = lerp(b, c, st.x);
    	a = lerp(a, b, st.y);
    	return a;
	}



	v2f vert(appdata v)
	{
		v2f o;

		o.vertex = UnityObjectToClipPos(v.vertex);
		o.uv = TRANSFORM_TEX(v.uv, _MainTex);
		UNITY_TRANSFER_FOG(o,o.vertex);
		// get world position of the vertex
		float3 worldPos = mul(unity_ObjectToWorld, v.vertex.xyz);
		// rotate it around XY
		float3 worldPosX = RotateAroundYInDegrees(float4(worldPos,0),360);
		// rotate around XZ
		float3 worldPosZ = float3 (worldPosX.y, worldPosX.z, worldPosX.x);
		// combine rotations with worldPos, based on sine wave from script
		float3 worldPosAdjusted = worldPos + (worldPosX  * _WobbleX) + (worldPosZ* _WobbleZ);

		////使用了顶点的世界坐标做随机项也可以使用UV，顶点色，顶点ID......
    	float noiseValue = 0.5 * abs(frac(worldPos.xz/_WaterWave+ worldPos.zx/_WaterWave + float2(_Time.y/2, _Time.y/1)) - 0.5);
		float waterLevel = _WaterLev * perlinNoise(noiseValue);

		// how high up the liquid is
		//o.fillEdge = worldPosAdjusted.y + (1-((_FillAmount*2-1))) + waterLevel/2;
		o.fillEdge = worldPosAdjusted.y + (1-((_FillAmount*0.3+0.35)))+ waterLevel/2 ;

		o.viewDir = normalize(ObjSpaceViewDir(v.vertex));
		

		o.normal = v.normal;
		//o.viewDir = normalize(ObjSpaceViewDir(v.vertex));

		float3 worldNorm = normalize(unity_WorldToObject[0].xyz * v.normal.x + unity_WorldToObject[1].xyz * v.normal.y + unity_WorldToObject[2].xyz * v.normal.z);
		worldNorm = mul((float3x3)UNITY_MATRIX_V, worldNorm);
		o.cap.xy = worldNorm.xy * 0.5 + 0.5;


		return o;
	}

	fixed4 frag(v2f i, fixed facing : VFACE) : SV_Target
	{
		// sample the texture
		fixed4 col = tex2D(_MainTex, i.cap) * _Tint;
		fixed4 col2 = tex2D(_MainTex2, i.cap) ;
		half ramp = smoothstep(0, _Fill2Smooth, i.cap.y - (_Fill2Amount*1.2-0.2));

		// apply fog
		UNITY_APPLY_FOG(i.fogCoord, col);


		// foam edge
		float4 foam = (step(i.fillEdge, 0.5) - step(i.fillEdge, (0.5 - _Rim)));
		float4 foamColored = foam * (_FoamColor * 0.9);
		// rest of the liquid
		float4 result = step(i.fillEdge, 0.5) - foam;
		float4 resultColored = result * col;


		

		// both together, with the texture
		float4 finalResult = resultColored + foamColored;

		// color of backfaces/ top
		float4 topColor = _Tint * (foam + result );
		//VFACE returns positive for front facing, negative for backfacing
		float4 finalB = facing > 0 ? finalResult : topColor;
		float4 finalO = col2 *(1- ramp);
		fixed4 fi = finalO + finalB*(ramp);
		return fi;
		

	}
		ENDCG
	}



	}
}

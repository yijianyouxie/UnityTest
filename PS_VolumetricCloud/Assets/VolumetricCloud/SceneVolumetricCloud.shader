// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

/*
* Volumetric Cloud 原理上是采用RayMarch
* Density Map : 3DTexture，其中R通道用于控制Volumetric Cloud 的轮廓，G通道用于控制 模拟透射现象，
*				B通道用于参与控制散射。
* NoiseMap 噪声控制，用于消融BaseMap产生的基础形状。
*
* ASMap: 每帧前先生成的一张散射图，用于后面的计算。
* Condition： 限制参数，目前程序先自己调用控制。
* Radius: Radius.x 最大半径 1300， Radius.y 当前的半径，该半径会随着摄像机移动 进行值得调整， 可以对效率进行优化。
* Density : 密度因子参数。
* SoftEdge：软边调节参数，用于控制调节Volumetric Cloud 在离Geometry近时进行软边处理，避免过于生硬。
* mainLightIntensity: 调节主光光强参数，实际上是主光与云颜色相乘后再参与控制。
* glossIntensity: 在散射光上增加一层类似于高光似的光泽度。
* HGParameter: 用于计算散射值参数调节。
* BaseTilling : 用于计算BaseMap uvw采样调节控制参数。
* NoiseTilling : 用于控制NoiseMap 的uvw采样调节控制参数。
* NoiseIntensity : 用于控制NoiseMap采样后的值得强度参数。
* Speed ：x,y 用于控制Densitymap的步进参数， z,w用于控制NoiseMap的步进参数。
*/
Shader "TLStudio/SceneVolumetricCloud"
{
	Properties
	{
		BaseMap("BaseMap", 3D) = "white" { }
		NoiseMap("NoiseMap", 3D) = "white" { }
		//ASMap("ASMap", 2D) = "white"{ }
		SampleCount("SampleCount", Float) = 40
		BaseTilling("BaseTilling", Vector) = (0.08,0.247,0.08,0)
		Condition("Condition", Vector) = (-52.9976196, -0.7476196, 0.0, -26.9785767)
		Radius("Radius", Vector) = (0.15,0.15,0,0)
		Density("Density", Vector) = (0.05,0.15,0,0)
		[HideInInspector]Parameter1("Parameter1", Vector) = (0.0000463, 0.0001083, 0.0002643, 0.0)
		[HideInInspector]Parameter2("Parameter2", Vector) = (0.0000154, 0.0000234, 0.000036, 108.6667175)
		[HideInInspector]Parameter3("Parameter3", Vector) = (0.002, 0.004, 0.0, 0.0)
		[HideInInspector]Parameter4("Parameter4", Vector) = (0.3333333, 0.0003333, 3.0, 0.01)
		SoftEdge("SoftEdge", Float) = 0.00001
		//LightIntensity("LightIntensity", Vector) = (0.15,0.15,0,0)
		mainLightIntensity("mainLightIntensity", Float) = 0.15
		glossIntensity("glossIntensity", Float) = 0.15
		HGParameter("HGParameter", Vector) = (0.15,0.15,0,0)
		[HDR]MainLightColor("MainLightColor", Color) = (1,1,1,1)
		[HDR]CloudColor("CloudColor", Color) = (1,1,1,1)
		NoiseTilling("NoiseTilling", Float) = 0.00005
		NoiseIntensity("NoiseIntensity", Float) = 1200
		Speed("Speed", Vector) = (0,0,0,0)

	}

	SubShader
	{
		Tags{"IGNOREPROJECTOR" = "true" "QUEUE" = "Transparent-2" "RenderType" = "Transparent" }
		//LOD 200
		//Cull [_Cull]

		Pass
		{
			Name "FORWARD"
			Tags {"IGNOREPROJECTOR" = "true" "LIGHTMODE" = "FORWARDBASE" "QUEUE" = "Transparent-2" "RenderType" = "Transparent"  }

			ZClip Off
			ZWrite Off
			Cull Off
			Blend SrcAlpha OneMinusSrcAlpha
			BlendOp Add

			CGPROGRAM
			//local keyword is supported form 20196
			////in cloud
			//#pragma shader_feature_local _ _RENDER_STATE_1
			////under cloud
			//#pragma shader_feature_local _ _RENDER_STATE_2
			//#pragma shader_feature_local _ _REVERSE_V
			//#pragma shader_feature_local _ _OPTIMIZATION_VERSION
			//#pragma shader_feature_local _ _ANDROID

			//in cloud
			#pragma shader_feature _ _RENDER_STATE_1
			//under cloud
			#pragma shader_feature _ _RENDER_STATE_2
			#pragma shader_feature _ _REVERSE_V
			#pragma shader_feature _ _OPTIMIZATION_VERSION
			#pragma shader_feature _ _ANDROID

			#pragma vertex vert_surf
			#pragma fragment frag_surf

			//#include "CGIncludes/Lighting.cginc"
			#include"TLStudioCG.cginc"
			//sampler2D ASMap;
			//sampler2D _CameraDepthTexture;
			sampler3D NoiseMap;
			sampler3D BaseMap;


			float4x4 InvVPMatrix_ViewDir;

			float4x4 VPosToLastScreenMatrix;
			float4 _ProjectionExtents;
			/*Ray*/
			float4 Parameter1;
			/*Mie*/
			float4 Parameter2;
			/*HeightFogData*/
			float4 Parameter3;
			/*z_fade_parameter*/
			float4 Parameter4;


			float4 MainLightColor;
			float3 MainLightDirection;
			float SampleCount;
			float3 BaseTilling;

			float4 Condition;
			float2 Radius;
			float2 Density;

			float SoftEdge;
			float viewDistanceFactor;
			float2 LightIntensity;
			float mainLightIntensity;
			float glossIntensity;
			/* 
				Henyey-Greenstein phase function 在CPU端进行计算，
			*/
			float3 HGParameter;

			float4 CloudColor;

			float NoiseTilling;
			float NoiseIntensity;

			float4 Speed;

			float4 AtmosphereColor;
			float AtmosphereColorSaturateDistance;


			struct appdata
			{
				float4 vertex : POSITION;
				//float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float4 pos  : POSITION;
				float4 view :TEXCOORD0;
			};

			float beer(float d)
			{
				return exp(-d);
			}

			float2 beer_2(float2 d)
			{
				return float2(exp(-d.x), exp(-d.y));
			}

			float3 beer_3(float3 d)
			{
				return float3(exp(-d.x), exp(-d.y), exp(-d.z));
			}
			v2f vert_surf(appdata v)
			{
				v2f o;

#ifndef _OPTIMIZATION_VERSION
				o.pos.xy = v.vertex.xy;
				//o.pos.zw = float2(1.0f, 1.0f);
					#ifndef _ANDROID
					o.pos.zw = float2(1.0f, 1.0f);
					#else
					o.pos.zw = float2(0.0f, 1.0f);
					#endif
				float4 t_WorldPos = mul(unity_ObjectToWorld, float4(v.vertex.x, v.vertex.y, v.vertex.z, 1.0f));
				float t_ViewZ = mul(unity_MatrixV, t_WorldPos).z;
				o.view.w = -t_ViewZ;

				float4 t_inverseWorldPos = mul(InvVPMatrix_ViewDir, o.pos);
				float4 t_w = float4(1.0f, 1.0f, 1.0f, 1.0f) / t_inverseWorldPos.w;
				t_inverseWorldPos = t_inverseWorldPos * t_w;
				o.view.xyz = t_inverseWorldPos.xyz;
				o.pos = UnityObjectToClipPos(v.vertex);
#else
				float4 t_WorldPos_screen = mul(unity_ObjectToWorld, v.vertex);
				o.pos = mul(UNITY_MATRIX_VP, t_WorldPos_screen);

				float4 t_WorldPos = mul(unity_ObjectToWorld, float4(v.vertex.xyz, 1.0f));
				float t_ViewZ = mul(unity_MatrixV, t_WorldPos).z;
				o.view.w = -t_ViewZ;
				//float3 viewVector = mul(unity_CameraInvProjection, float4(v.uv * 2 - 1, 0, -1));
				//o.view.xyz = mul(unity_CameraToWorld, float4(viewVector, 0));

				float4 t_inverseWorldPos = mul(InvVPMatrix_ViewDir, o.pos);
				float4 t_w = float4(1.0f, 1.0f, 1.0f, 1.0f) / t_inverseWorldPos.w;
				t_inverseWorldPos = t_inverseWorldPos * t_w;
				o.view.xyz = t_inverseWorldPos.xyz;

#endif
				//o.screenPos = ComputeScreenPos(v.vertex);
				return o;
			}


			// fragment shader
			fixed4 frag_surf(v2f i) : SV_Target
			{
//#ifdef _OPTIMIZATION_VERSION
//				return fixed4(1,0,0,1);
//#else
//				return fixed4(0, 1, 0, 1);
//#endif
				float2 t_ScreenUV = i.pos.xy * _ScreenParams.zw;

				float3 t_view = normalize(i.view.xyz);

				//float3 t_FogSkyColor = tex2Dlod(ASMap, float4(t_ScreenUV, 0.0f, 0.0f));
				int2 t_StartEndIndex;

#if defined(_RENDER_STATE_1)
				bool t_r0_w = 0.0f < t_view.y;
				float2 t_Condition = Condition.yx / t_view.y;

				float t_Bound_x;
				if (t_r0_w)
				{
					t_Bound_x = t_Condition.x;
				}
				else
				{
					t_Bound_x = t_Condition.y;
				}

				bool t_r1_w = 0.0f < Radius.y;
				t_Bound_x = min(t_Bound_x, Radius.y);
				t_Bound_x = t_Bound_x / Radius.x;
				t_Bound_x = sqrt(t_Bound_x);
				t_Bound_x = t_Bound_x * SampleCount;


				t_Bound_x = ceil(t_Bound_x);

				int t_y = int(t_Bound_x);
				int t_x = 0;


				t_StartEndIndex = t_r1_w ? float2(t_x, t_y) : int2(-1, -1);


				if (t_r1_w == 0)
				{
					clip(-1);
				}
#elif defined(_RENDER_STATE_2)
				float3 t_Condition = Condition.wxy / t_view.y;				
				// out of cloud range length.
				float t_StartSampleLength = _ProjectionParams.z - Radius.y;


				t_StartSampleLength = min(t_Condition.x, t_StartSampleLength);

				bool t_bRet = t_Condition.y >= 0.0f && t_Condition.y < Radius.y;


				t_Condition.y = t_Condition.y / Radius.x;
				t_Condition.y = sqrt(t_Condition.y);
				t_Condition.y = SampleCount * t_Condition.y;

				t_Condition.z = min(t_Condition.z, Radius.y);
				t_Condition.z = t_Condition.z / Radius.x;
				t_Condition.z = sqrt(t_Condition.z);
				t_Condition.z = t_Condition.z * SampleCount;
				t_Condition.z = ceil(t_Condition.z);

				//int t_Int_Bound_y = t_Condition.y;
				//int t_Int_Bound_z = t_Condition.z;
				t_StartEndIndex = t_bRet ? int2(t_Condition.y, t_Condition.z) : int2(-1, -1);

				float t_fTemp = (float)t_StartEndIndex.x;
				if (t_fTemp < 0.0f)
				{
					clip(-1);
				}
#else
				float3 t_Condition = Condition.wyx / t_view.y;
				// out of cloud range length.
				float t_StartSampleLength = _ProjectionParams.z - Radius.y;


				t_StartSampleLength = min(t_Condition.x, t_StartSampleLength);

				bool t_bRet = t_Condition.y >= 0.0f && t_Condition.y < Radius.y;


				t_Condition.y = t_Condition.y / Radius.x;
				t_Condition.y = sqrt(t_Condition.y);
				t_Condition.y = SampleCount * t_Condition.y;

				t_Condition.z = min(t_Condition.z, Radius.y);
				t_Condition.z = t_Condition.z / Radius.x;
				t_Condition.z = sqrt(t_Condition.z);
				t_Condition.z = t_Condition.z * SampleCount;
				t_Condition.z = ceil(t_Condition.z);

				//int t_Int_Bound_y = t_Condition.y;
				//int t_Int_Bound_z = t_Condition.z;
				t_StartEndIndex = t_bRet ? int2(t_Condition.y, t_Condition.z) : int2(-1, -1);

				float t_fTemp = (float)t_StartEndIndex.x;
				if (t_fTemp < 0.0f)
				{
					clip(-1);
				}
#endif

				float3 t_CombinedColor = /*_LightColor0 **/ CloudColor;

				/*
				* Mie Scattering
				* Henyey-Greenstein phase function
				* representing the bouncing light direction distribution when scattered.
				*/
				float t_cosAngle = dot(t_view, MainLightDirection);
				float t_HGTempValue = (-HGParameter.z) *(t_cosAngle) + HGParameter.y;
				t_HGTempValue = pow(t_HGTempValue, 1.5);
				float scatter = HGParameter.x / t_HGTempValue;


				float3 t_CombinedScatterColor = scatter * MainLightColor;
				float3 t_CombinedIntensityColor = t_CombinedColor * mainLightIntensity;
				float3 t_CombinedScatterIntensityColor = t_CombinedScatterColor * glossIntensity + t_CombinedIntensityColor;
				float3 t_CombinedDiffuseAlphaColor = t_CombinedColor * CloudColor.a;

				
				float3 t_uvw = mul(VPosToLastScreenMatrix, float4(i.pos.xyz, 1.0f)).xyw;




				float t_depth_w = 1.0f / t_uvw.z;
				float2 t_depth_uv = t_uvw.xy * t_depth_w;

				float depth = TL_SAMPLE_DEPTH_TEXTURE(t_depth_uv);

				//float depth = tex2D(_CameraDepthTexture, (i.screenPos / i.screenPos.w).xy);

				depth = LinearEyeDepth(abs(depth))/* * length(t_view)*/;


				

				float4 t_FinalColor;
				float t_SoftEdge;
#if defined(_RENDER_STATE_1)
				t_FinalColor = float4(t_CombinedScatterIntensityColor, 1.0f) * Condition.z;
				t_SoftEdge = saturate(depth *SoftEdge);
				t_FinalColor = t_FinalColor * t_SoftEdge;
#else
				t_FinalColor = float4(0.0f, 0.0f, 0.0f, 0.0f);

				#if _OPTIMIZATION_VERSION
				float t_compareDepth = i.view.w < depth;
				#endif
#endif
				float t_Density = Density.x * 10.0f;
				float t_LastSampleLength = 0.0f;

				for (int index = t_StartEndIndex.x; index < t_StartEndIndex.y; index++)
				{
					float fIndex = float(index);
					fIndex = fIndex / SampleCount;
					float fIndexSquare = fIndex * fIndex;
					float t_SampleLength = fIndexSquare * Radius.x;

				#if defined (_RENDER_STATE_1) /*|| defined(_RENDER_STATE_2)*/

					if (depth < t_SampleLength)
					{
						break;
					}
				#else
					float t_CurrentStartSampleLength = Radius.x * fIndexSquare + t_StartSampleLength;

					if (depth < t_CurrentStartSampleLength
					#if (_OPTIMIZATION_VERSION)
						&& t_compareDepth
					#endif
						)
					{
						break;
					}

				#endif
					/*
					* Cloud distribution and density.
					*/
					float2 t_ray_pos_xz = t_view.xz * t_SampleLength;
					float t_ray_pos_y = t_view.y * t_SampleLength - Condition.x;


					float2 t_noise_uv = t_view.xz * t_SampleLength + Speed.zw;

					float3 t_noise_uvw = float3(t_noise_uv, t_ray_pos_y) * NoiseTilling;

					float3 t_noise_data = tex3Dlod(NoiseMap, float4(t_noise_uvw, 0.0f));
					t_noise_data = t_noise_data + float3(-0.5f, -0.5f, -0.5f);
					t_noise_uvw = t_noise_uvw * float3(4.0f, 4.0f, 4.0f);
					float3 t_second_noise_data = tex3Dlod(NoiseMap, float4(t_noise_uvw, 0.0f));

					t_second_noise_data = t_second_noise_data - float3(0.5f, 0.5f, 0.5f);
					t_second_noise_data = t_second_noise_data * float3(0.5f, 0.5f, 0.5f) + t_noise_data;
					t_second_noise_data = t_second_noise_data * NoiseIntensity;

#if defined(_RENDER_STATE_1)
	#if defined(_REVERSE_V)
					float t_ray_pos_z_tilling = t_ray_pos_y * BaseTilling.y;
	#else
					float t_ray_pos_z_tilling = -t_ray_pos_y * BaseTilling.y + 1.0f;
					
	#endif
#elif defined(_RENDER_STATE_2)
					float t_ray_pos_z_tilling = -t_ray_pos_y * BaseTilling.y + 1.0f;
#else
					float t_ray_pos_z_tilling = t_ray_pos_y * BaseTilling.y;
#endif
					t_ray_pos_z_tilling = t_ray_pos_z_tilling * 0.25f + 0.75f;


					float3 t_density_offset = t_ray_pos_z_tilling * t_second_noise_data + float3(t_ray_pos_xz, t_ray_pos_y);



					t_density_offset.xy = t_density_offset.xy + Speed.xy;

					float4 t_density_data = float4(0, 0, 0, 0);
#if  defined(_RENDER_STATE_1) 

	#if defined(_REVERSE_V)
					float2 t_density_uv = t_density_offset.xy * BaseTilling.xz;
					float t_density_w = -t_density_offset.z * BaseTilling.y + 1.0f;

					t_density_w = -t_density_offset.z * BaseTilling.y + 1.0f;
					t_density_data = tex3Dlod(BaseMap, float4(t_density_uv, t_density_w, 0.0f));

					if (!(0.0f < t_density_w && t_density_w < 1.0f))
					{
						t_density_data = float4(0, 0, 0, 0);
					}
	#else
					float3 t_density_uvw = t_density_offset * BaseTilling.xzy;

					t_density_data = tex3Dlod(BaseMap, float4(t_density_uvw, 0.0f));

					if (!(0.0f < t_density_uvw.z && t_density_uvw.z < 1.0f))
					{
						t_density_data = float4(0, 0, 0, 0);
					}

	#endif


#elif defined(_RENDER_STATE_2)
					float2 t_density_uv = t_density_offset.xy * BaseTilling.xz;
					float t_density_w = -t_density_offset.z * BaseTilling.y + 1.0f;

					t_density_w = -t_density_offset.z * BaseTilling.y + 1.0f;
					t_density_data = tex3Dlod(BaseMap, float4(t_density_uv, t_density_w, 0.0f));

					if (!(0.0f < t_density_w && t_density_w < 1.0f))
					{
						t_density_data = float4(0, 0, 0, 0);
					}
#else


					float3 t_density_uvw = t_density_offset * BaseTilling.xzy;

					t_density_data = tex3Dlod(BaseMap, float4(t_density_uvw, 0.0f));

					if (!(0.0f < t_density_uvw.z && t_density_uvw.z < 1.0f))
					{
						t_density_data = float4(0, 0, 0, 0);
					}

#endif
					if (0.0f >= t_density_data.x)
					{
						t_LastSampleLength = t_SampleLength;
						continue;
					}


					/*
					* Volumetric cloud light rendering.
					*/
					float t_IntervalSampleLength = Radius.x * fIndexSquare - t_LastSampleLength;
#if defined(_RENDER_STATE_1)
					float t_CurrentPointToDepthEndLength = (-Radius.x) * fIndexSquare + depth;
#else
					float t_CurrentPointToDepthEndLength = depth - t_CurrentStartSampleLength;
#endif

					t_SoftEdge = saturate(abs(t_CurrentPointToDepthEndLength) * SoftEdge);

					float t_density_x_soft_edge = t_density_data.x * t_SoftEdge;
					float t_SampleLengthDensity = t_Density * t_IntervalSampleLength;
					t_SampleLengthDensity = t_density_x_soft_edge * t_SampleLengthDensity;

#if defined(_RENDER_STATE_1)
					float t_MieCalculate = Radius.x * fIndexSquare - Parameter2.w;
#else
					float t_MieCalculate = t_CurrentStartSampleLength - Parameter2.w;
#endif

					t_MieCalculate = max(t_MieCalculate, 0);

#if defined(_RENDER_STATE_1) || defined(_RENDER_STATE_2)
					float t_density_offset_length = t_SampleLength * t_density_offset.z;
#else
					float t_density_offset_length = t_CurrentStartSampleLength * t_density_offset.z;
#endif
					float t_density_offset_fog_length = t_density_offset_length * Parameter3.z;

					bool t_bRet = 0.000062f < abs(t_density_offset_fog_length);

					float t_fog_beer = beer(t_density_offset_fog_length);


					//-t_MieCalculate * t_fog_beer + t_MieCalculate
					float t_Mie_scatter_Fog = -t_MieCalculate * t_fog_beer + t_MieCalculate;
					float t_Fog_data = t_Mie_scatter_Fog / t_density_offset_fog_length;
					t_Fog_data = t_bRet ? t_Fog_data : t_MieCalculate;
					t_Fog_data = t_Fog_data * (-Parameter3.w);
					t_Fog_data = beer(-t_Fog_data);


#if defined(_RENDER_STATE_1) || defined(_RENDER_STATE_2)
					float t_ZFade_SampleLength = t_SampleLength * Parameter4.y - Parameter4.x;
					float t_TempValue = t_SampleLength * t_density_offset.z + _WorldSpaceCameraPos.y;
#else
					float t_ZFade_SampleLength = t_CurrentStartSampleLength * Parameter4.y - Parameter4.x;
					float t_TempValue = t_CurrentStartSampleLength * t_density_offset.z + _WorldSpaceCameraPos.y;
#endif
					float t_Density_offset_ZFade = -t_TempValue * Parameter4.w + Parameter4.z;

					t_Density_offset_ZFade = max(t_Density_offset_ZFade, 0);
					float t_ZFade_SampleLength_sat = saturate(t_ZFade_SampleLength * t_Density_offset_ZFade + t_ZFade_SampleLength);

					float t_ZFade_SampleLength_sat_square = t_ZFade_SampleLength_sat * t_ZFade_SampleLength_sat;

					float t_MieCalculateData = t_ZFade_SampleLength_sat_square * (10000 - t_MieCalculate) + t_MieCalculate;


					float t_ZFade_SampleLengthsat_Fog_data = (1.0f - t_ZFade_SampleLength_sat) * (1.0f - t_ZFade_SampleLength_sat) * t_Fog_data;



					float t_MieCalculateData_BetaRay = t_MieCalculateData * t_density_offset.z - Parameter1.w;
					
					float2 t_Mie_Value = t_MieCalculateData_BetaRay * Parameter3.xy;
					bool t_Ret = 0.000062f < abs(t_Mie_Value.y);


					float2 t_Mie_beer_value = beer_2(t_Mie_Value);


					t_Mie_beer_value = -t_MieCalculateData * t_Mie_beer_value + t_MieCalculateData;

					t_Mie_Value = t_Mie_beer_value / t_Mie_Value;

					t_Mie_Value = t_Ret ? t_Mie_Value : t_MieCalculateData;

					float3 t_Mie = t_Mie_Value.y * Parameter2.xyz;
					t_Mie = Parameter1.xyz * t_Mie_Value.x + t_Mie;					

					float3 t_Mie_scattering = beer_3(t_Mie);


					float t_SampleLengthDensity_beer = beer(t_SampleLengthDensity);

					//float transmit = t_ZFade_SampleLengthsat_Fog_data * (1 - t_SampleLengthDensity_beer);
					float transmit = -t_SampleLengthDensity_beer * t_ZFade_SampleLengthsat_Fog_data + t_ZFade_SampleLengthsat_Fog_data;

					float3 t_current_loop_color = t_CombinedDiffuseAlphaColor * t_density_data.y;
					t_current_loop_color = t_density_data.z * t_CombinedScatterIntensityColor + t_current_loop_color;

					t_current_loop_color = t_current_loop_color/* - t_FogSkyColor*/;
					t_current_loop_color = t_Mie_scattering * t_current_loop_color/* + t_FogSkyColor*/;
					//t_current_loop_color = t_Mie_scattering * t_current_loop_color;
					float3 t_transmit_FinalColor = t_current_loop_color * transmit;

					float t_alpha_value = 1.0f - t_FinalColor.w;

					float4 t_Current_Accumulative_color = t_alpha_value * float4(t_transmit_FinalColor, transmit) + t_FinalColor;

					if (t_Current_Accumulative_color.w >= 1.0f)
					{
						t_FinalColor = t_Current_Accumulative_color;
						break;
					}
					t_LastSampleLength = t_SampleLength;
					t_FinalColor = t_Current_Accumulative_color;
				}

				float atmosphericBlendFactor = exp(-t_LastSampleLength / AtmosphereColorSaturateDistance);
				t_FinalColor.rgb = lerp(AtmosphereColor, t_FinalColor.rgb, saturate(atmosphericBlendFactor));


				return t_FinalColor;
			}

			ENDCG

		}

	}
}

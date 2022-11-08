		sampler2D _MainTex;
		sampler2D _SkinTex;
		sampler2D _ControlTex;
		// mask begin
		//sampler2D _ClothFurControlTex;
		UNITY_DECLARE_DEPTH_TEXTURE(_ClothFurControlTex);
		sampler2D _ControlAddTex;
		// mask end
		sampler2D _NoiseTex;
		sampler2D _BumpMap;
		
	    struct Input {
      		fixed alpha;
          	float2 uv_MainTex;
          	float3 worldRefl;
          	fixed3 viewDir;
			float3 uv_MainTex1;
			// mask begin
			//float2 uv_ClothTex;
			// mask end
      	};

  	 	uniform float3 Displacement;
		half4 _RimColor;
		fixed4 _Color;
		fixed4 _FurColor;		
		half _FurGlossiness;
		half _Glossiness;
		// simplified begin
		float _EnvironmentLightAdd;
		// simplified end
	    half _RimPower;
 	 	half _RimLightMode;
 	 	half _StrandThickness;
        fixed _ShadowStrength;
		fixed _MaxHairLength;
 	 	fixed _SkinMode;
 	 	half _BumpScale;
 	 	fixed _UseFurSecondMap;
 	 	fixed _UseSkinSecondMap;
 	 	fixed _UseStrengthMap;
 	 	fixed _UseHeightMap;
 	 	fixed _UseBiasMap;
 	 	float _EdgeFade;

		fixed		_DissolveAmount;
		fixed4		_DissolveInfo;
		fixed4		_DissolveColor;
		sampler2D	_DissolveSrc;
		
		fixed4		_ExtraControl;
		
		sampler2D	_DecalColorControlSrc;
		fixed4 		_DecalColor1;
		
		fixed _RimStrength;
			
			


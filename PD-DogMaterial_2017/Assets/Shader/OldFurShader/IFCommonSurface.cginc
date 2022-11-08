			fixed4 c = tex2D (_MainTex, IN.uv_MainTex) * _FurColor;
			fixed4 n = tex2D (_NoiseTex, IN.uv_MainTex * _StrandThickness);			
			o.Albedo = c.rgb;			
			
			// handle noise map
			o.Alpha = c.a * (n.r / NOISEFACTOR);			
			// handle heightmap
			fixed alphaFactor = 1;
			if (_UseHeightMap != 0) {
				// mask begin
				fixed4 ct_01 = tex2D (_ControlTex, IN.uv_MainTex);
				fixed4 ct_02 = tex2D (_ControlAddTex, IN.uv_MainTex);
				if(ct_02.r < 0.1)
					discard;	
				// mask end
				
				// fixed4 ct = tex2D (_ControlTex, IN.uv_MainTex);
				fixed4 ct = ct_01;//min(ct_01, ct_02);
				// mask end
				alphaFactor *= ct.r;
				o.Alpha = (CURRENTLAYER > ct.r) ? 0 : o.Alpha;
				if (o.Alpha > 0)
					o.Alpha *= CURRENTLAYER;
			}
			if (o.Alpha == 0)
				return;
				
			// handle edge fade
			o.Alpha *= IN.alpha;
			
			fixed s = lerp(1,CURRENTLAYER / alphaFactor,_ShadowStrength);
			o.Albedo *= s;
			
			// handle rim light
			if (_RimLightMode != 0) {
				half rim = 1.0 - saturate(dot (normalize(IN.viewDir), o.Normal));
            	if (_RimLightMode == 3)
	          		o.Emission = _RimColor.rgb * pow (rim, _RimPower);
            	else if (_RimLightMode == 2)
	           		o.Emission = UNITY_LIGHTMODEL_AMBIENT.rgb * pow (rim, _RimPower);
	           	else
	           		o.Emission = o.Albedo * pow (rim, _RimPower) * _RimStrength;            	
          	}
          	
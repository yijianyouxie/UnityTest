		void vertSkin (inout appdata_full v, out Input o) {
			UNITY_INITIALIZE_OUTPUT(Input,o);
			
			if (_UseBiasMap) {
	          	float4 c = tex2Dlod (_ControlTex, float4(v.texcoord.xy,0,0));		
				fixed skinLength = _MaxHairLength - (_MaxHairLength * c.b) * c.r;
            	v.vertex.xyz -= v.normal * skinLength;
            }
		}
		
		void vert (inout appdata_full v, out Input o) {
			UNITY_INITIALIZE_OUTPUT(Input,o);

           	float4 c = tex2Dlod (_ControlTex, float4(v.texcoord.xy,0,0));
           	float4 c2 = tex2Dlod (_ControlAddTex, float4(v.texcoord.xy,0,0));

			if (_UseBiasMap) {
				fixed skinLength = _MaxHairLength - (_MaxHairLength * c.b);
				v.vertex.xyz -= v.normal * skinLength;
			}			
			
			float hairLength = _MaxHairLength * CURRENTLAYER * c2.g;
			v.vertex.xyz += (v.normal * hairLength);
      		float movementFactor = pow(CURRENTLAYER, 2);    
      		                                          
           	if (_UseStrengthMap != 0) {
				v.vertex.xyz += Displacement * movementFactor * hairLength * c.g;
			} else {
				v.vertex.xyz += Displacement * movementFactor * hairLength;			
			}
				
			o.alpha = 1 - (CURRENTLAYER * CURRENTLAYER);	
			float3 viewDir = normalize(ObjSpaceViewDir(v.vertex));
			o.alpha += dot(viewDir, v.normal) - _EdgeFade;

			o.alpha = clamp(o.alpha, 0, 1);
		}			
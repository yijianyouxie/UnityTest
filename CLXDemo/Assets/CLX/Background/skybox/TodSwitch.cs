using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using CYEngine;

public class TodSwitch : MonoBehaviour 
{
    public Vector4 m_dayMie = new Vector4(0.03f, 0.04f, 0.05f, 0.30f);
    public Vector4 m_dayRayleigh = new Vector4(0.04f, 0.09f, 0.90f, 10.0f);
    public Vector4 m_dayPhaseFunc = new Vector4(-42.61f, 42.61f, 1.0f, 0.0f);
    public Vector4 m_nightMie = new Vector4(0.03f, 0.04f, 0.05f, 0.30f);
    public Vector4 m_nightleight = new Vector4(0.04f, 0.09f, 0.55f, 1.0f);
    public Vector4 m_nightPhaseFunc = new Vector4(-42.61f, 42.61f, 1.0f, 0.0f);
    public Vector4 m_sunsetMie = new Vector4(0.24f, 0.19f, 0.11f, 0.30f);
    public Vector4 m_sunsetRayleigh = new Vector4(0.34f, 0.45f, 0.55f, 5.0f);
    public Vector4 m_sunsetPhaseFunc = new Vector4(-42.61f, 42.61f, 0.3f, 0.0f);
    

    private Material m_skyMtl;
    private Material m_cloudMtl;

    public enum TimeOfDay
    {
        Day,
        Sunset,
        Night
    }

    public TimeOfDay tod = TimeOfDay.Day;
    public Light m_sunLight;
    public GameObject m_cloud;
    public GameObject m_stars;
    public Texture m_texDay;
    public Texture m_texSunset;
    public float m_CloudTransparency = 0.5f;
    public float m_switchTime = 3.0f;

    public Color m_daySunColor = new Vector4(1.0f, 0.882f, 0.901f, 0.0f);
    public Color m_sunsetSunColor = new Vector4(0.4f, 0.2798f, 0.2448f, 0.0f);
    public Color m_nightSunColor = new Vector4(0.127f, 0.465f, 1.2f, 0.0f);

    public CYFogControl m_FogScript;
    public FogParams m_dayFog;
    public FogParams m_sunsetFog;
    public FogParams m_nightFog;

    private bool m_bIsSwitchTOD = false;
    private float m_currentSwitchTime = 0.0f;

	// Use this for initialization
	void Start () 
    {
        MeshRenderer renderer = gameObject.GetComponent<MeshRenderer>();
        m_skyMtl = renderer.material;

        renderer = m_cloud.GetComponent<MeshRenderer>();
        m_cloudMtl = renderer.material;
        m_FogScript.SetFogParams(m_dayFog);
    }

    public void SwitchTimeOfDay()
    {
        m_bIsSwitchTOD = true;
        m_currentSwitchTime = 0.0f;

        if (tod == TimeOfDay.Day)
        {
            tod = TimeOfDay.Sunset;
        }
        else if (tod == TimeOfDay.Sunset)
        {
            tod = TimeOfDay.Night;
        }
        else if (tod == TimeOfDay.Night)
        {
            tod = TimeOfDay.Day;
        }
    }

	
	// Update is called once per frame
	void Update () 
    {
		if(tod == TimeOfDay.Day || tod == TimeOfDay.Sunset)
		{
            Transform trans = m_cloud.GetComponent<Transform>();
            trans.RotateAround(Vector3.up, Time.deltaTime * 0.03f);
		}

        m_currentSwitchTime += Time.deltaTime;
        float r;

        if (m_bIsSwitchTOD)
        {
            r = UnityEngine.Mathf.Min(m_currentSwitchTime / m_switchTime, 1.0f);
        }
        else
        {
            r = 1.0f;
        }

        if (tod == TimeOfDay.Sunset)
        {
            m_skyMtl.SetVector("_PartialMieInScatteringConst", m_dayMie + (m_sunsetMie - m_dayMie) * r);
            m_skyMtl.SetVector("_PartialRayleighInScatteringConst", m_dayRayleigh + (m_sunsetRayleigh - m_dayRayleigh) * r);
            m_skyMtl.SetVector("_PhaseFunctionConstants", m_dayPhaseFunc + (m_sunsetPhaseFunc - m_dayPhaseFunc) * r);
            m_cloudMtl.SetTexture("_CloudLayerTex", m_texSunset);
            m_sunLight.color = m_daySunColor + (m_sunsetSunColor - m_daySunColor) * r;

            FogParams newFogParams = new FogParams();
            newFogParams.FogStart = m_sunsetFog.FogStart;
            newFogParams.FogBaseHeightCoef = m_sunsetFog.FogBaseHeightCoef;
            newFogParams.FogHeightRange = m_sunsetFog.FogHeightRange;
            newFogParams.HeightOffset = m_sunsetFog.HeightOffset;
            newFogParams.HeightWeight = m_sunsetFog.HeightWeight;
            newFogParams.FogDensity = m_dayFog.FogDensity + (m_sunsetFog.FogDensity - m_dayFog.FogDensity) * r;
            newFogParams.FogWeight = m_dayFog.FogWeight + (m_sunsetFog.FogWeight - m_dayFog.FogWeight) * r;
            newFogParams.FogColor = m_dayFog.FogColor + (m_sunsetFog.FogColor - m_dayFog.FogColor) * r;
            newFogParams.FogColor2 = m_dayFog.FogColor2 + (m_sunsetFog.FogColor2 - m_dayFog.FogColor2) * r;
            newFogParams.FogColor3 = m_dayFog.FogColor3 + (m_sunsetFog.FogColor3 - m_dayFog.FogColor3) * r;
            m_FogScript.SetFogParams(newFogParams);

            m_cloud.SetActive(true);
            m_stars.SetActive(false);
           
            if (m_currentSwitchTime >= m_switchTime)
            {
                m_bIsSwitchTOD = false;
            }
        }
        else if (tod == TimeOfDay.Night)
        {
            m_skyMtl.SetVector("_PartialMieInScatteringConst", m_sunsetMie + (m_nightMie - m_sunsetMie) * r);
            m_skyMtl.SetVector("_PartialRayleighInScatteringConst", m_sunsetRayleigh + (m_nightleight - m_sunsetRayleigh) * r);
            m_skyMtl.SetVector("_PhaseFunctionConstants", m_sunsetPhaseFunc + (m_nightPhaseFunc - m_sunsetPhaseFunc) * r);

            m_sunLight.color = m_sunsetSunColor + (m_nightSunColor - m_sunsetSunColor) * r;
            m_cloudMtl.SetFloat("_BlendFactor", m_CloudTransparency * (1-r));

            FogParams newFogParams = new FogParams();
            newFogParams.FogStart = m_nightFog.FogStart;
            newFogParams.FogBaseHeightCoef = m_nightFog.FogBaseHeightCoef;
            newFogParams.FogHeightRange = m_nightFog.FogHeightRange;
            newFogParams.HeightOffset = m_nightFog.HeightOffset;
            newFogParams.HeightWeight = m_nightFog.HeightWeight;
            newFogParams.FogDensity = m_sunsetFog.FogDensity + (m_nightFog.FogDensity - m_sunsetFog.FogDensity) * r;
            newFogParams.FogWeight = m_sunsetFog.FogWeight + (m_nightFog.FogWeight - m_sunsetFog.FogWeight) * r;
            newFogParams.FogColor = m_sunsetFog.FogColor + (m_nightFog.FogColor - m_sunsetFog.FogColor) * r;
            newFogParams.FogColor2 = m_sunsetFog.FogColor2 + (m_nightFog.FogColor2 - m_sunsetFog.FogColor2) * r;
            newFogParams.FogColor3 = m_sunsetFog.FogColor3 + (m_nightFog.FogColor3 - m_sunsetFog.FogColor3) * r;
            m_FogScript.SetFogParams(newFogParams);

            if (m_currentSwitchTime >= m_switchTime)
            {
                m_stars.SetActive(true);
                m_bIsSwitchTOD = false;
            }
        }
        else if (tod == TimeOfDay.Day)
        {
            m_skyMtl.SetVector("_PartialMieInScatteringConst", m_nightMie + (m_dayMie - m_nightMie) * r);
            m_skyMtl.SetVector("_PartialRayleighInScatteringConst", m_nightleight + (m_dayRayleigh - m_nightleight) * r);
            m_skyMtl.SetVector("_PhaseFunctionConstants", m_nightPhaseFunc + (m_dayPhaseFunc - m_nightPhaseFunc) * r);         

            m_sunLight.color = m_nightSunColor + (m_daySunColor - m_nightSunColor) * r;

            FogParams newFogParams = new FogParams();
            newFogParams.FogStart = m_dayFog.FogStart;
            newFogParams.FogBaseHeightCoef = m_dayFog.FogBaseHeightCoef;
            newFogParams.FogHeightRange = m_dayFog.FogHeightRange;
            newFogParams.HeightOffset = m_dayFog.HeightOffset;
            newFogParams.HeightWeight = m_dayFog.HeightWeight;
            newFogParams.FogDensity = m_nightFog.FogDensity + (m_dayFog.FogDensity - m_nightFog.FogDensity) * r;
            newFogParams.FogWeight = m_nightFog.FogWeight + (m_dayFog.FogWeight - m_nightFog.FogWeight) * r;
            newFogParams.FogColor = m_nightFog.FogColor + (m_dayFog.FogColor - m_nightFog.FogColor) * r;
            newFogParams.FogColor2 = m_nightFog.FogColor2 + (m_dayFog.FogColor2 - m_nightFog.FogColor2) * r;
            newFogParams.FogColor3 = m_nightFog.FogColor3 + (m_dayFog.FogColor3 - m_nightFog.FogColor3) * r;
            m_FogScript.SetFogParams(newFogParams);

            m_cloud.SetActive(true);
            m_cloudMtl.SetTexture("_CloudLayerTex", m_texDay);
            m_cloudMtl.SetFloat("_BlendFactor", m_CloudTransparency * r);

            if (m_currentSwitchTime >= m_switchTime)
            {
                m_stars.SetActive(false); 
                m_bIsSwitchTOD = false;
            }
        }
    }
}

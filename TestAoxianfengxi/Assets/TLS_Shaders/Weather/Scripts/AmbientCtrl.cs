using UnityEngine;
using System.Collections;

public class AmbientCtrl : MonoBehaviour {

    public float MinWaitTime = 0.0f;
    public float MaxWaitTime = 3.0f;
    public float MaxValue = 5.0f;

    private float curValue = 1.0f;
    private float Intensity;
    private float baseIntensity;
    private Light curLight;
    void Start () {
#if UNITY_538F1_T20180417
        Shader.EnableKeyword("GLOBALSH_ENABLE");
        RenderSettings.globalSH = true;
#else
        GameObject.Destroy(this);
        return;
#endif
        curLight = this.GetComponent<Light>();
        baseIntensity = 0;
        Intensity = 1;
        StartCoroutine(ambientLighting());
    }
    private IEnumerator ambientLighting()
    {
        do
        {
            yield return new WaitForSeconds(Random.Range(MinWaitTime, MaxWaitTime));
            while(curValue < MaxValue)
            {
                curValue = Mathf.Lerp(curValue, MaxValue + 0.1f, Time.deltaTime*25);
                curLight.intensity = Intensity * curValue;
                yield return new WaitForSeconds(0.0f);
            }
            curLight.intensity = baseIntensity;
            curValue = 1.0f;
        } while (true);
    }
}

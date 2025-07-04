//using UnityEngine;
//using System.Collections;
//using Games.TLBB.Manager;
//using Games.TLBB.Render;

//[ExecuteInEditMode]
//public class GlobalSHCtrl : MonoBehaviour {

//    public float RandomMinTime = 5;
//    public float RandomMaxTime = 15;
//    public float DurationTimes = 1;
//    public AnimationCurve TimeCurve;
//    public Light CtrlLight = null;
//    private float enableTime;
//    private float baseIntensity;
//    public int BackSFXSound = -1;
//    public  int SoundResID = -1;
//    private int soundIndex = -1;
//    public void OnEnable()
//    {
//        if (Shader.globalMaximumLOD < 200)
//        {
//            return;
//        }
//        enableTime = Time.realtimeSinceStartup;
//        baseIntensity = CtrlLight.intensity;
//#if UNITY_538F1_T20180417
//        Shader.EnableKeyword("GLOBALSH_ENABLE");
//        RenderSettings.globalSH = true;
//        if(BackSFXSound >= 0)
//        {
//            Games.TLBB.Lua.LuaSound.StopSceneSFX();
//            Games.TLBB.Manager.LogicSoundManager.Instance.StartLogicSound(BackSFXSound, (int)SOUNDTYPE.SceneSFXBG);
//        }
//        StartCoroutine(CoroutineUpdate());
//#else
//        return;
//#endif
//    }
//    public void OnDisable()
//    {
//#if UNITY_538F1_T20180417
//        Shader.DisableKeyword("GLOBALSH_ENABLE");
//        RenderSettings.globalSH = false;
//        if (soundIndex >= 0)
//        {
//            LogicSoundManager.Instance.StopLogicSound(soundIndex);
//            soundIndex = -1;
//        }
//        StopAllCoroutines();
//#else
//        return;
//#endif
//    }
//    private IEnumerator CoroutineUpdate()
//    {
//        do
//        {
//            float time = Time.realtimeSinceStartup - enableTime;
//            if (time >= DurationTimes)
//            {
//                yield return new WaitForSeconds(Random.Range(RandomMinTime, RandomMaxTime));
//                enableTime = Time.realtimeSinceStartup;
//                if(soundIndex >= 0)
//                {
//                    LogicSoundManager.Instance.StopLogicSound(soundIndex);
//                    soundIndex = -1;
//                }
//                if(SoundResID > 0)
//                {
//                    soundIndex = LogicSoundManager.Instance.StartLogicSound(SoundResID, MainPlayerRenderEntity.Instance);
//                }
//            }
//            else
//            {
//                if(Shader.globalMaximumLOD < 200)
//                {
//                    this.OnDisable();
//                }
//                else
//                {
//                    float intensity = TimeCurve.Evaluate(time);
//                    CtrlLight.intensity = intensity;
//                    yield return new WaitForSeconds(0.0f);
//                }
//            }
//        } while (true);
        
//    }
//}

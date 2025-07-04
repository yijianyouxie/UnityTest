//using UnityEngine;
//using System.Collections;
//using Games.TLBB.Global;

//namespace TLEngineTeam
//{
//	public class DisturanceEffect : MonoBehaviour
//	{
//        private GameObject cameraGO;
//		private Camera rtCamera;
//		private RenderTexture rt;
//		Material mat;

//        private bool useColorRT = false;
//        private bool useSceneColorTex = false;

//        void OnEnable()
//		{
//            mat = GetComponent<Renderer> ().material;
//            if(null == TLStudio.Utils.SceneTextureProvider.colorRT)
//            {
//                //rtCamera = Instantiate<Camera> (Camera.main);
//                cameraGO = new GameObject("DisturanceEffectCamera", typeof(Camera), typeof(Skybox));
//                rtCamera = cameraGO.GetComponent<Camera>();
//                rtCamera.clearFlags = Camera.main.clearFlags;
//                rtCamera.backgroundColor = Camera.main.backgroundColor;
//                rtCamera.farClipPlane = Camera.main.farClipPlane;
//                rtCamera.nearClipPlane = Camera.main.nearClipPlane;
//                rtCamera.orthographic = Camera.main.orthographic;
//                rtCamera.fieldOfView = Camera.main.fieldOfView;
//                rtCamera.aspect = Camera.main.aspect;
//                rtCamera.orthographicSize = Camera.main.orthographicSize;
//                rtCamera.cullingMask = Camera.main.cullingMask;
//                rtCamera.allowHDR = Camera.main.allowHDR;
//                rtCamera.allowMSAA = Camera.main.allowMSAA;
//                rtCamera.depth = Camera.main.depth;

//                rt = RenderTexture.GetTemporary(Screen.width / 2, Screen.height / 2, 16, RenderTextureFormat.ARGB32);
//                rtCamera.targetTexture = rt;
//                rtCamera.cullingMask = ~(GameDefine_GlobalVar.TransparentFXLayerMask);
//                mat.SetTexture("_MainTex", rt);
//            }
//            else
//            {
//                if (useColorRT)
//                {
//                    mat.SetTexture("_MainTex", TLStudio.Utils.SceneTextureProvider.colorRT);
//                }
//                else
//                {
//                    var stp = Camera.main.GetComponent<TLStudio.Utils.SceneTextureProvider>();
//                    mat.SetTexture("_MainTex", stp.sceneColorTex);
//                }
//            }
//        }
//		void OnDisable()
//		{
//            if( rt != null)
//            {
//                RenderTexture.ReleaseTemporary(rt);
//                rt = null;
//            }
//            if(null != rtCamera)
//            {
//			    Destroy (rtCamera);
//            }
//            if(null != cameraGO)
//            {
//                Destroy(cameraGO);
//            }
//        }

//		// Update is called once per frame
//		void Update ()
//		{
//            if(null != rtCamera)
//            {
//			    rtCamera.transform.position = Camera.main.transform.position;
//			    rtCamera.transform.rotation = Camera.main .transform .rotation;
//            }
//		}
//	}
//}
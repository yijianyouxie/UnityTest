using UnityEngine;
using System.Collections;

[ExecuteInEditMode]
public class MaterialTimeCtrl : MonoBehaviour {

    public Material mat = null;
	void OnEnable () {
        if (mat != null)
            mat.SetFloat("_BeginTimeX", Time.timeSinceLevelLoad/20);
    }

 //   // Update is called once per frame
 //   void OnDisable () {
	
	//}
}

using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class OceanDemo : MonoBehaviour {

	// Use this for initialization
	void Start () {
        if(Camera.main != null)
        {
            Camera.main.depthTextureMode |= DepthTextureMode.Depth;
        }
        
    }
	
	
}

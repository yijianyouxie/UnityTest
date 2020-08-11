using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class CameraEffectHelper : MonoBehaviour
{
    private void Update()
    {
        var mainCam = Camera.main;
        if (mainCam == null)
            return;
        transform.position = mainCam.transform.position;
    }
}

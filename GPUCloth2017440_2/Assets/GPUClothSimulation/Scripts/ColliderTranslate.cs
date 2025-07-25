﻿using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ColliderTranslate : MonoBehaviour
{

    public float TranslateCenterZ = 0.0f;
    public float TranslateLengthZ = 4.0f;

    public float speed = 0.1f;

    void Update()
    {
        var pos = transform.localPosition;
        transform.localPosition = new Vector3(pos.x, pos.y, TranslateCenterZ + Mathf.Cos(Time.time * speed) * TranslateLengthZ);
    }
}

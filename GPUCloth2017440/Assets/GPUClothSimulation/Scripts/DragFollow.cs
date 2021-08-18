using UnityEngine;

public class DragFollow : MonoBehaviour {

    Transform tr;
    private void Start()
    {
        tr = transform;
    }
    /// <summary>
    /// 判断玩家是否可以移动
    /// </summary>
    bool isMove;
    void Update()
    {
        if (Input.GetMouseButtonDown(0))
            isMove = true;
        if (Input.GetMouseButtonUp(0))
            isMove = false;

        if (isMove)
        {
            Vector3 m_MousePos = new Vector3(Input.mousePosition.x, Input.mousePosition.y, 5);
            Vector3 pos = Camera.main.ScreenToWorldPoint(m_MousePos);
            tr.position = pos;
        }
    }
}

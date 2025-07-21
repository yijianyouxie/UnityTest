using Games.TLBB.Log;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace Games.TLBB.Util
{
    public class GyroController_Player : MonoBehaviour
    {
        private GyroController gyroController;
        private Quaternion deltaQuaternion;

        public bool Test = false;
        public Vector2 _vec = Vector2.zero;

        private bool hasStart = false;
        public static float staticRange = 0.3f;
        private static bool enableGyro_Player = false;

        private string str;

        private void Start()
        {
            gyroController = GyroController.GetInstance();
        }
        // Update is called once per frame
        void LateUpdate()
        {
            if (!enableGyro_Player)
            {
                return;
            }
            //获取陀螺仪的增量旋转角度
            if(null != gyroController)
            {
                deltaQuaternion = gyroController.GetGyroData((int)GyroController.GYROFUNCTYPE.SCENECAMERA);
                var deltaEuler = deltaQuaternion.eulerAngles;
                var xAngle = deltaEuler.x;
                var yAngle = deltaEuler.y;

                //对于横屏游戏，沿x轴的旋转角度大于一定值的时候开启向前走
                //沿y轴的旋转直接作用到左右转向上，沿y轴旋转的比重要要大于沿x轴的比重
                //这两个方向的值直接传输到摇杆的逻辑上去

                Vector2 vec = Vector2.zero;
                //x分量表示左右移动的幅度，左侧为负，右侧为正
                //y分量表示上下移动的幅度，上侧为正，下侧为负
                if (xAngle <= 180)
                {
                    vec.y = Mathf.Clamp(xAngle / 30f, 0, 1f);
                }
                else
                {
                    vec.y = Mathf.Clamp((xAngle - 360f) / 30f, -1f, 0);
                }

                if (yAngle <= 180)
                {
                    vec.x = -Mathf.Clamp(yAngle / 30f, 0, 1f);
                }
                else
                {
                    vec.x = -Mathf.Clamp((yAngle - 360f) / 30f, -1f, 0);
                }
                if(Test)
                {
                    vec = _vec;
                }
                LogSystem.Error(str);
                if(Mathf.Abs(vec.x) < staticRange && Mathf.Abs(vec.y) < staticRange)
                {
                    //GameManager.Instance.OnMoveEnd();
                    hasStart = false;
                    return;
                }

                if(!hasStart)
                {
                    //GameManager.Instance.OnMoveStart();
                    hasStart = true;
                }

                str = "====deltaEuler:" + deltaEuler + " xAngle:" + xAngle + " :" + yAngle + " vec:" + vec;
                GameManager.GetInstance().OnMove(vec);
            }
        }

        public static void ControllGyroPlayer(bool _enableGyro_Player)
        {
            enableGyro_Player = _enableGyro_Player;
        }


        //private void OnGUI()
        //{
        //    GUI.TextArea(new Rect(0, 200, 400, 100), str);
        //}
    }
}

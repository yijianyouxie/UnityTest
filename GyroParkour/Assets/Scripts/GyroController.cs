using Games.TLBB.Log;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
namespace Games.TLBB.Util
{
    /// <summary>
    /// 陀螺仪控制器
    /// </summary>
    public class GyroController : MonoBehaviour {

        private Quaternion currQuaternion;
        private struct GyroData
        {
            public int funcId;
            public Quaternion initQuaternion;
            public Quaternion deltaQuaternion;
        }

        private List<GyroData> gyroDataList = new List<GyroData>(4);

        public enum GYROFUNCTYPE
        {
            SCENECAMERA = 1,
        }

        public bool _resetGyro = false;
        public bool gyroInLate = false;
        public float frequency = 5f;
        private float lastSetTime = 0;

        private bool supportsGyroscope = false;

        private string str;

        private static GyroController _instance = null;
        public static GyroController GetInstance()
        {
            return _instance;
        }
        private void Awake()
        {
            supportsGyroscope = SystemInfo.supportsGyroscope;
            _instance = this;
        }

        private void Start()
        {
            if(supportsGyroscope)
            {
                Input.gyro.enabled = true;
            }else
            {
                enabled = false;
            }
        }

        private void LateUpdate()
        {
            //注释掉，第一个添加的时候获得的currQuaternion是0，因为这里还没有开始赋值currQuaternion
            //var len = gyroDataList.Count;
            //if(len <= 0)
            //{
            //    return;
            //}

            if (_resetGyro)
            {
                if (supportsGyroscope)
                {
                    Input.gyro.enabled = false;
                    Input.gyro.enabled = true;
                }
            }
            if (gyroInLate)
            {
                if (supportsGyroscope)
                {
                    Input.gyro.enabled = true;
                }
            }
            var time = Time.realtimeSinceStartup;
            if (time - lastSetTime >= frequency && frequency <= 40f)
            {
                lastSetTime = time;

                if (supportsGyroscope)
                {
                    Input.gyro.enabled = false;
                    Input.gyro.enabled = true;
                }
            }

            var gyroRotation = Input.gyro.attitude;
            Quaternion finalRotation = Quaternion.identity;
            finalRotation = Quaternion.Euler(90, 0, 0) * (new Quaternion(gyroRotation.x, gyroRotation.y, -gyroRotation.z, -gyroRotation.w));

            currQuaternion = finalRotation;


            GyroData data;
            var len = gyroDataList.Count;
            for (int i = 0; i < len; i++)
            {
                data = gyroDataList[i];
                data.deltaQuaternion = Quaternion.Inverse(data.initQuaternion) * currQuaternion;

                str = "====currQuaternion:" + currQuaternion + " initQuaternion:" + data.initQuaternion /*+ " deltaQuaternion:" + data.deltaQuaternion*/;
                LogSystem.Error(str);

                gyroDataList[i] = data;
            }
        }

        public void AddGyroData(int funcID)
        {
            bool has = false;
            GyroData data;
            var len = gyroDataList.Count;
            for(int i = 0; i < len; i++)
            {
                data = gyroDataList[i];
                if(data.funcId == funcID)
                {
                    data.initQuaternion = currQuaternion;
                    gyroDataList[i] = data;

                    has = true;
                    break;
                }
            }
            if(!has)
            {
                data = new GyroData();
                data.funcId = funcID;
                data.initQuaternion = currQuaternion;
                gyroDataList.Add(data);
            }
            
        }

        public Quaternion GetGyroData(int funcID)
        {
            GyroData data;
            var len = gyroDataList.Count;
            for (int i = 0; i < len; i++)
            {
                data = gyroDataList[i];
                if (data.funcId == funcID)
                {
                    return data.deltaQuaternion;
                }
            }

            return Quaternion.identity;
        }

        //private void OnGUI()
        //{
        //    GUI.TextArea(new Rect(0, 100, 400, 100), str);
        //}
    }
}

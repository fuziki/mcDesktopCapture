using UnityEngine;
using System;
using System.Runtime.InteropServices;

namespace mcDesktopCapture
{
    [Serializable]
    public class DisplayProperty
    {
        public int id;
        public string name;
        public int vendorNumber;
        public int modelNumber;
        public int serialNumber;
    }

    [Serializable]
    public class DisplayList
    {
        public DisplayProperty[] list;
    }

    public static class DesktopCapture
    {
        [DllImport("mcDesktopCapture")]
        private static extern string mcDesktopCapture_displayList();

        [DllImport("mcDesktopCapture")]
        private static extern void mcDesktopCapture_startCapture(long displayId);

        [DllImport("mcDesktopCapture")]
        private static extern void mcDesktopCapture_stopCapture();

        [StructLayout(LayoutKind.Sequential)]
        struct FrameEntity
        {
            public long width;
            public long height;
            public IntPtr texturePtr;
        }
        [DllImport("mcDesktopCapture")]
        private static extern FrameEntity mcDesktopCapture_getCurrentFrame();

        public static DisplayProperty[] DisplayList
        {
            get
            {
                var str = mcDesktopCapture_displayList();
                var list = JsonUtility.FromJson<DisplayList>(str);
                return list.list;
            }
        }

        private static bool isRunning = false;

        public static void StartCapture(int displayId)
        {
            if (isRunning) return;
            isRunning = true;
            Log("mcDesktopCapture: Start Capture");
            mcDesktopCapture_startCapture(displayId);
        }

        public static void StopCapture()
        {
            if (!isRunning) return;
            _texture = null;
            Log("mcDesktopCapture: Stop Capture");
            mcDesktopCapture_stopCapture();
            isRunning = false;
        }

        private static Texture2D _texture = null;
        public static Texture2D GetTexture2D()
        {
            if (!isRunning) return null;
            if (_texture != null) return _texture;
            Log("mcDesktopCapture: Get Current Frame");
            FrameEntity frameEntity = mcDesktopCapture_getCurrentFrame();
            if (frameEntity.width > 0 && frameEntity.height > 0 && _texture == null)
            {
                Log("mcDesktopCapture: Create Texture2D");
                _texture = Texture2D.CreateExternalTexture((int)frameEntity.width, (int)frameEntity.height, TextureFormat.ARGB32, false, false, frameEntity.texturePtr);
            }
            return _texture;
        }

        private static void Log(object message)
        {
            Debug.Log(message);
        }
    }
}

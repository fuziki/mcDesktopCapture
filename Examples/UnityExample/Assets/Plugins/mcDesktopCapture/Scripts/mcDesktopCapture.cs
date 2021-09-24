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

    public class DesktopCapture
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

        [DllImport("mcDesktopCapture")]
        private static extern int mcDesktopCapture_clearFrame(IntPtr texturePtr);

        private static IntPtr texturePtr = IntPtr.Zero;
        private static bool inited = false;

        public static DisplayProperty[] DisplayList
        {
            get
            {
                var str = mcDesktopCapture_displayList();
                var list = JsonUtility.FromJson<DisplayList>(str);
                return list.list;
            }
        }

        public static void StartCapture(int displayId)
        {
            mcDesktopCapture_startCapture(displayId);
        }

        public static void StopCapture()
        {
            mcDesktopCapture_stopCapture();
        }

        public static Texture2D GetCurrentFrame()
        {
            if (inited)
            {
                mcDesktopCapture_clearFrame(texturePtr);
            }
            Texture2D texture = null;
            FrameEntity frameEntity = mcDesktopCapture_getCurrentFrame();
            if (frameEntity.width > 0 && frameEntity.height > 0)
            {
                inited = true;
                texturePtr = frameEntity.texturePtr;

                texture = Texture2D.CreateExternalTexture((int)frameEntity.width, (int)frameEntity.height, TextureFormat.ARGB32, false, false, texturePtr);
            }
            return texture;
        }
    }
}

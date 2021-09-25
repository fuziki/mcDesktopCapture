# mcDesktopCapture

Unity native plugin to capture the macOS desktop as Texture2D

![unity_example](docs/videos/unity_example.gif)  

# Environment
* macOS 11.3.1
* Unity 2020.3.5

# Installation
* Copy mcDesktopCapture.bundle to your project.

# Usage
## Start capture

```c#
var list = DesktopCapture.DisplayList;
mcDesktopCapture_startCapture(list[0].id);
```

## Get current frame

* If w and h are not updated, the frame acquisition has failed.
* Create Texture2D from IntPtr

```c#
FrameEntity frameEntity = mcDesktopCapture_getCurrentFrame();
if (frameEntity.width > 0 && frameEntity.height > 0)
{
    texture = Texture2D.CreateExternalTexture((int)frameEntity.width, (int)frameEntity.height, TextureFormat.ARGB32, false, false, texturePtr);
}
```

## Clear frame if need

```c#
mcDesktopCapture_clearFrame(texturePtr);
```

## Stop capture

```c#
mcDesktopCapture_stopCapture();
```

# mcDesktopCapture

Unity native plugin to capture the macOS desktop as Texture2D

![unity_example](docs/videos/unity_example.gif)  

# Environment
* macOS 13.4
* Unity 2021.3.6

# Installation
* Copy mcDesktopCapture.bundle to your project.

# Usage
## Start capture

```c#
var list = DesktopCapture.DisplayList;
DesktopCapture.StartCapture(list[0].id);
```

## Set Texture

```c#
var texture = DesktopCapture.GetTexture2D();
if (texture == null) return;
Renderer m_Renderer = GetComponent<Renderer>();
m_Renderer.material.SetTexture("_MainTex", texture);
```

## Stop capture

```c#
DesktopCapture.StopCapture();
```

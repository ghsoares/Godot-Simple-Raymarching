# Godot-Simple-Raymarching
There's a lot of raymaching shaders, but I found no one that writes the result depth to the depth buffer, so other meshes without any shader don't clip properly with the raymarched geometry.
So I made a simple version with depth writting, so you can see that other meshes interacts with the raymarched geometry.
It only works in GLES3, as GLES2 don't support depth writting.


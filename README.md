# Gardenrift

The goal of this project is to create a small game in Zig, both as a
learning opportunity and a proof-of-concept, to see Zig would be a good
language to stick with for future game development needs.

It would also be a good learning opportunity to learn lower-level
concepts such as graphics and audio APIs, and ECS implementation.


### References

#### Zig
- [Zig Documentation](https://ziglang.org/documentation/0.11.0/)
- [Zig Guide](https://zig.guide/)

#### Vulkan/OpenGL/GLFW
- [Vulkan Tutorial](https://vulkan-tutorial.com/) **(Highly Recommended!)**
- [Vulkan (c++) Game Engine Tutorials by Brendan
  Galea](https://www.youtube.com/playlist?list=PL8327DO66nu9qYVKLDmdLW_84-yE4auCR)
- [GLFW Docs](https://www.glfw.org/)
- [Vulkan-Zig by Snektron](https://github.com/snektron/vulkan-zig)
- [Vulkan Docs](https://docs.vulkan.org/)
- [Mach-GLFW by Hexops](https://github.com/hexops/mach-glfw)
- [Mach-GLFW-Vulkan-example by
  Hexops](https://github.com/hexops/mach-glfw-vulkan-example)
- [Vulkan by
  GetIntoGameDev](https://www.youtube.com/playlist?list=PLn3eTxaOtL2NH5nbPHMK7gE07SqhcAjmk)
- [OpenGL Tutorial](https://www.opengl-tutorial.org/)
- [Vulkan-Cookbook by
  Packt](https://github.com/PacktPublishing/Vulkan-Cookbook) 
- [Kohi Game Engine by Travis
  Vroman](https://www.youtube.com/playlist?list=PLv8Ddw9K0JPg1BEO-RS-0MYs423cvLVtj) 

#### OpenAL
- [OpenAL Programmers
  Guide](https://www.openal.org/documentation/OpenAL_Programmers_Guide.pdf)
- [OpenAL Tutorial by Code, Tech and
  Tutorials](https://www.youtube.com/playlist?list=PLalVdRk2RC6r7-4zciZ3LKc96ikviw6BS)

#### Math/Linear Algebra
- [Model-View-Projection](https://jsantell.com/model-view-projection/)
- [Matrix Transformations by Jordan
  Santell](https://jsantell.com/matrix-transformations/)
- [Perspective Projection Matrix by
  pikuma](https://youtu.be/EqNcqBdrNyI?feature=shared) 

#### Image File Format
- [Zigimg](https://github.com/zigimg/zigimg)
- [BMP File Format by University of
  Alberta](https://www.ece.ualberta.ca/~elliott/ee552/studentAppNotes/2003_w/misc/bmp_file_format/bmp_file_format.htm)

#### Audio File Format
- [Making WAVs by Low Byte
  Productions](https://www.youtube.com/watch?v=udbA7u1zYfc)
- [WAVE PCM soundfile
  format](http://soundfile.sapp.org/doc/WaveFormat/)
- [Understanding Audio Basics by
  waveroom](https://www.waveroom.com/blog/bit-rate-vs-sample-rate-vs-bit-depth/) 

#### 3D File Format
- [Model Loading on OpenGL
  Tutorial](https://www.opengl-tutorial.org/beginners-tutorials/tutorial-7-model-loading/) 
- [Wavefront .obj file on
  Wikipedia](https://en.wikipedia.org/wiki/Wavefront_.obj_file)

#### Misc
- [Mach Engine](https://machengine.org/)
- [Pixi by Foxnne](https://github.com/foxnne/pixi)
- [Aftersun by Foxnne](https://github.com/foxnne/aftersun)


### Resources
- [Viking Room by
  nigelgoh](https://sketchfab.com/3d-models/viking-room-a49f1b8e4f5c4ecf9e1fe7d81915ad38)
  (models/viking_room.obj, textures/viking_room.bmp)
- [Blinding Lights by Zander
  Noriega](https://opengameart.org/content/blinding-lights)
  (sounds/blinding-lights.wav)
- [Completion by Brandon
  Morris](https://opengameart.org/content/completion-sound)
  (sounds/competion.wav)


### Decisions
- Files with underscores as names (e.g. `_.zig`) will be known as
  exporters. These serve as the entrypoints of a directory that expose
  its public contents. This should have nothing in it except a list of
  `pub const <name> = @import("<file>");`. This is as opposed to
  `main.zig` which may contain functionalities.

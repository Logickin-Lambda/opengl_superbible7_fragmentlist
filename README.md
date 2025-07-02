# Forget About it. SuperBible 7th is a Shitty Book
I am not going to keep fighting against the OpenGL ShittyBible Framework because it has full of horrible practice and I have been spent too much time on debugging the knowledge of their F***ing in house Framework rather than actually learning OpenGL. 

If it is a production code, I would will have a thought of "Fine, people have no time, so they have to use some dirty tricks to get the job done", but OpenGL SuperBible Example Code are in fact Teaching Materials and it should be clear about their implementation.The completely lack of comments to explain their unclear raw pointer and gotos flying across the whole project, and multiple examples has no consistentformat for their project set up while some of them use virtual function, while some other use that :: symbol to override the function, lacking care any form of coding practice, not to mention the excessively use of in-house framework instead of actually teaching the reader how to properly set up an OpenGL Project.

I am going to not fighting against the Demon in the abstraction hell anymore, so I will stop translating code in that book and start something else. THUS, this project will be remained UNFINISHED. The next project will be learnt from a complete new source, with complete new structure.

# Warning:
The original intention of this project is to port the original C++ implementation of the OpenGL SuperBible into zig that is compatible with the book format, which shows the **main features of the gl library** and the **shader code**, but because of the ease of migrating the code while objects and inheritance is forbidden in zig, I have to use function pointer as an alternative.

This is a **strongly discouraged practice** because the idea of zig is to minimizing the hidden behavior, writing in a more directed way, and I also dissatisfied with this current implementation; however, for the time I have, porting sb7.h directly is a more efficient approach to learn from the gl example, so I don't really have a choice for now. My project other than superbible won't write like this, please don't copy the structure.

If you are not focusing on the shader and the gl part of the library, you **SHOULD** take other projects as an reference to set up your opengl with is corresponding windowing system with a more idiomatic way:

- https://github.com/Logickin-Lambda/learn_opengl_first_triangle/blob/main/src/main.zig
- https://github.com/castholm/zig-examples/tree/master/opengl-hexagon
- https://github.com/griush/zig-opengl-example/blob/master/src/main.zig

PS: In this fragment list example, I no longer think I am learning OpenGL, but fighting Demons in the framework hell just like the DOOM game. The original C++ SuperBible framework is the second worst code I have ever seen, filling full of gotos, magic numbers, top level variables and a single object implementation flying across different files... Not only it is hard if not impossible to trace the issue of the code, but it also severely against the zig coding practice.

# OpenGL SuperBible 7th Edition Triangle Example
This is a basic example to show how the gl library plot a triangle and apply color with a series of shader, 
and the compilation process.

# Dependencies
This sb7.h port applied with three dependencies:

[castholm - zigglen](https://github.com/castholm/zigglgen)

[zig-gamedev - zglfw](https://github.com/zig-gamedev/zglfw)

[griush - zm](https://github.com/griush/zm)

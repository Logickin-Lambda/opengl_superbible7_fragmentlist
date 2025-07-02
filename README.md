# Forget About it. SuperBible 7th is a Shitty Book if you are learning it with language other than C++
I am not going to keep fighting against the OpenGL ShittyBible Framework because it has full of horrible practice and I have been spent too much time on debugging the knowledge of their F***ing in house Framework rather than actually learning OpenGL. 

If it is a production code, I would will have a thought of "Fine, people have no time, so they have to use some dirty tricks to get the job done", but OpenGL SuperBible Example Code are in fact Teaching Materials and it should be clear about their implementation.The completely lack of comments to explain their unclear raw pointer and gotos flying across the whole project, and multiple examples has no consistentformat for their project set up while some of them use virtual function, while some other use that :: symbol to override the function, lacking care any form of coding practice, not to mention the excessively use of in-house framework instead of actually teaching the reader how to properly set up an OpenGL Project. Just look at these:

```
FILE * fp;
GLuint temp = 0;
GLuint retval = 0;
header h;
size_t data_start, data_end;
unsigned char * data;
GLenum target = GL_NONE;

fp = fopen(filename, "rb");

if (!fp)
    return 0;

// read a header from the file, and after that
if (fread(&h, sizeof(h), 1, fp) != 1)
    goto fail_read;

if (memcmp(h.identifier, identifier, sizeof(identifier)) != 0)
    goto fail_header;
```

And these:
```
SB6M_CHUNK_HEADER * chunk = (SB6M_CHUNK_HEADER *)ptr;
ptr += chunk->size;
switch (chunk->chunk_type)
{
    case SB6M_CHUNK_TYPE_VERTEX_ATTRIBS:
        vertex_attrib_chunk = (SB6M_VERTEX_ATTRIB_CHUNK *)chunk;
        break;
    case SB6M_CHUNK_TYPE_VERTEX_DATA:
        vertex_data_chunk = (SB6M_CHUNK_VERTEX_DATA *)chunk;
        break;
    case SB6M_CHUNK_TYPE_INDEX_DATA:
        index_data_chunk = (SB6M_CHUNK_INDEX_DATA *)chunk;
        break;
    case SB6M_CHUNK_TYPE_SUB_OBJECT_LIST:
        sub_object_chunk = (SB6M_CHUNK_SUB_OBJECT_LIST *)chunk;
        break;
    case SB6M_CHUNK_TYPE_DATA:
        data_chunk = (SB6M_DATA_CHUNK *)chunk;
        break;
    default:
        break; // goto failed;
}
```

And these:
```
static const unsigned char identifier[] =
{
    0xAB, 0x4B, 0x54, 0x58, 0x20, 0x31, 0x31, 0xBB, 0x0D, 0x0A, 0x1A, 0x0A
};
```

It is like... What kind of identifier? Why blindly casting the struct in such a low level manner and raw pointer calculation  everywhere? Why doing a bunch of goto when C++ has exceptions? I am not going to say if this is right or wrong, but the lack of explanation with such questionable code is unacceptable.

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

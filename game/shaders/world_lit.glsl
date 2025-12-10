@header package shaders
@header import sg "sokol:gfx/"
@header import "core:math/linalg/glsl"

@module lit

@ctype mat4 glsl.mat4
@ctype vec4 glsl.vec4
@ctype vec3 glsl.vec3
@ctype vec2 glsl.vec2

@vs vs

in vec2 a_pos;
in vec2 a_uv;

struct Draw_Cmd {
    mat4 xform;
    vec4 color;
    vec2 uv0;
    vec2 uv1;
};

layout(binding=0, std430) readonly buffer per_instance {
    Draw_Cmd cmds[];
};

layout(binding=0) uniform per_batch_data {
    int batch_start;
};

out struct VS_OUT{
    vec4 world_pos;
    vec4 color;
    vec2 uv;
} vs_out;

void main() {
    vs_out.world_pos = cmds[batch_start + gl_InstanceIndex].xform * vec4(a_pos, 0.0, 1.0);
    vs_out.uv = vec2(
        mix(cmds[batch_start + gl_InstanceIndex].uv0.x, cmds[batch_start + gl_InstanceIndex].uv1.x, a_uv.x),
        mix(cmds[batch_start + gl_InstanceIndex].uv0.y, cmds[batch_start + gl_InstanceIndex].uv1.y, a_uv.y)
    );

    vs_out.color = cmds[batch_start + gl_InstanceIndex].color;

    gl_Position = vs_out.world_pos;
}

@end

@fs fs

in struct VS_OUT {
    vec4 world_pos;
    vec4 color;
    vec2 uv;
} vs_out;

layout(binding=1) uniform texture2D tex;
layout(binding=0) uniform sampler smp;

out vec4 frag;

void main() {
    frag = texture(sampler2D(tex, smp), vs_out.uv) * vs_out.color;

    if (frag.a < 0.1) {
        discard;
    }
}

@end

@program world_lit vs fs
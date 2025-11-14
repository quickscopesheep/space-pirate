@header package shaders
@header import sg "sokol:gfx"
@header import glsl "core:math/linalg/glsl"

@ctype mat4 glsl.mat4
@ctype vec4 glsl.vec4
@ctype vec3 glsl.vec3
@ctype vec2 glsl.vec2

@vs main_vert

struct Draw_Cmd {
    mat4 xform;
    vec4 color;
    vec2 uv0;
    vec2 uv1;
};

layout(binding=0, std430) readonly buffer draw_cmds_buffer {
    Draw_Cmd cmds[];
};

//layout(binding=1) uniform world_state_buffer {
//   
//};

in vec3 a_pos;
in vec2 a_uv;

out struct VS_OUT{
    vec4 world_pos;
    vec4 color;
    vec2 uv;
} vs_out;

void main() {
    vs_out.world_pos = cmds[gl_InstanceIndex].xform * vec4(a_pos, 1.0);
    vs_out.uv = vec2(
        mix(cmds[gl_InstanceIndex].uv0.x, cmds[gl_InstanceIndex].uv1.x, a_uv.x),
        mix(cmds[gl_InstanceIndex].uv0.y, cmds[gl_InstanceIndex].uv1.y, a_uv.y)
    );

    vs_out.color = cmds[gl_InstanceIndex].color;

    gl_Position = vs_out.world_pos;
}

@end

@fs main_frag

in struct VS_OUT {
    vec4 world_pos;
    vec4 color;
    vec2 uv;
} vs_out;

layout(binding=1) uniform texture2DArray tex;
layout(binding=0) uniform sampler smp;

out vec4 frag_color;

void main(){
    frag_color = texture(sampler2DArray(tex, smp), vec3(vs_out.uv, 0.0));

    if (frag_color.a < 0.1) {
        discard;
    }
}

@end

@program main main_vert main_frag
@header package shaders
@header import sg "sokol:gfx/"
@header import "core:math/linalg/glsl"

@vs vs
in vec2 pos;
in vec2 uv;

out vec2 vertex_uv;

void main() {
    gl_Position = vec4(pos.xy, 0, 1.0);
    vertex_uv = uv;
}

@end

@fs fs

layout(binding=0) uniform texture2D tex;
layout(binding=0) uniform sampler smp;

in vec2 vertex_uv;
out vec4 frag;

void main() {
    frag = texture(sampler2D(tex, smp), vertex_uv);
}

@end

@program blit vs fs
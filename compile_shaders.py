import os

#TODO: Make not shit

PARAMS = "--slang hlsl5:wgsl --format sokol_odin"

def get_all_files_of_extension(dir, extension):
    dirs = os.listdir(dir)
    newdirs = []
    
    for dir in dirs:
        if dir.split('.')[1] == extension:
            newdirs.append(dir)

    return newdirs

build_src = "game/shaders/"
build_dst = "game/shaders/"

files = get_all_files_of_extension(build_src, "glsl")

for file in files:
    os.system(f'sokol-shdc --input {build_src + file} --output {build_dst + file.split(".")[0]}.odin {PARAMS}')
    print(f"compiled: {file}")
"""Build reusable canyon meshes in Blender; run through Blender MCP or --python."""
import bpy, math, random, json, hashlib, shutil
from pathlib import Path
from mathutils import Vector, noise
ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / 'assets/landscapes/canyon'
OUT.mkdir(parents=True, exist_ok=True)
(OUT/'textures').mkdir(exist_ok=True)
source = bpy.data.materials.get('rock_face_03')
if source is None:
    source=bpy.data.materials.new('rock_face_03')
    source.use_nodes=True
    for key in ['Diffuse','Rough','Displacement','nor_gl']:
        path=OUT/'textures'/(key+'.jpg')
        if not path.exists(): raise RuntimeError('Import Poly Haven rock_face_03 at 2k first.')
        n=source.node_tree.nodes.new('ShaderNodeTexImage')
        n.image=bpy.data.images.load(str(path),check_existing=False)
        n.image.name='rock_face_03_'+key
records=[]
for n in source.node_tree.nodes:
    if n.type != 'TEX_IMAGE' or not n.image: continue
    name=n.image.name
    key=next((x for x in ['Diffuse','Rough','Displacement','nor_gl'] if name.endswith('_'+x)),None)
    if key is None: continue
    dest=OUT/'textures'/(key+'.jpg')
    original=Path(bpy.path.abspath(n.image.filepath))
    if not dest.exists() and n.image.packed_file:
        dest.write_bytes(bytes(n.image.packed_file.data))
    elif not dest.exists() and original.resolve()!=dest.resolve(): shutil.copy2(original,dest)
    if n.image.packed_file:
        methods=bpy.types.Image.bl_rna.functions['unpack'].parameters['method'].enum_items
        n.image.unpack(method=next(i.identifier for i in methods if i.identifier=='REMOVE'))
    n.image.filepath=str(dest)
    n.image.reload()
    n.image.pack()
    records.append({'path':str(dest.relative_to(ROOT)), 'sha256':hashlib.sha256(dest.read_bytes()).hexdigest(), 'bytes':dest.stat().st_size})
(OUT/'sources.json').write_text(json.dumps({'asset':'rock_face_03','url':'https://polyhaven.com/a/rock_face_03','authors':['Dario Barresi','Rico Cilliers'],'license':'CC0-1.0','resolution':'4k','files':records},indent=2)+'\n')
# Keep the user's scene intact. All generated meshes belong to a separate scene.
scene=bpy.data.scenes.get('Canyon Asset Studio')
if scene is None: scene=bpy.data.scenes.new('Canyon Asset Studio')
bpy.context.window.scene=scene
for obj in list(scene.objects):
    if obj.get('stuntcar_canyon'): bpy.data.objects.remove(obj,do_unlink=True)
mat=bpy.data.materials.get('Canyon sandstone') or bpy.data.materials.new('Canyon sandstone')
mat.use_nodes=True
nodes=mat.node_tree.nodes; nodes.clear(); links=mat.node_tree.links
bsdf=nodes.new('ShaderNodeBsdfPrincipled'); out=nodes.new('ShaderNodeOutputMaterial');links.new(bsdf.outputs['BSDF'],out.inputs['Surface'])
tex=nodes.new('ShaderNodeTexImage');tex.image=bpy.data.images.load(str(OUT/'textures/Diffuse.jpg'),check_existing=True)
mix=nodes.new('ShaderNodeMixRGB');mix.blend_type='MULTIPLY';mix.inputs[0].default_value=1;mix.inputs[2].default_value=(0.81,0.68,0.53,1)
links.new(tex.outputs['Color'],mix.inputs[1]);links.new(mix.outputs['Color'],bsdf.inputs['Base Color']);bsdf.inputs['Roughness'].default_value=.88
normal=nodes.new('ShaderNodeTexImage');normal.image=bpy.data.images.load(str(OUT/'textures/nor_gl.jpg'),check_existing=True);normal.image.colorspace_settings.name='Non-Color'
nm=nodes.new('ShaderNodeNormalMap');nm.inputs['Strength'].default_value=.65;links.new(normal.outputs['Color'],nm.inputs['Color']);links.new(nm.outputs['Normal'],bsdf.inputs['Normal'])

def mesh_object(name,verts,faces):
    mesh=bpy.data.meshes.new(name);mesh.from_pydata(verts,[],faces);mesh.update()
    obj=bpy.data.objects.new(name,mesh);scene.collection.objects.link(obj);obj['stuntcar_canyon']=True
    obj.data.materials.append(mat)
    # Planar projection per face, in metres. Runtime uses world-space projection.
    uv=mesh.uv_layers.new(name='UVMap')
    for p in mesh.polygons:
        axis=max(range(3),key=lambda a: abs(p.normal[a]))
        axes=[a for a in range(3) if a!=axis]
        for li in p.loop_indices:
            v=mesh.vertices[mesh.loops[li].vertex_index].co
            uv.data[li].uv=(v[axes[0]]/2.7,v[axes[1]]/2.7)
        p.use_smooth=True
    return obj

def column(name,seed,w,d,h,center=(0,0,0),mesa=False):
    rng=random.Random(seed);N=160 if mesa else 96;verts=[];faces=[]
    levels=[i/56 for i in range(57)]
    phase=rng.random()*6.28
    # Unequal joints cut into the silhouette, not just into the surface shading.
    joints=[(rng.uniform(0,math.tau),rng.uniform(.035,.11),
             rng.uniform(.14,.32),rng.uniform(-.13,.13)) for _ in range(13 if mesa else 8)]
    beds=[(rng.uniform(.12,.88),rng.uniform(.012,.032),rng.uniform(.025,.065)) for _ in range(5)]
    crowns=[rng.uniform(-2.8,2.2) for _ in range(17)]
    def crown(a):
        t=a/math.tau*len(crowns);i=int(t)%len(crowns);f=t-int(t)
        # Flat ledges with short broken transitions instead of rounded lobes.
        f=max(0,min(1,(f-.35)/.3))
        return crowns[i]*(1-f)+crowns[(i+1)%len(crowns)]*f
    for j,z in enumerate(levels):
        for k in range(N):
            a=k*2*math.pi/N
            s=(1.08-.13*z) if mesa else (1.09-.20*z)
            cut=0
            for angle,width,depth,lean in joints:
                delta=abs((a-angle-lean*z-.013*math.sin(z*13+angle)+math.pi)%math.tau-math.pi)
                cut=max(cut,depth*max(0,1-delta/width)**.7)
            bed_cut=sum(depth*max(0,1-abs(z-height-.008*math.sin(a*3+phase))/width)
                        for height,width,depth in beds)
            ripple=1+.045*math.sin(a*3+phase)-cut-bed_cut
            ca=math.cos(a);sa=math.sin(a)
            x=math.copysign(abs(ca)**.48,ca)*w*.5*s*ripple
            y=math.copysign(abs(sa)**.48,sa)*d*.5*s*ripple
            p=Vector((x+seed*.73,y,z*h))
            broad=noise.noise_vector(p*.19)
            detail=noise.noise_vector(p*.63)
            displacement=broad.x*.6 + detail.y*.18
            zz=z*h+crown(a)*z**4+(0 if j==0 else .3*math.sin(a*7+phase)*min(1,z*8))
            verts.append((x+ca*displacement+center[0],y+sa*displacement+center[1],zz+detail.z*.18+center[2]))
    for j in range(len(levels)-1):
        for k in range(N):
            a=j*N+k;b=j*N+(k+1)%N
            faces.append((a,b,b+N,a+N))
    faces.append(tuple(reversed(range(N))))
    faces.append(tuple((len(levels)-1)*N+k for k in range(N)))
    return mesh_object(name,verts,faces)

def join_parts(parts,name):
    bpy.ops.object.select_all(action='DESELECT')
    for p in parts:p.select_set(True)
    bpy.context.view_layer.objects.active=parts[0]
    bpy.ops.object.join();obj=parts[0];obj.name=name
    return obj

modules=[]
for v in range(3):
    rng=random.Random(410+v)
    parts=[]
    for k in range(5):
        parts.append(column('wall_part',v*100+k,12+rng.random()*3,12+rng.random()*3,24+rng.random()*10,(k*7.3-14.6,rng.uniform(-1.3,1.3),-1)))
    modules.append(join_parts(parts,'wall_'+str(v+1)))
parts=[column('mesa_core',711,112,76,55,mesa=True)]
for k in range(7):
    a=k*math.tau/7
    parts.append(column('mesa_buttress',720+k,19,22,21+(k%3)*5,(math.cos(a)*49,math.sin(a)*32,0)))
modules.append(join_parts(parts,'mesa'))
# Continuous arch: a closed tube, with two legs and a clear central opening.
verts=[];faces=[];N=48
path=[]
for z in [0,3,6,9]:path.append((-16,0,z,-1,0))
for k in range(1,97):
    a=math.pi-k*math.pi/96
    path.append((16*math.cos(a),1.2*math.sin(a*2),9+24*math.sin(a)+2*math.sin(a*2),math.cos(a),math.sin(a)))
for z in [6,3,0]:path.append((16,0,z,1,0))
arch_rng=random.Random(915)
fractures=[(arch_rng.uniform(5,len(path)-5),arch_rng.uniform(1.2,3.4),
            arch_rng.uniform(.22,.48),arch_rng.uniform(0,math.tau)) for _ in range(26)]
for i,(x,y,z,nx,nz) in enumerate(path):
    for k in range(N):
        a=k*math.tau/N
        # An angular cross-section and partial fractures break the old smooth tube.
        cut=max(depth*max(0,1-abs(i-station-.7*math.sin(a+angle))/width)*
                max(0,math.cos(a-angle))**4 for station,width,depth,angle in fractures)
        r=3.8*(1+.14*math.sin(i*.17)+.09*math.sin(a*3+i*.12)-cut)
        ca=math.copysign(abs(math.cos(a))**.55,math.cos(a))
        sa=math.copysign(abs(math.sin(a))**.55,math.sin(a))
        p=Vector((x+nx*ca*r,y+sa*(5.6+.7*math.sin(i*.19))*(1-cut),z+nz*ca*r))
        p+=noise.noise_vector(p*.19)*.65+noise.noise_vector(p*.85)*.13
        verts.append(tuple(p))
for i in range(len(path)-1):
    for k in range(N):
        a=i*N+k;b=i*N+(k+1)%N;faces.append((a,b,b+N,a+N))
faces.append(tuple(reversed(range(N))));faces.append(tuple((len(path)-1)*N+k for k in range(N)))
arch=mesh_object('arch',verts,faces)
# Recalculate normals for the tube regardless of ring winding.
import bmesh
bm=bmesh.new();bm.from_mesh(arch.data);bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces));bm.to_mesh(arch.data);bm.free()
modules.append(arch)
report=[]
for obj in modules:
    bpy.ops.object.select_all(action='DESELECT');obj.select_set(True);bpy.context.view_layer.objects.active=obj
    # Export each module at its own origin before arranging the studio.
    bpy.ops.export_scene.gltf(filepath=str(OUT/(obj.name+'.glb')),use_selection=True,use_active_scene=True,export_format='GLB',export_materials='NONE')
    report.append({'name':obj.name,'vertices':len(obj.data.vertices),'faces':len(obj.data.polygons),'dimensions':list(obj.dimensions)})
for i,obj in enumerate(modules): obj.location=(i*95,0,0)
scene.world=bpy.data.worlds.new('Canyon Studio World') if scene.world is None else scene.world
scene.world.color=(.3,.3,.3)
(OUT/'models.json').write_text(json.dumps(report,indent=2)+'\n')
(ROOT/'tools/canyon/source').mkdir(parents=True,exist_ok=True)
(ROOT/'tools/canyon/source/.gdignore').touch()
bpy.data.libraries.write(str(ROOT/'tools/canyon/source/canyon_models.blend'),{scene},path_remap='RELATIVE',fake_user=True,compress=True)
print(json.dumps(report))

"""Prepare two small stone meshes without changing the user's active scene."""
import bpy
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / 'assets/landscapes/canyon'
previous = bpy.context.window.scene
scene = bpy.data.scenes.new('Canyon stone preparation')
bpy.context.window.scene = scene
records = []
try:
    for number, asset in enumerate(['namaqualand_boulder_02', 'namaqualand_boulder_03']):
        for obj in list(scene.objects):
            bpy.data.objects.remove(obj, do_unlink=True)
        bpy.ops.import_scene.gltf(filepath=str(ROOT / 'assets/landscapes/prepared' / (asset + '.glb')))
        objects = [obj for obj in scene.objects if obj.type == 'MESH']
        for obj in objects:
            bpy.ops.object.select_all(action='DESELECT')
            obj.select_set(True)
            bpy.context.view_layer.objects.active = obj
            bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
            modifier = obj.modifiers.new('Small stone budget', 'DECIMATE')
            modifier.ratio = min(1.0, 800 / max(1, len(obj.data.polygons)))
            bpy.ops.object.modifier_apply(modifier=modifier.name)
        bpy.ops.object.select_all(action='DESELECT')
        for obj in objects: obj.select_set(True)
        bpy.ops.export_scene.gltf(filepath=str(OUT / ('scree_%d.glb' % number)),
                                  export_format='GLB', use_selection=True, use_active_scene=True, export_materials='NONE')
        records.append({'source': asset, 'triangles': sum(len(obj.data.polygons) for obj in objects)})
    (OUT / 'scree.json').write_text(json.dumps(records, indent=2) + '\n')
    print(records)
finally:
    for obj in list(scene.objects): bpy.data.objects.remove(obj, do_unlink=True)
    bpy.context.window.scene = previous
    bpy.data.scenes.remove(scene)

"""Run with Blender: reduce large CC0 models while retaining their UV maps."""
import bpy
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
DEST = ROOT / 'assets/landscapes/prepared'
DEST.mkdir(parents=True, exist_ok=True)
records = []
for name, budget in [('namaqualand_boulder_02', 7000), ('namaqualand_boulder_03', 7000), ('quiver_tree_01', 24000), ('rock_07', 7000), ('shrub_02', 40000)]:
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=str(ROOT / 'assets/landscapes' / name / (name + '.gltf')))
    meshes = [obj for obj in bpy.context.scene.objects if obj.type == 'MESH']
    before = sum(len(obj.data.polygons) for obj in meshes)
    for obj in meshes:
        bpy.context.view_layer.objects.active = obj
        bpy.ops.object.select_all(action='DESELECT')
        obj.select_set(True)
        # Preserve the source orientation when Godot uses the mesh directly.
        bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
        if before > budget:
            modifier = obj.modifiers.new('Game detail', 'DECIMATE')
            modifier.ratio = budget / before
            bpy.ops.object.modifier_apply(modifier=modifier.name)
    after = sum(len(obj.data.polygons) for obj in meshes)
    bpy.ops.export_scene.gltf(filepath=str(DEST / (name + '.glb')), export_format='GLB', export_cameras=False, export_lights=False)
    records.append({'source':name, 'source_triangles':before, 'prepared_triangles':after})
(DEST / 'details.json').write_text(json.dumps(records, indent=2)+'\n')

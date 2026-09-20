"""Compile every Luau source and build the original Rojo project. Tools must be on PATH."""
from pathlib import Path
import subprocess
import tempfile

root = Path(__file__).resolve().parents[1]
files = sorted((root / 'src').rglob('*.luau'))
for path in files:
    result = subprocess.run(['luau-compile', str(path)], capture_output=True)
    if result.returncode:
        raise SystemExit(result.stderr.decode(errors='replace'))
print(f'PASS: {len(files)} Luau source files compile')
with tempfile.TemporaryDirectory() as folder:
    output = Path(folder) / 'portal.rbxlx'
    subprocess.run(['rojo', 'build', 'default.project.json', '-o', str(output)], cwd=root, check=True)
    import xml.etree.ElementTree as ET
    place = ET.parse(output)
    names = [node.text for node in place.findall('.//Item/Properties/string[@name="Name"]')]
    for required in ['Server', 'Client', 'Shared', 'Portal', 'Config', 'Service', 'Renderer', 'Transit', 'Gun', 'Phoenix', 'AvatarLoader', 'AvatarStyle', 'Body', 'Lab', 'Sequences', 'Motion', 'Storage', 'Punch']:
        assert required in names, f'Missing Rojo instance: {required}'
    print('PASS: Rojo place builds and contains expected script/module names')
subprocess.run(['lune', 'run', 'tests/run.luau'], cwd=root, check=True)

subprocess.run(['lune', 'run', 'tests/phoenix.luau'], cwd=root, check=True)

subprocess.run(['lune', 'run', 'tests/phoenix_pose.luau'], cwd=root, check=True)
subprocess.run(['lune', 'run', 'tests/avatar_style.luau'], cwd=root, check=True)

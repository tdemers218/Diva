"""Install/update/uninstall against an isolated desktop with stubbed IPC."""
import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]

class Install(unittest.TestCase):
    def test_workspace_migration_is_once_and_reversible(self):
        with tempfile.TemporaryDirectory() as folder:
            home = Path(folder)
            commands = home / 'commands'
            commands.mkdir()
            fake = '''#!/bin/bash
case "$(basename "$0"):$1:$2:$3" in
  omarchy:version:*) echo 4.0.4 ;;
  omarchy:plugin:list:--json) echo '[{"id":"io.github.tdemers218.diva","enabled":true}]' ;;
esac
exit 0
'''
            for name in ('omarchy', 'omarchy-shell', 'omarchy-theme-set', 'hyprctl', 'omarchy-restart-shell'):
                f = commands / name
                f.write_text(fake)
                f.chmod(0o755)
            config = home / '.config/omarchy/shell.json'
            config.parent.mkdir(parents=True)
            entry = {'id': 'omarchy.workspaces', 'custom': 'preserve this'}
            original = {'bar': {'layout': {'left': [{'id':'io.github.tdemers218.diva'}, entry], 'center': [], 'right': []}}, 'plugins': []}
            config.write_text(json.dumps(original))
            hypr = home / '.config/hypr'
            hypr.mkdir(parents=True)
            (hypr / 'bindings.lua').write_text('-- personal bindings\n')
            (hypr / 'hyprland.lua').write_text('-- personal desktop\n')
            env = dict(os.environ, HOME=str(home), XDG_CONFIG_HOME=str(home / '.config'), XDG_STATE_HOME=str(home / '.local/state'), PATH=str(commands)+':'+os.environ['PATH'])
            def run(*args):
                result = subprocess.run([str(ROOT/'bin/diva'), *args], env=env, capture_output=True, text=True, timeout=30)
                self.assertEqual(result.returncode,0,result.stdout+result.stderr)
            run('install','--no-theme','--no-look')
            statepath = home / '.local/state/diva/install.json'
            state = json.loads(statepath.read_text())
            self.assertTrue(state['desktopNavigation'])
            self.assertEqual(state['workspaceWidgets'][0]['entry'],entry)
            self.assertFalse(any(e['id']=='omarchy.workspaces' for e in json.loads(config.read_text())['bar']['layout']['left']))
            run('install','--no-theme','--no-look')
            self.assertEqual(json.loads(statepath.read_text())['workspaceWidgets'],state['workspaceWidgets'])
            run('uninstall')
            self.assertEqual(json.loads(config.read_text())['bar']['layout']['left'], original['bar']['layout']['left'])
            self.assertEqual((hypr/'bindings.lua').read_text(),'-- personal bindings\n')

if __name__ == '__main__': unittest.main()

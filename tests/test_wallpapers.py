"""Exercise discovery and path allowlisting in an isolated user directory."""
import importlib.machinery
from pathlib import Path
import tempfile
import unittest

loader = importlib.machinery.SourceFileLoader('wallpapers', str(Path(__file__).resolve().parents[1] / 'plugin/bin/diva-wallpapers'))
import importlib.util
import sys
sys.dont_write_bytecode = True
module = importlib.util.module_from_spec(importlib.util.spec_from_loader(loader.name, loader))
loader.exec_module(module)

class Wallpapers(unittest.TestCase):
    def test_theme_and_user_images_only(self):
        with tempfile.TemporaryDirectory() as folder:
            module.home = Path(folder)
            module.current = module.home / '.local/state/omarchy/current'
            images = module.current / 'theme/backgrounds'
            images.mkdir(parents=True)
            (module.current / 'theme.name').write_text('diva')
            (images / 'rose.jpg').touch()
            (images / 'credits.md').touch()
            custom = module.home / '.config/omarchy/backgrounds/diva'
            custom.mkdir(parents=True)
            (custom / 'photo.png').touch()
            result = module.wallpapers()
            self.assertEqual({r['name'] for r in result}, {'rose', 'photo'})
            self.assertTrue(all(Path(r['path']).is_absolute() for r in result))
    def test_theme_name_cannot_escape_user_backgrounds(self):
        with tempfile.TemporaryDirectory() as folder:
            module.home = Path(folder)
            module.current = module.home / '.local/state/omarchy/current'
            module.current.mkdir(parents=True)
            (module.current / 'theme.name').write_text('../../outside')
            self.assertEqual(module.wallpapers(), [])

if __name__ == '__main__': unittest.main()

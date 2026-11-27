import contextlib
import io
import os
import tempfile
import unittest

from PIL import Image
import dmi
from dmi.merge_driver import DmiDriver

RED = (255, 0, 0, 255)
GREEN = (0, 255, 0, 255)
BLUE = (0, 0, 255, 255)
WHITE = (255, 255, 255, 255)


def build(states, size=(32, 32)):
    """Create a DMI file from a list of `(name, color, ...)`, with one frame per color."""
    sheet = dmi.Dmi(*size)
    for name, *colors in states:
        state = sheet.state(name)
        for color in colors:
            state.frame(Image.new('RGBA', size, color))
    result = io.BytesIO()
    sheet.to_file(result)
    result.seek(0)
    return result


def describe(sheet):
    return [(state.name, *(frame.getpixel((0, 0)) for frame in state.frames)) for state in sheet.states]


class MergeTest(unittest.TestCase):
    BASE = [('a', RED), ('b', GREEN)]

    def merge(self, base, left, right):
        """Returns `(success, states)`, with the states as read back from the saved file."""
        driver = DmiDriver()
        files = [x if isinstance(x, io.BytesIO) else build(x) for x in (base, left, right)]
        with contextlib.redirect_stdout(io.StringIO()):
            success, merged = driver.merge(*files)
        if merged is None:
            return success, None
        output = io.BytesIO()
        driver.to_file(output, merged)
        output.seek(0)
        return success, describe(dmi.Dmi.from_file(output))

    def test_different_states(self):
        self.assertEqual(
            self.merge(self.BASE, [('a', WHITE), ('b', GREEN), ('l', BLUE)], [('a', RED), ('b', BLUE), ('r', WHITE)]),
            (True, [('a', WHITE), ('b', BLUE), ('l', BLUE), ('r', WHITE)]))

    def test_add_conflict(self):
        self.assertFalse(self.merge(self.BASE, self.BASE + [('n', WHITE)], self.BASE + [('n', BLUE)])[0])

    def test_delete_change_conflict(self):
        success, states = self.merge(self.BASE, [('b', GREEN)], [('a', WHITE), ('b', GREEN)])
        self.assertFalse(success)
        self.assertEqual(states, [('b', GREEN), ('a !CONFLICT! right', WHITE)])
        success, states = self.merge(self.BASE, [('a', WHITE), ('b', GREEN)], [('b', GREEN)])
        self.assertFalse(success)
        self.assertEqual(states, [('b', GREEN), ('a !CONFLICT! left', WHITE)])

    def test_duplicates_not_merged(self):
        duplicate = [('a', RED), ('a', WHITE), ('b', GREEN)]
        self.assertEqual(self.merge(duplicate, self.BASE, self.BASE), (False, None))
        self.assertEqual(self.merge(self.BASE, duplicate, self.BASE), (False, None))
        self.assertEqual(self.merge(self.BASE, self.BASE, duplicate), (False, None))

    def test_animation_changed(self):
        self.assertEqual(
            self.merge(self.BASE, [('a', RED, BLUE), ('b', GREEN)], self.BASE),
            (True, [('a', RED, BLUE), ('b', GREEN)]))

    def test_same_change(self):
        changed = [('a', WHITE), ('b', GREEN), ('n', BLUE)]
        self.assertEqual(self.merge(self.BASE, changed, changed), (True, changed))

    def test_change_conflict(self):
        success, states = self.merge(self.BASE, [('a', WHITE), ('b', GREEN)], [('a', BLUE), ('b', GREEN)])
        self.assertFalse(success)
        self.assertEqual(states, [
            ('b', GREEN),
            ('a !CONFLICT! base', RED),
            ('a !CONFLICT! left', WHITE),
            ('a !CONFLICT! right', BLUE),
        ])

    def test_deleted(self):
        self.assertEqual(
            self.merge(self.BASE, [('b', GREEN)], self.BASE + [('r', WHITE)]),
            (True, [('b', GREEN), ('r', WHITE)]))
        self.assertEqual(self.merge(self.BASE, self.BASE, [('b', GREEN)]), (True, [('b', GREEN)]))
        self.assertEqual(self.merge(self.BASE, [('b', GREEN)], [('b', GREEN)]), (True, [('b', GREEN)]))

    def test_rename_change_conflict(self):
        success, states = self.merge(self.BASE, [('z', RED), ('b', GREEN)], [('a', WHITE), ('b', GREEN)])
        self.assertFalse(success)
        self.assertIn(('z', RED), states)

    def test_resized(self):
        self.assertEqual(self.merge(self.BASE, self.BASE, build(self.BASE, (64, 64))), (False, None))

    def test_reordered(self):
        self.assertEqual(
            self.merge(self.BASE, self.BASE[::-1], self.BASE + [('r', WHITE)]),
            (True, self.BASE + [('r', WHITE)]))

    def test_transparent_pixels_ignored(self):
        self.assertEqual(
            self.merge([('a', (0, 0, 0, 0))], [('a', (255, 0, 0, 0))], [('a', WHITE)]),
            (True, [('a', WHITE)]))

    def test_driver_writes_result(self):
        with tempfile.TemporaryDirectory() as directory:
            paths = []
            sides = (self.BASE, self.BASE + [('l', BLUE)], self.BASE + [('r', WHITE)])
            for name, states in zip(('base', 'left', 'right'), sides):
                paths.append(os.path.join(directory, name))
                with open(paths[-1], 'wb') as f:
                    f.write(build(states).read())
            with contextlib.redirect_stdout(io.StringIO()):
                self.assertFalse(DmiDriver().main(['icon.dmi', *paths, '7']))
            with open(paths[1], 'rb') as f:
                self.assertEqual(describe(dmi.Dmi.from_file(f)), self.BASE + [('l', BLUE), ('r', WHITE)])


if __name__ == '__main__':
    unittest.main()

"""Check DPI clock ordering, including one clock and coincident clock edges."""
import os
from pathlib import Path
import shlex
import subprocess
import tempfile
import unittest

HERE = Path(__file__).resolve().parent
BASEJUMP = HERE.parents[2]


class ClockSchedule(unittest.TestCase):
    def test_edge_schedule(self):
        # Only the standard DPI scope declarations are needed: use the real
        # simulator header if configured, otherwise this small interface stub.
        with tempfile.TemporaryDirectory() as temporary:
            build = Path(temporary)
            if 'VERILATOR_ROOT' in os.environ:
                includes = Path(os.environ['VERILATOR_ROOT']) / 'include/vltstd'
            else:
                includes = build
                (build / 'svdpi.h').write_text('''
#pragma once
typedef void* svScope;
extern "C" svScope svGetScopeFromName(const char*);
extern "C" svScope svSetScope(svScope);
''')
            binary = build / 'clock-test'
            compiler = shlex.split(os.environ.get('CXX', 'c++'))
            command = compiler + ['-std=c++11', '-O2', '-D_GLIBCXX_ASSERTIONS',
                '-D_LIBCPP_HARDENING_MODE=_LIBCPP_HARDENING_MODE_DEBUG',
                '-I' + str(includes), '-I' + str(BASEJUMP / 'bsg_test'),
                str(HERE / 'main.cpp'), str(BASEJUMP / 'bsg_test/bsg_nonsynth_dpi_clock_gen.cpp'),
                '-o', str(binary)]
            subprocess.run(command, check=True)
            for periods in [(4,), (4, 6), (4, 4), (4, 6, 10)]:
                with self.subTest(periods=periods):
                    result = subprocess.run([str(binary)] + [str(p) for p in periods],
                                            text=True, capture_output=True, timeout=10)
                    self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
                    self.assertIn('PASS clocks=' + str(len(periods)), result.stdout)


if __name__ == '__main__':
    unittest.main()

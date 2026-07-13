from __future__ import annotations

import os
import subprocess
import sys


def main() -> None:
    script = os.path.join(os.path.dirname(__file__), "qa.sh")
    sys.exit(subprocess.call(["bash", script]))

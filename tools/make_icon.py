#!/usr/bin/env python3
"""10秒日記のアイコン（Icon Composer の .icon）を作る。
採用は候補 A「日記のページ＋ガラスのストップウォッチ」（2026-11-26 決定）。
形は design/candidates2/make.py の A-page-watch で作り、それを JubyoNikki/AppIcon.icon に写す。
  python3 tools/make_icon.py
"""
import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
subprocess.run([sys.executable, str(ROOT / "design" / "candidates2" / "make.py")], check=True)
src = ROOT / "design" / "candidates2" / "A-page-watch.icon"
dst = ROOT / "JubyoNikki" / "AppIcon.icon"
shutil.rmtree(dst, ignore_errors=True)
shutil.copytree(src, dst)
print("AppIcon.icon ← A-page-watch.icon")

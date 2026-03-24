#!/usr/bin/env python3
import os
import re

isar_path = os.path.expanduser(
    "~/AppData/Local/Pub/Cache/hosted/pub.dev/isar_flutter_libs-3.1.0+1/android/build.gradle"
)

if os.path.exists(isar_path):
    with open(isar_path, "r") as f:
        content = f.read()

    if "namespace" not in content:
        content = content.replace(
            "android {", 'android {\n    namespace "dev.isar.isar_flutter_libs"'
        )
        with open(isar_path, "w") as f:
            f.write(content)
        print("Isar namespace patched successfully")
    else:
        print("Isar already has namespace")
else:
    print("Isar path not found")

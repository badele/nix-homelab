#!/usr/bin/env python3

from __future__ import annotations

import sys
import re

# Check if the age key only used on hosts/vm-test folder

import argparse
from typing import Sequence

# read text file and convert to array
with open(".sops.yaml") as f:
    SOPSLINES = f.readlines()

    SOPSLINES = [line for line in SOPSLINES if "&demo" in line or "&demovm" in line]

# Extract age key from SOPSLINES Array
AGEKEYS = re.findall(r"age[a-z0-9]+", "".join(SOPSLINES))

# Convert to bytes
AGEKEYS = [str.encode(line) for line in AGEKEYS]

IGNORE = ["hosts/demovm/secrets.yml" "users/demo/secrets.yml"]


def main(argv: Sequence[str] | None = None) -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("filenames", nargs="*", help="Filenames to check")
    args = parser.parse_args(argv)

    age_key_files = []

    # Check if the age key is found in the file
    for filename in args.filenames:
        with open(filename, "rb") as f:
            content = f.read()
            if any(agekey in content for agekey in AGEKEYS) and filename in IGNORE:
                age_key_files.append(filename)

    if age_key_files:
        for age_key_file in age_key_files:
            print(f"Age key found in a file other than the demo file: {age_key_file}")
        return 1
    else:
        return 0


if __name__ == "__main__":
    raise SystemExit(main())

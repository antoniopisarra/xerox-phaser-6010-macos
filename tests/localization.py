#!/usr/bin/env python3
"""Check that every static localization call has an English translation."""
import json
import re
from pathlib import Path
root = Path(__file__).resolve().parents[1]
quoted = r'"(?:\\.|[^"\\])*"'
source = (root/'app/Language.swift').read_text()
keys = {json.loads(m.group(1)) for m in re.finditer('('+quoted+r')\s*:\s*'+quoted, source)}
used = set()
for path in (root/'app').glob('*.swift'):
    for m in re.finditer(r'\bL\(\s*('+quoted+r')\s*\)', path.read_text()):
        used.add(json.loads(m.group(1)))
missing = used - keys
assert not missing, f'Missing English translations: {sorted(missing)}'
assert len(used) > 90
print(f'PASS: all {len(used)} UI localization keys have English translations.')

#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# Tests for validate_license.sh — offline, deterministic, no network.
# Exercises the license classifier via LICENSE_TEXT_FILE / LICENSE_SPDX.
# Exit 0 = a license that PERMITS paid distribution (build allowed);
# exit 1 = denied or unidentifiable (build blocked, fail-closed).
#
# Run:  ./test_validate_license.sh
# ---------------------------------------------------------------------------
set -uo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT="$DIR/validate_license.sh"
[ -f "$SCRIPT" ] || { echo "validate_license.sh not found next to tests"; exit 2; }

tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
pass=0; fail=0

# run <name> <expected_exit> <spdx>   (license text on stdin)
run() {
  local name="$1" expected="$2" spdx="${3:-}"
  local f="$tmp/lic"; cat > "$f"
  local out ec
  out="$(LICENSE_TEXT_FILE="$f" LICENSE_SPDX="$spdx" bash "$SCRIPT" 2>&1)"; ec=$?
  if [ "$ec" = "$expected" ]; then
    printf 'ok   - %s\n' "$name"; pass=$((pass+1))
  else
    printf 'FAIL - %s (expected exit %s, got %s)\n' "$name" "$expected" "$ec"
    printf '%s\n' "$out" | sed 's/^/         /'; fail=$((fail+1))
  fi
}

echo "== licenses that PERMIT paid distribution (expect exit 0) =="

run "MIT" 0 <<'EOF'
Permission is hereby granted, free of charge, to any person obtaining a copy
of this software, to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish, distribute,
sublicense, and/or sell copies of the Software.
EOF

run "Apache-2.0" 0 <<'EOF'
                                 Apache License
                           Version 2.0, January 2004
EOF

run "BSD-3-Clause" 0 <<'EOF'
Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:
EOF

run "ISC" 0 <<'EOF'
Permission to use, copy, modify, and/or distribute this software for any
purpose with or without fee is hereby granted.
EOF

run "GPL-3.0 (text)" 0 <<'EOF'
                    GNU GENERAL PUBLIC LICENSE
                       Version 3, 29 June 2007
EOF

run "AGPL-3.0 (text)" 0 <<'EOF'
                    GNU AFFERO GENERAL PUBLIC LICENSE
                       Version 3, 19 November 2007
EOF

run "LGPL (text)" 0 <<'EOF'
                   GNU LESSER GENERAL PUBLIC LICENSE
                       Version 3, 29 June 2007
EOF

run "MPL-2.0 (text)" 0 <<'EOF'
Mozilla Public License Version 2.0
==================================
EOF

run "Unlicense" 0 <<'EOF'
This is free and unencumbered software released into the public domain.
EOF

run "CC0-1.0" 0 <<'EOF'
Creative Commons Legal Code

CC0 1.0 Universal
EOF

run "Boost (BSL-1.0)" 0 <<'EOF'
Boost Software License - Version 1.0 - August 17th, 2003
EOF

run "WTFPL" 0 <<'EOF'
DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
EOF

run "Zlib" 0 <<'EOF'
This software is provided 'as-is'. Altered source versions must be plainly
marked as such, and must not be misrepresented as being the original software.
EOF

run "PostgreSQL/MIT-style" 0 <<'EOF'
Permission to use, copy, modify, and distribute this software and its
documentation for any purpose, without fee, and without a written agreement.
EOF

echo "== permitted via explicit SPDX id (text unrecognised) =="
run "SPDX MIT"              0 "MIT"              <<<"opaque"
run "SPDX Apache-2.0"       0 "Apache-2.0"       <<<"opaque"
run "SPDX GPL-3.0-or-later" 0 "GPL-3.0-or-later" <<<"opaque"
run "SPDX BSD-3-Clause"     0 "BSD-3-Clause"     <<<"opaque"

echo
echo "== licenses that FORBID paid distribution (expect exit 1) =="

run "Business Source License" 1 <<'EOF'
Business Source License 1.1
Licensor: Example Corp
EOF

run "SSPL" 1 <<'EOF'
Server Side Public License
VERSION 1, OCTOBER 16, 2018
EOF

run "Elastic-2.0" 1 <<'EOF'
Elastic License 2.0
URL: https://www.elastic.co/licensing/elastic-license
EOF

run "Commons Clause on top of MIT" 1 <<'EOF'
"Commons Clause" License Condition v1.0

The Software is provided to you under the MIT license, subject to the
condition that you may not Sell the Software.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software, to deal in the Software without restriction, and/or sell.
EOF

run "CC BY-NC" 1 <<'EOF'
Creative Commons Attribution-NonCommercial 4.0 International
EOF

run "PolyForm Noncommercial" 1 <<'EOF'
PolyForm Noncommercial License 1.0.0
EOF

run "Prosperity" 1 <<'EOF'
The Prosperity Public License 3.0.0
EOF

run "generic noncommercial clause" 1 <<'EOF'
You may use this software for noncommercial use only.
EOF

echo "== denied via explicit SPDX id =="
run "SPDX SSPL-1.0"       1 "SSPL-1.0"       <<<"opaque"
run "SPDX BUSL-1.1"       1 "BUSL-1.1"       <<<"opaque"
run "SPDX CC-BY-ND-4.0"   1 "CC-BY-ND-4.0"   <<<"opaque"
run "SPDX CC-BY-NC-4.0"   1 "CC-BY-NC-4.0"   <<<"opaque"

echo "== precedence: text deny beats an allowed SPDX id =="
run "SPDX MIT but Commons Clause text" 1 "MIT" <<'EOF'
"Commons Clause" License Condition v1.0 — you may not Sell the Software.
Permission is hereby granted, free of charge, to deal in the Software.
EOF

echo
echo "== composite license files that DECLARE the project license =="

# oven-sh/bun's real LICENSE.md shape: a self-declaration, then a table of the
# licenses of everything statically linked. GitHub reports these NOASSERTION.
run "bun-style composite (declared MIT)" 0 "NOASSERTION" <<'EOF'
Bun itself is MIT-licensed.

## JavaScriptCore

Bun statically links JavaScriptCore (and WebKit) which is LGPL-2 licensed.

## Linked libraries

| Library | License |
|---------|---------|
| `brotli` | MIT |
| `tinycc` | LGPL v2.1 |
| `simdutf` | Apache 2.0 |
EOF

run "declared Apache" 0 <<'EOF'
This project is licensed under the Apache License, Version 2.0.
EOF

run "declared LGPL" 0 <<'EOF'
This library is released under the LGPL v2.1.
EOF

# The matcher must key off the statement about the project ITSELF. A bare
# dependency table full of "MIT" rows says nothing about the project's own
# terms and must NOT be enough to pass.
run "dependency table only, no self-declaration" 1 "NOASSERTION" <<'EOF'
## Linked libraries

| Library | License |
|---------|---------|
| `brotli` | MIT |
| `mimalloc` | MIT |
| `simdutf` | Apache 2.0 |
| `libuv` | MIT |
EOF

# Restrictive add-ons must still win over a permissive self-declaration.
run "declared MIT but Commons Clause" 1 "NOASSERTION" <<'EOF'
Bun itself is MIT-licensed.

"Commons Clause" License Condition v1.0 — you may not Sell the Software.

| Library | License |
|---------|---------|
| `brotli` | MIT |
EOF

run "declared MIT but noncommercial-only" 1 "NOASSERTION" <<'EOF'
This project is MIT-licensed.
The compiled binaries are provided for non-commercial use only.
EOF

run "declared proprietary" 1 "NOASSERTION" <<'EOF'
This software is licensed under the ACME Proprietary Terms.
All rights reserved. Contact sales for a quote.
EOF

echo
echo "== fail-closed on unidentifiable licenses (expect exit 1) =="
run "unknown custom license" 1 <<'EOF'
ACME Proprietary Terms. All rights reserved. Contact sales for a quote.
EOF

run "empty license" 1 <<'EOF'
EOF

echo
echo "-------------------------------------------"
echo "passed: $pass   failed: $fail"
[ "$fail" -eq 0 ] || exit 1

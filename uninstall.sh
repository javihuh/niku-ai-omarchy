#!/bin/bash

set -euo pipefail

plugin_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
python3 "$plugin_dir/scripts/bindings.py" remove

printf '%s\n' "Now remove the plugin with:" "  omarchy plugin remove cibo.niku-ai"

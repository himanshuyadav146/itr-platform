#!/bin/bash
# Apache (daemon) must traverse your home dir to follow htdocs/api symlinks
# into itr-platform/apps/api. Run after macOS updates if localhost/api returns 403.
set -euo pipefail

chmod o+x "$HOME" "$HOME/Android_Projects" "$HOME/Android_Projects/itr-platform/apps"
echo "XAMPP traverse permissions updated. Test: http://localhost/api/"

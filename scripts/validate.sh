#!/usr/bin/env sh
set -eu

echo "[validate] resolving dependencies + init"
pwsh -NoProfile -NonInteractive -File ./Build/build.ps1 -ResolveDependency -TaskList init

echo "[validate] staging module"
pwsh -NoProfile -NonInteractive -File ./Build/build.ps1 -TaskList stage

echo "[validate] running analyzer"
pwsh -NoProfile -NonInteractive -File ./Build/build.ps1 -TaskList analyze

echo "[validate] running tests"
pwsh -NoProfile -NonInteractive -File ./Build/build.ps1 -TaskList test

echo "[validate] completed"
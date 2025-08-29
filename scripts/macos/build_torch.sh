#!/bin/bash
set -x -e
cd "$(dirname "$0")"
exec bash ../ios/build_torch.sh
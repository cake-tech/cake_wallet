#!/bin/sh
set -eu

zypper --non-interactive refresh
zypper --non-interactive in --force-resolution \
	clang \
	cmake \
	make

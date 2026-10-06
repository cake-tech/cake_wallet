#!/usr/bin/env bash

# .svg -> .svg.vec
# to add images to the app, put .svgs in res/pictures then run this.
# compiled .svg.vec will be added to assets/new-ui
# CakeImageWidget automatically takes care of loading the compiled .vec file
# if for whatever reason you don't wanna use it, do SvgPicture(AssetBytesLoader("assets/new-ui/something.svg.vec"))

src="res/pictures"
dst="assets/new-ui"

# --input-dir is recursive and writes every svg to out-dir/<basename>.vec, so
# passing a dir with subfolders flattens them and same-named files overwrite
# each other. compile only each dir's own svgs, via a temp copy.
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

while read -r dir; do
    rel="${dir#"$src"}"
    outdir="$dst$rel"
    indir="$(mktemp -d "$tmp/XXXXXX")"

    mkdir -p "$outdir"
    find "$dir" -maxdepth 1 -type f -name '*.svg' -exec cp {} "$indir" ';'
    dart run vector_graphics_compiler --input-dir "$indir" --out-dir "$outdir" >/dev/null &
done < <(find "$src" -type d)

wait
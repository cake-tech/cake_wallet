#!/usr/bin/env bash

# .svg -> .svg.vec
# to add images to the app, put .svgs in res/pictures then run this.
# compiled .svg.vec will be added to assets/new-ui
# CakeImageWidget automatically takes care of loading the compiled .vec file
# if for whatever reason you don't wanna use it, do SvgPicture(AssetBytesLoader("assets/new-ui/something.svg.vec"))

src="res/pictures"
dst="assets/new-ui"

while read -r dir; do
    rel="${dir#"$src"}"
    outdir="$dst$rel"

    mkdir -p "$outdir"
    dart run vector_graphics_compiler --input-dir "$dir" --out-dir "$outdir" >/dev/null &
done < <(find "$src" -type d)

wait
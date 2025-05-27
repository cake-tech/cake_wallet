#!/usr/bin/env python3

import os
import subprocess
import requests
import lzma
import shutil



# Define triplets list
triplets = [
    "x86_64-linux-gnu",
    "x86_64-linux-android",
    "aarch64-linux-android",
    "armv7a-linux-androideabi",
    # "x86_64-w64-mingw32",
    # "aarch64-apple-darwin",
    # "x86_64-apple-darwin",
    "aarch64-host-apple-darwin",
    # "aarch64-apple-ios",
    # "aarch64-apple-iossimulator",
]


def main():
    # Get the latest release data
    resp = requests.get("https://api.github.com/repos/mrcyjanek/monero_c/releases")
    data = resp.json()[0]
    tag_name = data["tag_name"]
    print(f"Downloading artifacts for: {tag_name}")

    assets = data["assets"]
    for asset in assets:
        for triplet in triplets:
            filename = asset["name"]
            if triplet not in filename:
                continue

            coin = filename.split("_")[0]
            local_filename = filename.replace(f"{coin}_{triplet}_", "")
            local_filename = (
                f"scripts/monero_c/release/{coin}/{triplet}_{local_filename}"
            )

            # Create directory if it doesn't exist
            os.makedirs(os.path.dirname(local_filename), exist_ok=True)

            url = asset["browser_download_url"]
            print(f"- downloading {local_filename}")

            # Download the file
            response = requests.get(url)
            with open(local_filename, "wb") as f:
                f.write(response.content)

            # Extract if it's an .xz file
            if local_filename.endswith(".xz"):
                print(f"  extracting {local_filename}")
                with lzma.open(local_filename) as f_in:
                    with open(local_filename.replace(".xz", ""), "wb") as f_out:
                        shutil.copyfileobj(f_in, f_out)

    # Generate iOS framework if on macOS
    if os.uname().sysname == "Darwin":  # Check if on macOS
        print("Generating ios framework")
        result = subprocess.run(
            ["bash", "-c", "cd scripts/ios && ./gen_framework.sh && cd ../.."],
            capture_output=True,
            text=True,
        )
        print(result.stdout.strip() + result.stderr.strip())


if __name__ == "__main__":
    main()

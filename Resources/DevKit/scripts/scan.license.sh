# # Copy from https://github.com/Lakr233/FlowDown/blob/bc9ba079f9474f315b985255a4e9ed67b72e9fd0/Resources/DevKit/scripts/scan.license.sh, which is licensed under the MIT license.
#!/bin/zsh

cd "$(dirname "$0")"

while [[ ! -d .git ]] && [[ "$(pwd)" != "/" ]]; do
    cd ..
done

if [[ -d .git ]] && [[ -d SubZen.xcworkspace ]]; then
    echo "[*] found project root: $(pwd)"
else
    echo "[!] could not find project root"
    exit 1
fi

PROJECT_ROOT=$(pwd)
PACKAGE_CLONE_ROOT="${PROJECT_ROOT}/.build/license.scanner/dependencies"

function with_retry {
    local retries=3
    local count=0
    while [[ $count -lt $retries ]]; do
        "$@"
        if [[ $? -eq 0 ]]; then
            return 0
        fi
        count=$((count + 1))
    done
    return 1
}

if [[ -n $(git status --porcelain) ]]; then
    echo "[!] git is not clean"
    exit 1
fi

echo "[*] cleaning framework dir..."
pushd Frameworks >/dev/null
# spm may have duplicated LICENSE file inside their own .build directory
git clean -fdx -f
popd >/dev/null

echo "[*] resolving packages..."

with_retry xcodebuild -resolvePackageDependencies \
    -clonedSourcePackagesDirPath "$PACKAGE_CLONE_ROOT" \
    -workspace *.xcworkspace \
    -scheme SubZen |
    xcbeautify

echo "[*] scanning licenses..."

SCANNER_DIR=(
    "$PROJECT_ROOT/Frameworks"
    "$PROJECT_ROOT/Resources/AdditionalLicenses"
    "$PACKAGE_CLONE_ROOT/checkouts"
)

SCANNED_LICENSE_CONTENT="# Open Source License\n\n"

for dir in "${SCANNER_DIR[@]}"; do
    if [[ -d "$dir" ]]; then
        for file in $(find "$dir" -name "LICENSE*" -type f); do
            PACKAGE_NAME=$(basename $(dirname $file))
            SCANNED_LICENSE_CONTENT="${SCANNED_LICENSE_CONTENT}\n\n## ${PACKAGE_NAME}\n\n$(cat $file)"
        done
        for file in $(find "$dir" -name "COPYING*" -type f); do
            PACKAGE_NAME=$(basename $(dirname $file))

            # special handling for zstd license, it was dual licensed with BSD and GPL
            # https://github.com/facebook/zstd/issues/3717
            if [[ "$PACKAGE_NAME" == "zstd" ]]; then
                continue
            fi

            SCANNED_LICENSE_CONTENT="${SCANNED_LICENSE_CONTENT}\n\n## ${PACKAGE_NAME}\n\n$(cat $file)"
        done
    fi
done

echo -e "$SCANNED_LICENSE_CONTENT" >"$PROJECT_ROOT/SubZen/BundledResources/OpenSourceLicenses.md"

echo "[*] checking for incompatible licenses..."

INCOMPATIBLE_LICENSES_KEYWORDS=(
    "GNU General Public License"
    "GNU Lesser General Public License"
    "GNU Affero General Public License"
)

for keyword in "${INCOMPATIBLE_LICENSES_KEYWORDS[@]}"; do
    if grep -q "$keyword" "$PROJECT_ROOT/SubZen/BundledResources/OpenSourceLicenses.md"; then
        echo "[!] found incompatible license: $keyword"
        exit 1
    fi
done

echo "[*] done"

# Copy from https://github.com/Lakr233/FlowDown/blob/bc9ba079f9474f315b985255a4e9ed67b72e9fd0/Resources/DevKit/scripts/archive.all.sh, which is licensed under the MIT license.
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

if [[ -n $(git status --porcelain) ]]; then
    echo "[!] git is not clean"
    exit 1
fi

./Resources/DevKit/scripts/bump.version.sh
git add -A
git commit -m "Archive Commit $(date)"

./Resources/DevKit/scripts/scan.license.sh

xcodebuild -workspace SubZen.xcworkspace \
    -scheme SubZen \
    -configuration Release \
    -destination 'generic/platform=iOS' \
    -archivePath "$PROJECT_ROOT/.build/SubZen.xcarchive" \
    archive | xcbeautify

echo "[*] registering SubZen.xcarchive in Xcode Organizer..."
open "$PROJECT_ROOT/.build/SubZen.xcarchive" -g

# xcodebuild -workspace SubZen.xcworkspace \
#     -scheme SubZen-Catalyst \
#     -configuration Release \
#     -destination 'generic/platform=macOS' \
#     -archivePath "$PROJECT_ROOT/.build/SubZen-Catalyst.xcarchive" \
#     archive | xcbeautify

# echo "[*] registering SubZen-Catalyst.xcarchive in Xcode Organizer..."
# open "$PROJECT_ROOT/.build/SubZen-Catalyst.xcarchive" -g

echo "[*] done"

osascript -e 'display notification "SubZen has completed archive process." with title "Build Success"'

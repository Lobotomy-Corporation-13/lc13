#!/bin/bash
# Merges a base commit into a pull request using the DMI merge driver, for use by
# the "Resolve icon conflicts" workflow.
#
# Usage: merge_dmi.sh <repo> <tools> <base sha> <head sha> <attributes sha> <output>
#
# <repo> is a bare repository which has all of the commits. Nothing from the pull
# request is ever checked out or executed: the merge happens without a working
# tree, the merge driver comes from <tools>, and .gitattributes is read from the
# <attributes sha> commit.
#
# Writes `status` to the <output> directory, which is one of:
#	clean      - there are no conflicts, so there is nothing to do
#	unrelated  - there are conflicts, but none of them are in icons
#	conflict   - some conflicts must be resolved by hand
#	resolved   - every conflict was resolved
# Also writes `conflicts.txt` (the files that are still in conflict), `report.txt`
# (the output of the merge driver), and if resolved, `sha` and `merge.bundle`.
set -euo pipefail

if [ $# -ne 6 ]; then
	echo "Usage: $0 <repo> <tools> <base sha> <head sha> <attributes sha> <output>"
	exit 2
fi

Tools="$(cd "$2" && pwd)"
Base="$3"
Head="$4"
Attributes="$5"
mkdir -p "$6"
Output="$(cd "$6" && pwd)"
cd "$1"

for sha in "$Base" "$Head" "$Attributes"; do
	if ! [[ "$sha" =~ ^[0-9a-f]{40}$ ]]; then
		echo "Not a commit: $sha"
		exit 2
	fi
done

export GIT_CONFIG_GLOBAL=/dev/null
export GIT_CONFIG_NOSYSTEM=1
# Don't allow Python to import anything from the current directory
export PYTHONSAFEPATH=1
export PYTHONPATH="$Tools"
export DMI_REPORT="$Output/report.txt"
: > "$DMI_REPORT"
: > "$Output/conflicts.txt"

finish() {
	echo "$1" > "$Output/status"
	echo "Result: $1"
	exit 0
}

# Sets `Tree` and `Conflicts`
merge() {
	local code=0
	git --attr-source="$Attributes" "$@" merge-tree --write-tree --name-only --no-messages -z \
		"$Head" "$Base" > "$Output/merge-tree" || code=$?
	if [ $code -gt 1 ]; then
		echo "git merge-tree failed with code $code"
		exit 1
	fi
	mapfile -d '' -t Conflicts < "$Output/merge-tree"
	rm "$Output/merge-tree"
	Tree="${Conflicts[0]}"
	Conflicts=("${Conflicts[@]:1}")
	if [ $code -eq 0 ] && [ ${#Conflicts[@]} -ne 0 ]; then
		echo "git merge-tree listed conflicts for a clean merge"
		exit 1
	fi
}

# Merge without the driver, as GitHub does, to check that there's something to do
merge
if [ ${#Conflicts[@]} -eq 0 ]; then
	finish clean
fi
HasIcons=0
for path in "${Conflicts[@]}"; do
	if [[ "$path" == *.dmi ]]; then
		HasIcons=1
	fi
done
if [ $HasIcons -eq 0 ]; then
	printf '%q\n' "${Conflicts[@]}" > "$Output/conflicts.txt"
	finish unrelated
fi

# Merge with the driver. Its output can't go to stdout, as merge-tree is using it.
merge -c merge.dmi.driver='python3 -u -m dmi.merge_driver %P %O %A %B %L >> "$DMI_REPORT" 2>&1'
if [ ${#Conflicts[@]} -ne 0 ]; then
	printf '%q\n' "${Conflicts[@]}" > "$Output/conflicts.txt"
	finish conflict
fi

# The first parent must be the pull request, so that pushing is a fast-forward
Commit="$(git commit-tree "$Tree" -p "$Head" -p "$Base" -m "Merge base branch, resolving icon conflicts")"
git update-ref refs/heads/resolve-dmi "$Commit"
git bundle create -q "$Output/merge.bundle" refs/heads/resolve-dmi "^$Head" "^$Base"
echo "$Commit" > "$Output/sha"
finish resolved

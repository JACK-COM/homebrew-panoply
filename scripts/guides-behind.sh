#!/usr/bin/env bash
# Name each guide page a release has moved past:  scripts/guides-behind.sh locket 0.4.1
#
# Every page under docs/<piece>/ carries a hidden stamp, <!-- reviewed: <piece> X.Y.Z -->,
# naming the version its author last read it against. A page whose stamp is missing or
# names another version is printed. It only warns: whether a page is stale is a reader's
# call, so re-read the page and move the stamp by hand, never by script.
set -uo pipefail

piece="${1:?usage: $0 <piece> X.Y.Z}"; version="${2:?usage: $0 <piece> X.Y.Z}"
dir="$(cd "$(dirname "$0")/.." && pwd)/docs/$piece"
[[ -d "$dir" ]] || exit 0

behind=()
for page in "$dir"/*.md; do
  [[ -e "$page" ]] || continue
  stamp="$(grep -oE "<!-- reviewed: $piece [0-9]+\.[0-9]+\.[0-9]+ -->" "$page" | head -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')"
  [[ "$stamp" == "$version" ]] || behind+=("docs/$piece/$(basename "$page") (${stamp:-no stamp})")
done

if (( ${#behind[@]} )); then
  echo "guides last reviewed before $version; re-read each, then move its stamp:"
  printf '  %s\n' "${behind[@]}"
fi
exit 0

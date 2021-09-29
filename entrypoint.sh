#!/usr/bin/env bash

event_file=event.json
diff_cmd="git diff FECH_HEAD"

if [ -f "$event_file" ]; then
  pr_branch=$(cat event.json | \
  python3 -c "import sys, json; print(json.load(sys.stdin)['pull_request']['head']['ref'])")
  base_branch=$(cat event.json | \
  python3 -c "import sys, json; print(json.load(sys.stdin)['pull_request']['base']['ref'])")
  clone_url=$(python3 -c "import sys, json; print(json.load(sys.stdin)['pull_request']['head']['repo']['clone_url'])" < event.json)
  echo "remotes:"
  git remote -v
  echo "adding new remote: $clone_url"
  git remote add pr_repo "$clone_url"
  echo "remotes:"
  git remote -v
  echo "fetching:"
  git fetch pr_repo "$pr_branch"
  git checkout "$pr_branch"
  echo "current HEAD is: "
  git rev-parse HEAD
  echo "the PR branch is $pr_branch"
  echo "the base branch is $base_branch"
  diff_cmd="git diff $base_branch $pr_branch"
  export OVERRIDE_GITHUB_EVENT_PATH=$(pwd)/event.json
fi

verible-verilog-format --inplace ${{ inputs.paths }} > /dev/null 2>&1
tmp_file=$(mktemp)
git diff >"${tmp_file}"
git stash
export REVIEWDOG_GITHUB_API_TOKEN="${{ inputs.github_token }}"
echo "running reviewdog"
./bin/reviewdog -name="verible-verilog-format" \
-f=diff -f.diff.strip=1 \
-reporter="github-pr-review" \
-filter-mode="diff_context" \
-level="info" \
-diff="$diff_cmd" \
-fail-on-error="false" <"${tmp_file}" || true

echo "done running reviewdog"
if [ -f "$event_file" ]; then
    git checkout -
fi

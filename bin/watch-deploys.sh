#!/usr/bin/env bash

# Watch karaconnect workflow runs whose name contains "deploy" and notify
# via terminal-notifier when they finish. Scope: runs triggered by me, or
# runs on the head branch of a PR I opened.
#
# Discovery loop polls every $POLL_INTERVAL seconds. Each in-flight run is
# handed to `gh run watch` in the background, which blocks server-side
# until the run terminates — so we don't poll per-run ourselves.
#
# Requires bash, gh, jq, terminal-notifier. The active gh account is
# switched to $GH_USER at startup (default: sophie-katz-kara) so the
# script works regardless of whichever account is currently selected.

set -o pipefail

ORG=${ORG:-karaconnect}
GH_USER=${GH_USER:-sophie-katz-kara}
POLL_INTERVAL=${POLL_INTERVAL:-30}
PR_LOOKBACK=${PR_LOOKBACK:-50}
RUN_LOOKBACK=${RUN_LOOKBACK:-30}

for cmd in gh jq terminal-notifier; do
  command -v "$cmd" >/dev/null || { echo "missing: $cmd" >&2; exit 1; }
done

# Require the v3.x fork of terminal-notifier from
# https://github.com/sophie-iren-katz/terminal-notifier, which supports
# -sender bundle-ID spoofing natively (so we no longer have to clone the
# .app and swap its icon by hand).
NOTIFIER_BIN=$(command -v terminal-notifier)
TN_MAJOR=$("$NOTIFIER_BIN" -version 2>/dev/null | sed -nE 's/.* ([0-9]+)\.[0-9]+\.[0-9]+.*/\1/p')
if [[ "$TN_MAJOR" != "3" ]]; then
  if [[ "$TN_MAJOR" == "2" ]]; then
    cat >&2 <<EOF
watch-deploys.sh: found terminal-notifier v2.x at $NOTIFIER_BIN — this script requires v3.x.

Uninstall the existing version first (e.g. \`brew uninstall terminal-notifier\`)
and remove $NOTIFIER_BIN if it still exists. Then install the fork:

  git clone https://github.com/sophie-iren-katz/terminal-notifier.git
  cd terminal-notifier
  just install
EOF
  else
    cat >&2 <<EOF
watch-deploys.sh: terminal-notifier at $NOTIFIER_BIN is not v3.x.

This script requires the v3.x fork from sophie-iren-katz/terminal-notifier:

  git clone https://github.com/sophie-iren-katz/terminal-notifier.git
  cd terminal-notifier
  just install
EOF
  fi
  exit 1
fi

SENDER_BUNDLE_ID="com.github.GitHubClient"

# Wrap every gh invocation with a fresh `auth switch`. The active gh account
# is global state shared with every other shell, so we re-assert ours right
# before each call rather than relying on a single switch at startup that
# something else could flip out from under us.
gh() {
  command gh auth switch -u "$GH_USER" >/dev/null 2>&1 \
    || { echo "failed to switch gh account to $GH_USER" >&2; return 1; }
  command gh "$@"
}

ME=$(gh api user --jq .login) || exit 1
echo "watching $ORG deploys for @$ME (poll ${POLL_INTERVAL}s)"

# bash 3.2 has no associative arrays — track state as space-delimited
# strings with leading+trailing spaces for safe substring matching.
SEEN=" "
MY_REFS=" "  # tokens of form "repo|branch"
NEW_REFS=" " # refs added during the current scan iteration only
CHILDREN=""
FIRST_SCAN=1  # on first scan, just populate SEEN — don't notify for history

is_seen()    { case "$SEEN"     in *" $1 "*) return 0 ;; *) return 1 ;; esac; }
mark_seen()  { SEEN="$SEEN$1 "; }
is_my_ref()  { case "$MY_REFS"  in *" $1 "*) return 0 ;; *) return 1 ;; esac; }
is_new_ref() { case "$NEW_REFS" in *" $1 "*) return 0 ;; *) return 1 ;; esac; }
add_my_ref() {
  is_my_ref "$1" && return
  MY_REFS="$MY_REFS$1 "
  # After the initial baseline, a ref appearing for the first time means a
  # newly-opened PR. Historical runs on its branch must be baselined into
  # SEEN — otherwise they'd fire notifications for week-old deploys.
  (( FIRST_SCAN )) || NEW_REFS="$NEW_REFS$1 "
}

cleanup() {
  for pid in $CHILDREN; do
    kill "$pid" 2>/dev/null || true
  done
  # Reap so backgrounded `gh run watch` children don't outlive us.
  wait 2>/dev/null || true
}

# Prune PIDs that have already exited so $CHILDREN doesn't grow unbounded
# over the daemon's lifetime (one entry per finished `gh run watch`).
prune_children() {
  local alive="" pid
  for pid in $CHILDREN; do
    if kill -0 "$pid" 2>/dev/null; then
      alive="$alive $pid"
    fi
  done
  CHILDREN="$alive"
}
# Bash runs INT/TERM traps but does NOT exit afterwards — without an explicit
# `exit`, Ctrl-C just runs cleanup and then the script returns to its `sleep`
# loop. Make the signal actually terminate the script.
trap cleanup EXIT
trap 'cleanup; exit 130' INT
trap 'cleanup; exit 143' TERM

notify_done() {
  local repo=$1 wf=$2 conclusion=$3 url=$4
  local icon msg
  case "$conclusion" in
    success)   icon="✅"; msg="succeeded" ;;
    failure)   icon="❌"; msg="failed" ;;
    cancelled) icon="⚠️";  msg="cancelled" ;;
    *)         icon="ℹ️";  msg="$conclusion" ;;
  esac
  "$NOTIFIER_BIN" \
    -sender "$SENDER_BUNDLE_ID" \
    -title "$icon Deploy $msg" \
    -message "$repo · $wf" \
    -open "$url" \
    -sound default >/dev/null 2>&1 || true
}

watch_run() {
  local repo=$1 run_id=$2 wf=$3 url=$4
  gh run watch "$run_id" -R "$repo" --interval 15 >/dev/null 2>&1 || true
  local conclusion
  conclusion=$(gh run view "$run_id" -R "$repo" --json conclusion --jq .conclusion 2>/dev/null || echo unknown)
  notify_done "$repo" "$wf" "$conclusion" "$url"
}

refresh_my_refs() {
  # One GraphQL call to fetch (repo, headBranch) for every PR I've opened in $ORG.
  local pairs pair branch
  pairs=$(gh api graphql -f query="
    {
      search(query: \"is:pr author:@me org:$ORG\", type: ISSUE, first: $PR_LOOKBACK) {
        nodes {
          ... on PullRequest {
            headRefName
            repository { nameWithOwner }
          }
        }
      }
    }" --jq '.data.search.nodes[] | "\(.repository.nameWithOwner)|\(.headRefName)"' 2>/dev/null) || return 0
  while IFS= read -r pair; do
    [[ -z "$pair" ]] && continue
    branch=${pair#*|}
    # Shared base branches cause false positives — release PRs like develop→main
    # leave "develop" in our set, then every scheduled/push deploy on develop matches.
    case "$branch" in
      main|master|develop|staging|production|release|release/*) continue ;;
    esac
    add_my_ref "$pair"
  done <<< "$pairs"
}

scan_repo() {
  local repo=$1
  local runs
  runs=$(gh api "/repos/$repo/actions/runs?per_page=$RUN_LOOKBACK" 2>/dev/null) || return 0

  while IFS=$'\t' read -r run_id wf status conclusion url branch trigger event; do
    [[ -z "$run_id" ]] && continue
    is_seen "$run_id" && continue
    # Scheduled runs report triggering_actor=last-author-of-workflow, which fires
    # false positives ("dry-run deployment every morning" etc). Exclude them.
    [[ "$event" == "schedule" ]] && continue
    # Match criteria: triggered by me OR run is on a branch belonging to a PR I opened.
    if [[ "$trigger" != "$ME" ]] && ! is_my_ref "$repo|$branch"; then
      continue
    fi
    mark_seen "$run_id"
    if (( FIRST_SCAN )); then
      # Baseline pass — record state without notifying for historical runs.
      continue
    fi
    # Ref baselined this scan (new PR opened on a branch with old runs):
    # only skip if the ref match is what got us here — runs that *we*
    # triggered should still notify normally.
    if [[ "$trigger" != "$ME" ]] && is_new_ref "$repo|$branch"; then
      continue
    fi
    if [[ "$status" == "completed" ]]; then
      echo "[done    ] $repo · $wf · #$run_id ($conclusion)"
      notify_done "$repo" "$wf" "$conclusion" "$url"
    else
      echo "[watching] $repo · $wf · #$run_id ($status)"
      watch_run "$repo" "$run_id" "$wf" "$url" &
      CHILDREN="$CHILDREN $!"
    fi
  done < <(echo "$runs" | jq -r '
    .workflow_runs[]
    | select(.name | test("deploy"; "i"))
    | [
        .id,
        .name,
        .status,
        (.conclusion // ""),
        .html_url,
        .head_branch,
        (.triggering_actor.login // .actor.login // ""),
        (.event // "")
      ]
    | @tsv
  ')
}

scan() {
  NEW_REFS=" "
  refresh_my_refs
  # Repos to scan = union of repos with my PRs (covers org-wide subset where I'm active).
  local repos
  repos=$(echo "$MY_REFS" | tr ' ' '\n' | awk -F'|' 'NF==2 {print $1}' | sort -u)
  while IFS= read -r repo; do
    [[ -z "$repo" ]] && continue
    scan_repo "$repo"
  done <<< "$repos"
}

while true; do
  scan || echo "[scan] error (continuing)" >&2
  prune_children
  if (( FIRST_SCAN )); then
    echo "[ready   ] baseline established; watching for new deploys"
    FIRST_SCAN=0
  fi
  sleep "$POLL_INTERVAL"
done

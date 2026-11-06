# Changes, tests and checks

All changes happen in `~/Documents/my-morning-briefing`. Always `git pull` first, change only what they asked for, then commit with a short message saying what changed ("Add Handelsblatt", "Briefing in German") and push. Tell them in one sentence what's different and that they'll hear it tomorrow morning (or offer a test run).

## Sources (`sources.yaml`)

- **Add**: name (what the voice says), url (homepage or feed), optional `priority: High` and `focus`. Check the url opens (`curl -sIL -o /dev/null -w "%{http_code}" <url>`); a homepage is fine.
- **Pause**: `active: false`. **Remove**: delete the block.
- **Too much of one source / wrong stories**: sharpen its `focus`, or set `priority: High` for favourites.

## Interests, things to skip, language, length (`config.yaml`)

`listener.interests`, `listener.skip`, `language` (e.g. German), `length_minutes` (it's a maximum; quiet days are shorter). If they say "it picked the wrong stories", ask for an example of what they wanted and what they didn't, and turn that into interests, skip or a source focus.

## Voice (`config.yaml` → `voice`)

Make a couple of samples as in `setup.md` step 6 (say it uses a little credit), let them choose, set `voice_id`. Library voices: `brighter: 0`. Own clones that sound too dark: try `brighter: 3.5`. `speed` goes from 0.7 to 1.2.

## Wake-up time

The **alarm** itself is set in the iPhone app. The **schedule** that makes the briefing should end about an hour before it: recompute the `cron` line in `.github/workflows/briefing.yml` as in `setup.md` step 5.

## Newsletters (optional)

Newsletters often aren't online. The briefing can read a separate inbox:

1. They create a new Gmail address just for this (e.g. `name.briefing@gmail.com`) and subscribe their newsletters there, or forward them to it.
2. In that account: turn on 2-Step Verification, then create an app password at `https://myaccount.google.com/apppasswords`.
3. They add `IMAP_USER=` (the address) and `IMAP_PASSWORD=` (the app password) to `.env` themselves. Then set those two secrets as in `setup.md` step 7.1.

Never use their main or work email for this: the briefing reads everything in that inbox.

## Test run

Say it costs a few cents of Claude credit and about 4,500 ElevenLabs characters. Then `setup.md` step 8.

## Check today's run

`gh run list -R <name>/my-morning-briefing -L 5` and the date on the audio branch: `gh api -H "Accept: application/vnd.github.raw" "repos/<name>/my-morning-briefing/contents/date.txt?ref=audio"`.

- If today's briefing is missing and no run succeeded: read `gh run view <id> --log-failed` and fix it. Out of credit (Anthropic or ElevenLabs) is the most common reason.
- If there was no run at all: GitHub sometimes skips scheduled runs, which is why the schedule retries every 15 minutes. Start one now with a test run.
- If the workflow shows as disabled (`gh workflow list -R <name>/my-morning-briefing --all`), turn it back on with `gh workflow enable briefing.yml -R <name>/my-morning-briefing`.

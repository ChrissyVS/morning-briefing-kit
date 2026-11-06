# Setup: the daily briefing

Goal: by the end, the user has their own private GitHub repository that makes their briefing every morning, and they've heard their first one. About 30 minutes. Go step by step and confirm each one before the next.

Start by telling them what's ahead in three lines: "We'll pick your news and your voice, set up three free accounts, and make your first briefing. You'll click in your browser and paste two keys into a file; I do the rest. Never paste keys into this chat."

## 1. Check the computer

Run these quietly and fix what's missing:

- **macOS**: `sw_vers -productVersion`. The briefing works on any computer, but the iPhone app needs a Mac. If it's not a Mac, say so now: they'll get the briefing, and the Shortcut fallback in `app.md` instead of the app.
- **git**: `git --version`. If macOS offers to install the "command line developer tools", tell them to click **Install** and wait.
- **GitHub CLI**: `gh --version`. If it's missing:
  - with Homebrew (`brew --version` works): `brew install gh`
  - otherwise download the official build: get the newest `gh_*_macOS_universal.zip` from `https://api.github.com/repos/cli/cli/releases/latest`, unzip it into a new folder in the scratchpad or `~/.local/gh`, copy `bin/gh` to `~/.local/bin/gh`, and use that full path from now on.

## 2. The interview

Ask in small groups, with multiple-choice options where you can. Write the answers into `config.yaml` later (step 5).

1. **About them**: first name (the voice greets them with it), and one line on what they do ("Product manager at a fintech in Berlin").
2. **What matters**: 2–5 interests ("AI and startups", "German politics", "climate tech", "my city Munich"). Then what to **skip** (sport, celebrities, stock tickers, …).
3. **Language and length**: which language the briefing is in (sources can be in any language), and how long at most: 3, 5 (default) or 8 minutes.
4. **Wake-up time**: when they usually wake up, and their time zone (read it with `readlink /etc/localtime`, which ends in e.g. `Europe/Berlin`, and confirm).

## 3. Sources

Ask which websites, newspapers or blogs they read, and suggest a few that fit their interests and language, for example:

- World: BBC World `https://feeds.bbci.co.uk/news/world/rss.xml`, The Guardian `https://www.theguardian.com/world/rss`
- Germany: Tagesschau `https://www.tagesschau.de/xml/rss2`, Spiegel `https://www.spiegel.de/schlagzeilen/index.rss`
- Tech and startups: TechCrunch `https://techcrunch.com`, The Verge `https://www.theverge.com`, Hacker News `https://hnrss.org/frontpage?points=300`
- Austria/Switzerland: ORF `https://rss.orf.at/news.xml`, SRF `https://www.srf.ch/news/bnf/rss/1646`

A normal homepage works: the briefing finds the site's news feed by itself, and if there's none it reads the front page. Some sites block automated readers: if a source shows FAILED or 403 in a run, look for its RSS feed instead, or pick another source. Never try to get around a block. 4–8 sources is a good start. For each, note a **name** (what the voice says: "according to …"), the **url**, **priority** (High for their favourites) and a short **focus** ("only AI and defence").

Paywalled sites only give headlines and teasers. Newsletters are an optional extra later (`changes.md`, "Newsletters").

## 4. Accounts and keys

Walk them through each account in their browser. Wait until each one is done.

1. **GitHub** (free): `https://github.com/signup` if they don't have an account. Then sign the CLI in: run `gh auth login --web --git-protocol https` in a terminal the user can see and type in (open one in the app's Terminal panel if you can, or tell them to open Terminal). They press Enter, copy the 8-character code, paste it in the browser and click **Authorize**. Then run `gh auth setup-git`.
2. **Create their copy**:
   ```
   gh repo create my-morning-briefing --private --template ChrissyVS/morning-briefing-kit --clone
   ```
   run inside `~/Documents`, so the folder is `~/Documents/my-morning-briefing`. If GitHub says the repository is still being created, wait 10 seconds and run `gh repo clone <name>/my-morning-briefing ~/Documents/my-morning-briefing`.
3. **Anthropic (Claude) API key**: this is separate from their Claude subscription. `https://console.anthropic.com/settings/keys` → **Create Key**. They also need a few dollars of credit under **Billing** (a briefing costs a few cents).
4. **ElevenLabs**: sign up at `https://elevenlabs.io`, then `https://elevenlabs.io/app/settings/api-keys` → **Create API Key**. If it asks for permissions, they need **Text to Speech** and **Voices: read**. A 5-minute briefing uses about 4,500 characters a day, so roughly 135,000 a month: point them to `https://elevenlabs.io/pricing` to pick a plan that covers it.
5. **Paste the keys**: in their folder, copy `.env.example` to `.env`, then `open -e .env` so it opens in TextEdit. They paste each key right after the `=` (no spaces, no quotes) and save with Cmd + S. They never paste keys into the chat.
6. **Check the keys without showing them**: in one command, load `.env` (`set -a; . ./.env; set +a`) and check that both start correctly (`sk-ant-` for Anthropic) and that `https://api.elevenlabs.io/v1/voices` answers 200 with the ElevenLabs key. Print only "works" or the error.

## 5. Fill in their settings

Edit in `~/Documents/my-morning-briefing`:

- `config.yaml`: `listener` (name, about, interests, skip), `language`, `length_minutes`, `timezone`.
- `sources.yaml`: their sources from step 3, replacing the examples.
- `.github/workflows/briefing.yml`: the schedule. GitHub uses UTC, and in summer and winter the UTC hour differs, so cover both. Let **H1** be the UTC hour of (wake-up time − 3 hours) in **summer** time, and **H2** the UTC hour of (wake-up time − 1 hour) in **winter** time. Set `- cron: "*/15 H1-H2 * * *"`. Example: wake-up 6:30 in Berlin (UTC+2 summer, UTC+1 winter): H1 = 3:30 − 2 = 1, H2 = 5:30 − 1 = 4, so `*/15 1-4 * * *`. If H1 > H2 (it crosses midnight UTC), use two lines. Later tries see the briefing is done and stop after seconds.

## 6. Pick a voice

Say it costs a little ElevenLabs credit (about 250 characters per sample).

1. List their voices without showing the key: `curl -s -H "xi-api-key: $ELEVENLABS_API_KEY" https://api.elevenlabs.io/v1/voices` (after loading `.env`), and show name and labels in a short table. Suggest 3–4 that suit a calm morning news show in their language.
2. Make a 15-second sample for each: POST to `https://api.elevenlabs.io/v1/text-to-speech/<voice_id>?output_format=mp3_44100_128` with JSON `{"text": "...", "model_id": "eleven_multilingual_v2"}`. Use a short made-up morning greeting with their name in their language. Save to `voice-samples/<Name>.mp3`, play each with `afplay` (and send the files if you can), and let them choose.
3. **Their own voice**: if they want to wake up to themselves, they can make an Instant Voice Clone in ElevenLabs (Voices → Create a voice → Instant Voice Clone, 1–3 minutes of clear speech). It then appears in the list. If the clone sounds darker than them, set `brighter` to around 3.5 and compare samples.
4. Write the chosen `voice_id` (and `brighter` if used) into `config.yaml`.

## 7. Save and send it to GitHub

1. Store the keys as GitHub secrets, only the ones that are filled in, without printing them: filter `.env` to lines matching `^[A-Z_]+=.+` (leave out `IMAP_HOST`) into a temporary file with `umask 077`, run `gh secret set -f <that file> -R <name>/my-morning-briefing`, then delete the file. Show `gh secret list` (names only).
2. Commit `config.yaml`, `sources.yaml` and the workflow ("My morning briefing settings") and push.

## 8. First briefing

Say it uses a few cents of Claude credit and about 4,500 ElevenLabs characters.

1. `gh workflow run briefing.yml -R <name>/my-morning-briefing`, wait a few seconds, then follow it with `gh run watch <id> --exit-status` (in the background if possible; it takes about 2 minutes).
2. If it fails, read the log (`gh run view <id> --log-failed`) and fix it. Common causes: a key without credit, a typo in a key, a voice ID that doesn't exist.
3. Download it the way the phone will: `gh api -H "Accept: application/vnd.github.raw" "repos/<name>/my-morning-briefing/contents/latest.mp3?ref=audio" > voice-samples/first-briefing.mp3`, play it with `afplay` (or send it), and show the script (`latest.txt` the same way).
4. Ask what they think: wrong stories → sharpen interests, skip or a source's focus; too long or short → `length_minutes`; voice → step 6.

## 9. Next

Tell them: "From tomorrow your briefing is made every morning before you wake up." Then offer the iPhone app (`app.md`): "Now let's put the Briefing app on your iPhone, so it wakes you with a real alarm and you can pause it on the Lock Screen. You'll need Xcode, Apple's free app, from the Mac App Store." Suggest they start the Xcode download now if they haven't.

# Morning Briefing ☀️

Wake up to your own spoken news briefing instead of an alarm tone.

Every morning, before you wake up, it reads the websites (and newsletters) **you** choose, Claude picks the stories that matter to **you** and writes a short script for the ear, and ElevenLabs reads it in a voice you pick, even your own. Your iPhone wakes you with a real alarm; tap **Play briefing** and your news starts, with pause and skip on the Lock Screen.

- **Your news**: your sources, your interests, your language, 5 minutes max. It never repeats yesterday's stories.
- **Your voice**: any ElevenLabs voice, or a clone of your own.
- **Your accounts**: it runs on your own free GitHub account with your own Claude and ElevenLabs keys. Nobody else sees your briefing.
- **No coding**: Claude sets it all up with you, step by step, and changes it whenever you ask ("add Handelsblatt", "make it German").

## What you need

- A **Mac** and an **iPhone with iOS 26** or newer (for the app; without a Mac there's a simpler Shortcut version)
- The **Claude desktop app** with a paid plan (for Claude Code)
- An **Anthropic API key** with a few dollars of credit (a briefing costs a few cents): [console.anthropic.com](https://console.anthropic.com)
- An **ElevenLabs** account: a 5-minute briefing is about 4,500 characters a day, see [elevenlabs.io/pricing](https://elevenlabs.io/pricing)
- A free **GitHub** account (Claude helps you create one)
- **Xcode**, Apple's free app from the Mac App Store, to put the app on your iPhone

## Install

In the Claude desktop app, open a **Code** session and type:

```
/plugin marketplace add ChrissyVS/morning-briefing-kit
/plugin install morning-briefing@morning-briefing
```

Then type **`/morning-briefing`** and follow along. The first setup takes about an hour, most of it waiting for Xcode to download.

## Later

Just tell Claude what you want:

- "Add Sifted to my morning briefing" · "Pause TechCrunch"
- "Make my briefing in German" · "Make it 3 minutes"
- "Switch the voice" · "Wake me at 7 instead"
- "Did my briefing run today?"
- "Renew my app" (apps you build yourself need a one-minute reinstall every 7 days with a free Apple ID)

## How it works

```
your sources ─► GitHub (every morning, free) ─► Claude writes ─► ElevenLabs speaks ─► mp3
                                                                                        │
                       iPhone app: alarm rings ─► "Play briefing" ◄────────────────────┘
```

- `briefing.py`: collects (RSS feeds, front pages, optional newsletter inbox), writes and speaks the briefing
- `config.yaml`: who you are, your interests, language, length, voice
- `sources.yaml`: your websites and feeds
- `.github/workflows/briefing.yml`: the daily schedule
- `ios/`: the Briefing iPhone app (SwiftUI, AlarmKit)
- `skills/morning-briefing/`: the instructions Claude follows to set it up with you

## Good to know

- **Your briefing is for your ears only.** It's made from other people's journalism, often paywalled. Don't post or share the audio.
- **Never share your keys.** Your `.env` file and your GitHub key are like passwords. Claude never asks you to paste them into the chat.
- **AI can get things wrong.** Claude is told to use only what's in your sources and never add facts, but if something sounds surprising, check the source.

Made by [Christina Vogt-Sasse](https://github.com/ChrissyVS). MIT license.

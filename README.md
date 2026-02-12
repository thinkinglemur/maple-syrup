# maple-syrup

> Clone once. Answer a few questions. Get a fully scaffolded project with CI/CD, Docker, observability and AI coding assistance — in minutes.

## What it does

1. **Asks Claude** to analyse your project synopsis and suggest the right tech stack
2. **Lets you review and override** every suggestion
3. **Configures aider** (AI coding assistant) with the right model and settings
4. **Initialises git** + a language-aware `.gitignore`
5. **Generates `init.sh`** — a self-contained script you commit to your new repo that:
   - Scaffolds the chosen framework
   - Creates a multi-stage `Dockerfile`
   - Creates `docker-compose.yml` with app + DB + cache services
   - Writes GitHub Actions workflows (CI + deploy)
   - Stubs out Sentry and Google Analytics
   - Generates a `README.md` for your project

## Supported stacks

| Language   | Frameworks                              |
|------------|-----------------------------------------|
| TypeScript | Next.js, Remix, NestJS, Express, Fastify |
| Python     | FastAPI, Django, Flask                  |
| Rust       | Axum, Actix-web                         |
| Go         | Gin, Echo, Fiber                        |
| PHP        | Laravel, Symfony                        |

**Databases:** PostgreSQL · MySQL · MongoDB · SQLite · Supabase · PlanetScale  
**Caching:** Redis · Memcached  
**Deploy:** AWS ECS Fargate · Vercel · Railway

## Quick start

```bash
# 1. Clone this repo
git clone https://github.com/thinkinglemur/maple-syrup.git
cd maple-syrup

# 2. Make setup.sh executable
chmod +x setup.sh

# 3. Run setup (needs curl, jq, git)
./setup.sh
```

You'll be asked for your Anthropic API key, then describe your project in plain English. Claude will suggest a stack and you can accept or override each choice.

When done, `init.sh` will be written to the current directory. Run it to fully scaffold your project.

## Dependencies

| Tool | Why |
|------|-----|
| `git` | Repository management |
| `curl` | Claude API calls |
| `jq` | JSON parsing |

All three are pre-installed on most developer machines. The script checks for them on startup and prints install instructions if any are missing.

## Aider models

During setup you choose the aider model:

| Option | Model | Best for |
|--------|-------|----------|
| 1 (default) | `claude-sonnet-4-5-20250929` | Most tasks — fast and smart |
| 2 | `gpt-4o` | If you prefer OpenAI |
| 3 | `gemini/gemini-2.5-pro` | Long context, extended thinking |

Two aider config files are written:
- **`.aider.conf.yml`** — model, editor mode, commit behaviour
- **`.aider.model.settings.yml`** — per-model advanced settings (edit format, repo map, thinking tokens)

## Repository structure

```
project-bootstrap/
├── setup.sh                        # Main entry point
├── lib/
│   ├── colours.sh                  # Terminal colour helpers
│   ├── checks.sh                   # Dependency verification
│   ├── claude_api.sh               # Synopsis analysis via Claude
│   ├── prompts.sh                  # Interactive review & override
│   ├── aider_config.sh             # Write .aider.conf.yml
│   ├── git_setup.sh                # git init + .gitignore
│   └── generators/
│       └── generate_init.sh        # Generate init.sh
└── README.md
```

## Environment variables

The script saves your API key to `.env` in the directory you run it from (which is gitignored). You can also pre-set it:

```bash
export ANTHROPIC_API_KEY=sk-ant-...
./setup.sh
```

## Contributing

PRs welcome — especially for:
- New framework templates
- Additional cloud deploy targets
- Windows/WSL support

## Licence

MIT
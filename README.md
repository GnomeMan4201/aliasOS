# aliasOS

Textual TUI for managing operator shell aliases. Browse, CRUD, health check, history mine, gap analysis.

**[live demo → gnomeman4201.github.io/aliasOS](https://gnomeman4201.github.io/aliasOS)**

## install
```bash
pip install textual
python3 aliasOS_tui.py
```

## tabs

| key | tab | purpose |
|-----|-----|---------|
| `1` | aliases | browse, search, CRUD, run |
| `2` | ecosystem | BANANA_TREE live map |
| `3` | shell | sourced subshell |
| `4` | gap analysis | 155 curated suggestions |
| `5` | health | dead commands, shadows, loops |
| `6` | history | mine bash_history for aliases |
| `7` | git | per-repo alias context |

## keybindings

`1-7` switch tabs · `n` new alias · `enter` run alias in shell · `^r` reload · `^e` export · `^s` save · `^p` palette · `^q` quit

---

built by [GnomeMan4201](https://github.com/GnomeMan4201) // badBANANA research

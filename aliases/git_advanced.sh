#!/usr/bin/env bash
# ── git advanced ─────────────────────────────────────────────────────────────

# blame / history
alias gblame='git blame'
alias gwho='git log --format="%an" | sort | uniq -c | sort -rn'  # contributor frequency
alias gfiles='git log --name-only --pretty=format: | sort | uniq -c | sort -rn | head -20'  # most changed files
alias gheat='git log --format="" --name-only | sort | uniq -c | sort -rn'  # heatmap by file

# delta diff (install: https://github.com/dandavison/delta)
alias gdelta='GIT_PAGER="delta" git diff'
alias gddelta='GIT_PAGER="delta" git diff --staged'
alias gldelta='GIT_PAGER="delta" git log -p'

# fixup / squash workflow
gfixup() {
    # gfixup <hash> — create a fixup commit for a specific commit
    local hash="${1:?usage: gfixup <commit-hash>}"
    git commit --fixup "$hash"
}
gsquash() {
    # gsquash <n> — interactive rebase squashing last n commits
    local n="${1:?usage: gsquash <n>}"
    git rebase -i "HEAD~$n"
}
alias grebase='git rebase -i'
alias grebaseup='git rebase -i @{upstream}'

# cherry-pick
alias gcherry='git cherry-pick'
alias gcherryno='git cherry-pick --no-commit'
alias gcherryabort='git cherry-pick --abort'
alias gcherrycontinue='git cherry-pick --continue'

# tags
alias gtag='git tag'
alias gtagls='git tag -l --sort=-v:refname'                      # newest first
alias gtagpush='git push origin --tags'
alias gtagdel='git tag -d'
alias gtagdelpush='git push origin --delete'                     # gtagdelpush v1.0.0
gtagnew() {
    local tag="${1:?usage: gtagnew <tag> [message]}"
    local msg="${2:-Release $tag}"
    git tag -a "$tag" -m "$msg" && echo "tagged: $tag"
}

# bisect workflow
alias gbisect='git bisect'
alias gbisectstart='git bisect start'
alias gbisectbad='git bisect bad'
alias gbisectgood='git bisect good'
alias gbisestreset='git bisect reset'

# reflog
alias greflog='git reflog --date=relative'
alias greflogall='git reflog --all'

# stash power
alias gstash='git stash'
alias gstashp='git stash push -m'           # gstashp "wip: feature name"
alias gstashl='git stash list'
alias gstashshow='git stash show -p'        # gstashshow stash@{0}
alias gstashdrop='git stash drop'
alias gstashclean='git stash clear'
alias gstashbranch='git stash branch'       # gstashbranch <branch> stash@{0}

# worktree
alias gwt='git worktree'
alias gwtls='git worktree list'
alias gwtadd='git worktree add'
alias gwtrm='git worktree remove'
alias gwtprune='git worktree prune'

# submodule
alias gsub='git submodule'
alias gsubup='git submodule update --init --recursive'
alias gsubsync='git submodule sync --recursive'
alias gsubpull='git submodule foreach git pull origin main'

# stats
alias gcount='git rev-list --count HEAD'
alias gsize='git count-objects -vH'
alias gchanged='git diff --stat HEAD~1 HEAD'

# search commits
ggrep() {
    # search commit messages
    git log --oneline --all --grep="${1:?usage: ggrep <pattern>}"
}
gpickaxe() {
    # search for when a string was added/removed
    git log -S "${1:?usage: gpickaxe <string>}" --oneline
}

# undo helpers
alias gundo='git reset HEAD~1 --soft'      # undo last commit, keep changes staged
alias gundo-hard='git reset HEAD~1 --hard' # undo last commit, discard changes
alias gunstage='git restore --staged'      # gunstage <file>
alias grevert='git revert'                 # safe undo with new commit

# upstream management
alias gtrack='git branch -u'               # gtrack origin/main
alias gupstream='git remote add upstream'
alias gfetchup='git fetch upstream && git merge upstream/main'

# clean working tree
alias gpristine='git reset --hard && git clean -fdx'  # nuclear: reset + clean tracked + untracked + ignored

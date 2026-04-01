#!/usr/bin/env bash
# ── ollama — local LLM management ───────────────────────────────────────────

alias olllist='ollama list'
alias ollpull='ollama pull'
alias ollrm='ollama rm'
alias ollshow='ollama show'
alias ollrun='ollama run'
alias ollserve='ollama serve'
alias ollps='ollama ps'         # show running models

# quick prompt to a model — ollask <model> <prompt>
ollask() {
    local model="${1:?usage: ollask <model> <prompt>}"
    shift
    local prompt="$*"
    ollama run "$model" "$prompt"
}

# pipe stdin to model
ollpipe() {
    local model="${1:?usage: <cmd> | ollpipe <model>}"
    ollama run "$model"
}

# show model details
ollinfo() {
    local model="${1:?usage: ollinfo <model>}"
    ollama show --modelfile "$model"
}

# list models with size
ollsize() {
    ollama list | awk 'NR>1 {printf "%-30s %s %s\n", $1, $3, $4}'
}

# pull common useful models
ollsetup() {
    echo "# pulling base models..."
    ollama pull mistral
    ollama pull codellama
    ollama pull llama3
    echo "# done"
}

# check if ollama is running
ollstatus() {
    if curl -s http://localhost:11434/api/tags &>/dev/null; then
        echo "ollama: running"
        ollama list
    else
        echo "ollama: not running (try: ollama serve)"
    fi
}

# interactive model picker with fzf if available
ollpick() {
    if command -v fzf &>/dev/null; then
        local model
        model=$(ollama list | tail -n +2 | awk '{print $1}' | fzf --prompt="select model: ")
        [[ -n "$model" ]] && ollama run "$model"
    else
        ollama list
        echo -n "model: "
        read -r model
        ollama run "$model"
    fi
}

# stop a running model
ollstop() {
    local model="${1:?usage: ollstop <model>}"
    # ollama doesn't have a direct stop — kill the process
    pkill -f "ollama run $model" 2>/dev/null && echo "stopped: $model" || echo "not running: $model"
}

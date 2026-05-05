# aliasOS operator context prompt helper

operator_ctx() {
  if [ -n "$SESSION_ID" ]; then
    echo "[$SESSION_ID]"
  else
    echo "[no-session]"
  fi
}

export PS1='$(operator_ctx) \u@\h:\w\$ '

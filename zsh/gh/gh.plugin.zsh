#Github repo switcher

GH_BASE_DIR=${GH_BASE_DIR:-$HOME/src}
GH_PROTO=${GH_PROTO:-"ssh"}

escape_name() {
    echo "${1}" | tr '|/.' '-'
}

function gh () {
  typeset +x account=$GITHUB[user]
  typeset +x repo=""

  if (( ${+argv[2]} )); then
    repo=$argv[2]
    account=$argv[1]
  elif (( ${+argv[1]} )); then
    repo=$argv[1]
  else
    echo "USAGE: gh [user] [repo]"
    return 127
  fi

  typeset +x directory=$GH_BASE_DIR/github.com/$account/$repo
  if [[ ! -a $directory ]]; then
   if [[ $GH_PROTO == "ssh" ]]; then 
      git clone git@github.com:$account/$repo.git $directory
     elif [[ $GH_PROTO == "https" ]]; then
      git clone https://github.com/$account/$repo.git $directory
     else
      echo "GH_PROTO must be set to ssh or https"
    fi
    if [[ ! -a $directory ]]; then
      return 127
    fi
  fi

  if [ "$GH_TMUXINATOR" -eq 1 ] && [ -z "$TMUX" ] && tmuxinator doctor &>/dev/null
  then
      account_esc="$(escape_name "$account")"
      repo_esc="$(escape_name "$repo")"
      name="${account_esc}/${repo_esc}"
      file="$HOME/.tmuxinator/${name}.yml"

      mkdir -p $(dirname "$file")

      if [ ! -f "$file" ]
      then
          echo "Tmuxinator project $name does not exist yet, creating it."
          echo "root: ${directory}" > "$file"
          cat "$HOME/.tmuxinator/gh_base.yml" >> "$file" 
          sed -i "s|%NAME%|${name}|g; s|%REPO%|${repo_esc}|g" "$file"
      fi

      tmuxinator start "$name"
  else
      cd $directory
  fi
}

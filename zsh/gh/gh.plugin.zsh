#Github repo switcher

GH_BASE_DIR=${GH_BASE_DIR:-$HOME/src}
GH_PROTO=${GH_PROTO:-"ssh"}
# $1 username
# $2 repo
get_tmuxinator_name()
{
    echo "${1}_${2}" | tr '.' '-'
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
      name="$(get_tmuxinator_name "$account" "$repo")"
      file="$HOME/.tmuxinator/${name}.yml"

      if [ ! -f "$file" ]
      then
          echo "Tmuxinator project $name does not exist yet, creating it."
          cp "$HOME/.tmuxinator/gh_base.yml" "$file" 
          echo "$(sed "s|name: gh_base|name: ${name}\nroot: ${directory}|" "$file")" > "$file"
      fi

      tmuxinator start "$name"
  else
      cd $directory
  fi
}

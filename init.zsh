#!/bin/zsh

# set -x

SCRIPT_PATH="${0:A:h}"
# echo "SCRIPT_PATH=$SCRIPT_PATH"

################################################################################
################################################################################

function coloured_banner() {
  text=$1
  colour=$2
  typeset -u colour_name
  colour_name="COLOUR_${colour}"
  width=80
  margin=2
  max_text_length=$( echo "$width - $margin" | bc | xargs )
  text_length=$( echo -n "$text" | wc -c | xargs )
  truncated_text=$( eval 'echo "${text:0:$max_text_length}"' )
  padding=$( echo "$max_text_length - $text_length - $margin" | bc )
  escape_code_colour=$( eval "echo \$$colour_name" )
  escape_code_reset=$( echo "$COLOUR_RESET" )

  # echo "max_text_length=$max_text_length, text_length=$text_length"
  # echo "truncated_text=$truncated_text"
  # echo "padding=$padding"
  # echo "colour_name=$colour_name, escape_code_colour=$escape_code_colour"

  echo "################################################################################"
  eval "printf '#%${max_text_length}s#' ''"
  echo
  eval "printf '#%0${margin}s%s%s%s%${padding}s#' '' '$escape_code_colour' '$truncated_text' '$escape_code_reset' ''"
  echo
  eval "printf '#%${max_text_length}s#' ''"
  echo -e "\n################################################################################"
}

################################################################################
################################################################################

coloured_banner "initialising vundle..." yellow

test -d ~/.vim/bundle/Vundle.vim || git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim

################################################################################
################################################################################

coloured_banner "creating and populating $HOME/git_tree..." green

mkdir -p $HOME/git_tree
cd $HOME/git_tree

for owner_and_repo in atomicstack/{dotfiles,atomicstack_perl} tmux/tmux junegunn/{fzf,fzf.vim} tmux-plugins/tpm Aloxaf/fzf-tab; do
  repo=$(basename $owner_and_repo)
  if [[ ! -d $repo ]]; then echo timeout 3 git clone github.com:$owner_and_repo; fi
done

if [[ ! ~/.dotfiles && ~/git_tree/dotfiles ]]; then
  mv ~/git_tree/dotfiles ~/.dotfiles
  ln -sv ~/.dotfiles ~/git_tree/dotfiles
fi

################################################################################
################################################################################

coloured_banner "building tmux..." blue

cd $HOME/git_tree/tmux
echo $SCRIPT_PATH/rebuild-tmux.sh

echo "run these to install this tmux build into /usr/local:"
echo -e "\tln -sv $HOME/git_tree/tmux/bin/tmux /usr/local/bin/"
echo -e "\tsudo mkdir /usr/local/share/man/man1 && sudo ln -sv $HOME/git_tree/tmux/tmux.1 /usr/local/share/man/man1/"

################################################################################
################################################################################

coloured_banner 'fetching fzf binary...' magenta
cd $HOME/git_tree/fzf
echo ./fetch-latest-fzf-binary.pl

echo "run these to install this fzf build into /usr/local:"
echo -e "\tln -svf $HOME/git_tree/fzf/bin/fzf{,-tmux} /usr/local/bin/";
echo -e "\tln -svf $HOME/git_tree/fzf/{plugin,shell}/* /usr/local/share/fzf/";
################################################################################
################################################################################

################################################################################
################################################################################


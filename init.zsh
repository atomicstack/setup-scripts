#!/bin/zsh

# set -x

SCRIPT_PATH="${0:A:h}"
SCRIPT_NAME=$(basename $0)
# echo "SCRIPT_PATH=$SCRIPT_PATH"

################################################################################
################################################################################

function warn() {
  echo "$(tput setaf 227)[$SCRIPT_NAME]$(tput sgr0) $(tput setaf 9)$*$(tput sgr0)" 1>&2
}

################################################################################
################################################################################

function die() {
  warn "$*"
  exit 1
}

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

function preflight() {

  local missing=0
  local command_path

  for command in bc git; do
    command_path="$(command -v $command)"
    if [[ -z "$command_path" || ! -f "$command_path" ]]; then
      warn "can't find command $command"
      missing=1
    fi
  done

  if [[ $missing == 1 ]]; then
    warn "pre-requisite/s missing, bailing :("
    exit 1
  fi
}

################################################################################
################################################################################

preflight

################################################################################
################################################################################

coloured_banner "initialising vundle..." yellow

test -d ~/.vim/bundle/Vundle.vim || git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim

################################################################################
################################################################################

coloured_banner "creating and populating $HOME/git_tree..." green

mkdir -p $HOME/git_tree
cd $HOME/git_tree

for owner_and_repo in \
    atomicstack/{dotfiles,atomicstack_perl} \
    Aloxaf/fzf-tab\
    tmux/tmux \
    junegunn/{fzf,fzf.vim} \
    tmux-plugins/tpm \
    zsh-users/zsh \
; do
  repo=$(basename $owner_and_repo)
  if [[ ! -d $repo ]]; then timeout 20 git clone github.com:$owner_and_repo; fi
done

if [[ ! ~/.dotfiles && ~/git_tree/dotfiles ]]; then
  mv ~/git_tree/dotfiles ~/.dotfiles
  ln -sv ~/.dotfiles ~/git_tree/dotfiles
fi

################################################################################
################################################################################

coloured_banner "building tmux..." blue
tmux_build_dir="$HOME/git_tree/tmux"
test -d "$tmux_build_dir" || die "can't find tmux_build_dir=$tmux_build_dir"
cd "$tmux_build_dir"

test -x "$tmux_build_dir/bin/tmux" || $SCRIPT_PATH/rebuild-tmux.sh
test -x "$tmux_build_dir/bin/tmux" || die "can't find tmux at $tmux_build_dir/bin/tmux"

if [[ ! -f "/usr/local/bin/tmux" ]]; then
  echo "$(tput setaf 10)run these to install this tmux build into /usr/local:$(tput sgr0)"
  echo -e "\tln -sv $tmux_build_dir/bin/tmux /usr/local/bin/"
  echo -e "\tsudo mkdir /usr/local/share/man/man1 && sudo ln -sv $tmux_build_dir/tmux.1 /usr/local/share/man/man1/"
fi

################################################################################
################################################################################

coloured_banner 'building perl...' lightmagenta

if [[ -z "$PERLPATH" && $( ls $HOME | egrep -c 'perl-5[.]??[.]?' ) == 0 ]]; then
  ~/git_tree/atomicstack_perl/build_perl.sh
  echo "$(tput setaf 10)run these to install additional requirements:$(tput sgr0)"
  echo -e "\t~/perl-5.??.?/bin/cpanm Net::GitHub"
fi

################################################################################
################################################################################

coloured_banner 'fetching fzf binary...' cyan
fzf_build_dir="$HOME/git_tree/fzf"
test -d "$fzf_build_dir" || die "can't find fzf_build_dir=$fzf_build_dir"
cd "$fzf_build_dir"

test -x "$fzf_build_dir/bin/fzf" || $SCRIPT_PATH/fetch-latest-fzf-binary.pl
test -x "$fzf_build_dir/bin/fzf" || die "can't find fzf at $fzf_build_dir/bin/fzf"

if [[ ! -f "/usr/local/bin/fzf" ]]; then
  echo "$(tput setaf 10)run these to install this fzf build into /usr/local:$(tput sgr0)"
  echo -e "\tln -svf $HOME/git_tree/fzf/bin/fzf{,-tmux} /usr/local/bin/";
  echo -e "\tln -svf $HOME/git_tree/fzf/{plugin,shell}/* /usr/local/share/fzf/";
fi
################################################################################
################################################################################

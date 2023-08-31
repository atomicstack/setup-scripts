#!/bin/bash

function l() {
  echo "$*" 1>&2
}

echo "################################################################################"
echo "################################################################################"

if [[ -z "$NO_GIT_PULL" ]]; then
  l "running git pull..."
  git pull
fi

echo "################################################################################"
echo "################################################################################"

if [[ -z "$NO_TMUX_CLEANUP" ]]; then
  l "running make clean..."
  make clean
fi

echo "################################################################################"
echo "################################################################################"

# automake libevent-devel bison ncurses-devel
if [[ ! $(which automake) || ! $( which yacc ) ]];
  echo -n "missing dependencies: automake/yacc/... "

  if   [[ $( which yum rpm ) ]]; then
    echo "run this:\nsudo yum install automake libevent-devel bison ncurses-devel"
  elif [[ $( which apt-get ) ]]; then
    echo "run this:\nsudo apt-get install build-essential pkg-config autoconf zip unzip bzip2 libssl-dev zlib1g-dev libreadline-dev libexpat-dev libevent-dev libncurses-dev"
  else
    echo "you're on your own!"
  fi
fi

echo "################################################################################"
echo "################################################################################"

if [[ "$MY_OS" == "Darwin" ]]; then
  export ENABLE_UTF8PROC="--enable-utf8proc"
  export CFLAGS=$( pkg-config --cflags-only-I libutf8proc )
  export LDFLAGS=$( pkg-config --libs-only-L libutf8proc )
  echo "CFLAGS=$CFLAGS"
  echo "LDFLAGS=$LDFLAGS"
  echo "################################################################################"
  echo "################################################################################"
fi

l "running autogen.sh..."

if $(./autogen.sh); then
  l "triggering build pipeline..."
  ./configure --prefix=$PWD $ENABLE_UTF8PROC && make && make install && cp -va bin/tmux bin/$(bin/tmux -V | sed "s/ /-/g")-$(date +%F).$(date +%s)
else
  l "autogen.sh failed, build aborted"
fi

echo "################################################################################"
echo "################################################################################"

echo "to link files to their destination:"
echo "ln -sv $HOME/git_tree/tmux/bin/tmux /usr/local/bin/"
echo "sudo mkdir /usr/local/share/man/man1 && sudo cp -va $HOME/git_tree/tmux/tmux.1 /usr/local/share/man/man1/"

l "$0 finishing, enjoy your shiny new tmux!"

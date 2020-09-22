#!/usr/bin/env bash

set -e

which git 2> /dev/null || (echo "git is not installed" && exit 1)
which vim 2> /dev/null || (echo "vim is not installed" && exit 1)

# curl --create-dirs occured permission error in git-bash
# create folder before download
mkdir -p $HOME/.vim/autoload

curl -fLo $HOME/.vim/autoload/plug.vim \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

# overwrite $HOME/.vimrc
curl -fLo $HOME/.vimrc \
    https://raw.githubusercontent.com/cp949/study-dev/master/scripts/vim-settings/.vimrc

vim +PlugInstall +qall


# download if there is no ~/.editorconfig
if [ -e "$HOME/.editorconfig" ]
then
  echo "$HOME/.editorconfig already exists, skip downloading"
else
  curl -fLo $HOME/.editorconfig \
    https://raw.githubusercontent.com/cp949/study-dev/master/scripts/vim-settings/.editorconfig
fi


which ack 2>&1 > /dev/null || (which apt-get 2>&1 > /dev/null && sudo apt-get install -y ack-grep)

which ack 2>&1 > /dev/null || (which yum 2>&1 > /dev/null && sudo yum install -y ack)

echo
echo "vim setting finished"
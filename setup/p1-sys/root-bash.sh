#!/bin/bash

. ../common/fwk.sh "p1" "../setup/log" "setup-p1.log"

################
## sync root .bashrc
################

begin_block "Setting up .bash_aliases file for the user ROOT from user $(server_user)"
    install_file /etc hosts
    install_file "/home/$(server_user)" dot.bash_aliases ~/.bash_aliases
    replace_in_file "(PRODUCT_NAME)" "$(product_name)" "~/.bash_aliases"
end_block "Setting up .bash_aliases file for the user ROOT from user $(server_user)"
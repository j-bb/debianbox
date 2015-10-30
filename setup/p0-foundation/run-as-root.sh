#!/bin/bash

. ../common/fwk.sh "p0" "../setup/log" "setup-p1.log"

################
## add sudo which is not installed by default on Debian
################

begin_block "Run as root step"
    su root

    apt-get install aptitude
    napt-get install sudo
    adduser $(server_user) sudo

    add_unique_line_to_file /etc/sudoers "$(server_user) ALL=(ALL:ALL) ALL" "#Added by $(product_name)" true

    exit 0

end_block "Run as root step"
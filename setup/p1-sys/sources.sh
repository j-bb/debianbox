#!/bin/bash

. ../common/fwk.sh "p1" "../setup/log" "setup-p1.log"

################ OK.
## /etc/apt/sources.list
################

begin_block "Configuring apt sources.list."

    sourcefilein="sources-$(arch).list"
    echo "Source file in $(product_name) is $sourcefilein"
    install_file /etc/apt $sourcefilein sources.list
    chmod ugo+r /etc/apt/sources.list
    chmod ugo-w /etc/apt/sources.list

    napt-get clean
    napt-get update

    . ./p1-sys/lang.sh

    begin_block "Package cleanup"
        echo "Before cleaning :"
    
        dpkg --get-selections

        ## debconf-utils
        ## http://serverfault.com/questions/19367/scripted-install-of-mysql-on-ubuntu
        ## http://pwet.fr/man/linux/commandes/debconf_set_selections
        napt-get install debconf-utils

        napt-get purge dnsutils bind9 bind9-host bind9utils libbind9-60 libisccfg60 libisccc60
        rm -rf /var/run/bind
### not installed anymore #        napt-get purge alsa-base alsa-utils linux-sound-base
### not installed anymore #        napt-get purge dselect reportbug
        napt-get purge ppp pppconfig pppoeconf 
### not installed anymore #        napt-get purge lynx
        ## w3m is a text based browser
        napt-get purge w3m wireless-tools wpasupplicant eject telnet
### try to simplify and might fail 15 #        napt-get purge ntfs-3g libntfs-3g23 dhcp3-client dhcp3-common

##TODO purge candidat : libldap-2.4-2 vim-common vim-tiny

############################
###
### After the transfer to Ubuntu V 10.04 (Lucid Lynx)
### we decided to remov the following packages
###
############################

        napt-get purge dictionaries-common hunspell-fr postfix apport apport-symptoms
        napt-get purge landscape-common landscape-client nano ubuntu-serverguide
        napt-get clean
        napt-get update
        napt-get safe-upgrade

        echo "upgrading openssh-client openssh-server openssh-blacklist openssh-blacklist-extra ..."
        ##
        ## This is a special case for SSH. We upgrade it here rather than in ssh.sh because we use SSH for $(product_name) setup
        ##
        ## bof : http://love.hole.fi/atte/openssh-blacklist/openssh-blacklist-extra_0.3_all.deb
        ## this link is better and kept updated : http://packages.debian.org/sid/all/openssh-blacklist-extra/download
        ## This one is ubuntu and is the final choice : https://launchpad.net/ubuntu/intrepid/amd64/openssh-blacklist-extra/0.4.1
        napt-get install openssh-client openssh-server openssh-blacklist openssh-blacklist-extra

        napt-get clean
        napt-get update
        napt-get safe-upgrade

        echo
        echo "After cleaning :"
        dpkg --get-selections
    end_block "Package cleanup"

    begin_block "Correct Ubuntu crap on GRUB"
        napt-get reinstall grub-pc
    end_block "Correct Ubuntu crap on GRUB"

end_block "Configuring apt sources.list."
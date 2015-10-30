#!/bin/bash

################
## Installation
##
## En etude :
## http://www.dedibox-news.com/doku.php?id=installation:virtualisation_avec_dtc-xen
## D'apres : http://prendreuncafe.com/blog/post/2007/02/05/Securiser-son-Ubuntu-server
## * un analyseur de log
## * un detecteur de rootkit
##    apt-get install chkrootkit
##   # A la mano :
##    chkrootkit
##   # Automated
##   chkrootkit 2>&1 | mail vous@domain.tld -s "Rapport de chkrootkit"
##   # Add to the CRON...
##   # 1. apt-get install binutils chrootkit
##   # 2. run it with an email.
##   # 3. apt-get remove it, remove the cache, so next time a fresh not corrupted install is launched.
##
##
## * Send email :
##    apt-get install mailx
################

## p1 -> DO NOT USE /PROD.

. ../common/fwk.sh "p1" "../setup/log" "setup-p1.log"

begin_block "p1"
#    warning_continue "dpkg-reconfigure debconf ... Choose DIALOG and then eleve. This should be default options : enter twice"
#    dpkg-reconfigure debconf

#TODO DebianBox: email from command line
##    your_eyes_only ../common/email-mime.php
##    if [ -d ../tests ] ; then
##        your_eyes_only ../tests/*
##    fi

    chmod -R ugo-rwx ../prod/*.sh
    chmod -R u+rx ../prod/*.sh

#TODO DebianBox: email
##    ask_mail

    add_log_file services.log

begin_block "Setting up bash_aliases"
    install_file "/home/$(server_user)" dot.bash_aliases ~/.bash_aliases
    replace_in_file "(PRODUCT_NAME)" "$(product_name)" "~/.bash_aliases"
end_block "Setting up bash_aliases"

    . ./p1-sys/root-bash.sh 2>&1 | tee -a $log
#TODO DebianBox:    . ./p1-sys/sources.sh 2>&1 | tee -a $log
#TODO DebianBox:    . ./p1-sys/clamav.sh 2>&1 | tee -a $log
#TODO DebianBox:    . ./p1-sys/popularity-contest.sh 2>&1 | tee -a $log
#TODO DebianBox:    . ./p1-sys/arptables.sh 2>&1 | tee -a $log
#TODO DebianBox:    . ./p1-sys/ssh.sh 2>&1 | tee -a $log
#TODO DebianBox:    . ./p1-sys/ntp.sh 2>&1 | tee -a $log
#TODO DebianBox:
#TODO DebianBox:    . ./p1-sys/remove-apache2.sh 2>&1 | tee -a $log
#TODO DebianBox:    . ./p1-sys/apache2.sh 2>&1 | tee -a $log
#TODO DebianBox:
#TODO DebianBox:
#TODO DebianBox:    ## http://www.openssl.org/docs/apps/req.html
#TODO DebianBox:    ## http://www.simpleentrepreneur.com/2009/03/30/creer-un-certificat-self-signed-en-une-seule-ligne/
#TODO DebianBox:    . ./p1-sys/ssl-certificate.sh 2>&1 | tee -a $log
#TODO DebianBox:
#TODO DebianBox:
#TODO DebianBox:    . ./p1-sys/fail2ban.sh 2>&1 | tee -a $log
#TODO DebianBox:    . ./p1-sys/utilities.sh 2>&1 | tee -a $log
#TODO DebianBox:    . ./p1-sys/iptables.sh 2>&1 | tee -a $log
#TODO DebianBox:    . ./p1-sys/remove-prod-from-fstab.sh 2>&1 | tee -a $log
#TODO DebianBox:    . ./p1-sys/munin.sh 2>&1 | tee -a $log
#TODO DebianBox:    . ./p1-sys/php.sh 2>&1 | tee -a $log
#TODO DebianBox:    . ./p1-sys/last.sh 2>&1 | tee -a $log
#TODO DebianBox:    ../prod/update-server.sh 2>&1 | tee -a $log
#TODO DebianBox:
#TODO DebianBox:    chmod ugo-rwx ../prod/*.sh
#TODO DebianBox:    chmod u+rx ../prod/*.sh
#TODO DebianBox:
#TODO DebianBox:    add_log_file novboot.log
#TODO DebianBox:
#TODO DebianBox:    . ./p1-sys/email.sh

    echo -e "$ROUGE""--------------------------------------------"
    echo "Go the dedibox console and add basic supervision" | tee -a $log
    echo "  * ping SMS + email" | tee -a $log
    echo "  * http email" | tee -a $log
    echo "" | tee -a $log
    echo "Go the dedibox console and add DMA advanced supervision" | tee -a $log
    echo "  * diskused 70%" | tee -a $log
    echo "  * uptime" | tee -a $log
    echo "  * swap 90%" | tee -a $log
    echo "  * loadavg 90%" | tee -a $log
    echo "  * keep temp, alim and disk that should be there by default" | tee -a $log
    echo "" | tee -a $log
    echo "Security note : This host identification has changed, don't worry." | tee -a $log
    echo "" | tee -a $log
    echo "Security : change root and $server_user password NOW" | tee -a $log
    echo "           passwd, then su root and passwd" | tee -a $log
    echo "           At least 13 char !" | tee -a $log
    echo -e "--------------------------------------------""$NORMAL"
    echo "Now, please reboot 'sudo reboot'..." | tee -a $log
end_block "p1"
sign_register "p1"
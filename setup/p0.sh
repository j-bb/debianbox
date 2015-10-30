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

## p0 -> DO NOT USE /PROD.

. ../common/fwk.sh "p0" "../setup/log" "setup-p0.log"

begin_block "p0"

    . ./p1-sys/run-as-root.sh 2>&1 | tee -a $log

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
end_block "p0"
sign_register "p0"
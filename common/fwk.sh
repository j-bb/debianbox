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

product_name="DebianBox"

if [ "$1" != "cron" -o "$1" != "cron-root" ] ; then
    silentlog=true
else
    silentlog=false
fi

if [ -z "$server_name" ] ; then
    server_name=$HOSTNAME
fi

#debug "$0 server_name = $server_name"

## Check file that store email and other config like partition, ...
if [ -e ../common/$server_name-local.sh ] ; then
. ../common/$server_name-local.sh
fi

if [ fwk_loaded != "true" ] ; then
export LANG=en_US.UTF-8
source_url="http://jbriaud.free.fr/master-45292"
product_version="3.0"
if [ $silentlog != "true" ] ; then
    echo "$product_name version $product_version"
fi

arch="debian"
if [ $silentlog != "true" ] ; then
    echo "Architecture is $arch"
fi
. ../common/date-fwk.sh

################
## DATA. Color variables
## http://tips.trustonme.net/tips-read-43.html
################
VERT="\\033[1;32m"
NORMAL="\\033[0;39m"
ROUGE="\\033[1;31m"
ROSE="\\033[1;35m"
BLEU="\\033[1;34m"
BLANC="\\033[0;02m"
BLANCLAIR="\\033[1;08m"
JAUNE="\\033[1;33m"
CYAN="\\033[1;36m"

################
## function for outputing without logging
## error "Unable to destroy your computer, cant't change voltage"
################
error() {
    #echo -e "$ROUGE""[ERR]""$NORMAL"" $1"
    echo "[ERR] $1"
}

debug() {
    #echo -e "$JAUNE""[DBG]""$NORMAL"" $1"
    echo "[DBG] $1"
}

################
## Check parameters
################

# Ensure $1 is there
if [ -z $1 ] ; then
    error "Call to fwk.sh without caller identification string argument !"
    exit -1
fi

# Ensure $1 has the correct value
if [ "$1" != "client-side" -a "$1" != "p0" -a "$1" != "p1" -a "$1" != "p2" -a "$1" != "p3" -a "$1" != "p4" -a "$1" != "p5" -a "$1" != "dev" -a "$1" != "prod" -a "$1" != "p0" -a "$1" != "prod-nocheck" -a "$1" != "tests" -a "$1" != "cron" -a "$1" != "cron-root" ] ; then
    error "Call to fwk.sh using invalid argument : $1 is not allowed. Valid value is {client-side, p1, p2, p3, p4, p5, dev, tests}"
    exit -1
fi

# Ensure $2 is there
if [ -z $2 ] ; then
    error "Call to fwk.sh without log folder argument !"
    exit -1
fi

# ensure $3 is there
if [ -z $3 ] ; then
    error "Call to fwk.sh without log file argument !"
    exit -1
fi

################
## Initialise log
################

logfolder=$2
logfile=$3
log=$logfolder/$logfile
if [ "$2" == "no" -a "$3" == "no" ] ; then
    unset logfolder
    unset logfile
    unset log
fi

if [ -n "$log" ] ; then
    mkdir -p $logfolder
    touch $log
fi

################
## function for logging only
## error "Unable to destroy your computer, cant't change voltage"
################
ltecho() {
    if [ -n "$log" ] ; then
        get_timestamp
        echo "$timestamp - $1"
    fi
}

################
## function warning_continue
## Ask a yes/NO confirmation.
## warning_continue "This will destroy your computer"
################
warning_continue() {
    #echo -e "$ROUGE""Warning !""$NORMAL"" $1. Continue [y/N]"
    echo -e " *** Warning ! $1. Continue [y/N]"
    read key
    if [ "$key" != "y" ] ; then
        echo "OK, exiting"
        exit 0;
    fi
}

################
## CHECK
## Code that execute on load for various check
################

# Make sure we are root
if [ "$1" == "client-side" -o "$1" == "tests" -o "$1" == "cron" ] ; then
    if [ $silentlog != "true" ] ; then
        echo "client-side : Check for root user bypassed."
    fi
else
    if [ "$1" == "dev" ] ; then
        read line < ../common/executor.csv
        servers=(${line//,/' '})
        i=0
        while [[ "${servers[$i]}" ]] 
        do 
            if [ "$HOSTNAME" == "$servers[$i]" ] ; then
                error "This script must run on DEV, and you are on prod"
                exit -1
            else
                i=$(($i+1))
            fi
        done
        echo "ok, you may run this script" 
    else
        current_user_id=`id | sed -n 's/.*uid=\([0-9][0-9]*\)(.*/\1/p'`
        if [ "$current_user_id" -ne 0 ] ; then
            error "You must be root to use that script"
            exit -1;
        fi
        if [ "$1" == "p3" -o "$1" == "p4" -o "$1" == "prod" -a "$1" != "prod-nocheck" ] ; then
            # Check for /prod
            prodmounted=`../prod/service-storage.sh status`
            if [ "$prodmounted" != "/prod is mounted" ] ; then
                error "This is a $1 level script, /prod *must* be mounted."
                echo "sudo ../prod/service-storage.sh start"
                exit -1
            fi
        fi
    fi
fi

stagedescription="$1"

################
## function. Block log
## begin_block "Destroying your computer"
################
begin_block() {
    #echo -e "$BLEU""+ $1 ...""$NORMAL"
    #echo "+ $1 ..."
    ltecho "begin $1 ..."
}

################
## function. Block log
## end_block "Destroying your computer"
################
end_block() {
    #echo -e "$BLEU""- $1. Done.""$NORMAL"
    #echo "- $1. Done."

    ltecho "end $1. Done."
    echo ""
}

################
## DATA
## Common variables.
################

scriptsPath="../common"

#debug "scriptsPath = $scriptsPath"
#debug "Loading ./$scriptsPath/$server_name.sh"

##DebianBox : not sure it is still usefull:
##if [ -e ./$scriptsPath/$server_name.sh ] ; then
##    . ./$scriptsPath/$server_name.sh
##else
##    if [ "$1" == tests -o "$1" == "client-side" ] ; then
##        debug "File $(product_name)/common/$server_name.sh doesn't exist, but don't worry, it's ok"
##    else
##        error "File $(product_name)/common/$server_name.sh doesn't exist"
##        exit -1
##    fi
##fi

#ensure $server_user is defined
server_user=$USER
if [ -z $server_user ] ; then
    error " *** Variable server_user undefined *** (this is gravement important !)"
else
    if [ $silentlog != "true" ] ; then
        echo "server_user = $server_user"
    fi
fi

# Aknowlege test
if [ "$test" == "true" ] ; then
    echo
    echo " *** Running in test mode ***"
    echo
fi

# Aknowledge local
if [ "$local" == "true" ] ; then
    echo
    echo " *** Running in local mode ***"
    echo
fi

server_port=1022
www_root=/prod/www-normal
www_maintenance=/var/www

## Do not change !
## Known dependency are :
## * apache2-confd-munin.conf
## * munin.conf
## * apache2-confd-icons.conf

################
## function. Create an .original file for the records.
## create_original_file <path> <file name>
################
create_original_file() {
    if [ -e $1/$2 ] ; then
        get_timestamp
        # Keep a copy of the original file.
        echo "   Copying $1/$2 to $1/$2.$timestamp-original"
        cp $1/$2 $1/$2.$timestamp-original

        # No one can write on the original file, so, less risk.
        echo "   Making $1/$2.$timestamp-original not writeable"
        chmod ugo-w $1/$2.$timestamp-original
    else
        echo "   create_original_file bypassed file doesn't exist : $1/$2"
    fi
}

get_file_to_copy() {
    if [ -e "$1/$2" ] ; then
        filetocopy="$1/$2"
    else
        debug "$1/$2 doesn't exist, let's try $1/$server_name/$2"
        filetocopy="$1/$server_name/$2"
    fi
    if [ -e "$filetocopy" ] ; then
        debug "   $filetocopy exists"
    else
        error "File doesn't exist : $filetocopy"
        exit -1;
    fi
}

################
## function. Install a file : create an original file, then copy the .install file
## install_file() <path on the server> <file name inside ../config without .install ext> ?< filename on the server in case it is not the same than in ../config >
## config_folder could be a parameter : where to look for config file
################
install_file() {
    if [ -z $config_folder ] ; then
        config_folder="../config"
    echo "Config folder was not defined. Using the default folder : $config_folder"
    fi

    debug "   config_folder = $config_folder"
    
    if [ -z $3 ] ; then
        destinationfile="$2"
        destination="$1/$2"
    else
        destinationfile="$3"
        destination="$1/$3"
    fi
    begin_block "Installing $destination"

        get_file_to_copy $config_folder $2

        difference=`diff --new-file $destination $filetocopy | wc -l`
        debug "   difference = $difference"
        if [ -e $destination -a $difference == "0" ] ; then
            echo "   Nothing to install as no differences found when comparing $filetocopy and $destination"
        else
            if [ -e $destination ] ; then
                echo "   Differences found :"
                diff $destination $filetocopy
            else
                echo "   New file. $destination doesn't exist and will be created."
            fi
            create_original_file $1 $destinationfile
            echo "   Copying $filetocopy to $destination"
            rm -rf $destination
            cp $filetocopy $destination
        fi
    end_block "Installing $destination"
    unset config_folder
}

################
## function. Replace a string by another in a file : replace $1 by $2 in $3 $4
## if $4 is true, it will not show $2 on trace for password secrecy.
################
replace_in_file() {
if [ "$4" == "true" ] ; then
    begin_block "Replacing $1 by ***** in file $3"
else
    begin_block "Replacing $1 by $2 in file $3"
fi
        workingfile="$3"
        tmpfile="$workingfile.tmp-fwk-replace_in_file"
        tmptest="$1"
        replace="$2"

        rm -rf $tmpfile
        touch $tmpfile
        get_permissions "$workingfile"
        chmod u+w $tmpfile

        while read line
        do
            echo "${line//$tmptest/$replace}" >> $tmpfile
            # line2=${line//$tmptest/$replace}
            # debug "just before echo : $line2"
            # echo "$line2" >> $tmpfile
        done < $workingfile
        echo "${line//$tmptest/$replace}" >> $tmpfile
        
        rm -rf $workingfile
        mv $tmpfile $workingfile
        set_permissions $workingfile
if [ "$4" == "true" ] ; then
    end_block "Replacing $1 by ***** in file $3"
else
    end_block "Replacing $1 by $2 in file $3"
fi

    unset replace
}

################
## function check_on
## Switch on console nechoing to a color. User should pay attention.
################
check_on() {
    #echo -e "$ROSE"
    echo ""
    echo "vvv ** Check ON ** vvv -------------------------------------"
}

################
## function check_off
## Switch off console nechoing to a color. User should pay attention.
################
check_off() {
    #echo -e "$NORMAL"
    echo "^^^ ** Check OFF ** ^^^ -------------------------------------"
    echo ""
}

################
## function chown_www
## Change the owner and right to file or folder
## chown_www <path>
################
chown_www() {
    chown -R www-data:www-data $1
    chmod -R o-rwx $1
    chmod -R ug+rw $1
}

################
## function napt-get
## apt-get wrapper to enclose in green color on the console.
################
napt-get() {

    if [ $# -gt 9 ] ; then
        error "Call to napt-get with more than 9 arguments !"
    fi

    echo ""
    echo "+++ aptitude +++"
    debug "aptitude -y -R -q $1 $2 $3 $4 $5 $6 $7 $8 $9"
    aptitude -y -R -q -o Acquire::http::No-Cache=True $1 $2 $3 $4 $5 $6 $7 $8 $9
    echo "--- aptitude ---"
    echo ""

    #echo -e "$NORMAL"
}

################
## function send_email <subject> <path+file for body content> <? to (a valid email)>
## Content can't be HTML
################
send_email() {
    if [ -z "$3" ] ; then
        reciever=$admin_email
    else
        reciever=$3
    fi
    begin_block "send email $1 $2 $reciever"
        mailtimestamp="$(date +%Y-%m-%d_%H:%M:%S)"
        echo "[$product_name] $1" > /tmp/$mailtimestamp-subject.txt
        cp $2 /tmp/$mailtimestamp-body.txt

        php ../common/email-mime.php "/tmp/$mailtimestamp-subject.txt" "/tmp/$mailtimestamp-body.txt" $reciever

        rm -rf /tmp/$mailtimestamp-subject.txt
        rm -rf /tmp/$mailtimestamp-body.txt
    end_block "send email $1 $2 $reciever"
}

################
## function your_eyes_only
## Will restrict to be only readable by $server_user and no one else.
################
your_eyes_only() {
    chown $server_user:$server_user $1
    chmod a-rwx $1
    chmod u+r $1
}

################
## function add_log_file
## Add a file in /var/log/$(product_name) with the right rights.
################
add_log_file() {
    mkdir -p "/var/log/$(product_name)"
    touch "/var/log/$(product_name)/$1"
    chown -R "root:adm /var/log/$(product_name);"
    chmod -R a-rwx "/var/log/$(product_name);"
    chmod ug+rx "/var/log/$(product_name);"
    chmod -R ug+rw,o-rw "/var/log/$(product_name)"
}

################
## function install_remote_file <compression> <URL without the file> <filename> <destination folder without the file>
##
################
install_remote_file() {

    compress="$1"
    url="$2"
    file="$3"
    destination_folder="$4"
    force_nocash="$5"

    debug "force_nocash = $force_nocash"
    begin_block "Installing $file from $url to $destination_folder ($compress)"
        if [ -e $destination_folder/$file -a "$force_nocash" == "force_nocash" ] ; then
            echo " ** download skipped : $destination_folder/$file already exist !"
        else
            mkdir -p $destination_folder
            wget --progress=dot:mega --output-document=$destination_folder/$file $url/$file
        fi
        
        if [ -e $destination_folder/$file ] ; then
            #if download was successful
            cp ../md5/$file.md5 $destination_folder
            check_on
            (
                cd $destination_folder
                echo "MD5 checking :"
                md5result=`md5sum -c $file.md5`
                echo "[DBG] md5result = $md5result"
            )
            check_off
        else
            error "wget failed !!! File not there : $destination_folder/$file"
            exit -1;
        fi

        echo "uncompressing $file ..."
        if [ "$compress" == "zip" ] ; then
            # -q for quiet output
            # -o for overwrite in case the output already exists.
            unzip -q -o $destination_folder/$file -d $destination_folder
            find $destination_folder -name "._*" -exec rm -rf {} \;
            find $destination_folder -name ".DS_Store" -exec rm -rf {} \;
            find $destination_folder -name "__MAC*" -exec rm -rf {} \;
        elif [ "$compress" == "tar" ] ; then
            tar -C $destination_folder -xjf $destination_folder/$file --exclude='._*' --exclude='.DS_Store' --exclude='__MAC*'
        elif [ "$compress" == "deb" ] ; then
            dpkg -i $destination_folder/$file
        elif [ "$compress" == "none" ] ; then
            ## Nothing to do.
            echo "No compression."
        else
            error " Unknown compression : $compress"
        fi
        echo "uncompressing $file. Done."

        echo "Scanning for virus $destination_folder ..."
        if [ "$test" != "true" ]
        then
            check_on
            clamdscan $destination_folder
            check_off
        else
            echo "Skipped ..."
        fi
        echo "Scanning for virus $destination_folder. Done."

    end_block "Installing $file from $url to $destination_folder"
}

################
## function ask_pass <text> <other line of text>
##
################
ask_pass() {

    password="1"
    password2="2"

    until [ "$password" == "$password2" ]
    do
        echo
        echo "-->"
        echo "$1"
        if [ -n "$2" ] ; then
            echo "$2"
        fi
        echo -n ">"
        stty -echo
        read password
        stty echo
        echo ""

        echo "Verification. $1"
        if [ -n "$2" ] ; then
            echo "$2"
        fi
        echo -n ">"
        stty -echo
        read password2
        stty echo
        echo ""
        if [ "$password" != "$password2" ] ; then
            echo
            echo -e "$ROUGE""*** Passwords are differents !! Enter it again ***""$NORMAL"
            echo
        fi
    done

    unset password2
}

################
## function install_db <db name> <db user> <? extra file to replace too> <? -mysqlupass> <$mysqlupass> <? -mysqlrpass> <$mysqlrpass>
##
################
install_db() {
    dbname=$1
    dbuser=$2
    if [ -n "$3" -a "$3" != "-mysqlrpass" -a "$3" != "-mysqlupass" ] ; then
        extra_file=$3
    fi
    begin_block "Creating database $dbname and user $dbuser"

    if [ $# -lt 3 ] ; then
        ask_pass "MySQL root password"
        mysqlrpass=$password
        unset password

        ask_pass "MySQL password for database $dbname, user $dbuser" "!! Make sure you store it somewhere !!"
        mysqlupass=$password
        unset password
    else
        declare -i i=3
        while [ $i -lt $# ] ; do
            if [ $"$i" == "-mysqlrpass" ] ; then
                mysqlrpass="$(($i+1))"
            elif [ $"$i" == "-mysqlupass" ] ; then
                mysqlrpass="$(($i+1))"
            fi
            i=$(($i+1))
        done
    fi

        begin_block "Creating database $dbname"
            cp ../common/create-db.sql /tmp/create-db.sql
            replace_in_file "(MYSQL_DB)" $dbname "/tmp/create-db.sql"
            mysql --no-beep --user=root --password=$mysqlrpass < /tmp/create-db.sql
            rm -rf /tmp/create-db.sql
        end_block "Creating database $dbname"

        begin_block "Creating user $dbuser for database $dbname"
            cp ../common/create-user.sql /tmp/create-user.sql
            replace_in_file "(MYSQL_DB)" $dbname "/tmp/create-user.sql"
            replace_in_file "(MYSQL_DB_USER)" $dbuser "/tmp/create-user.sql"
            replace_in_file "(MYSQL_DB_PASSWD)" $mysqlupass "/tmp/create-user.sql" true

            #mysql -v --no-beep --user=root --password=$mysqlpass < /tmp/xwiki.sql
            mysql --no-beep --user=root --password=$mysqlrpass < /tmp/create-user.sql
            rm -rf /tmp/create-user.sql
        end_block "Creating user $dbuser for database $dbname"

    end_block "Creating database $dbname and user $dbuser"

    if [ -z $3 ] ; then
        echo "no extra file to replace"
    elif [ "$3" != "-mysqlrpass" -a "$3" != "-mysqlupass" ] ; then
        begin_block "Replacing extra file $3"
            replace_in_file "(MYSQL_DB)" $dbname "extra_file"
            replace_in_file "(MYSQL_DB_USER)" $dbuser "extra_file"
            replace_in_file "(MYSQL_DB_PASSWD)" $mysqlupass "extra_file" true
        end_block "Replacing extra file $3"
    fi
}

clean_db_pass() {
    unset mysqlrpass
    unset mysqlupass
}

################
## function sign_register <key>
##
## Will add a key to ../setup/log/db
################
sign_register() {
    echo "$1 - $stagedescription - $(date +%Y-%m-%d_%H:%M:%S)" >> ../setup/log/db
}

check_register() {
    status=`cat ../setup/log/db | grep "$1" | wc -l`
    if [ "$status" == "0" ] ; then
        error "check_register : dependency not satisfyed !! $1 had not been done according to the db"
        exit -1;
    else
        debug "check_register : dependency OK : $1"
    fi
}

#######
##
## Executor block:
## String_to_tab : converts a string with commas to a tab.
######
string_to_tab() {
    if [ -z "$1" ] ; then
        error "[string_to_tab] No string :("
    else
       string=$1
       line3=`echo $string | tr -d "\""`
       line=(${line3//,/' '})
    fi
}

#######
##
## Executor : 
## executor <executor_folder> <csv_file> <generated_script>
## Reads <csv_file> and write a new shell script depending on 0 or 1 in the csv file.
## The <generated_script> is finally executed.
##
## Example : executor /truc/bidule machin.csv /chose/chouette.sh
######
executor() {
    executor_folder=$1
    csv_file=$2
    generated_file="$3"

    if [ -z "$executor_folder" ] ; then
        echo "[Executor] ---> \$1 folder parameter is missing"
        exit -1
    fi

    if [ -z "$csv_file" ] ; then
        error "[Executor] ---> \$2 \"file.csv\" parameter is missing"
        exit -1
    fi

    while read csv_line ; do
        echo "" > /dev/null
    done < $csv_file
    if [ "$csv_line" != "" ] ; then
        debug "added a string to csv file : $csv_file"
        echo "" >> $csv_file
    fi

    server=$server_name
    begin_block "[Executor] ---> Reading $csv_file file"
        read servs < $csv_file
        string_to_tab $servs
        debug "[Executor] ---> server = $server"

        i=0
        while [[ "$server" != "${line[i]}" ]] ; do
        debug ${line[i]}
            i=$(($i+1))
            if [ $i -gt ${#line} ] ; then
                error "[Executor] ---> No server $server in file $csv_file"
                exit -1
            fi
        done

        serv_pos=$i
        i=0

        echo "#!/bin/bash" >> $generated_file
        while read csv_line ; do
            if [ $i -gt 0 ] ; then
                string_to_tab $csv_line
                if [[ "${line[$serv_pos]}" == "1" ]]; then
                    if [ -e "$executor_folder/${line[0]}" ] ; then
                        echo "begin_block \"[Executor] ---> Executing $executor_folder/${line[0]}\"" >> $generated_file
                        echo "$executor_folder/${line[0]}" >> $generated_file
                        echo "end_block \"[Executor] ---> Executing $executor_folder/${line[0]}\"" >> $generated_file
                    else
                        error "[Executor] ---> Executable not found : $executor_folder/${line[0]}"
                        exit -1
                    fi
                else
                    debug "[Executor] ---> Not setup to run in $csv_file : $executor_folder/${line[0]}"
                fi
            fi
            i=$(($i+1))
        done < $csv_file
    end_block "[Executor] ---> Reading $csv_file file"
    
    chmod u+x $generated_file
    . $generated_file
}

################
## function time_out <one command to run> <max time allowed in second>
## example : time_out ls 5. This will force ls not to exceed 5 second.
##
################
timeout() {
    begin_block "timeout -t $2 -i $2 -d 1 $1"
        ../common/time-out.sh -t $2 -i 2 -d 1 $1 
    end_block "timeout -t $2 -i $2 -d 1 $1"
}


##############
##
## ask_question : ask a question and wait for an aswer on screen.
## the result is stored in variable answer.
## The text to show must be in $1
##
###############
ask_question() {
    if [ $# -lt 1 ] ; then
        error "no question asked!"
        exit
    fi
    echo $1
    read answer
}

###############
##
## ask_mail : actually used in setup/p1.sh and prod/change_mail.sh
##
## Ask an email on screen and store it in common/admin_email.sh
## This set the admin email for the $(product_name). Can be changed anytime by
## launching $(product_name)/prod/change_email.sh
##
###############
ask_mail() {
    if [ -e ../common/$server_name-local.sh ] ; then
        echo "current mail is $admin_email"
        warning_continue "do you want to replace it ?"
    elif [ ! -e ../common/$server_name-local.sh ] ; then
        debug "File did not exist!"
        echo "#!/bin/bash" > ../common/$server_name-local.sh
        chown $server_user:$server_user ../common/$server_name-local.sh
        chmod u+x ../common/$server_name-local.sh
    fi
    ask_question "what is your mail?"
    ADMIN_MAIL=$answer
    unset answer
    debug "your mail is $ADMIN_MAIL . Putting it to ../common/$server_name-local.sh"
    add_unique_line_to_file "../common/$server_name-local.sh" "admin_email=$ADMIN_MAIL" "ADMIN_MAIL"
}

################
## Add a line to a file with garantee that there will be only one line : the new one you wnt to dd without diplicate.
## This is done via an identifier that must be identical across call to the function.
##
## add_unique_line_to_file <file> <line> <identifier> <identifierAtTheEndOfLine:true|false>
##
################
add_unique_line_to_file() {
    identifier=$3
    file=$1
    line=$2
    identifierAtTheEndOfLine=$4
    if [ -z "$identifierAtTheEndOfLine" ] ; then
        identifierAtTheEndOfLine="false"
    else
        identifierAtTheEndOfLine="true"
    fi
    debug "identifier at the end of line=$identifierAtTheEndOfLine"
    line_already_there=`cat $file | grep "## $identifier" | wc -l`
    if [ $line_already_there == 0 ] ; then
        echo >> $file
        if [ $identifierAtTheEndOfLine == "false" ] ; then
            echo "$line ## $identifier" >> $file
        else
            echo "## $identifier" >> $file
            echo "$line" >> $file
        fi
    else
        tmpfile="$file.tmp"
        rm -rf $tmpfile
        touch $tmpfile
        while read current_line ; do
            line_already_there=`echo "$current_line" | grep "## $identifier" | wc -l`
            if [ $line_already_there == 0 ] ; then
                echo "$current_line" >> $tmpfile
            else
                if [ "$identifierAtTheEndOfLine" == "false" ] ; then
                    echo "$line ## $identifier" >> $tmpfile
                else
                    read old_line
                    echo "## $identifier" >> $tmpfile
                    echo "$line" >> $tmpfile
                    debug "Replaced $old_line by $line"
                fi
            fi
        done < $file
        mv $tmpfile $file
    fi
}

###############
## A function to install a script to crontab
## Example :
## install_cron <minute> <hour> <day(day of month 1-31)> <month> <day(day of week 0-6)> <user> <command> <identifier>
## install_cron "08" "*" "*" "*" "*" "root" "(cd /home/$server_user/$(product_name)/prod && ./drive-space-surveyor.sh)"DRIVE-SPACE"
##
## TODO how to ensure last command is executed ?
## A && B will execute B only if A is executed OK.
## How to log that so it can be corrected ?
##
## install_cron "08" "*" "*" "*" "*" "root" "<command to execute>" "identifier"
##
## <command to execute> is the command that the crontab will launch.
##
## Actually, there are two ways to use the function : 
## 1) install_cron "08" "*" "*" "*" "*" "root" "(cd /home/$server_user/$(product_name)/prod && ./drive-space-surveyor.sh)" "DRIVE-SPACE"
## It means you must have a "cd" in <command to execute>.
## The directory and the name of the script must be separated by ";" or by "&&".
## These two commands must be included in parantheses "()"
## Do not put the slash in the end of the directory!
##
## 2) install_cron "08" "*" "*" "*" "*" "munin" "/usr/bin/munin-cron" "MUNIN"
## <command to execute> contains only a path to a script to execute. 
## This one is not to be included in parantheses
##
## <identifier> is used to install a line to crontab only once.
## See the docs of "add_unique_line_to_file" for more information.
##
###############
install_cron () {
    if [ $# -lt 8 ] ; then
        error "install_cron : not enough commands"
    else
        cron_line="$1 $2 $3 $4 $5 $6 $7"
        cmd_to_execute="$7"
        user="$6"
        lenght=`echo "$cron_line" | wc -c`
        lenght=$(($lenght-1))
        identifier="$8"
        if [ "`expr "$cmd_to_execute" : "(cd.* [;&]* \./.*)"`" -eq "$lenght" ] ; then
            file=`echo $cmd_to_execute | cut -d ")" -f 1 | rev | cut -d "/" -f 1 | rev`
            path=`echo $cmd_to_execute | cut -d "(" -f 2 | cut -d " " -f 2`
            if [ ! -e "$path/$file" ] ; then
                error "$path/$file does not exist"
                exit -1
            fi
        fi
        add_unique_line_to_file "/etc/crontab" "$cron_line" "$identifier"
        unset cmd_to_execute
        unset cron_line
    fi
}

###############
##
## the 4 following functions get are used to 
## get the mapping of the hard drive for p2
##
###############
get_SWAP_partiton () {
    SWAP_partiton=`fdisk -l /dev/sda | grep swap | cut -d " " -f 1`
    debug "swap partiton is $SWAP_partiton"
}

get_PROD_partiton () {
    PROD_partiton=`df -h | grep /prod | cut -d " " -f 1`
    debug "prod partiton is $PROD_partiton"
}

get_BOOT_partiton () {
    BOOT_partiton=`df -h | grep /boot | cut -d " " -f 1`
    debug "boot_partiton is $BOOT_partiton"
}

get_ROOT_partiton () {
    ROOT_partiton=`df -h | grep /$ | cut -d " " -f 1`
    debug "root partition is $ROOT_partiton"
}

###############
##
## set_wrapper : the following function
## set_wrapper <runlevel> <prefix> <wrapper_to_launch>
## example : set_wrapper "2" "S10" "arptables.sh
## This will install the file "arptables.sh" in /etc/rc2.d
###############
set_wrapper () {
    runlevel=$1
    prefix=$2
    wrapper=$3

    config_folder="../config/wrappers"
    rm -rf /etc/rc$runlevel.d/$prefix$wrapper
    install_file "/etc/rc$runlevel.d" "wrapper.sh" "$prefix$wrapper"
    replace_in_file "(USER_PATH)" "/home/$server_user" "/etc/rc$runlevel.d/$prefix$wrapper"
    replace_in_file "(WRAPPER_TO_LAUNCH)" "./$wrapper.sh" "/etc/rc$runlevel.d/$prefix$wrapper"
    chmod a-rwx /etc/rc$runlevel.d/$prefix$wrapper
    chmod u+rx /etc/rc$runlevel.d/$prefix$wrapper
}

###############
##
## Get permissions for a file <$1>
## The "permissions" variable is set.
## Pay attention to it please.
##
###############
get_permissions () {
    permission_file="$1"
    if [ -n "$permission_file" ] ; then
        permissions=`stat --print=%a $permission_file`
    else
        error "get_permissions : file not set!"
    fi
}

set_permissions () {
    if [ -n "$1" ] ; then
        permission_file=$1
    fi
    chmod $permissions $permission_file
}

###############
##
## Choose a partition to remove in fstab. No parameter.
## This function ensure /prod will be removed.
## The end user will have to tell the line in the fstab file where /prod is.
## If you don't zqnt to remoove any line, you can enter "0"
###############
choose_prod_in_fstab () {
    . ../common/$server_name-local.sh

    begin_block "Upgrading fstab and cryptab"
        echo "fstab : remove $partition or make sure it's not there"
        if [ `grep $partition /etc/fstab | wc -l` -ge 1 ] ; then 
            cat -n /etc/fstab
            ask_question "What line do you want to remove ? (0 for nothing)"
            line_number=$answer
            if [ ! "$line_number" -eq 0 ] ;then
                i=1
                rm -rf /tmp/fstab
                debug "line number is $line_number"
                while read fstab_line ; do
                    if [ ! $i -eq $line_number ] ; then
                        echo "$fstab_line" >> /tmp/fstab
                    fi
                    i=$(($i+1))
                done < "/etc/fstab"

                cp /etc/fstab $logfolder/before-crypt-prod-fstab
                mv /tmp/fstab /etc/fstab
                cp /etc/fstab $logfolder/after-crypt-prod-fstab
            fi
        else
            debug "Already updated, no need to take care"
        fi
    end_block "Upgrading fstab and cryptab"
}

#######
## prod_check : checks if the partiton is written down in
## ../common/$server_name-local.sh
######
prod_check () {
    if [ -z "$prod_partition" ] ; then
        get_PROD_partiton
        partition="$PROD_partiton"
        add_unique_line_to_file "../common/$server_name-local.sh" "prod_partition=$partition" "PROD"
    else
        partition=$prod_partition
    fi
    debug "[prod_check()] PROD partition : $partition"
}

#######
## add_firewall_rule <rule> <identifier>
## Adds a <rule> to the custom zone of iptables.sh
## and ensure the <rule> is not duplicated (see add_unique_line_to_file)
######
add_firewall_rule () {

    begin_block "Adding a new rule to iptables"
        rule=$1
        identifier=$2
        
        rm -rf "/tmp/iptables.sh"
        
        while read iptables_line ; do
            if [ "$iptables_line" == "## end custom zone" ] ; then
                add_unique_line_to_file "/tmp/iptables.sh" "$rule" "$identifier" "true"
            fi
            echo "$iptables_line" >> /tmp/iptables.sh
        done < "../prod/iptables.sh"
        config_folder="/tmp"
        install_file "../prod" "iptables.sh"
        chmod u+x ../prod/iptables.sh
    end_block "Adding a new rule to iptables"
}

##########
##
## Timer : A couple of functions to get the time that a commands takes to be executed.
## Timers can be nested. Exemple :
##      timer_start ## (timer 1)
##      timer_start ## (timer 2)
##      sleep 5
##      timer_stop ## (timer 2)
##      timer_start ## (timer 3)
##      sleep 10
##      timer_stop ## (timer 3)
##      timer_stop ## (timer 1)
## will output :
##      5 ## due to timer 2
##      10 ## due to timer 3
##      15 ## due to timer 1
##########

timer_start () {
    timer_len=${#timer_array[*]}
    echo "starting a timer, $timer_len timers already active"
    timer_array[timer_len]=`date +%s` 
}

timer_stop () {
    timer_len=${#timer_array[*]}
    echo "shutting down timer $timer_len"
    current_time=`date +%s`
    runtime=$(( $current_time - ${timer_array[timer_len - 1]} ))
   if [ $runtime -ge 3600 ] ; then
        echo "Runtime : $((runtime/3600))h $((runtime/60%60))m $((runtime%60))s"
    elif [ $runtime -ge 60 ] ; then
        echo "Runtime : $((runtime/60))m $((runtime%60))s"
    else
        echo "Runtime : $((runtime))s"
    fi
    unset timer_array["timer_len - 1"]
}

##########
##
## Async : asynchronous task management.
## For example, use it for downloading files in the background.
## use :
## async_begin <cmd> <key>
## // some code
## adync_stop <key> <? time to sleep>
## //some code 2
## code 1 will be executed at the same time with async command 
## code 2 will be executed only after async command execution is over
##
##########

asyncfolder=/tmp/async

##########
##
## async_start : begin an asynchronous job
## async_start <cmd> <key>
##
##########
async_start () {
    cmd=$1
    key=$2

    debug "cmd = $cmd"
    debug "key = $key"
    get_timestamp
    rm -rf $asyncfolder/$key
    mkdir -p $asyncfolder/$key
    (echo "$timestamp - begin $key" > $asyncfolder/$key/begin ; $cmd | tee > $asyncfolder/$key/log ; get_timestamp ; echo "$timestamp - end $key" > $asyncfolder/$key/end ) &
}

##########
##
## async_rendez_vous : begin an asynchronous job
## async_rendez_vous <cmd> <key>
##
##########

async_rendez_vous () {
    key=$1
    time_to_sleep=$2
    if [ -z $time_to_sleep ] ; then
        time_to_sleep=5
    fi

    if [ -d $asyncfolder/$key ] ; then 
        while [ ! -e $asyncfolder/$key/end ] ; do
            debug "[async_rendez_vous] Waiting in rendez-vous for $key."
            sleep "$time_to_sleep"
        done
        debug "[async_rendez_vous] Task $key ended."
        begin_block "[async_rendez_vous] Dump of execution of task $key"
            cat $asyncfolder/$key/begin | tee -a $log
            cat $asyncfolder/$key/log | tee -a $log
            cat $asyncfolder/$key/end | tee -a $log
            rm -rf $asyncfolder/$key
        end_block "[async_rendez_vous] Dump of execution of task $key. Done."
        
    else
        error "Command with key \"$key\" was not launched"
    fi
}

export fwk_loaded="true"
fi
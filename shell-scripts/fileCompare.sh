#!/bin/bash
#
# ***************************************************************************
# Created 1/9/2017
# Author: jmorales
# Change Log:
# 1/9/17 - created
#
# Known Issues:
#
#
#
# ***************************************************************************
#

function script_help () {

cat <<eof

The purpose of this script is to compare the output of two files.  
If the files are the same return 0.  Otherwise, return 1.
All white space is ignored by default.

REQUIRED Arguments
==================
        -f1          <file-name-1>       # fully qualified name of the first file
        -f2          <file-name-2>       # fully qualified name of the second file		
        -env         <environment>       # environment; dev, qa or prod		
        
eof
}

# ***************************************************************************
# STANDARD ENVIRONMENT SETUP
# ***************************************************************************
setup_env () {

    mail_list='jim.morales@kbb.com'

    current_dir=$(pwd)
    script_dir=$(dirname $0)
    this_script=`basename $0`

    if [ $script_dir = '.' ]; then
        script_dir="$current_dir" 
    fi

    status=0
    if [ ! $env == "prod" ] ; then env=dev\/$env ; fi
    wrk_dir=/controlm_stage/kbb_ds/$env/data/wrk

 
}

# ***************************************************************************
# ERROR HANDLING FOR INVALID FILENAME
# ***************************************************************************
invalid_file_name () {

    echo "ERROR: The file name argument is invalid.  Make sure the file"
    echo ${1} " exists and try your command again."
    exit 2

}

# *************************************************************************** 
# STANDARD ERROR FOR MISSING ARGUMENTS
# ***************************************************************************
required_arg_missing () {

    echo "ERROR:  You must specify the ${1} option.  This is a required argument"
    echo "Try \"`basename $0` -h\" for more information."
    exit 1

}

# *************************************************************************** 
# STANDARD SYNTAX FOR COMMAND LINE OPTIONS
# ***************************************************************************
while [ "$1" != "" ]; do

        OPTION=`echo $1 | dd conv=lcase 2>/dev/null`

        case $OPTION in

                # Options
                # -------
                "-f1"          )       f1=$2             ; shift 2 ;;

                "-f2"          )       f2=$2             ; shift 2 ;;

                "-env"         )       env=$2            ; shift 2 ;;

 # Help
                # ----

                "-?" | "--?" | "-h" | "--h" | "-help" | "--help" )
                        script_help
                        exit 0
                        ;;

                # Unknown
                # -------
        * )
                echo "Invalid argument: $1"
                echo "Try \"`basename $0` -h\" for more information."
                exit 1
                ;;

        esac
done

if [ "$f1"     = "" ] ; then required_arg_missing  "-f1"  ; fi
if [ "$f2"     = "" ] ; then required_arg_missing  "-f2"  ; fi
if [ "$env"    = "" ] ; then required_arg_missing  "-env" ; fi

# ***************************************************************************
# This will validate the path to the input files
# ***************************************************************************
#
validate_input () {

    if [ ! -f "$f1" ]; then

        invalid_file_name "$f1"

    fi

    if [ ! -f "$f2" ]; then

        invalid_file_name "$f2"

    fi

}
    
# ***************************************************************************
# Ccompare the files
# ***************************************************************************
exec_diff() {

    result=$(diff -w $f1 $f2)

    if [ -n "$result" ]; then
    
        echo "The files do not match."
        status=1
		
	else

        echo "The files match."	
        status=0    
        
    fi

}



# ***************************************************************************
# SEND RESULTS TO MAILLIST RECIPIENTS
# ***********************************************************************
email_results () {

    CR=$(printf '\r')

    sed 's/\$/$CR/' "$f1" > $wrk_dir/f1.tmp
    sed 's/\$/$CR/' "$f2" > $wrk_dir/f2.tmp
    sed -i 's/|/\t/g' $wrk_dir/f1.tmp
    sed -i 's/|/\t/g' $wrk_dir/f2.tmp

    msgbody=$wrk_dir/msgbody.txt
	
    if [ ${1} = 0 ]; then
	subject="SUCCESS: NADA Data Validation Completed Successfully"
        echo "NADA Data Validation Completed Successfully." > "$msgbody"
    else
        subject="ALERT:  NADA Data Validation Failure"
        echo "ERROR - NADA Data Validation failed." > "$msgbody"
    fi

    echo ""                                     >> "$msgbody"
    echo "Netezza Counts:"                      >> "$msgbody"
    cat $wrk_dir/f1.tmp                      >> "$msgbody"
    echo ""                                     >> "$msgbody"
    echo "Hadoop Counts:"                       >> "$msgbody"
    cat $wrk_dir/f2.tmp                      >> "$msgbody"

    mailx -s "$subject" -r edw_web@kbb.com  $mail_list < "$msgbody"
}

# ***************************************************************************
# MAIN PROGRAM
# ***************************************************************************

setup_env

validate_input

exec_diff

email_results $status

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

The purpose of this script is to execute data valiudation queries against Netezza and save the resultsend
to a file.  

REQUIRED Arguments
==================
                -server      <server>            # name of the server to connect to
                -dbname      <dbname>            # name of the database to connect to 
                -username    <username>          # valid username for the sever and databsase (encrypted)
                -password    <password>          # password for the username (encrypted)
                -env         <environment>       # environment used for Control-M log folder location
                                                 # Logs  written to /controlm_stage/kbb_ds/$env/logs/nzdbquery/
                -output_fil  <output_fil>        # the name of the file to write to; file will be created if it does not exist
				
OPTIONAL Arguments
===================
                -query       <query>             # query string
                -query_fil   <query_fil>         # file name that contains the query to execute
                                                 # query string and query file options are mutually exclusive
                -delim       <delimiter>         # column delimiter to use in the output file
                -output_dir  <output_dir>        # the directory where the output file will be stored
                                                 # if not specified then the current directory will be used
Example
=======
                ./execNZQuery.sh -s 10.228.135.47 -db test -q 'select * from table limit 10;' -u xyz123== -p 123bcA== -env dev -output_fil test.dat -output_dir /controlm_stage/kbb_ds/dev/dev/data/wrk -output_fil nzquery.out

eof
}

# ***************************************************************************
# ERROR HANDLING FOR INVALID FILENAME
# ***************************************************************************
invalid_file_name () {

        echo "ERROR: The file name argument is invalid.  Make sure the file"
        echo $db " exists and try your command again."
        exit 1

}
# *************************************************************************** 
# STANDARD ERROR FOR MISSING ARGUMENTS
# ***************************************************************************
required_arg_missing () {

        echo "ERROR:  You must specify the ${1} option.  This is a required argument"
        echo "Try \"`basename $0` -h\" for more information."
        exit 2

}

# *************************************************************************** 
# STANDARD ERROR FOR MUTUALLY EXCLUSIVE OPTIONS
# ***************************************************************************
mutually_exclusive_options () {

        echo "ERROR:  Mutually exclusive options selected.  Options ${1} conflict."
        echo "Try \"`basename $0` -h\" for more information."
        exit 3

}

# *************************************************************************** 
# STANDARD ERROR FOR ASTERRISK IN QUERY
# ***************************************************************************
asterisk_in_query () {

        echo "ERROR:  SELECT * from table is not supported.  Please specify the columns you want to return."
        echo "Try \"`basename $0` -h\" for more information."
        exit 4
		
}

# ***************************************************************************
# STANDARD ENVIRONMENT SETUP
# ***************************************************************************
setup_env () {

	ti=$(date | awk '{print $4}' |  sed -e "s/://g")
	dt=$(date +"%Y-%m-%d-%H%M%S")

    current_dir=$(pwd)
    script_dir=$(dirname $0)

    if [ $script_dir = '.' ]; then

        script_dir="$current_dir" 

    fi
	
	exec_dir=/controlm_code/kbb_ds/$env/java/dbquery
	log_dir=/controlm_stage/kbb_ds/$env/logs
	log_fil=nzdbquery_$$_$dt_$ti.log
}

# *************************************************************************** 
# STANDARD SYNTAX FOR COMMAND LINE OPTIONS
# ***************************************************************************
while [ "$1" != "" ]; do

        OPTION=`echo $1 | dd conv=lcase 2>/dev/null`

        case $OPTION in

                # Options
                # -------
                "-s"          | "-server"      )                      s=$2                ; shift 2 ;;

                "-db"         | "-dbname"      )                      db=$2               ; shift 2 ;;

                "-u"          | "-username"    |    "-user"  )        u=$2                ; shift 2 ;;

                "-p"          | "-password"    |    "-pwd"   )        p=$2                ; shift 2 ;;

                "-q"          | "-query"       )                      q=$2                ; shift 2 ;;

                "-f"          | "-query_fil"   )                      f=$2                ; shift 2 ;;

                "-env"        | "-environment" )                      env=$2              ; shift 2 ;;

                "-delim"                       )                      delim=$2            ; shift 2 ;;

                "-output_dir" | "-dir"         )                      output_dir=$2       ; shift 2 ;;

                "-output_fil" | "-fil"         )                      output_fil=$2       ; shift 2 ;;

#                "-log_dir"                     )                      log_dir=$2          ; shift 2 ;;

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

if [ "$s"          = "" ] ; then required_arg_missing "-server"      ; fi
if [ "$db"         = "" ] ; then required_arg_missing "-database"    ; fi
if [ "$u"          = "" ] ; then required_arg_missing "-username"    ; fi
if [ "$p"          = "" ] ; then required_arg_missing "-password"    ; fi
if [ "$env"        = "" ] ; then required_arg_missing "-environment" ; fi
if [ "$output_fil" = "" ] ; then required_arg_missing "-output_fil"  ; fi

if [ -n "$q" ] && [ -n "$f" ] ; then mutually_exclusive_options "-query and -query_fil" ; fi

if [ -n "$q" ] ; then 
	
	qtype=-q
	query="$q"

elif [ -n "$f" ] ; then

    qtype=-i
    query=$f

else

    required_arg_missing "-query or -query_fil"

fi

# set the default delimiter
if [ ! -n "$delim"      ] ; then delim=^                             ; fi

# ***************************************************************************
# This will validate the path to the output directory If the path is relative
# it assumes that the current directory, otherwise it leaves it alone.
# ***************************************************************************
validate_input () {

#	validate the output directory
    if [ -n "$output_dir" ]; then

        cd $output_dir 2> $script_dir/dir_check.tmp

        RC=`grep "No such file or directory" $script_dir/dir_check.tmp | wc -l`

        if [ $RC -ge 1 ]; then
            echo "Warning: The output directory is not valid."
            echo "output will be written to the current directory."
            output_dir=`pwd`
        fi

    else

        output_dir=`pwd`

    fi

#	remove the output file if it exists
    if [ -f $output_dir/$output_fil ]; then rm $output_dir/$output_fil ; fi
  
}

# ***************************************************************************
# execute the query
# ***************************************************************************
exec_query() {

   echo java -cp $exec_dir/execDBQuery.jar GetNZQueryResult -s $s -d $db -u $u -p $p -r 5480 -o $output_dir/$output_fil -l $delim $qtype "$query"
   		java -cp $exec_dir/execDBQuery.jar GetNZQueryResult -s $s -d $db -u $u -p $p -r 5480 -o $output_dir/$output_fil -l $delim $qtype "$query" > $log_dir/$log_fil 2>&1

        RC=$?

        if [ $RC -ne 0 ]; then

            echo "ALERT: The query failed, see log for errors."
			echo "Log File Location: $log_dir/$log_fil"
			echo `cat $log_dir/$log_fil`
			exit 5

        fi

}

# ***************************************************************************
# MAIN PROGRAM
# ***************************************************************************

setup_env

validate_input

exec_query

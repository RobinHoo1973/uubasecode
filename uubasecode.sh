#!/bin/bash

################################################################################ 
# Function Name:   HELP_USAGE                           
# Description:     Function to display the usage of the script          
# Parameters:      None                             
# Return:          Help messages                        
# Called By:       Script Main Loop->Script Parameters' Handler         
# History:         2014-May-29 Initial Edition               RobinHoo  
################################################################################

function help_usage()
{
cat <<EOF
Unix-to-Unix & Base64 ENCODE & DECODE BASH SCRIPT
Usage: $PROGNAME [OPTION]... [FILE]
  -d, --decode Decode mode for handling the input file
  -b, --base64 Encode or Decode in base64 rules
  -u, --uucode Encode or Decode in Unix-to-Unix rules
  -h, --help   Show current help message of the script usages
    

Please Report Script Bugs to $AUTHOR_MAIL
EOF
exit 1
}

function ENCODE()
{
    local wide=$1
    local char=$2
    [ "$char" == "\`" ] && which uuencode >/dev/null 2>&1 && uuencode "$FNAME" "$FNAME" 2>/dev/null && return 0
    [ "$char" == "=" ] && which base64 >/dev/null 2>&1 && base64 "$FNAME" && return 0
    [ "$char" == "\`" ] && echo "begin $(stat -c %a "$FNAME") $(basename "$FNAME")"

    hexdump -ve '3/1 "%d " "\n"' < "$FNAME"|awk -v w=$wide -v ch="$char" 'BEGIN{UB64="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";if (ch=="`") {UB64="`";for(i=33;i<96;i++)UB64=sprintf("%s%c",UB64,i)}}{k+=NF;t=$1*65536+$2*256+$3;for(j=3;j>=0;j--){c=(3-j<=NF)?substr(UB64,int(t/2^(6*j))+1,1):ch;o=sprintf("%s%c",o,c);t%=2^(6*j);if (length(o)==w) {if (ch=="`") printf"M";printf"%s\n",o;o=""}}}END{if(length(o)>0){if (ch=="`") printf"%c",32+k%45;printf"%s\n",o;if (ch=="`") printf"`\nend\n"}}'

}

function DECODE(){
    local buff=""
    local wide=$1
    local char=$2
    [ "$char" == "\`" ] && which uudecode >/dev/null 2>&1 && uudecode -o /dev/stdout "$FNAME" && return 0
    [ "$char" == "=" ] && which base64 >/dev/null 2>&1 && base64 -d "$FNAME" && return 0

    for buff in $(cat < "$FNAME"|awk -v ch="$char" '{if ($0==ch) exit; if (NR>1 || ch!="`") print $0}'|awk -v w=$wide -v ch="$char" 'BEGIN{UB64="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";if (ch=="`") {UB64="`";for(i=33;i<96;i++)UB64=sprintf("%s%c",UB64,i)}}{c=$0;gsub(/[^=]/,"",c);m=(ch=="`")?index(UB64,substr($0,1,1)):length()*3/4-length(c)+1;n=0;$0=substr($0,1+(ch=="`"));while(length()){split(substr($0,1,4),a,"");$0=substr($0,5);t=0;for(i=3;i>=0;i--) t=t+2^(6*i)*((a[4-i]==ch)?0:index(UB64,a[4-i])-1);for (i=2;i>=0;i--) if (++n<m){printf("\\x%x",t/2^(8*i));t=t%2^(8*i)}}printf"\n"}');do printf "$buff"; done
}
BASE_DIR=$(cd "$(dirname "$0")" && pwd)
PROGNAME=$(basename "$0")
AUTHOR_MAIL="robin.hoo@hotmail.com"
DECODE=0
HELP=0
FNAME=""
MODE="="
WIDE=76
while [ $# -gt 0 ]
do
    case "$1" in
    (-d)    DECODE=1;;
    (-h)    HELP=1;;
    (-b)    MODE="=" && WIDE=76;;
    (-u)    MODE="\`" && WIDE=60;;
    (--uucode)  MODE="\`" && WIDE=60;;
    (--base64)  MODE="=" && WIDE=76;;
    (--decode)  DECODE=1;;
    (--help)    HELP=1;;
    (-*)    echo "$PROGNAME: error - unrecognized option or parameter $1" 1>&2; HELP=1;break;;
    (*)     [ "$FNAME" != "" ] && echo "$PROGNAME: error - more than one file name " 1>&2 && HELP=1 && break || FNAME="$1";;
    esac
    shift
done
[ $# -gt 1 ] && HELP=1
[ "$FNAME" == "" ] && FNAME="/dev/stdin"
[ $HELP -eq 1 ] && help_usage
[ $DECODE -eq 1 ] && DECODE $WIDE $MODE || ENCODE $WIDE $MODE 

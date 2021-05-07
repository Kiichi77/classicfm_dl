#!/bin/bash
PROG=`basename $0`
EPS=$1

Get_Dist_Name()
{
    if grep -Eqi "CentOS" /etc/issue || grep -Eq "CentOS" /etc/*-release || grep -Eq "Red Hat" /etc/*-release; then
        release='RHEL'
        PM='yum'
    elif grep -Eqi "Debian" /etc/issue || grep -Eq "Debian" /etc/*-release; then
        release='Debian'
        PM='apt'
    elif grep -Eqi "Ubuntu" /etc/issue || grep -Eq "Ubuntu" /etc/*-release; then
        release='Ubuntu'
        PM='apt'
    else
        release='unknow'
    fi
    
}

#Start from here



if [[ -f out.html ]]; then
    rm -f out.html
fi
curl https://www.globalplayer.com/catchup/classicfm/uk/46wcDMX/ > out.html
if [[ -f out.json ]]; then
    rm -f out.json
fi
if ! command -v jq &> /dev/null; then
    echo "jq is not installed, going to download jq"
    curl -O -sSL https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64
    mv jq-linux64 jq
    chmod +x jq
else
    echo "We have jq, moving on."
fi

cat out.html | awk -F'<script id="__NEXT_DATA__" type="application/json">' '{ print $2 }'| awk -F'</script>' '{ print $1 }'| awk 'NF'| ./jq '.props.pageProps.catchupInfo.episodes[] '> out.json

DATA=$(cat out.json)

if [[ -f startDate.txt ]]; then
    rm -f startDate.txt
fi
if [[ -f date.txt ]]; then
    rm -f date.txt
fi

#cat out.json | jq '.startDate' | cut -d'T' -f 1 > startDate.txt

for row in $(echo "${DATA}" | jq -r '. | @base64'); do
    _jq(){
        echo ${row} | base64 --decode | jq -r ${1}
    }
    echo $(_jq '.startDate')
done | cut -d'T' -f 1 > startDate.txt

while read line; do
    date -d "$line+1day" +%Y-%m-%d
done < startDate.txt > date.txt


if [[ -f streamUrl.txt ]]; then
    rm -f streamUrl.txt
fi

for row in $(echo "${DATA}" | jq -r '. | @base64'); do
    _jq(){
        echo ${row} | base64 --decode | jq -r ${1}
    }
    echo $(_jq '.streamUrl')
done > streamUrl.txt


if [[ -f description.txt ]]; then
    rm -f description.txt
fi

for row in $(echo "${DATA}" | jq -r '. | @base64'); do
    _jq(){
        echo ${row} | base64 --decode | jq -r ${1}
    }
    echo $(_jq '.description')
done | sed s/\"//g > description.txt

if ! command -v ffmpeg &> /dev/null; then
    echo "ffmpeg is not installed, going to download ffmpeg"
    rm -rf ffmpeg*
    curl -O -sSL https://johnvansickle.com/ffmpeg/releases/ffmpeg-release-amd64-static.tar.xz
    tar xf ffmpeg-release-amd64-static.tar.xz
else
    echo "We have ffmpeg, moving on."
fi

if [ $# -eq 0 ]; then
    echo "Going to download all available."
    TIMES=$(cat date.txt | wc -l)
else
    echo "Going to download last $EPS day(s)"
    TIMES=$EPS
fi
echo "Total: $TIMES"
for (( i=1; i<=$TIMES; i++)); do
    FILENAME=$(awk "NR==$i" date.txt)
    echo "Downloading $FILENAME"
    COMMENT=$(awk "NR==$i" description.txt)
    URL=$(awk "NR==$i" streamUrl.txt)
    curl -o $FILENAME.m4 -sSL $URL
    ffmpeg*/ffmpeg  -i $FILENAME.m4 -metadata comment="$COMMENT" -c copy $FILENAME.m4a
    rm -f $FILENAME.m4
done

ls -la *.m4a
rm -f date.txt description.txt streamUrl.txt

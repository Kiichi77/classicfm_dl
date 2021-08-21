#!/bin/bash
curYear=$(date "+%Y")
curMonth=$(date "+%m")
minSizeK=10

for country in "ar-XA" "bg-BG" "cs-CZ" "da-DK" "de-AT" "de-CH" "de-DE" "el-GR" "en-AU" "en-CA" "en-GB" "en-ID" "en-IE" "en-IN" "en-MY" "en-NZ" "en-PH" "en-SG" "en-US" "en-XA" "en-ZA" "es-AR" "es-CL" "es-ES" "es-MX" "es-US" "es-XL" "et-EE" "fi-FI" "fr-BE" "fr-CA" "fr-CH" "fr-FR" "he-IL" "hr-HR" "hu-HU" "it-IT" "ja-JP" "ko-KR" "lt-LT" "lv-LV" "nb-NO" "nl-BE" "nl-NL" "pl-PL" "pt-BR" "pt-PT" "ro-RO" "ru-RU" "sk-SK" "sl-SL" "sv-SE" "th-TH" "tr-TR" "uk-UA" "zh-CN" "zh-HK" "zh-TW" "ROW"; do
    echo "Working on $country..."
    url="http://www.bing.com/HPImageArchive.aspx?format=js&idx=0&n=1&mkt=$country"
     
    geturl=$(curl -sSL $url\
      -H 'authority: www.bing.com' \
      -H 'sec-ch-ua: "Chromium";v="92", " Not A;Brand";v="99", "Google Chrome";v="92"' \
      -H 'sec-ch-ua-mobile: ?0' \
      -H 'sec-ch-ua-full-version: "92.0.4515.159"' \
      -H 'sec-ch-ua-arch: "x86"' \
      -H 'sec-ch-ua-platform: "Windows"' \
      -H 'sec-ch-ua-platform-version: "10.0"' \
      -H 'sec-ch-ua-model: ""' \
      -H 'dnt: 1' \
      -H 'upgrade-insecure-requests: 1' \
      -H 'user-agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/92.0.4515.159 Safari/537.36' \
      -H 'accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9' \
      -H 'sec-fetch-site: none' \
      -H 'sec-fetch-mode: navigate' \
      -H 'sec-fetch-user: ?1' \
      -H 'sec-fetch-dest: document' \
      -H 'accept-language: en-US,en;q=0.9,zh-TW;q=0.8,zh;q=0.7,zh-CN;q=0.6' \
      --compressed | jq .images[].urlbase | sed s/\"//g)
    #echo I got $geturl
    filename=$(echo $geturl | awk -F'[.]' '{print $2}')
    checkname=$(echo $filename | awk -F'[_]' '{print $1}')
    #echo Checkname is $checkname
    
    # Normal resolution
    # Check if directory exist
    if [ ! -d /var/www/html/webdav/BingImages/$curYear/$curMonth ]
    then
        mkdir -p /var/www/html/webdav/BingImages/$curYear/$curMonth
        
    #else
        #echo directory existed.
    fi
    # Check if the same picture exist
    CHECKRES=$(find /var/www/html/webdav/BingImages/$curYear/$curMonth -type f -name "$checkname*" | wc -l)
    if [[ $CHECKRES == 0 ]]
    then
        # Means there will be a new image
        # Set the URL and filename
        fullfilename="$filename""_1920x1200.jpg"
        realurl="http://bing.com$geturl""_1920x1200.jpg"
        #echo the filename to save is $fullfilename
        #echo the URL to download the image is $realurl
        #echo equal 0, no match files
        curl -sSL -o /var/www/html/webdav/BingImages/$curYear/$curMonth/$fullfilename  $realurl
        actualsize=$(du -k "/var/www/html/webdav/BingImages/$curYear/$curMonth/$fullfilename" | cut -f 1)
        if [ $actualsize -le $minSizeK ]
        then
            rm -f /var/www/html/webdav/BingImages/$curYear/$curMonth/$fullfilename
            fullfilename1080="$filename""_1920x1080.jpg"
            realurl1080="http://bing.com$geturl""_1920x1080.jpg"
            curl -sSL -o /var/www/html/webdav/BingImages/$curYear/$curMonth/$fullfilename1080  $realurl1080
            echo downloaded $fullfilename1080
        else
            echo downloaded $fullfilename
        fi
        
    else
        #echo not equal 0, there is at least 1 file with that pattern.
        echo File existed, skipping...
    fi
    # End of normal resolution
    
    
    # UHD resolution
    # Check if directory exist
    if [ ! -d /var/www/html/webdav/BingImagesUHD/$curYear/$curMonth ]
    then
        mkdir -p /var/www/html/webdav/BingImagesUHD/$curYear/$curMonth
        
    #else
        #echo directory existed.
    fi
    # Check if the same picture exist
    CHECKRES=$(find /var/www/html/webdav/BingImagesUHD/$curYear/$curMonth -type f -name "$checkname*" | wc -l)
    if [[ $CHECKRES == 0 ]]
    then
        # Means there will be a new image
        # Set the URL and filename
        fullfilename="$filename""_UHD.jpg"
        realurl="http://bing.com$geturl""_UHD.jpg"
        #echo the filename to save is $fullfilename
        #echo the URL to download the image is $realurl
        #echo equal 0, no match files
        curl -sSL -o /var/www/html/webdav/BingImagesUHD/$curYear/$curMonth/$fullfilename  $realurl
        actualsize=$(du -k "/var/www/html/webdav/BingImagesUHD/$curYear/$curMonth/$fullfilename" | cut -f 1)
        if [ $actualsize -le $minSizeK ]
        then
            rm -f /var/www/html/webdav/BingImages/$curYear/$curMonth/$fullfilename
        else
            echo downloaded $fullfilename
        fi
        
    else
        #echo not equal 0, there is at least 1 file with that pattern.
        echo File existed, skipping...
    fi
    
    # fix permission
    chown apache:apache -R /var/www/html/webdav/BingImagesUHD
    chown apache:apache -R /var/www/html/webdav/BingImages

done

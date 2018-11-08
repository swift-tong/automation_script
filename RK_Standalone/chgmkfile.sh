#/bin/sh
#when you try to insert the third party apk, suddenly you will happend to meet the unbelievable
#amount of ".so" file. to change the makefile by hand is unacceptalbe !!, so, toolize it. !!
#first object, change suying.mk

#source setenv.sh cu he
#still local append has some problem, but next time I will fix it !!!!!!!!
#accept so, then 
InsertSo() {
    local filename=$1
    local suyingmk=$2
    grep "#libs" $suyingmk
    if [ $? -ne 0 ];then 
        echo "Nothing to do , please check if #libs in suying.mk return"
        return $?
    fi
    #other wise, inset $1 under libCTC_MediaControl
    local number=`awk '/'"#libs"'/{print NR}' "$suyingmk"`
    local linenumber=`expr $number + 1`
    grep $filename $suyingmk
    if [ $? -eq 0 ]; then
        echo "the file $filename already exists, nothing to do"
        return 0
    fi
    #cannot only for cuhe
    #local append="        device\/rockchip\/rksdk\/IPTV\/IPTV_cuhe\/libs\/$filename:system\/lib\/$filename"
    if [ $inputlauncher = "nolauncher" ];then
        local vendorstr="IPTV_"$carrier$province
    else
        local vendorstr="IPTV_"$carrier$province"_"$inputlauncher
    fi
    local append="device\/rockchip\/rksdk\/IPTV\/$vendorstr\/libs\/$filename:system\/lib\/$filename"
    echo $append
    sed -i ''"$linenumber"'a\'"       $append \\\\"'' $suyingmk
}

InsertApk() {
    local filename=$1
    local suyingmk=$2
    grep "#apk" $suyingmk
    if [ $? -ne 0 ];then 
        echo "Nothing to do ,please check if #apk in suying.mk return"
        return $?
    fi
    #other wise, inset $1 under Setting
    grep -w "$filename " $suyingmk
    if [ $? -eq 0 ]; then
        echo "the file $filename already exists, nothing to do"
        return 0
    fi
    local number=`awk '/'"#apk"'/{print NR}' "$suyingmk"`
    local linenumber=`expr $number + 1`
    echo $linenumber
    local append="$filename"
    echo $append
    sed -i ''"$linenumber"'a\'"       $append \\\\"'' $suyingmk
}

InsertBin() {
    local filename=$1
    local suyingmk=$2
    grep  "#bin" $suyingmk
    if [ $? -ne 0 ];then 
        echo "Nothing to do ,please check if #bin in suying.mk return"
        exit 1
    fi
    #other wise, inset $1 under Setting
    grep $filename $suyingmk
    if [ $? -eq 0 ];then
        echo "the file $filename already exists, nothing to do"
        return 0
    fi
    local number=`awk '/'"#bin"'/{print NR}' "$suyingmk"`
    local linenumber=`expr $number + 1`
    if [ $inputlauncher = "nolauncher" ];then
        local vendorstr="IPTV_"$carrier$province
    else
        local vendorstr="IPTV_"$carrier$province"_"$inputlauncher
    fi
    local append="device\/rockchip\/rksdk\/IPTV\/$vendorstr\/bin\/$filename:system\/bin\/$filename"
    echo $append
    sed -i ''"$linenumber"'a\'"       $append \\\\"'' $suyingmk
}

InsertEtc() {
    local filename=$1
    local suyingmk=$2
    grep  "#bin" $suyingmk
    if [ $? -ne 0 ];then 
        echo "Nothing to do ,please check if sy_tr069 in suying.mk return"
        exit 1
    fi
    #other wise, inset $1 under Setting
    grep $filename $suyingmk
    if [ $? -eq 0 ];then
        echo "the file $filename already exists, nothing to do"
        return 0
    fi
    local number=`awk '/'"#bin"'/{print NR}' "$suyingmk"`
    local linenumber=`expr $number + 1`
    if [ $inputlauncher = "nolauncher" ];then
        local vendorstr="IPTV_"$carrier$province
    else
        local vendorstr="IPTV_"$carrier$province"_"$inputlauncher
    fi
    local append="device\/rockchip\/rksdk\/IPTV\/$vendorstr\/etc\/$filename:system\/etc\/$filename"
    echo $append
    sed -i ''"$linenumber"'a\'"       $append \\\\"'' $suyingmk
}

InsertAllSo() {
    local libsdir=$1
    cd $libsdir
    local suyingmk=$2
    for names in $(find . -type f); 
    do
        if [[ $names == *.so ]]; then
        #echo "extracted file name is: $names"
        #try to insert the filename.so to suying.mk
            local localfilename=`basename "$names"`
            echo "localfilename is $localfilename"
            local tobechange="../suying.mk"
            InsertSo $localfilename $tobechange
        fi
    done
}

InserAllApk() {
    local apkdir=$1
    local suyingmk=$2
    cd $apkdir
    for names in $(find . -maxdepth 1 -type f); 
    do
        if [[ $names == *.apk ]]; then
        #echo "extracted file name is: $names"
        #try to insert the filename.so to suying.mk
            local fullpathfilename=$(readlink -f "$names")
            local localfilename=$(basename "$fullpathfilename")
            local localfileprefix=$(basename  "$localfilename" ".apk")
            echo "localfileprefix is $localfileprefix"
            local tobechange=$suyingmk
            InsertApk $localfileprefix $tobechange
        fi
    done
}

InsertAllBin() {
    local miscdir=$1
    local suyingmk=$2
    cd $miscdir
    for names in $(find . -type f); 
    do
        local fullpathfilename=$(readlink -f "$names")
        local localfilename=$(basename "$fullpathfilename")
        local tobechange=$suyingmk
        InsertBin $localfilename $tobechange
    done
}

InsertAllEtc() {
    local miscdir=$1
    local suyingmk=$2
    cd $miscdir
    for names in $(find . -type f); 
    do
        local fullpathfilename=$(readlink -f "$names")
        local localfilename=$(basename "$fullpathfilename")
        local tobechange=$suyingmk
        InsertEtc $localfilename $tobechange
    done
}
#InserAllApk
#####################add apk name in Android.mk##################
checkAndroidmk(){
     local apknamedir=$1
	 echo "addAndroid shell already running"
     echo "$apknamedir"
     cd "$apknamedir"
     #app_num=$(find $iptv -name "*.apk" |wc -l)
     #echo "app_num is $app_num"
     local FILE="$HOME/build/input/common/android.mk"
     if [ $inputlauncher = "nolauncher" ];then
	     local bb="$carrier$province"
	     local target="$HOME/workspace/device/rockchip/rksdk/IPTV/IPTV_$carrier$province"
     else
	     local bb=$carrier$province"_"$inputlauncher
	     local target="$HOME/workspace/device/rockchip/rksdk/IPTV/IPTV_"$carrier$province"_"$inputlauncher
     fi
	 local inum
	 local replace
	 if [ -f "$FILE" ]; then
        echo "File $FILE exist."
		echo "copy android.mk to code area"
		cp $FILE $target
     else
        echo "File $FILE does not exist,Please check $FILE" 
		return 1
     fi
     #cal IPTV_$carrier$province line"
	 num=$(sed -n '/IPTV_'"$bb"'/=' Android.mk)
	 let num=num+1
	 echo $num
	 inum="${num}r"
	 ###################################
     for name in `ls *.apk`
       do
       echo "name is $name"
       filename=${name%.*}
       echo "filename is $filename"
       grep -rw $filename Android.mk
       if [ $? -ne 0 ]; then
	    replace=$(grep -wr LOCAL_MODULE android.mk | grep -v LOCAL_SRC_FILES)
		echo $replace
		replace="LOCAL_MODULE := $filename"
		sed -i 's/^.*LOCAL_MODULE :.*$/'"$replace"'/' android.mk
        echo "$filename app module will be added"
		sed -i "$inum"<(sed -e '1,10!d' android.mk) Android.mk
       else
        echo "$filename app module already existed in Android.mk"
       fi
        done
        echo "addAndroid function running over"
		rm android.mk
        }

#####################add apk name in Android.mk##################

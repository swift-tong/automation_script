#/bin/sh


InitSubDir () {
    mkdir -p $tmp
    mkdir -p $apk
    mkdir -p $libs
    mkdir -p $bin
    mkdir -p $etc
    mkdir -p $rar
    mkdir -p $image
    mkdir -p $ota
    mkdir -p $third
    mkdir -p "$ota/target"
    mkdir -p "$ota/full"
}

ClearSubDir () {
    rm -rf $tmp
    rm -rf $apk
    rm -rf $libs
    rm -rf $bin
    rm -rf $etc
    rm -rf $rar
    rm -rf $third
    #rm -rf $image
}

#the logic behind it is very simple, recursively unpack the unpacked files which are of 
#type 'rar', 'zip', 'apk' !!!!
checkPackFile() {
    local filename=$1
    if [[ $filename == *.zip ]] || [[ $filename == *.apk ]] ; then
        echo "the file is O.K "
        return 0
    fi
    #echo "the file is not O.K "
    return 1
}

#Unpack any types of 'apk', 'rar' or 'zip'. if apk, then will not unpack it recursively
Unpack () {
    echo "accept the input parameter must be of type rar, zip, apk "
    local inputfilename=$1
    echo "Input file name is $inputfilename"
    local fullpathfilename=$(readlink -f "$inputfilename")
    echo "fullpathfilename is $fullpathfilename"
    local fullpath=$(dirname "$fullpathfilename")
    echo "fullpath is $fullpath"
    local localfilename=$(basename "$fullpathfilename")
    echo "localfilename is $localfilename"
    
    if [[ $inputfilename == *.zip ]]; then
        local localfileprefix=$(basename  "$localfilename" ".zip")
        echo "local file prefix is $localfileprefix"
        unzip -d $localfileprefix $inputfilename
        local nextpath="$fullpath/$localfileprefix"
        echo "next path is $nextpath"
        #cd $lcoalfileprefix
        cd $nextpath
        echo "current path is `pwd`"
        for names in $(find . -type f); 
        do
            echo "extracted file name is: $names"
            checkPackFile $names
            if [ $? -eq 0 ] ; then
                Unpack $names
            fi
        done      
        cd $fullpath
    elif [[ $inputfilename == *.rar ]]; then
        localfileprefix=$(basename  "$localfilename" ".rar")
        echo "local file prefix is $localfileprefix"
        mkdir -p $localfileprefix
        unrar x $inputfilename $localfileprefix
        local nextpath="$fullpath/$localfileprefix"
        echo "next path is $nextpath"
        #cd $lcoalfileprefix
        cd $nextpath
        echo "current path is `pwd`"
        for names in $(find . -type f); 
        do
            echo "extracted file name is: $names"
            checkPackFile $names
            if [ $? -eq 0 ] ; then
                Unpack $names
            fi
        done      
        cd $fullpath
        localfileprefix=$(basename  "$localfilename" ".rar")
        echo "local file prefix is $localfileprefix"
    # As for APK we don't unpack to next level      
    elif [[ $inputfilename == *.apk ]]; then
        localfileprefix=$(basename  "$localfilename" ".apk")
        echo "local file prefix is $localfileprefix"
        unzip -d $localfileprefix $inputfilename
    else
        echo "the inut type cannot be recognised !!!"
        return 1
    fi
}

RawCopy () {
    find "$tmp" -name *.so -exec cp {} "$libs"  \;
    find "$tmp" -name *.apk -exec cp {} "$apk"  \;
    find "$tmp" -name syConfig.conf -exec cp {} "$etc"  \;
    find "$tmp" -name syConfig.xml -exec cp {} "$etc"  \;
	cp $(find "$tmp" -name 'sy_tr069' | grep -v -i 'iptv') "$bin"
	cp $(find "$tmp" -name 'sy_tracert' | grep -v -i 'iptv') "$bin"
    find "$tmp" -name 'dhcpcd' -exec cp {} "$bin"  \;
    find "$tmp" -name 'ItvServ' -exec cp {} "$bin"  \;
    find "$tmp" -name 'IptvService' -exec cp {} "$bin"  \;
    find "$tmp" -name 'amtprox' -exec cp {} "$bin"  \;
}


ApkSign () {
    local SignApkJar="$WP/out/host/linux-x86/framework/signapk.jar"
    local x509pem="$WP/build/target/product/security/platform.x509.pem"
    local platformpk8="$WP/build/target/product/security/platform.pk8"
    local apkfile=$1   #old names
    local tmpapk="$apk/tmp.apk"
    mv $apkfile $tmpapk
    java -jar $SignApkJar $x509pem $platformpk8 $tmpapk $apkfile
}

HandleMisc () {
    cd $bin
    mv ItvServ IptvServ
    chmod 777 *
    cd $libs
    chmod 777 *
}

FormaliseIptvApk () {
    echo "++++ FormaliseIptvApk now !!!!!"
    local filename="$1"
    local target="IPTV.apk"
    echo "try to formalise Iptv APK"
    #first case
    SubstrMatch $filename "_IPTV_EPG"
    if [ $? -eq 0 ]; then
        echo "formailise it to IPTV.apk +1 "
        mv $filename $target
        return 0
    else
        echo "not match _iptv_epg"
    fi
	
    SubstrMatch $filename "IPTV"
    if [ $? -eq 0 ]; then
        echo "formailise it to IPTV.apk +1 "
        mv $filename $target
        return 0
    else
        echo "not match _iptv_epg"
    fi
    #second case
    SubstrMatch2 $filename "_IPTV_" "Setting"
    if [ $? -eq 0 ]; then
        echo "$filename" |grep -v "NOLOG"
        if [ $? -eq 0 ]; then
            echo "formailise it to IPTV.apk +2"
            mv $filename $target
            return 0
        fi
    else
        echo "not match _iptv_ -v Setting"
    fi    
    #special case for ctha with Log version
    #SubstrMatch1 $filename "IPTVEPG" -v "NOLOG"
    echo "Apk file name is $filename"
#   note: !!!! -IPTVEPG- not accpeted !!!!!
    SubstrMatch2 $filename "IPTVEPG" "Setting"
    if [ $? -eq 0 ]; then
        echo "formailise it to IPTV.apk +3 "
        mv $filename $target
        return 0
    fi
    #grep IPTV $filename |grep -v Setting |grep -v NOLOG
    #echo $filename |grep IPTV |grep -v Setting |grep -v NOLOG
    #if [ $? -eq 0 ]; then
    #    echo "formailise it to IPTV.apk +4"
    #    mv $filename $target
    #    return 0
    #fi    
    return 1
}

#   grep -i can ignore the upper/lower case difference
FormaliseSettingApk () {
    echo "++++ FormaliseSettingApk now !!!!!"
    local filename="$1"
    local target="ItvSetting.apk"
    SubstrMatch $filename "_IPTV_Setting"
    if [ $? -eq 0 ]; then 
        echo "formailise it to ItvSetting.apk"
        target="ItvSetting.apk"
        mv $filename $target
        return 0
    fi
	
    SubstrMatch $filename "ItvSetting"
    if [ $? -eq 0 ]; then 
        echo "formailise it to ItvSetting.apk"
        target="ItvSetting.apk"
        mv $filename $target
        return 0
    fi
    SubstrMatch $filename "IPTVSetting"
    if [ $? -eq 0 ]; then 
        echo "formailise it to ItvSetting.apk"
        target="ItvSetting.apk"
        mv $filename $target
        return 0
    fi
#	Liu xiaocheng add begin
	echo "$filename" | grep -i "setting"
    if [ $? -eq 0 ]; then 
        echo "formailise it to ItvSetting.apk"
        target="ItvSetting.apk"
        mv $filename $target
        return 0
    fi	
#	Liu xiaocheng add end
    return 1
}

FormaliseUpgradeApk() {
    echo "++++ FormaliseUpgradeApk now"
    local filename="$1"
    local target="UpgradeManager.apk"
    SubstrMatch $filename "UPGRADE"
    if [ $? -eq 0 ]; then 
        echo "formailise it to UpgradeManager.apk"
        mv $filename $target
        return 0
    fi
	
    SubstrMatch $filename "UpgradeManager"
    if [ $? -eq 0 ]; then 
        echo "formailise it to UpgradeManager.apk"
        mv $filename $target
        return 0
    fi
    SubstrMatch $filename "Upgrade"
    if [ $? -eq 0 ]; then 
        echo "formailise it to UpgradeManager.apk"
        mv $filename $target
        return 0
    fi
    return 1
}

FormaliseGameApk() {
    echo "++++ FormaliseGameApk now"
    local filename="$1"
    local target="Jvm.apk"
    SubstrMatch $filename "JVM"
    if [ $? -eq 0 ]; then 
        echo "formailise it to Jvm.apk"
        mv $filename $target
        return 0
    fi
    SubstrMatch $filename "ItvGame"
    if [ $? -eq 0 ]; then 
        echo "formailise it to Jvm.apk"
        mv $filename $target
        return 0
    fi  
    return 1
}

FormaliseBootSetupWizard() {
    echo "++++ FormaliseBootSetupWizard now"
    local filename="$1"
    local target="BootSetupwizard.apk"
    SubstrMatch $filename "BootSetupwizard"
    if [ $? -eq 0 ]; then 
        echo "formailise it to BootSetupwizard.apk"
        target="BootSetupwizard.apk"
        mv $filename $target
        return 0
    fi
    return 1
}
#####################liu xiaochen##################
FormaliseLauncher() {
    echo "++++ FormaliseLauncher now"
    local filename="$1"
    local target="Launcher.apk"
    SubstrMatch $filename "Launcher"
    if [ $? -eq 0 ]; then 
        echo "formailise it to Launcher.apk"
        target="Launcher.apk"
        mv $filename $target
        return 0
    fi
    return 1
}

FormaliseSharedDataApk()
{
	echo "++++ FormaliseSharedData now"
    local filename="$1"
    local target="SharedData.apk"
    SubstrMatch $filename "SharedDataProvider"
    if [ $? -eq 0 ]; then 
        echo "formailise it to SharedData.apk"
        target="SharedData.apk"
        mv $filename $target
        return 0
    fi
    return 1
}

FormaliseAIDLServiceApk()
{
	echo "++++ FormaliseAIDLService now"
    local filename="$1"
    local target="AIDLService.apk"
    SubstrMatch $filename "StartService"
    if [ $? -eq 0 ]; then 
        echo "formailise it to AIDLService.apk"
        target="AIDLService.apk"
        mv $filename $target
        return 0
    fi
    return 1

}

FormaliseSTBManagerApk()
{
	echo "++++ FormaliseSTBManager now"
    local filename="$1"
    local target="STBManager.apk"
    SubstrMatch $filename "STBManager"
    if [ $? -eq 0 ]; then 
        echo "formailise it to STBManager.apk"
        target="STBManager.apk"
        mv $filename $target
        return 0
    fi
    return 1
}

FormaliseZeroConfigApk()
{
	echo "++++ FormaliseZeroConfig now"
    local filename="$1"
    local target="ZeroConfig.apk"
    SubstrMatch $filename "ZeroConfig"
    if [ $? -eq 0 ]; then 
        echo "formailise it to ZeroConfig.apk"
        target="ZeroConfig.apk"
        mv $filename $target
        return 0
    fi
    return 1
}

FormaliseTr069ServiceApk()
{
	echo "++++ FormaliseZeroConfig now"
    local filename="$1"
    local target="tr069Service.apk"
    SubstrMatch $filename "tr069Service"
    if [ $? -eq 0 ]; then 
        echo "formailise it to tr069Service.apk"
        target="tr069Service.apk"
        mv $filename $target
        return 0
    fi
    return 1
}

###################wu kaili #######################


FormaliseSingleApk() {
    local filename="$1"
    FormaliseIptvApk $filename
    if [ $? -eq 0 ]; then return 0 ; fi
    FormaliseSettingApk $filename
    if [ $? -eq 0 ]; then return 0 ; fi
    FormaliseUpgradeApk $filename
    if [ $? -eq 0 ]; then return 0 ; fi
    FormaliseGameApk $filename
    if [ $? -eq 0 ]; then return 0 ; fi
    FormaliseBootSetupWizard $filename
	if [ $? -eq 0 ]; then return 0 ; fi
    ################liu xiaochen ###########
	FormaliseLauncher $filename
    if [ $? -eq 0 ]; then return 0 ; fi
	################wu kaili ###########
	FormaliseSharedDataApk $filename
	if [ $? -eq 0 ]; then return 0 ; fi
	FormaliseAIDLServiceApk $filename
	if [ $? -eq 0 ]; then return 0 ; fi
	FormaliseSTBManagerApk $filename
	if [ $? -eq 0 ]; then return 0 ; fi
	FormaliseZeroConfigApk $filename
	if [ $? -eq 0 ]; then return 0 ; fi
	FormaliseTr069ServiceApk $filename
	if [ $? -eq 0 ]; then return 0 ; fi
	################end#####################
    return 1
}

FormaliseApk () {
    cd $apk
    for names in $(find . -type f); 
    do
        echo "extracted file name is: $names"
        FormaliseSingleApk $names
        if [ $? -eq 0 ]; then 
            echo "to be signed apk file name is: $names"
            #ApkSign $names
        else    
            rm $names
        fi        
    done
}

ApkSignAll() {
    cd $apk
    for names in $(find . -type f); 
    do
        echo "to be signed file name is: $names"
        ApkSign $names        
    done
    rm "tmp.apk"    
}

Formalise () {
    ApkSignAll
    HandleMisc
}
RecordMd5sum() {
    TXT="${vendorpath}/middleware_checksum.txt"
    declare num=1
    #record apk
    cd $apk
    for file in ./*
    do
        test -f "$file" || continue
        echo -n ${num}'->'${file:2}"    md5:" >> $TXT
        let "num++"
        md5sum $file | awk '{print $1}' >> $TXT
    done
    #record bin
    cd $bin
    for file in ./*
    do
        test -f "$file" || continue
        echo -n ${num}'->'${file:2}"    md5:" >> $TXT
        let "num++"
        md5sum $file | awk '{print $1}' >> $TXT
    done
    #record etc
    cd $etc
    for file in ./*
    do
        test -f "$file" || continue
        echo -n ${num}'->'${file:2}"    md5:" >> $TXT
        let "num++"
        md5sum $file | awk '{print $1}' >> $TXT
    done
    echo '****************************************************************' >> $TXT 
    
}
PrepareFile() {
    ClearSubDir
    InitSubDir
#Pre-handle related zip file and extract it to related directory
    if [ $1 = "" ]; then
        echo "Please input zip/rar file name"
        return 1
    fi
    cp $1 $tmp
    cd $tmp
    Unpack $1
    RawCopy
    RecordMd5sum
    Formalise
    RecordMd5sum
    mv $TXT $image
}

#first copy, then apk sign
HandleThird () {
    local inputfilename=$1
    echo "inputfilename is $inputfilename"
    find "$third" -name *.so -exec cp {} "$libs"  \;
    local filename=$(basename "$inputfilename")
    echo "++++ HandleThird local filename is : $filename"
    #local fileprefix=$(basename ".rar")
    local fileprefix=$(basename  "$filename" ".rar")
    echo "++++ HandleThird local file prefix is : $fileprefix"
    #find "$third" -name *.apk -exec cp {} "$apk"  \;
	
    find "$third" -name syConfig.conf -exec cp {} "$etc"  \;
    find "$third" -name 'amtprox' -exec cp {} "$bin"  \;

    cd "$third/$fileprefix"
    find . -name *.so -exec cp {} "$libs" \;
    cp *.apk $apk
    #cp "$third/*.apk" $apk
    cd $apk
    for names in $(find . -type f); 
    do
        echo "to be signed apk file name is: $names"
        ApkSign $names
    done
#   add for pre-signed apk
    local slash="/"
    local signed="signed"
    local signedarc="$third$slash$fileprefix$slash$signed"
    echo "++++++ signedarc is $signedarc"
    cd $signedarc
    echo `pwd`
    cp *.apk $apk
    if [ -f $apk/tmp.apk ]
    then
        rm $apk/tmp.apk
    fi
    ls -lat
}

PrepareThird () {
    ClearSubDir
    InitSubDir
    #Pre-handle related zip file and extract it to related directory
    if [ $1 = "" ]; then
        echo "Please input rar file name, only rar file is allowed"
        return 1
    fi
    cp $1 $third
    cd $third
    pwd
    local ifilename=$1
    Unpack $1
    HandleThird $ifilename
}

HandleApk(){
    vendorpath="$HOME/build/input/zy/$carrier$province"
    cd $vendorpath
	
    handle_apk_ret=$(python handleInput.py  "$buildtype" "$carrier$province" "$inputlauncher")    
    if [ "$handle_apk_ret" == "False" ];then
        echo "handle_apk_ret return false!! prepare.sh line 581"
        exit
    fi

}

Copyfile () {
    cd $iptv
    echo "Copy related prepared files begins"
    cd "$libs"
    chmod +777 *.so
    HandleApk
    local apkfile="$apk/*.apk"
    #echo $apkfile
    cp $apkfile $iptv
    local libsfile="$libs/*.so"
    cp $libsfile $iptvlibs
    local binfile="$bin/*"
    cp $binfile $iptvbin
    local etcfile="$etc/sy*"
    cp $etcfile $iptvetc
    echo "Copy related prepared files ends"
    source chgmkfile.sh
    echo "Automatic change the suying.mk for the new APK !!!!!!"
    InserAllApk $iptv "$iptv/suying.mk"
    echo "Automatic change the suying.mk for the new so !!!!!!!"
    InsertAllSo $iptvlibs "$iptv/suying.mk"
    echo "Automatic change the suying.mk for the new misc file !!!!!!!"
    InsertAllBin $iptvbin "$iptv/suying.mk"
    InsertAllEtc $iptvetc "$iptv/suying.mk"
    echo "Automatic change the Android.mk for the new APK !!!!!!"
    checkAndroidmk $iptv 
}




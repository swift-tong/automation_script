#/bin/sh


InitSubDir () {
    mkdir -p $tmp
    mkdir -p $apk
    mkdir -p $libs
	mkdir -p $bin
	mkdir -p $etc

}

ClearSubDir () {
    rm -rf $tmp
    rm -rf $apk
    rm -rf $libs
	rm -rf $bin
	rm -rf $etc
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
	#cp $(find "$tmp" -name 'sy_capture' | grep -v -i 'iptv') "$bin"
	#cp $(find "$tmp" -name 'sy_tr069' | grep -v -i 'iptv') "$bin"
	#cp $(find "$tmp" -name 'sy_tracert' | grep -v -i 'iptv') "$bin"
    find "$tmp" -name 'dhcpcd' -exec cp {} "$bin"  \;
    find "$tmp" -name 'ItvServ' -exec cp {} "$bin"  \;
	find "$tmp" -name 'IptvService' -exec cp {} "$bin"  \;
    find "$tmp" -name 'amtprox' -exec cp {} "$bin"  \;
	find "$tmp" -name 'sy_tr069' -exec cp {} "$bin"  \;
	find "$tmp" -name 'sy_tracert' -exec cp {} "$bin"  \;
	find "$tmp" -name 'sy_capture' -exec cp {} "$bin"  \;
	
	
	cd $bin
    chmod 777 *
    cd $libs
    chmod 777 *
	cd $apk
    chmod 777 *
	cd $etc
    chmod 777 *
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

ApkSignAll() {
    cd $apk
    for names in $(find . -type f); 
    do
        echo "to be signed file name is: $names"
        ApkSign $names        
    done
    rm "tmp.apk"    
	echo "apksign is completed!"
}

InsertSo() {
    local libname=$1
    local carriermk=$2
    grep hotkey.properties $carriermk
    if [ $? -ne 0 ];then 
        echo "Nothing to do , return"
        return $?
    fi
    #other wise, inset $1 under libCTC_MediaControl

    grep $libname $carriermk
    if [ $? -eq 0 ]; then
        echo "the file $libname already exists, nothing to do"
        return 0
    fi
	
	#for cuhl chuq ctsh and cmsh
	if [ $carrier$province = "cuhl" ] ;then
		local append="    device\/amlogic\/common\/$common_APKS\/$carrier_apks\/$launcher\/$libname:system\/lib\/$libname"
		if [ $launcher = "huawei" ] ;then
			sed -i '/CUHL_IPTV_HOME_HW.apk/a \'"$append \\\\"'' "$carriermk"
		elif [ $launcher = "fenghuo" ] ;then
			sed -i '/CUHL_IPTV_NOHOME_FH/a \'"$append \\\\"'' "$carriermk"
		fi
	elif [ $carrier$province = "cujc" ] ;then
		local append="    device\/amlogic\/common\/$common_APKS\/BJ_jicai_apks\/SY\/$libname:system\/lib\/$libname"
		sed -i '/hotkey.properties/a \'"$append \\\\"'' "$carriermk"
	elif [ $carrier$province = "ctjc" ] ;then
		echo "china telecom_jicai don't insert libs"
	elif [ $carrier$province = "cthq" ] ;then
		echo "china telecom_jicai don't insert libs"
	elif [ $carrier$province = "cmsh" ] ;then
		local append="    device\/amlogic\/common\/$common_APKS\/sh\/$libname:system\/lib\/$libname"
		sed -i '/hotkey.properties/a \'"$append \\\\"'' "$carriermk"
	else
		local append="    device\/amlogic\/common\/$common_APKS\/$carrier_apks\/$libname:system\/lib\/$libname"
		sed -i '/hotkey.properties/i \'"$append \\\\"'' "$carriermk"
	fi

}

InsertApk() {
    local apkname=$1
    local carriermk=$2
    grep hotkey.properties $carriermk
    if [ $? -ne 0 ];then 
        echo "Nothing to do , return"
        return $?
    fi
    #other wise, inset $1 under Setting
    grep $apkname $carriermk
    if [ $? -eq 0 ]; then
        echo "the file $filename already exists, nothing to do"
        return 0
    fi
	
	#for cuhl chuq ctsh and cmsh
	if [ $carrier$province = "cuhl" ] ;then
		local append="    device\/amlogic\/common\/$common_APKS\/$carrier_apks\/$launcher\/$apkname:system\/app\/$apkname"
		if [ $launcher = "huawei" ] ;then
			sed -i '/CUHL_IPTV_HOME_HW.apk/a \'"$append \\\\"'' "$carriermk"
		elif [ $launcher = "fenghuo" ] ;then
			sed -i '/CUHL_IPTV_NOHOME_FH/a \'"$append \\\\"'' "$carriermk"
		fi
	elif [ $carrier$province = "cujc" ] ;then
		local append="    device\/amlogic\/common\/$common_APKS\/BJ_jicai_apks\/SY\/$apkname:system\/app\/$apkname"
		sed -i '/hotkey.properties/a \'"$append \\\\"'' "$carriermk"
	elif [ $carrier$province = "cthq" ] ;then
		#local append="    device\/amlogic\/common\/$common_APKS\/BJ_jicai_apks\/SY\/$apkname:system\/app\/$apkname"
		#sed -i '/hotkey.properties/a \'"$append \\\\"'' "$carriermk"
        echo "Do nothing!"
	elif [ $carrier$province = "ctjc" ] ;then
		echo "china telecom_jicai don't insert apks"
	elif [ $carrier$province = "cmsh" ] ;then
		local append="    device\/amlogic\/common\/$common_APKS\/sh\/$apkname:system\/app\/$apkname"
		sed -i '/hotkey.properties/a \'"$append \\\\"'' "$carriermk"
	else
		local append="    device\/amlogic\/common\/$common_APKS\/$carrier_apks\/$apkname:system\/app\/$apkname"
		sed -i '/hotkey.properties/i \'"$append \\\\"'' "$carriermk"
	fi
	
    echo $append
	
	
}

InsertBin() {
    local binname=$1
    local carriermk=$2
    grep  hotkey.properties $carriermk
    if [ $? -ne 0 ];then 
        echo "Nothing to do ,please check if hotkey.properties in $binname return"
        exit 1
    fi
    #other wise, inset $1 under Setting
    grep $binname $carriermk
    if [ $? -eq 0 ];then
        echo "the file $binname already exists, nothing to do"
        return 0
    fi
	
	#for cuhl chuq ctsh and cmsh
	if [ $carrier$province = "cuhl" ] ;then
		local append="    device\/amlogic\/common\/$common_APKS\/$carrier_apks\/$launcher\/$binname:system\/bin\/$binname"
		if [ $launcher = "huawei" ] ;then
			sed -i '/CUHL_IPTV_HOME_HW.apk/a \'"$append \\\\"'' "$carriermk"
		elif [ $launcher = "fenghuo" ] ;then
			sed -i '/CUHL_IPTV_NOHOME_FH/a \'"$append \\\\"'' "$carriermk"
		fi
	elif [ $carrier$province = "cujc" ] ;then
		local append="    device\/amlogic\/common\/$common_APKS\/BJ_jicai_apks\/SY\/$binname:system\/bin\/$binname"
		sed -i '/hotkey.properties/a \'"$append \\\\"'' "$carriermk"
	elif [ $carrier$province = "ctjc" ] ;then
		local append="    device\/amlogic\/common\/$common_APKS\/SH_jicai_apks\/SY\/sy_tr069\/$binname:system\/bin\/$binname"
		sed -i '/hotkey.properties/a \'"$append \\\\"'' "$carriermk"
	elif [ $carrier$province = "cmsh" ] ;then
		local append="    device\/amlogic\/common\/$common_APKS\/sh\/$binname:system\/bin\/$binname"
		sed -i '/hotkey.properties/a \'"$append \\\\"'' "$carriermk"
	else
		local append="    device\/amlogic\/common\/$common_APKS\/$carrier_apks\/$binname:system\/bin\/$binname"
		sed -i '/hotkey.properties/i \'"$append \\\\"'' "$carriermk"
	fi	

}

InsertEtc() {
    local libname=$1
    local carriermk=$2
    grep  hotkey.properties $carriermk
    if [ $? -ne 0 ];then 
        echo "Nothing to do ,please check if hotkey.properties in $carriermk return"
        exit 1
    fi
    #other wise, inset $1 under Setting
    grep $libname $carriermk
    if [ $? -eq 0 ];then
        echo "the file $libname already exists, nothing to do"
        return 0
    fi
	
	#for cuhl chuq ctsh and cmsh
	if [ $carrier$province = "cuhl" ] ;then
		local append="    device\/amlogic\/common\/$common_APKS\/$carrier_apks\/$launcher\/$libname:system\/etc\/$libname"
		if [ $launcher = "huawei" ] ;then
			sed -i '/CUHL_IPTV_HOME_HW.apk/a \'"$append \\\\"'' "$carriermk"
		elif [ $launcher = "fenghuo" ] ;then
			sed -i '/CUHL_IPTV_NOHOME_FH/a \'"$append \\\\"'' "$carriermk"
		fi
	elif [ $carrier$province = "cujc" ] ;then
		local append="    device\/amlogic\/common\/$common_APKS\/BJ_jicai_apks\/SY\/$libname:system\/etc\/$libname"
		sed -i '/hotkey.properties/a \'"$append \\\\"'' "$carriermk"
	elif [ $carrier$province = "ctjc" ] ;then
		local append="    device\/amlogic\/common\/$common_APKS\/SH_jicai_apks\/SY\/sy_tr069\/$libname:system\/etc\/$libname"
		sed -i '/hotkey.properties/a \'"$append \\\\"'' "$carriermk"
	elif [ $carrier$province = "cmsh" ] ;then
		local append="    device\/amlogic\/common\/$common_APKS\/sh\/$libname:system\/etc\/$libname"
		sed -i '/hotkey.properties/a \'"$append \\\\"'' "$carriermk"
	else
		local append="    device\/amlogic\/common\/$common_APKS\/$carrier_apks\/$libname:system\/etc\/$libname"
		sed -i '/hotkey.properties/i \'"$append \\\\"'' "$carriermk"
	fi
	
}
InsertAllSo() {
    local libsdir=$1
    cd $libsdir
    local carriermk=$2
    for names in $(find . -type f); 
    do
        if [[ $names == *.so ]]; then
        #echo "extracted file name is: $names"
        #try to insert the filename.so to unicom.mk
            local localfilename=`basename "$names"`
            echo "localfilename is $localfilename"
            local tobechange="$common/$current_mk"
            InsertSo $localfilename $tobechange
        fi
    done
}

InserAllApk() {
    local apkdir=$1
    cd $apkdir
    for names in $(find . -type f); 
    do
        if [[ $names == *.apk ]]; then
        #echo "extracted file name is: $names"
        #try to insert the filename.so to unicom.mk
            local localfilename=`basename "$names"`
            local tobechange="$common/$current_mk"
			echo "localfilename is $tobechange"
            InsertApk $localfilename $tobechange
        fi
    done
}

InsertAllBin() {
    local bindir=$1
    cd $bindir
    local carriermk=$2
    for names in $(find . -type f); 
    do
        local localfilename=`basename "$names"`
        echo "localfilename is $localfilename"
        local tobechange="$common/$current_mk"
        InsertBin $localfilename $tobechange
    done
}

InsertAllEtc() {
    local libdir=$1
    cd $libdir
    local carriermk=$2
    for names in $(find . -type f); 
    do
        local localfilename=`basename "$names"`
        echo "localfilename is $localfilename"
        local tobechange="$common/$current_mk"
        InsertEtc $localfilename $tobechange
    done
}

HelpChips () {
	echo " the accepted chip types are: "
	echo " ##########################################################"
	echo "      s905l(1)  (2)  s905l2(3)  s905l3(4)             "
	echo " ##########################################################"     
}

CheckChips () {
    echo "Function CheckChips, you have input chip type: $1"
    local found=0
    local chip=$1
    for i in "${chiptypes[@]}"
    do
        if [ $i = $chip ];then
            echo "Input chip Found"
            found=1
        fi
    done 
    if [ $found -eq 0 ];then
        echo "Input chip type is not in correct format"
        return 1
    fi
}

HandleApk(){
    local launchers=( nolauncher lpddr3 huawei fenghuo bestv washu gaoan)
    echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    echo "Please input your launcher:"
    echo "nolauncher(1) lpddr3(2) huawei(3) fenghuo(4) bestv(5) washu(6) gaoan(7)"
    echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    read launcher
    case $launcher in
    "1")
       launcher="nolauncher";;
    "2")
       launcher="lpddr3";;
    "3")
       launcher="huawei";;
    "4")
       launcher="fenghuo";;
    "5")
       launcher="bestv";;
    "6")
       launcher="washu";;
    "7")
       launcher="gaoan";;
    *)
       launcher=$launcher;;
    esac 
    local found=0
    local laun=$launcher
	for i in "${launchers[@]}"
	do
        if [ "$i" = "$laun" ]; then
            echo "Input launcher Found"
            found=1
        fi
	done
	if [ $found -eq 0 ]; then
		echo "Input launcher is not correct format"
		exit
	fi  
    laun=$launcher
	
    local chip=
    HelpChips
    read chip
    case $chip in
    "1")
        chip="s905l";;
    "2")
        chip="s905lv2";;
    "3")
        chip="s905l2";;
    "4")
        chip="s905l3";;
    *)
        chip=$chip;;
    esac
    CheckChips $chip
    if [ $? -eq 1 ];then
        echo "Sorry, You've input wrong chip type !!!!"
        return 1
    fi
    inputchip=$chip
	
    cd $HOME"/amlbuild"
    handle_apk_ret=$(python handleInput.py  $inputchip "$carrier$province" "$laun")    
    if [ "$handle_apk_ret" == "False" ];then
        echo "handle_apk_ret return false!! prepare.sh line 581"
        exit
    fi

}

Copyfile () {

	CalculatePath
	
	echo "the current apk file is $copy_directory"
	echo "Copy related prepared files begins"
    cd "$libs"
    chmod +777 *.so
    HandleApk
    local apkfile="$apk/*.apk"
	local libsfile="$libs/*.so"
	local binfile="$bin/*"
	local etcfile="$etc/*"
	local copy_directory=""
	local apkdir=""
	local bin_directory=""
	local libs_dir=""
	
	#for cuhl
	if [ $carrier$province = "cuhl" ] ;then
		copy_directory="$common/$common_APKS/$carrier_apks/$launcher"
		bin_directory="$common/$common_APKS/$carrier_apks"
		
		cp $apkfile $copy_directory
		cp $libsfile $bin_directory/libs
		cp $binfile $bin_directory/bin
		cp $etcfile $bin_directory/etc
	elif [ $carrier$province = "ctjc" ];then
		copy_directory="$common/$common_APKS/SH_jicai_apks/SY"
		copy_apkdir="$copy_directory/sy_apk"
		libs_dir="$copy_directory/sy_libs"
		bin_directory="$copy_directory/sy_tr069"
				
		cp $apkfile $copy_apkdir
		cp $libsfile $libs_dir
		cp $binfile $bin_directory
		cp $etcfile $bin_directory
	elif [ $carrier$province = "cthq" ];then
		copy_directory="$common/$common_APKS/SH_jicai_apks/SY_FusionGateway"
		copy_apkdir="$copy_directory/sy_apk"
		libs_dir="$copy_directory/sy_libs"
		bin_directory="$copy_directory/sy_tr069"
				
		cp $apkfile $copy_apkdir
		cp $libsfile $libs_dir
		cp $binfile $bin_directory
		cp $etcfile $bin_directory
	elif [ $carrier$province = "cujc" ] ;then
		copy_directory="$common/$common_APKS/BJ_jicai_apks/SY"
		cp $apkfile $libsfile $binfile $etcfile $copy_directory
	elif [ $carrier$province = "cmsh" ] ;then
		copy_directory="$common/$common_APKS/sh"
		cp $apkfile $libsfile $binfile $etcfile $copy_directory
	else
		copy_directory="$common/$common_APKS/$carrier_apks"
		cp $apkfile $libsfile $binfile $etcfile $copy_directory
	fi

    echo "Copy related prepared files ends"
	
 
    echo "Automatic change the $current_mk for the new APK !!!!!!"
    InserAllApk $apk "$common/$current_mk"
    echo "Automatic change the $current_mk for the new so !!!!!!!"
    InsertAllSo $libs "$common/$current_mk"
    echo "Automatic change the $current_mk for the new misc file !!!!!!!"
    InsertAllBin $bin "$common/$current_mk"
    InsertAllEtc $etc "$common/$current_mk"
	
}

CalculatePath () {

    CAPPROVINCE=${province^^}   #convert to upper case
    CAPCARRIER=${carrier^^}
	local carrier_mk=""
	local apks="_apks"
	carrier_apks="$CAPPROVINCE$apks"
	
	case $carrier in
	"cu")
		carrier_mk="unicom_"
		common_APKS="ChinaUnicom_apks"
		;;
	"ct")
		carrier_mk="telecom_"
		common_APKS="ChinaTelecom_apks"
		;;
	"cm")
		carrier_mk="mobile_"
		common_APKS="ChinaMobile_apks"
		;;
	esac	

	if [ $carrier$province = "cujc" ] ;then
		current_mk="unicom.mk"
	elif [ $carrier$province = "ctjc" ] || [ $carrier$province = "cthq" ];then
		current_mk="telecom.mk"
	elif [ $carrier$province = "cmsh" ] ;then
		current_mk="mobile.mk"
	else
		current_mk="$carrier_mk$province.mk"
	fi
	echo "*********the current mk file is $current_mk"
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
	ApkSignAll
}

current_mk=""
carrier_apks=""
tmp="$HOME/amlbuild/tmp"
apk="$HOME/amlbuild/apk"
libs="$HOME/amlbuild/libs"
etc="$HOME/amlbuild/etc"
bin="$HOME/amlbuild/bin"
WP="$HOME/workspace"
common="$WP/device/amlogic/common"




	
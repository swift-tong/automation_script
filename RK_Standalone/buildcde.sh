#/bin/sh
# Why this file, for all this file content is related with detail carrier
# we have to handle the detail province information and got related information .

CheckLaunchers () {
    echo "Function CheckLaunchers"
#   remember if local variable is found, must declare it as local
    local found=0
    local laun=$1
	for i in "${launchers[@]}"
	do
        #echo "$laun"
        if [ "$i" = "$laun" ]; then
            echo "Input launcher Found"
            found=1
        fi
	done
	if [ $found -eq 0 ]; then
		echo "Input launcher is not in correct format"
		return 1
	fi  
}

DeleteAndroidMkApk () {
#   We must first check if we can find the apkname (exact match), then execute the awk
    local apkname=$1
    grep -w "$apkname" Android.mk|grep -v '/'
    if [ $? -eq 0 ];then
        local linenumber=`awk '/'"$apkname"'/{print NR}' Android.mk`
    #echo "linenumber is :$linenumber"
        let beginline=linenumber-1
        let endline=linenumber+8
        sed ''"$beginline"','"$endline"' d' Android.mk >tmp.mk 
        mv tmp.mk Android.mk
    fi
}

DeleteSuyingMkApk () {
    local apkname=$1
    grep -w "$apkname" suying.mk|grep -v '/'
    if [ $? -eq 0 ];then
        local linenumber=`awk '/'"$apkname"'/{print NR}' suying.mk`
        echo "linenumber is $linenumber"
        sed ''"$linenumber"'d' suying.mk >tmp.mk
        mv tmp.mk suying.mk
    fi
}

DeleteThirdApk () {
    cd "$iptv"
    DeleteAndroidMkApk $1
    DeleteSuyingMkApk $1
}
MdSuyingMk_cuhl_epg () {
    cd $iptv
	if [ $1 = SD ];then
		local append="        ro.product.epg.platform=SD"
	elif [ $1 = HD ];then
		local append="        ro.product.epg.platform=HD"
	fi
    if grep ro.product.epg.platform suying.mk > /dev/null
	then
		#replace the incorrect value
		sed -i 's/^.*ro.product.epg.platform.*$/'"$append \\\\"'/' suying.mk
	else
		#append new item
		sed -i '/PRODUCT_PROPERTY_OVERRIDES/a \'"$append \\\\"'' suying.mk
	fi		
}


MdSuyingMk_cuhl_platform () {
    cd $iptv
	if [ $1 = sd ];then
		local append="        ro.product.platform=sd"
	elif [ $1 = 4k_huawei ];then
		local append="        ro.product.platform=4k_huawei"
	elif [ $1 = 4k_fonsview ];then
		local append="        ro.product.platform=4k_fonsview"
	fi
    if grep ro.product.platform suying.mk > /dev/null
	then
		#replace the incorrect value
		sed -i 's/^.*ro.product.platform.*$/'"$append \\\\"'/' suying.mk
	else
		#append new item
		sed -i '/PRODUCT_PROPERTY_OVERRIDES/a \'"$append \\\\"'' suying.mk
	fi		
}

MDPrivateInfo () {
	cd $buildtool
	local lauid=$1
	local conn="_"
	local SW="SW"
    GenVersionStr $majorversion $minorversion
    if [ $buildfactory -eq 0 ]; then
        local Incre="$PRODUCTNAME$conn$SW$conn$CAPPROVINCE$conn$lauid$conn$VERSIONSTR"
    else
        Incre="$PRODUCTNAME$conn$SW$conn$CAPWIFI$conn$VERSIONSTR"
    fi
    echo "this increamental is $Incre"
    replacedIncre="echo \"ro.build.version.incremental=$Incre\""
    echo $replacedIncre
    sed -i 's/^.*ro.build.version.incremental=.*$/'"$replacedIncre"'/' buildinfo.sh
    
    cd $RKSDK
    GenVersionStr $majorversion $minorversion
    if [ $buildfactory -eq 0 ]; then
        local replaced="ro.rksdk.version=$PRODUCTNAME$conn$SW$conn$CAPPROVINCE$conn$lauid$conn$VERSIONSTR"
    else
        replaced="ro.rksdk.version=$PRODUCTNAME$conn$SW$conn$CAPWIFI$conn$VERSIONSTR"
    fi
    echo $replaced
    sed -i 's/^.*ro.rksdk.version.*$/'"$replaced"'/' device.mk
}



DeleteApk_cuhl_3228h () {
    local input=$1
    #HW platform only
    local HWApk=( Bestv_huawei 4k_HW 1905hd_HW chyy_HW huishenghuo_HW jiaoyu_HW ltyy_HW qxyb_HW \
                 xinxi_HW yingyong_HW zsj_HW cjjc_HW game_HW wbyx_HW yyjc_HW )
    #FH platform only
    local FHApk=( Bestv_fenghuo 4k_FH 1905hd_FH chyy_FH huishenghuo_FH jiaoyu_FH ltyy_FH qxyb_FH \
                 xinxi_FH yingyong_FH zsj_FH cjjc_FH game_FH wbyx_FH yyjc_FH )
    
    if [ $input = "HW" ];then
        for apk in "${HWApk[@]}"
        do
            echo delete $apk 
            DeleteThirdApk $apk
        done
    elif [ $input = "FH" ];then
        for apk in "${FHApk[@]}"
        do
            echo delete $apk 
            DeleteThirdApk $apk
        done
    fi
}

DeleteKeyLayoutFile () {
    local keylayout=$1
    while grep $1 suying.mk > /dev/null
    do
        local lineStr=$(awk '/'"$keylayout"'/{print NR}' suying.mk)
        local lineNum=$(echo $lineStr | awk '{print $1}')
        echo "lineNum is: $lineNum"
        sed ''"$lineNum"'d' suying.mk >tmp.mk
        mv tmp.mk suying.mk
    done
}

HandleML_cuhl_3228h(){
    echo "Handle heilongjiang liantong multi-launcher"
    if [ "$inputlauncher" = "nolauncher" ];then
		MdSuyingMk_cuhl_epg SD
		MdSuyingMk_cuhl_platform sd
    elif [ "$inputlauncher" = "huawei" ];then
		MdSuyingMk_cuhl_epg HD
		MdSuyingMk_cuhl_platform 4k_huawei
    elif [ "$inputlauncher" = "fenghuo" ];then
		MdSuyingMk_cuhl_epg HD
		MdSuyingMk_cuhl_platform 4k_fonsview
    else
        echo "do nothing"
    fi
}


CheckConfigXml(){
    cd $WP/frameworks/base/core/res/res/values/
    git checkout -- config.xml
    if [ "$inputlauncher" == "huawei" ];then
        cp $HOME/config/config_huawei.xml config.xml
    elif [ "$inputlauncher" == "fenghuo" ];then
        cp $HOME/config/config_fenghuo.xml config.xml
    fi
}

CheckML_cuhl_3228h (){
    HandleML_cuhl_3228h
    CheckConfigXml	
}
CheckML_ctnm (){
    
    LauncherTypes=( normal industry )
    echo "Function CheckLaunchertypes"
#   remember if local variable is found, must declare it as local
    local found=0
	#echo "Please input wifis : "
	#read province
    LauncherType=$1
	for i in "${LauncherTypes[@]}"
	do
        #echo $i
        if [ "$i" = "$LauncherType" ]; then
            echo "Input LauncherType Found"
            found=1          
        fi
	done
	if [ $found -eq 0 ]; then
		echo "Input LauncherType type is not in correct format"
		return 1
	fi 
    
}

#Yunyouxi.apk
#Yingyongshangcheng.apk
#Wojiashixun.apk
#Boyasichuanmajiang.apk
#Caizhixiaotiandi.apk
#Vleyouxi.apk
#Shengdongyuyindoudizhu.apk
#Suningyigou.apk
#Taobao.apk
#Youpeng:
#    4kChaojiyingyuan_youpeng.apk
#    Lunbo_youpeng.apk
#    Launcher_youpeng.apk
#Bestv:
#    4kChaojiyingyuan_bestv.apk
#    Launcher_bestv.apk
HandleML_cuhe () {
    echo "Handle hebei liantong multi-launcher"
	if [ "$inputlauncher" = "youpeng" ];then
        DeleteThirdApk 4kChaojiyingyuan_bestv
        DeleteThirdApk Launcher_bestv
		DeleteThirdApk AppStore_bestv
		DeleteThirdApk IPTV_third_launcher
		MDPrivateInfo C
    elif [ "$inputlauncher" = "bestv" ];then
        DeleteThirdApk 4kChaojiyingyuan_youpeng
        DeleteThirdApk Lunbo_youpeng
        DeleteThirdApk Launcher_youpeng
		DeleteThirdApk IPTV_third_launcher
		MDPrivateInfo A
	elif [ "$inputlauncher" = "huashu" ];then
	    DeleteThirdApk IPTV_third_launcher
		MDPrivateInfo B
	elif [ "$inputlauncher" = "third" ];then
        DeleteThirdApk 4kChaojiyingyuan_bestv
        DeleteThirdApk Launcher_bestv
		DeleteThirdApk AppStore_bestv
		DeleteThirdApk 4kChaojiyingyuan_youpeng
        DeleteThirdApk Lunbo_youpeng
        DeleteThirdApk Launcher_youpeng
		MDPrivateInfo D
    else
        echo "do nothing"
    fi        
}

CheckML_cuhe () {
    local launchers=( bestv huashu youpeng third )
    cd "$RKSDK/IPTV/IPTV_cuhe"
    echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    echo "Hebei Liantong has multiple launcher, you must specify this launcher "
    echo "The accepted laucnhers are : bestv , huashu, youpeng, third"
	echo "third: bestv , huashu, youpeng in one apk"
    echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    echo "Please Input Launcher: "
    read launcher
    #CheckLaunchers $launcher
    #if [ $? -eq 1 ]; then
    #    return 1
    #fi
    local found=0
    local laun=$launcher
	for i in "${launchers[@]}"
	do
        #echo "$laun"
        if [ "$i" = "$laun" ]; then
            echo "Input launcher Found"
            found=1
        fi
	done
	if [ $found -eq 0 ]; then
		echo "Input launcher is not in correct format"
		return 1
	fi  
    inputlauncher=$launcher
    HandleML_cuhe 
}


ChangeBoardConfigMk(){
    cd $rksdk
    if [ $inputlauncher = "nolauncher" ];then
        replaced="USE_TARGET_PRODUCT := IPTV_"$carrier$province
        grepItem="IPTV_"$carrier$province
    else
        replaced="USE_TARGET_PRODUCT := IPTV_"$carrier$province"_"$inputlauncher
        grepItem="IPTV_"$carrier$province"_"$inputlauncher
    fi
    echo $grepItem
    grep -w $grepItem BoardConfig.mk
    if [ $? -ne 0 ];then
        sed -i 's/USE_TARGET_PRODUCT.*$/'"$replaced"'/' BoardConfig.mk
        if [ $? -ne 0 ];then
            echo "change BoardConfig.mk failed!!!"
           		return 1
        fi				
    fi
}

#why Prebuild, for some ugly thing need to be checked, like cuhe has multi-launcher
CheckMultiLauncher () {
    ChangeBoardConfigMk
    if [ $? -ne 0 ];then
        echo "change BoardConfig.mk failed!!!"
        return 1
    fi
    echo "CheckMultiLauncher function province is $province, carrier is $carrier"
    if [ "$province" = "he" ] && [ "$carrier" = "cu" ]; then
        #CheckML_cuhe
		echo "#########NOW cuhe launcher is youpeng bestv huashu in one apk############"
        #return $?
		return 0
    elif [ "$province" = "hl" ] && [ "$carrier" = "cu" ] && [ "$PRODUCTNAME" = "S-010W-AV2S" ]; then
        CheckML_cuhl_3228h
        return $?
	elif [ "$province" = "sm" ] && [ "$carrier" = "os" ] && [ "$PRODUCTNAME" = "S-010W-AV2B" ]; then
        CheckML_s010wav2b_ossm
        return $?
    else
        return 0

    fi
}

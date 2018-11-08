#/bin/sh
# Why this file, for all this file content is related with detail carrier
# we have to handle the detail province information and got related information .



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

HandleDiffLauncher () {
    echo "Handle different launcher ,bugzilla 105"
    local launcher=$1
    local backup="$ownbuild/backup"
    local common="$WP/device/rockchip/common"
    local vpu_lib="$common/vpu/lib"
    local iptv_lib="$rksdk/IPTV/lib"
    if [ "X$launcher" = "X" ];then
        return 1
    fi
    if [ $launcher = "nolauncher" ];then
        cd $backup
        tar -xvf '*.tar.gz'
        unrar x '*.rar'
        find . -name librkffplayer.so -exec cp {} $vpu_lib  \;
        find . -name libCTC_MediaProcessor.so -exec cp {} $iptv_lib  \;
        rm *.so
        find . -name '*.so' -exec cp {} $common  \;
    else
        cd $common
        git clean -f
        git checkout -- "$vpu_lib/librkffplayer.so"
        cd $iptv_lib
        git checkout -- libCTC_MediaProcessor.so      
        
    fi
}


#Huawei:-------------------------------------------------------------------
#  Bestv_huawei.apk
#计费
#4k_HW.apk 1905hd_HW.apk chyy_HW.apk  huishenghuo_HW.apk  jiaoyu_HW.apk  ltyy_HW.apk  qxyb_HW.apk  xinxi_HW.apk  yingyong_HW.apk  zsj_HW.apk cjjc_HW.apk game_HW.apk
#wbyx_HW.apk yyjc_HW.apk

#Fenghuo:------------------------------------------------------------------
#  Bestv_fenghuo.apk

#计费
#4k_FH.apk 1905hd_FH.apk chyy_FH.apk  huishenghuo_FH.apk  jiaoyu_FH.apk  ltyy_FH.apk  qxyb_FH.apk  xinxi_FH.apk  yingyong_FH.apk  zsj_FH.apk cjjc_FH.apk game_FH.apk  
#wbyx_FH.apk yyjc_FH.apk

#Common:-------------------------------------------------------------------
#    ItvSetting.apk
#    UpgradeManager.apk     
#    tr069Service.apk     
#增值业务-------------------------------------------------------------------
#行云超级剧场
###SuperTheatreFree.apk 
   
#彩虹
###rainbow_music.apk

#路通
###lutong_kalaok.apk

#天气预报
###weather.apk

#掌世世界
###handleworld.apk

#UT(玩吧)
###JustPlay.apk

#小沃(目前只集成长虹的)
####xiaowo.apk

#TV中心APK---------------------------------------------------------------
#应用商城
#DSMClient.apk

#融合视屏
#rongheshiping.apk

#飞流
#DUI_feiliu.apk

#Launcher
#Launcher.apk

#计费插件
#USP_jifeichajian.apk


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
        DeleteApk_cuhl_3228h HW
        DeleteApk_cuhl_3228h FH
		MdSuyingMk_cuhl_epg SD
		MdSuyingMk_cuhl_platform sd
    elif [ "$inputlauncher" = "huawei" ];then
        DeleteApk_cuhl_3228h FH
		MdSuyingMk_cuhl_epg HD
		MdSuyingMk_cuhl_platform 4k_huawei
    elif [ "$inputlauncher" = "fenghuo" ];then
        DeleteApk_cuhl_3228h HW
		MdSuyingMk_cuhl_epg HD
		MdSuyingMk_cuhl_platform 4k_fonsview
    else
        echo "do nothing"
    fi
}


CheckML_cuhl_3228h (){
    local launchers=( nolauncher huawei fenghuo )
    cd "$RKSDK/IPTV/IPTV_cuhl"
    echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    echo "Hebei Liantong has multiple launcher, you must specify this launcher "
    echo "The accepted laucnhers are : nolauncher , huawei, fenghuo"
    echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    echo "Please Input Launcher: "
    read launcher

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
    HandleML_cuhl_3228h 
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
    echo "CheckMultiLauncher function province is $province, carrier is $carrier"
    if [ "$province" = "he" ] && [ "$carrier" = "cu" ]; then
        #CheckML_cuhe
		echo "#########NOW cuhe launcher is youpeng bestv huashu in one apk############"
        #return $?
		return 0
    elif [ "$province" = "hl" ] && [ "$carrier" = "cu" ] && [ "$PRODUCTNAME" = "G-120WT-P" ]; then
        HandleDiffLauncher $inputlauncher
        return $?
    elif [ "$province" = "hl" ] && [ "$carrier" = "cu" ] && [ "$PRODUCTNAME" = "S-010W-AV2S" ]; then
        CheckML_cuhl_3228h
        return $?
    else
        return 0

    fi
}

#/bin/sh
#this file is used to split the prev build from normal build and after build process.

#sed help : http://www.theunixschool.com/2012/06/sed-25-examples-to-delete-line-or.html

#Build flag
enableadb=0         #default is true
enablerkupdate=0    #default rk update service is 1
enableRkLauncher=0
enbackup=0
enableanimation=0
enabledownloadapp=0
enablerealstandby=0
enablehdmicec=0
downloadappapk=""
otahostaddr=""
nsblogserver=""
appversion=""
middlewareapklist=( IPTV.apk ItvSetting.apk UpgradeManager.apk Jvm.apk Launcher.apk )
enTestVideoPlay=1


ReadCdeParameter () {
    cd $vendorpath
    source iniparser.sh
    cfg_parser iptvcde.ini
	if [ $? -eq 1 ]; then
	   echo "parse iptvcde.ini failed"
	   exit 1
	fi
    cfg_section_cde
    #echo $otaserver
    #echo $itvlauncher
    #echo $adb
    #echo $rkupdate
    if [ $adb == "true" ];then  let enableadb=1; fi
    if [ $en_backup == "true" ];then let enbackup=1;fi
    if [ $itvlauncher == "true" ];then  let enableRkLauncher=1; fi
    if [ $rkupdate == "true" ];then  let enablerkupdate=1; fi
    if [ $en_animation == "true" ];then  let enableanimation=1; fi
    if [ $en_animation == "both" ];then  let enableanimation=2; fi
    if [ $en_downloadapp == "true" ];then  
        let enabledownloadapp=1
        downloadappapk=$en_dlappname
    fi
	if [ $en_realstandby == "true" ];then  let enablerealstandby=1; fi
    if [ $en_hdmicec == "true" ];then let enablehdmicec=1; fi
	otahostaddr=$rkotahost
	nsblogserver=$nsblogserver #1123liangchao
	echo "!!!!!!!!!!!!!!!!!Check offcialversion and onsitebuild variable!!!!!!!!!!!!!!!!!!!"
	echo "officialbuild is $officialbuild"
	echo "officialonsitebuild is $officialonsitebuild"
	echo "enableadb is $enableadb"
	if [ $officialbuild = 1 ] && [ $officialonsitebuild = 1 ] && [ $enableadb = 1 ]; then
	    echo "!!!!!!!!!!!!WARNNING iptvcde.ini is adb function OPEN NOW We force change adb function CLOSE!!!!!!!!!!!!!"
        enableadb=0
		echo "enableadb is $enableadb"
     fi
	if [ $en_TestVideoPlay == "false" ];then  
		let enTestVideoPlay=0; 
		echo "enTestVideoPlay=0 delete TestVideoPlay!!!"
	fi
    enbackup=1
}

CheckVersion(){
    cd $image
    ls $imgpfx".img"
    if [ $? -eq 0 ];then
        echo "!!!!!!! Alert !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
        echo "Sorry, You've requested for one officla build , but the version has "
        echo "already been occupied, please you make it for sure again !!!!"
        return 1
    fi
}
# The build Logic is as below:
# We assume that you must input for minor version, (currently no need major version)
# if you input minor version, then the name of update.img will be renamed, other wise, we only
# put it as update.img.
CheckInputParameter () {
    echo "Please confirm if you need to make this build official, if official, then OTA check will be done"
    echo "No input is no offifcial input"
    echo "Please enter [Yy/Nn]: "
    read -t 10 offcialversion
    if [[ $? -ne 0 ]] ;then
        echo "You don't give any input, use default Minor Version"
        return 0
    fi
    if [ "$offcialversion" = "y" ] || [ "$offcialversion" = "Y" ]; then
        let officialbuild=1
        
        echo "Please confirm if it is one ONSITE official build, if yes, Major version must greater than 0"
        echo "Please enter [Yy/Nn]: "       
        read onsitebuild
        if [ "$onsitebuild" = "y" ] || [ "$onsitebuild" = "Y" ]; then
            echo "Please Input Major version now, must greater that 0"
            read majversion
            if [ $majversion -lt 1 ];then
                echo "You've input wrong major version !!!!"
                return 1
            fi
		    let officialonsitebuild=1
        else
            majversion=0
        fi
        
        echo "accepted minor version input is from 0 to 99"
        echo "Please input current minor version :"
        read minversion
        #minorversion=$minversion
        #SetVersion 0 $minversion
        SetVersion $majversion $minversion
        GenVersionStr $majorversion $minorversion
    fi
    return 0
}

CheckDeviceMk () {
#first we should change device.mk
    cd $RKSDK
    if [ $buildfactory -eq 0 ]; then
        replaced="ro.rksdk.version=$innerVersion"
    else
        replaced="ro.rksdk.version=$facVersion"
    fi
    echo $replaced
    sed -i 's/^.*ro.rksdk.version.*$/'"$replaced"'/' device.mk
    #change field ro.vendor.sw.version to G-120WT-P_SW_ZY_CTNX_R1.01.15
    replaced="ro.vendor.sw.version=$vendorVersion"
    sed -i 's/^.*ro.vendor.sw.version.*$/'"$replaced"'/' device.mk
}

#ro.build.version.incremental and ro.build.display.id for factory
CheckBuildInfo () {
    cd $buildtool
    local replaced="echo \"ro.build.display.id=$display_id\""
    echo $replaced
    sed -i 's/^.*ro.build.display.id.*$/'"$replaced"'/' buildinfo.sh
    #now change ro.product.manufacturer
    local replaced1='echo "ro.product.manufacturer=NSB"'
    local prodg="CMIOT-EG-G12"
    if [ "$PRODUCTNAME" = "$prodg" ]; then
        #echo ""
        #found=1
        replaced1='echo "ro.product.manufacturer=CIOT"'
        echo "ro.product.manufacture is : $ replaced1"
    fi
    echo $replaced1
    sed -i 's/^.*ro.product.manufacturer=.*$/'"$replaced1"'/' buildinfo.sh
    #now change echo "ro.product.name=$PRODUCT_NAME"
    local replaced2='echo "ro.product.name=$PRODUCT_MODEL"'
    echo $replaced2
    sed -i 's/^.*ro.product.name.*$/'"$replaced2"'/' buildinfo.sh
    #external version
    if [ $buildfactory -eq 0 ]; then
        local Incre=$extVersion
    else
        Incre=$facVersion
    fi
    echo "this increamental is $Incre"
    replacedIncre="echo \"ro.build.version.incremental=$Incre\""
    echo $replacedIncre
    sed -i 's/^.*ro.build.version.incremental=.*$/'"$replacedIncre"'/' buildinfo.sh
	
    if [ "$product" = "G-120WT-P" ] && [ "$carrier" = "os" ] && [ "$province" = "sm" ];then	
        FingerIncre="4.4.4\/$PRODUCTNAME\/`date +%Y%m%d-%H-%M-%S`"
        replacedFinger="echo \"ro.build.fingerprint=$FingerIncre\""
        echo $replacedFinger
        sed -i 's/^.*ro.build.fingerprint=.*$/'"$replacedFinger"'/' buildinfo.sh
    fi
}

CheckRk3228bMk () {
    cd $rk3228
    #echo $rk3228
	 
    local probrandreplaced="PRODUCT_BRAND := 4K-UHD-STB"
    sed -i 's/^.*PRODUCT_BRAND.*$/'"$probrandreplaced"'/' rk3228.mk
    local promodreplaced="PRODUCT_MODEL := $PRODUCTNAME"
    echo $promodreplaced
    sed -i 's/^.*PRODUCT_MODEL.*$/'"$promodreplaced"'/' rk3228.mk
#   production version
    local lauid="A"
    GenVersionStr $majorversion $minorversion
	local Con='_'
	local SW="SW"
    if [ $buildfactory -eq 0 ];then 
        
        local prodver="$PRODUCTNAME$Con$SW$Con$CAPPROVINCE$Con$lauid$Con$VERSIONSTR"        
        #local prodver="$PRODUCTNAME_SW$conn$CAPPROVINCE$conn$lauid$conn$VERSIONSTR"
        echo "prod version is : $prodver"
        local prodverreplaced="    ro.product.version = $prodver"
    else
	    local FAC="FAC"
        #prodver="$PRODUCTNAME_SW$Con$CAPWIFI$Con$VERSIONSTR"
		prodver="$PRODUCTNAME$Con$SW$Con$FAC$Con$VERSIONSTR"
        prodverreplaced="    ro.product.version = $prodver"
    fi
    echo $prodverreplaced
    sed -i 's/^.*ro.product.version.*$/'"$prodverreplaced \\\\"'/' rk3228.mk
    cat rk3228.mk
    #GenVersionStr $majorversion $minorversion
    #if [ $buildfactory -eq 0 ]; then
    #    local Incre="$PRODUCTNAME_SW$conn$CAPPROVINCE$conn$lauid$conn$VERSIONSTR"
    #else
    #    Incre="$PRODUCTNAME_SW$conn$CAPWIFI$conn$VERSIONSTR"
    #fi
    #echo "this increamental is $Incre"
    #replacedIncre="echo \"ro.build.version.incremental=$Incre\""
    #echo $replacedIncre
    #sed -i 's/^.*ro.build.version.incremental=.*$/'"$replacedIncre"'/' buildinfo.sh
    
    #, Product_manufacture
    local manfacreplaced="PRODUCT_MANUFACTURER := Nokia Shanghai Bell"
    sed -i 's/^.*PRODUCT_MANUFACTURER.*$/'"$manfacreplaced"'/' rk3228.mk
    #, Append PRODUCT_NUMBER
    #local pronumberreplaced="PRODUCT_NUMBER := $prodver"
    grep PRODUCT_NUMBER rk3228.mk
    if [ $? -ne 0 ]; then
        local append1="PRODUCT_NUMBER := $prodver"
        echo $append1
        sed -i '/PRODUCT_NAME/a \'"$append1"'' rk3228.mk
    fi
    
    #, 
    grep ro.product.ota.host rk3228.mk
    if [ $? -eq 0 ]; then
       local hostreplaced="        ro.product.ota.host=$otahostaddr"
       echo "hostreplaced is $hostreplaced"
       sed -i 's/^.*ro.product.ota.host.*$/'"$hostreplaced"'/' rk3228.mk
	fi 
}

CheckRk3228hMk () {
    cd $rk3228h
    #echo $rk3228h
	 
    local probrandreplaced="PRODUCT_BRAND := 4K-Super-high-definition-intelligent-STB"
    sed -i 's/^.*PRODUCT_BRAND.*$/'"$probrandreplaced"'/' rk3228h.mk
    local promodreplaced="PRODUCT_MODEL := $PRODUCTNAME"
    echo $promodreplaced
    sed -i 's/^.*PRODUCT_MODEL.*$/'"$promodreplaced"'/' rk3228h.mk
#   production version
    local lauid="A"
    GenVersionStr $majorversion $minorversion
	local Con='_'
	local SW="SW"
    if [ $buildfactory -eq 0 ];then 
        
        local prodver="$PRODUCTNAME$Con$SW$Con$CAPPROVINCE$Con$lauid$Con$VERSIONSTR"        
        #local prodver="$PRODUCTNAME_SW$conn$CAPPROVINCE$conn$lauid$conn$VERSIONSTR"
        echo "prod version is : $prodver"
        local prodverreplaced="    ro.product.version = $prodver"
    else
	    local FAC="FAC"
        #prodver="$PRODUCTNAME_SW$Con$CAPWIFI$Con$VERSIONSTR"
		prodver="$PRODUCTNAME$Con$FAC$Con$VERSIONSTR"
        prodverreplaced="    ro.product.version = $prodver"
    fi
    productswversion="$prodver"
    echo $prodverreplaced
    sed -i 's/^.*ro.product.version.*$/'"$prodverreplaced \\\\"'/' rk3228h.mk
    cat rk3228h.mk
    #GenVersionStr $majorversion $minorversion
    #if [ $buildfactory -eq 0 ]; then
    #    local Incre="$PRODUCTNAME_SW$conn$CAPPROVINCE$conn$lauid$conn$VERSIONSTR"
    #else
    #    Incre="$PRODUCTNAME_SW$conn$CAPWIFI$conn$VERSIONSTR"
    #fi
    #echo "this increamental is $Incre"
    #replacedIncre="echo \"ro.build.version.incremental=$Incre\""
    #echo $replacedIncre
    #sed -i 's/^.*ro.build.version.incremental=.*$/'"$replacedIncre"'/' buildinfo.sh
    
    #, Product_manufacture
    local manfacreplaced="PRODUCT_MANUFACTURER := Nokia Shanghai Bell"
    sed -i 's/^.*PRODUCT_MANUFACTURER.*$/'"$manfacreplaced"'/' rk3228h.mk
    #, Append PRODUCT_NUMBER
    #local pronumberreplaced="PRODUCT_NUMBER := $prodver"
    grep PRODUCT_NUMBER rk3228h.mk
    if [ $? -ne 0 ]; then
        local append1="PRODUCT_NUMBER := $prodver"
        echo $append1
        sed -i '/PRODUCT_NAME/a \'"$append1"'' rk3228h.mk
    fi
    
    #, 
    grep ro.product.ota.host rk3228h.mk
    if [ $? -eq 0 ]; then
       local hostreplaced="        ro.product.ota.host=$otahostaddr"
       echo "hostreplaced is $hostreplaced"
       sed -i 's/^.*ro.product.ota.host.*$/'"$hostreplaced"'/' rk3228h.mk
	fi 
}

MdAllowInstallApps (){
    local python_s="$vendorpath"
    confRet=$(python $python_s/intmapext.py  "handleConfigFile" $vendorpath"/dealapk.ini" $iptv"/allow_install_apps.xml")
    CheckVersionReturn $confRet	
}
MdRk3228bSuyingMk () {
    ##now append ro.build.description
    cd $iptv
    grep ro.product.description suying.mk
    if [ $? -ne 0 ]; then
    local append0="        ro.product.description=IPTV_4K_STB"
    echo $append0
    sed -i '/PRODUCT_PROPERTY_OVERRIDES/a \'"$append0 \\\\"'' suying.mk
	fi     
	
    #now append productclass
    grep ro.product.productclass suying.mk
    if [ $? -ne 0 ]; then
        #local append1="        ro.product.productclass=G-120WT-P"
        local append1="        ro.product.productclass=$PRODUCTNAME"
        echo $append1
        sed -i '/PRODUCT_PROPERTY_OVERRIDES/a \'"$append1 \\\\"'' suying.mk
    fi
    
    #append manufactureroui
    grep ro.product.manufactureroui suying.mk
    if [ $? -ne 0 ]; then
        local append="        ro.product.manufactureroui=$nsb_oui"
        echo $append
        sed -i '/PRODUCT_PROPERTY_OVERRIDES/a \'"$append \\\\"'' suying.mk
    fi
    #append devicesummary
    grep ro.devicesummary suying.mk
    if [ $? -ne 0 ]; then
        #local append3="        ro.devicesummary=G-120WT-P"
        local append3="        ro.devicesummary=$PRODUCTNAME"
        echo $append3
        sed -i '/PRODUCT_PROPERTY_OVERRIDES/a \'"$append3 \\\\"'' suying.mk
    fi
    
     #append hardware.id
    grep ro.build.hardware.id suying.mk
    if [ $? -ne 0 ]; then		
        local append4="        ro.build.hardware.id=$hw_id"
        echo $append4
        sed -i '/PRODUCT_PROPERTY_OVERRIDES/a \'"$append4 \\\\"'' suying.mk
    fi

    #append chiptype 
    grep ro.product.chiptype suying.mk
    if [ $? -ne 0 ]; then
        if [ "$carrier" = "cu" ] && [ "$province" = "sx" ] && [ "$PRODUCTNAME" = "G-120WT-P" ];then
            local append5="        ro.product.chiptype=rk3228"
        else
            local append5="        ro.product.chiptype=RK3228B"
        fi
        echo $append5
        sed -i '/PRODUCT_PROPERTY_OVERRIDES/a \'"$append5 \\\\"'' suying.mk
    fi
        
    #append cpuarchitec
    grep ro.product.cpuarchitec suying.mk
    if [ $? -ne 0 ]; then
        local append6="        ro.product.cpuarchitec=ARM-A7"
        echo $append6
        sed -i '/PRODUCT_PROPERTY_OVERRIDES/a \'"$append6 \\\\"'' suying.mk
    fi
	
	#append nsblogserver
	grep ro.config.nsblogserver suying.mk
    if [ $? -ne 0 ]; then
        local append7="        ro.config.nsblogserver=$nsblogserver"
        echo $append7
        sed -i '/PRODUCT_PROPERTY_OVERRIDES/a \'"$append7 \\\\"'' suying.mk
    fi
	
	##now append persist.ppp.paditimeout
    cd $iptv
    grep persist.ppp.paditimeout suying.mk
    if [ $? -ne 0 ]; then
    local append8="        persist.ppp.paditimeout=1"
    echo $append8
    sed -i '/PRODUCT_PROPERTY_OVERRIDES/a \'"$append8 \\\\"'' suying.mk
	fi  

    #now append ro.build.launcher.category 
    grep ro.build.launcher.category suying.mk
    if [ $? -ne 0 ]; then 
        if [ "$inputlauncher"="normal" ] || [ "$inputlauncher"="industry" ]; then 
            local append9="        ro.build.launcher.category=$inputlauncher"
            echo $append9
            sed -i '/PRODUCT_PROPERTY_OVERRIDES/a \'"$append9 \\\\"'' suying.mk
        fi
    fi

    if [ "$PRODUCTNAME" == "G-120WT-P" ] && [ "$carrier" == "ct" ] && [ "$province" == "sx" ];then
        #append Android.os.Build.Fignerprint
        grep android.os.Build.Fignerprint suying.mk
        if [ $? -ne 0 ]; then
            FingerIncre="4.4.4\/$PRODUCTNAME\/`date +%Y%m%d-%H-%M-%S`"
            local append10="        android.os.Build.Fignerprint=$FingerIncre"
            sed -i '/PRODUCT_PROPERTY_OVERRIDES/a \'"$append10 \\\\"'' suying.mk         
        fi
		
        #append Android.os.Build.incremntal
        grep android.os.Build.incremntal suying.mk
        if [ $? -ne 0 ]; then
            incremntalIncre=$extVersion
            local append11="        android.os.Build.incremntal=$incremntalIncre"
            sed -i '/PRODUCT_PROPERTY_OVERRIDES/a \'"$append11 \\\\"'' suying.mk         
        fi
    fi
}

MdRk3228hSuyingMk () {
    cd $rk3228h
    git checkout -- system.prop
    grep ro.build.hardware.id system.prop
    if [ $? -eq 0 ];then
        sed -i '/ro.build.hardware.id/d' system.prop
        git add system.prop
        git  commit -m  "delete ro.build.hardware.id in system.prop"
    fi
    ##now append ro.build.description
    cd $iptv
    grep ro.product.description suying.mk
    if [ $? -ne 0 ]; then
    local append0="        ro.product.description=IPTV_4K_STB"
    echo $append0
    sed -i '/PRODUCT_PROPERTY_OVERRIDES/a \'"$append0 \\\\"'' suying.mk
	fi     
	
    #now append productclass
    grep ro.product.productclass suying.mk
    if [ $? -ne 0 ]; then
        #local append1="        ro.product.productclass=G-120WT-P"
        local append1="        ro.product.productclass=$PRODUCTNAME"
        echo $append1
        sed -i '/PRODUCT_PROPERTY_OVERRIDES/a \'"$append1 \\\\"'' suying.mk
    fi
    
    #append manufactureroui
    grep ro.product.manufactureroui suying.mk
    if [ $? -ne 0 ]; then
        local append="        ro.product.manufactureroui=$nsb_oui"
        echo $append
        sed -i '/PRODUCT_PROPERTY_OVERRIDES/a \'"$append \\\\"'' suying.mk
    fi
    #append devicesummary
    grep ro.devicesummary suying.mk
    if [ $? -ne 0 ]; then
        #local append3="        ro.devicesummary=G-120WT-P"
        local append3="        ro.devicesummary=$PRODUCTNAME"
        echo $append3
        sed -i '/PRODUCT_PROPERTY_OVERRIDES/a \'"$append3 \\\\"'' suying.mk
    fi
    
     #append hardware.id
    grep ro.build.hardware.id suying.mk
    if [ $? -ne 0 ]; then		
        local append4="        ro.build.hardware.id=$hw_id"
        echo $append4
        sed -i '/PRODUCT_PROPERTY_OVERRIDES/a \'"$append4 \\\\"'' suying.mk
    fi

    #append chiptype 
    grep ro.product.chiptype suying.mk
    if [ $? -ne 0 ]; then
        local append5="        ro.product.chiptype=RK3228H"
        echo $append5
        sed -i '/PRODUCT_PROPERTY_OVERRIDES/a \'"$append5 \\\\"'' suying.mk
    fi
        
    #append cpuarchitec
    grep ro.product.cpuarchitec suying.mk
    if [ $? -ne 0 ]; then
        local append6="        ro.product.cpuarchitec=ARM-A7"
        echo $append6
        sed -i '/PRODUCT_PROPERTY_OVERRIDES/a \'"$append6 \\\\"'' suying.mk
    fi
	
	#append nsblogserver
	grep ro.config.nsblogserver suying.mk
    if [ $? -ne 0 ]; then
        local append7="        ro.config.nsblogserver=$nsblogserver"
        echo $append7
        sed -i '/PRODUCT_PROPERTY_OVERRIDES/a \'"$append7 \\\\"'' suying.mk
    fi
	
	##now append persist.ppp.paditimeout
    cd $iptv
    grep persist.ppp.paditimeout suying.mk
    if [ $? -ne 0 ]; then
    local append8="        persist.ppp.paditimeout=1"
    echo $append8
    sed -i '/PRODUCT_PROPERTY_OVERRIDES/a \'"$append8 \\\\"'' suying.mk
	fi  
	
	#append ro.product.version
	#local Con='_'
    #local ZY="ZY"
    #local prodver="$PRODUCTNAME_SW$Con$ZY$Con$CAPCARRIER$CAPPROVINCE$Con$VERSIONSTR"
	#grep ro.product.version suying.mk
    #if [ $? -ne 0 ]; then
    #    local append7="        ro.product.version=$prodver"
    #    echo $append7
    #    sed -i '/PRODUCT_PROPERTY_OVERRIDES/a \'"$append7 \\\\"'' suying.mk
    #fi
}

#make sure rk3228.mk, buildinfo.sh and device.mk are not private
CleanRk3228bPrivateChange () {
    cd $RKSDK
    git co -- fastplay
    git co -- device.mk
    cd $buildtool
    git co -- buildinfo.sh
    cd $rk3228
    git co -- rk3228.mk
    cd $iptv
    git co -- suying.mk
    git co -- Android.mk
}

CleanRk3228hPrivateChange () {
    cd $RKSDK
    git co -- fastplay
    git co -- device.mk
    cd $buildtool
    git co -- buildinfo.sh
    cd $rk3228h
    git co -- rk3228h.mk
    cd $iptv
    git co -- suying.mk
    git co -- Android.mk
}

CheckSuyingMk () {
    cd $iptv
    iptvstr="IPTV_$carrier$province"
    iptv_num=$(grep "$iptvstr" suying.mk |grep -v "\#device"| wc -l)
    echo "number of $iptvstr is $iptv_num"
    ####.so file number####
    so_num=$(grep "\.so" suying.mk |grep -v "\#device"|wc -l)
    ####/bin####/etc
    sy_tracert_num=$(grep sy_tracert suying.mk |grep -v "\#device"| wc -l)
    dhcpcd_num=$(grep dhcpcd suying.mk |grep -v "\#device"| wc -l)
    sy_tr069_num=$(grep sy_tr069 suying.mk |grep -v "\#device"| wc -l)
    IptvServ_num=$(grep IptvServ suying.mk |grep -v "\#device"| wc -l)
    syConfig_num=$(grep syConfig.conf suying.mk |grep -v "\#device"| wc -l)

    init_iptv_rc_num=$(grep 'init\.iptv\.rc' suying.mk |grep -v "\#device"| wc -l)

    let file_num=sy_tracert_num+dhcpcd_num+sy_tr069_num+IptvServ_num+syConfig_num+syConfig_num+so_num
    echo "file_num is $file_num"

    if [ $iptv_num -gt $file_num ]; then
        echo "iptv_num > file_num"
    else
        echo "iptv_num < file_num"
        return 1
    fi
}


#a. 
#/kernel/arch/arm/boot/dts/rk322x.dtsi,
#rockchip,usb-mode = <1>;
#/*0 - Normal, 1 - Force Host, 2 - Force Device*/
#b.
#persist.sys.usb.config=mtp \
#to 
#persist.sys.usb.config=mtp,adb \

EnableRK3228BAdb () {
    cd $RKSDK
    local replaced="                persist.sys.usb.config=mtp,adb"
    echo $replaced
    sed -i 's/^.*persist.sys.usb.config.*$/'"$replaced \\\\"'/' device.mk
    
    cd "$WP/kernel/arch/arm/boot/dts"
    local replaced1="                rockchip,usb-mode = <0>;"
    echo $replaced1
    sed -i 's/^.*usb-mode.*$/'"$replaced1"'/' rk322x.dtsi
}

EnableRK3228HAdb(){
    cd $RKSDK
    local replaced="                persist.sys.usb.config=mtp,adb"
    echo $replaced
    sed -i 's/^.*persist.sys.usb.config.*$/'"$replaced \\\\"'/' device.mk
	
	grep persist.service.adb.enable device.mk
	if [ $? -eq 0 ]; then
		local appendx_adb="    persist.service.adb.enable=1"
		echo $replaced_hdid
		sed -i 's/^.*persist.service.adb.enable.*$/'"$appendx_adb \\\\"'/' device.mk
	fi

    cd "$WP/kernel/arch/arm64/boot/dts"
    if [ "$PRODUCTNAME" = "S-010W-AV2" ];then
        local replaced1="    rockchip,usb-mode = <2>;"
        echo $replaced1
        sed -i 's/^.*usb-mode.*$/'"$replaced1"'/' twowing_3228h_rk805_rtl8822_2layout_ddr3.dts
    elif [ "$PRODUCTNAME" = "G-120WT-Q" ];then
        local replaced1="    rockchip,usb-mode = <2>;"
        echo $replaced1
        sed -i 's/^.*usb-mode.*$/'"$replaced1"'/' rk322xh.dtsi
    else
        local replaced1="    rockchip,usb-mode = <2>;"
        echo $replaced1
        sed -i 's/^.*usb-mode.*$/'"$replaced1"'/' twowing_3228h_rk805_rtl8192_4layout_lpddr3.dts
    fi		
}

DisableRK3228HAdb(){
    cd $RKSDK
	grep persist.service.adb.enable device.mk
	if [ $? -eq 0 ]; then
		local appendx_adb="    persist.service.adb.enable=0"
		echo $replaced_hdid
		sed -i 's/^.*persist.service.adb.enable.*$/'"$appendx_adb \\\\"'/' device.mk
	fi
    cd "$WP/kernel/arch/arm64/boot/dts"
    if [ "$PRODUCTNAME" = "S-010W-AV2" ];then
        local replaced1="    rockchip,usb-mode = <1>;"
        echo $replaced1
        sed -i 's/^.*usb-mode.*$/'"$replaced1"'/' rk322xh.dtsi
    elif [ "$PRODUCTNAME" = "G-120WT-Q" ];then
        local replaced1="    rockchip,usb-mode = <1>;"
        echo $replaced1
        sed -i 's/^.*usb-mode.*$/'"$replaced1"'/' rk322xh.dtsi
    else
        local replaced1="    rockchip,usb-mode = <1>;"
        echo $replaced1
        sed -i 's/^.*usb-mode.*$/'"$replaced1"'/' twowing_3228h_rk805_rtl8192_4layout_lpddr3.dts
    fi
}

EnableAdbFunction () {
    if [ "$buildtype" = "3228b" ];then
        EnableRK3228BAdb
    elif [ "$buildtype" = "3228h" ];then
        EnableRK3228HAdb
    fi
}

DisableAdbFunction(){
    if [ "$buildtype" = "3228b" ];then
        echo "Nothing to do"
    elif [ "$buildtype" = "3228h" ];then
        DisableRK3228HAdb
    fi    
}

EnableRkUpdate () {
    cd $RKSDK
    grep rkupdateservice device.mk |grep "\#include"
    if [ $? -eq 0 ];then
        local replaced="include device\/rockchip\/common\/app\/rkupdateservice.mk"
        echo $replaced
        sed -i 's/^.*rkupdateservice.*$/'"$replaced"'/' device.mk
    fi
}

EnableRkLuancher () {
    cd $RKSDK
    grep rkitvlauncher device.mk |grep "\#"
    if [ $? -eq 0 ];then
        local replaced="    include device\/rockchip\/common\/app\/rkitvlauncher.mk"
        #local replaced="include device\/rockchip\/common\/app\/rkupdateservice.mk"
        echo $replaced
        sed -i 's/^.*rkitvlauncher.*$/'"$replaced"'/' device.mk
    fi
}

DisableRkLauncher () {
    cd $RKSDK
    grep rkitvlauncher device.mk |grep -v "\#"
    if [ $? -eq 0 ];then
        local replaced="#    include device\/rockchip\/common\/app\/rkitvlauncher.mk"
        echo $replaced
        sed -i 's/^.*rkitvlauncher.*$/'"$replaced"'/' device.mk
    fi    
}

EnableBackup(){
    cd $imgmake_tool/../
	grep "^backup" package-file.normal
    if [ $? -eq 0 ];then
        local replaced="backup        Image\/backup.img"
        echo $replaced
        sed -i 's/^backup.*$/'"$replaced"'/' package-file.normal
    else
        echo "There is no backup in package-file.normal"
    fi
}

DisableBackup(){
    cd $imgmake_tool/../
	grep "^backup" package-file.normal
    if [ $? -eq 0 ];then
        local replaced="backup        RESERVED"
        echo $replaced
        sed -i 's/^backup.*$/'"$replaced"'/' package-file.normal
    else
        echo "There is no backup in package-file.normal"
    fi
}

ActivateAnimation () {
    cd "$RKSDK/fastplay"
    if [ $enableanimation -eq 1 ];then
        #cp "$iptv/bootanimation.ts" .
        cp "$iptv/bootanimation.mp4" .
        rm bootanimation.zip
    elif [ $enableanimation -eq 2 ];then
        cp "$iptv/bootanimation.mp4" .
        cp "$iptv/bootanimation.zip" .

        cd $iptv
        grep persist.sys.bootmovie suying.mk
        if [ $? -ne 0 ]; then
            local append0="        persist.sys.bootmovie=true"
            echo $append0
            sed -i '/PRODUCT_PROPERTY_OVERRIDES/a \'"$append0 \\\\"'' suying.mk
        fi      
    else
        cp "$iptv/bootanimation.zip" .
        #rm bootanimation.ts
        rm bootanimation.mp4
    fi
}

ActivateDownloadApp () {
    cd "$iptv"
    if [ $enabledownloadapp -eq 1 ] && [ "$downloadappapk" != "bla" ]; then
        grep persist.appstore.packagename suying.mk
        if [ $? -ne 0 ];then
            local append="        persist.appstore.packagename=$downloadappapk"
            echo $append
            sed -i '/PRODUCT_PROPERTY_OVERRIDES/a \'"$append \\\\"'' suying.mk
        else
            echo "!!!! We assume you've checkin the suying.mk and we don't change that"
        fi
    else
        echo "!!!! Alert, You didn't activate the download app function,please check iptvcde.ini"
    fi
}


Realstandby (){
    cd $iptv
##now rkupdateservice.mk
#########rkupdateservice function already added###########
##now persist.sys.realsleep
    grep persist.sys.realsleep suying.mk
    if [ $? -ne 0 ]; then
       local append1="        persist.sys.realsleep=true"
       echo $append1
       sed -i '/PRODUCT_PROPERTY_OVERRIDES/a \'"$append1 \\\\"'' suying.mk
	   echo "added persist.sys.realsleep=true"
	else
	   echo "persist.sys.realsleep existed in suying.mk"
	fi 
	
##now system.SuspendOrReboot
    grep system.SuspendOrReboot suying.mk
    if [ $? -ne 0 ]; then
       local append2="        system.SuspendOrReboot=true"
       echo $append2
       sed -i '/PRODUCT_PROPERTY_OVERRIDES/a \'"$append2 \\\\"'' suying.mk
	   echo "added system.SuspendOrReboot=true"
	else
	   echo "system.SuspendOrReboot existed in suying.mk"
	fi 

}


#device.mk ,no need to be changed !!

#Our workspace strategy is clear : Only maintain the RKSDK as local change
#For all other local change, include : 
CleanWorkspace () {
    if [ "$buildtype" = "3228b" ];then
        CleanRk3228bPrivateChange #RK3228.mk, buildinfo.sh, device.mk
        cd "$WP/kernel/arch/arm/boot/dts"
        git co -- rk322x.dtsi
    elif [ "$buildtype" = "3228h" ];then
        CleanRk3228hPrivateChange #RK3228h.mk, buildinfo.sh, device.mk
        cd "$WP/kernel/arch/arm64/boot/dts"
        git co -- twowing_3228h_rk805_rtl8192_4layout_lpddr3.dts
    else
        echo "Clean Workspace failed"
        exit
    fi		
}

Enablehdmicec () {
    cd $iptv
	grep persist.sys.isTvStandby suying.mk
    if [ $? -ne 0 ]; then
       local append="        persist.sys.isTvStandby=true"
       echo $append
       sed -i '/PRODUCT_PROPERTY_OVERRIDES/a \'"$append \\\\"'' suying.mk
	   echo "persist.sys.isTvStandby=true"
	else
	   echo "persist.sys.isTvStandby existed in suying.mk"
	fi
    
    grep persist.sys.TvStanbytimeout suying.mk
    if [ $? -ne 0 ]; then
       local append="        persist.sys.TvStanbytimeout=3"
       echo $append
       sed -i '/PRODUCT_PROPERTY_OVERRIDES/a \'"$append \\\\"'' suying.mk
	   echo "persist.sys.TvStanbytimeout=3"
	else
	   echo "persist.sys.TvStanbytimeout existed in suying.mk"
	fi
    
    
}


EnableCdeFunction () {
    if [ $enableadb -eq 1 ];then
       EnableAdbFunction
    else
       DisableAdbFunction
    fi
    
    if [ $enablerkupdate -eq 1 ];then
        EnableRkUpdate
    fi
    if [ $enableRkLauncher -eq 1 ];then
        EnableRkLuancher
    else
        DisableRkLauncher
    fi
	
    if [ $enbackup -eq 1 ];then
        EnableBackup
        mkbackup="true"
    else
        DisableBackup
    fi	
	
    if [ $enablerealstandby -eq 1 ];then
        Realstandby
	fi	
	
	if [ $enablehdmicec -eq 1 ];then 
        Enablehdmicec
    fi
	if [ $enTestVideoPlay -eq 0 ]; then
		enableVideoPlayer_cuhe	
	fi
    ActivateAnimation
    ActivateDownloadApp
}

	
enableVideoPlayer_cuhe () {

	echo "CheckVideoPlayer_cuhe function province is $province, carrier is $carrier"
    if [ "$province" = "he" ] && [ "$carrier" = "cu" ]; then
        source buildcde.sh
		DeleteThirdApk TestVideoPlay
		echo "delete TestVideoPlay.apk completed!!!"
	fi
}
DisableFactoryMode () {
    cd $iptv
    grep ro.build.office suying.mk
    if [ $? -ne 0 ];then
        return $?
    fi
    local replaced="        ro.build.office=NSB_IPTV_$carrier$province"
    echo $replaced
    sed -i 's/^.*ro.build.office.*$/'"$replaced"'/' suying.mk
}

#Very funcking solution:
ResetFactoryPatch () {
    cd $WP/kernel
    git reset --hard 61710ae3b02117952ecc0aa414887d82b0b55968
    git status |grep modified|grep dhd_config.c
    if [ $? -ne 0 ];then
        echo "+++++++++++Bro, you've restore the kernel successfully++++++++++"
    fi
}

ReadUserInputForNormal () {
    # read wifi type
    echo "you want to build private mode image, please input your moduletypes"
    echo "For public mode image, Just Press Enter"
    HelpWifis
    read wifi
    case $wifi in
    "1")
        wifi="bgn";;
    "2")
        wifi="ac";;
    "3")
        wifi="nowifi";;
    *)
        wifi=$wifi;;
    esac
    CheckWifis $wifi
    if [ $? -eq 1 ]; then
        echo "Sorry, You've input wrong Module types !!!!"
        return 1
    fi

    if [ "$buildtype" = "3228b" ];then
        inputchip="rk3228b"
    elif [ "$buildtype" = "3228h" ];then
        inputchip="rk3228h"
    else
        echo "buildtype is not right"
        return 1
    fi
    
    local dts=
    if [ $wifi == "ac" ];then
        HelpAcDts
        read dts
        case $dts in
        "1")
           dts="rtl8822bs";;
        "2")
           dts="en7526g";;
        *)
           dts=$dts;;
        esac
        CheckAcDts $dts
        if [ $? -eq 1 ];then
            echo "Sorry, You've input wrong dts type !!!!"
            return 1
        fi
    elif [ $wifi == "bgn" ] ;then
        HelpBgnDts
        read dts
        case $dts in
        "1")
           dts="rtl8189etv";;
        "2")
           dts="rtl8676";;
        "3")
           dts="mtk7526fu";;
        "4")
           dts="8189ftv";;
        "5")
           dts="en7526fd";;
        *)
           dts=$dts;;
        esac
        CheckBgnDts $dts
        if [ $? -eq 1 ];then
            echo "Sorry, You've input wrong dts type !!!!"
            return 1
        fi
    else [ $wifi == "nowifi" ]
        HelpNoWifiDts
        read dts
        case $dts in
        "1")
           dts="nowifi";;
        *)
           dts=$dts;;
        esac
        CheckBgnDts $dts
        if [ $? -eq 1 ];then
            echo "Sorry, You've input wrong dts type !!!!"
            return 1
        fi
    fi
    inputmodule=$dts
    #local python_s=$BUILD/input/$middleware/$carrier$province
}

CheckVersionReturn () {
    local ret=$1
    if [ $ret = 'lessargs' ];then
        echo "less arguments than the method"
        return 1
    elif [ $ret = '2manyargs' ];then
        echo "more arguments than the method needed"
        return 1
    elif [ $ret = 'wrongmethod' ];then
        echo " not accepted method like 'getExtStr' or 'getInnerStr' or 'getFacStr' or 'getVendorStr' "
        return 1
    elif [ $ret = 'hwerror' ];then
        echo "the combination of ¡®Chips¡¯ + ¡®Wifigroups¡¯ can not be found"
        return 1
    elif [ $ret = 'nokey' ];then
        echo " your input cannot make the translation"
        return 1
    elif [ $ret = 'facimgFalse' ];then
        echo "Alert !!!!!!!!!!!!!!!!!!!!!!!!!!!!"
        echo " your local factory.img is not newest"
        echo "please synchronization on 194"
        echo "###############"
        return 1
    elif [ $ret = 'modeFalse' ];then
        echo "Alert !!!!!!!!!!!!!!!!!!!!!!!!!!!!"
        echo " your MACHINE_MODEL and PRODUCT_MODEL is not same"
        echo "plese check paramater and rk3228x.mk!"
        echo "###############"
        return 1
    fi
    set +e
    echo "python script return value is: $ret"
}

UpdateVersionStr () {
    local python_s="$vendorpath"
    local inputchip_u=`tr '[a-z]' '[A-Z]' <<<"$inputchip"`
    local inputmodule_u=`tr '[a-z]' '[A-Z]' <<<"$inputmodule"`
    echo "PRODUCTNAME=$PRODUCTNAME"
    echo "inputchip_u=$inputchip_u"
    echo "inputmodule_u=$inputmodule_u"
    echo "middleware=$middleware"
    echo "inputlauncher=$inputlauncher"
    echo "carrierprovince=$carrier$province"
	
    hw_id=$(python $python_s/intmapext.py  "getHwId" "$PRODUCTNAME" "$inputchip_u" "$inputmodule_u" "$middleware" "$inputlauncher" "$carrier$province" $majorversion $minorversion)
        CheckVersionReturn $hw_id
		
    nsb_oui=$(python $python_s/intmapext.py  "getOui" "$PRODUCTNAME" "$inputchip_u" "$inputmodule_u" "$middleware" "$inputlauncher" "$carrier$province" $majorversion $minorversion)
        CheckVersionReturn $nsb_oui
		
    display_id=$(python $python_s/intmapext.py  "getDisplayId" "$PRODUCTNAME" "$inputchip_u" "$inputmodule_u" "$middleware" "$inputlauncher" "$carrier$province" $majorversion $minorversion)
        CheckVersionReturn $display_id
		
    imgpfx=$(python $python_s/intmapext.py  "getImgPfx" "$PRODUCTNAME" "$inputchip_u" "$inputmodule_u" "$middleware" "$inputlauncher" "$carrier$province" $majorversion $minorversion)
        CheckVersionReturn $imgpfx
		
    if [ $buildfactory -eq 1 ]; then	
        facVersion=$(python $python_s/intmapext.py  "getFacStr" "$PRODUCTNAME" "$inputchip_u" "$inputmodule_u" "$middleware" "$inputlauncher" "$carrier$province" $majorversion $minorversion)    
        CheckVersionReturn $facVersion
     
        vendorVersion=$(python $python_s/intmapext.py  "getVendorStr" "$PRODUCTNAME" "$inputchip_u" "$inputmodule_u" "$middleware" "$inputlauncher" "$carrier$province" $majorversion $minorversion)    
        CheckVersionReturn $vendorVersion
        if [ $? -eq 1 ]; then
            return 1
        fi		
    else
        innerVersion=$(python $python_s/intmapext.py  "getInnerStr" "$PRODUCTNAME" "$inputchip_u" "$inputmodule_u" "$middleware" "$inputlauncher" "$carrier$province" $majorversion $minorversion)
        CheckVersionReturn $innerVersion
       
        vendorVersion=$(python $python_s/intmapext.py  "getVendorStr" "$PRODUCTNAME" "$inputchip_u" "$inputmodule_u" "$middleware" "$inputlauncher" "$carrier$province" $majorversion $minorversion)    
        CheckVersionReturn $vendorVersion	

        extVersion=$(python $python_s/intmapext.py  "getExtStr" "$PRODUCTNAME" "$inputchip_u" "$inputmodule_u" "$middleware" "$inputlauncher" "$carrier$province" $majorversion $minorversion)    
        CheckVersionReturn $extVersion
        if [ $? -eq 1 ]; then
            return 1
        fi
     fi   

}
BuildCheck(){
    local python_s="$vendorpath"
    local inputchip_u=`tr '[a-z]' '[A-Z]' <<<"$inputchip"`
    local inputmodule_u=`tr '[a-z]' '[A-Z]' <<<"$inputmodule"`
    local branchname="g120wtp_zy_"$carrier"_"$province
    echo "PRODUCTNAME=$PRODUCTNAME"
    echo "inputchip_u=$inputchip_u"
    echo "carrierprovince=$carrier$province" 
    echo "branchname=$branchname"
    local flag=0
    
    if [ $buildfactory -ne 1 ]; then
        #This must first check,please do not put other check upside this	
        gitStatus_ret=$(python $python_s/buildCheck.py  "checkGitStatus" "$PRODUCTNAME" "$inputchip_u" "$carrier$province" "$branchname" $inputlauncher)
        if [ "$gitStatus_ret" == "changed" ];then
            if [ $majorversion -ne 0 ];then
                echo "Please select comtinue build or break build."
                echo "##### continue(1) break(2) #####"
                read ans
                if [ $ans == "break" ] || [ $ans -eq 2 ];then
                    echo "Exit,please check uncommit folder."
                    exit
                elif [ $ans == "continue" ] || [ $ans -eq 1 ];then
                    echo "Continue build."
                else
                    echo "Select error."
                fi
            fi			
        elif [ "$gitStatus_ret" == "nochanged" ];then
            echo "No folder commit changed,continue build."
        fi
	
        fac_ret=$(python $python_s/buildCheck.py  "checkFacImg" "$PRODUCTNAME" "$inputchip_u" "$carrier$province" "$branchname" $inputlauncher)		
        if [ "$fac_ret" == "False" ];then
            echo "buildCheck return false!! line 1114"
            flag=1
        fi
		
        nsbMaintenancer_ret=$(python $python_s/buildCheck.py  "checkNsbMaintenance" "$PRODUCTNAME" "$inputchip_u" "$carrier$province" "$branchname" $inputlauncher)    
        if [ "$nsbMaintenancer_ret" == "False" ];then
            echo "buildCheck return false!! line 1140"
            flag=1
        fi
    fi

    nomal_ret=$(python $python_s/buildCheck.py  "checknormalInput" "$PRODUCTNAME" "$inputchip_u" "$carrier$province" "$branchname" $inputlauncher)    
    if [ "$nomal_ret" == "False" ];then
        echo "buildCheck return false!! line 1121"
        flag=1
    fi

    keyValueMapping_ret=$(/usr/bin/python3 $python_s/keyValueMapping.py  "$PRODUCTNAME" "$inputchip_u" "$carrier$province" "$branchname" $inputlauncher $imgpfx)    
    if [ "$keyValueMapping_ret" == "False" ];then
        echo "keyValueMapping return false!! line 1105"
        flag=1
    fi	
	
    parameter_ret=$(python $python_s/buildCheck.py  "checkBuildParameter" "$PRODUCTNAME" "$inputchip_u" "$carrier$province" "$branchname" $inputlauncher $imgpfx)    
    if [ "$parameter_ret" == "False" ];then
        echo "buildCheck return false!! line 1127"
        flag=1
    fi
	
    config_ret=$(python $python_s/buildCheck.py  "checkConfig" "$PRODUCTNAME" "$inputchip_u" "$carrier$province" "$branchname" $inputlauncher)    
    if [ "$config_ret" == "False" ];then
        echo "buildCheck return false!! line 1125"
        flag=1
    fi
	
    if [ $flag -eq 1 ];then
        exit
    else
        return 0
    fi
}

CheckPreBuild1 () {
    CheckInputParameter
    if [ $? -eq 1 ]; then
        echo "Sorry, You've input wrong version number, please re-input !!!!"
        return 1
    fi
    #   Please be noted that clean must be the first, for multi-launcher, it maybe copy the 
    #   launcher file first !!!!
    source buildcde.sh
    #CleanPrivateChange      #make sure all private of rk3228/device/buildinfo.sh local change co
	CleanWorkspace
    echo "Check pre-build function"
    #HandleMultiLauncher
    CheckMultiLauncher
    if [ $? -eq 1 ]; then
        return 1
    fi
    ReadUserInputForNormal
    if [ $? -eq 1 ];then
        echo "error!!!"
        return 1
    fi
    if [ $? -eq 1 ]; then
        echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
        echo "you build mk is not compatible with your input, please re-check !!!!!!!"
        return 1
    fi
    UpdateVersionStr
    if [ $? -eq 1 ]; then
        echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
        echo "Update version string failed, please re-check !!!!!!!"
        return 1
    fi
	
    CheckVersion
    local retval=$?
    echo "CheckVersion return value is: $retval"
    if [ $retval -eq 1 ]; then
        echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
        echo "you input is invalid, please re-Input !!!!!!!"
        return 1
    fi
	
    ReadCdeParameter
    if [ "$buildtype" = "3228b" ];then
        echo "buildprepare.sh 1115"
        CheckRk3228bMk
    elif [ "$buildtype" = "3228h" ];then
        CheckRk3228hMk
    else
        echo "product name is not right"
        exit
    fi    
    CheckDeviceMk
    CheckBuildInfo
    echo "##########"
    echo $innerVersion
    echo "##########"
    echo "##########"
    echo $extVersion
    echo "##########"
    echo "##########"
    echo $vendorVersion
    echo "##########"
    echo "##########"
    echo $facVersion
    echo "##########"
    echo "##########"
    echo $imgpfx
    echo "##########"
    echo "##########"
    echo $display_id
    echo "##########"
    if [ "$buildtype" = "3228b" ];then
        MdRk3228bSuyingMk
    elif [ "$buildtype" = "3228h" ];then
        MdRk3228hSuyingMk
    else
        echo "product name is not right"
        exit
    fi
    MdAllowInstallApps
    EnableCdeFunction
	
    DisableFactoryMode
    BuildCheck
}

#make sure ro.build.office=NSB_IPTV_FAC_BASE
EnableFactoryMode () {
    cd $iptv
    grep ro.build.office suying.mk
    if [ $? -ne 0 ];then
        return $?
    fi
    local replaced="        ro.build.office=NSB_IPTV_FAC_BASE"
    echo $replaced
    sed -i 's/^.*ro.build.office.*$/'"$replaced"'/' suying.mk
}

#Very ugly solution
AddFactroyPatch () {
    cd $WP/kernel
    git status |grep modified|grep dhd_config.c
    if [ $? -eq 0 ];then
        echo "+++++++++++Bro, you've add the kernel successfully++++++++++"
        return 0
    fi
    git am /home/mengxl/build/patch/patch/kernel/0001-kernel-patch-for-making-factory-img.patch
    git am /home/mengxl/build/patch/patch/kernel/0002-add-wireless-driver-rtl8192eu.patch
    patch -p1 < /home/mengxl/build/patch/patch/kernel/0003-cpy-to-nvram_ap6356s.txt-on-BCM4356_CHIP_ID-BCM4371_C.patch 
    
}

CheckPreBuildFactory () {
    CheckInputParameter
    if [ $? -eq 1 ]; then
        echo "Sorry, You've input wrong version number, please re-input !!!!"
        return 1
    fi
#   check wifi types
    echo "Factory Image generation must input Wifi types !!!"
    HelpWifis
    read wifi
    case $wifi in
    "1")
        wifi="bgn";;
    "2")
        wifi="ac";;
    "3")
        wifi="nowifi";;
    *)
        wifi=$wifi;;
    esac
    CheckWifis $wifi
    if [ $? -eq 1 ]; then
        echo "Sorry, You've input wrong wifi types !!!!"
        return 1
    fi
    CAPWIFI=${wifi^^}
#   read chip type
    if [ "$buildtype" = "3228b" ];then
        inputchip="rk3228b"
    elif [ "$buildtype" = "3228h" ];then
        inputchip="rk3228h"
    else
        echo "buildtype is not right"
        return 1
    fi
	
	    local dts=
    if [ $wifi == "ac" ];then
        HelpAcDts
        read dts
        case $dts in
        "1")
           dts="rtl8822bs";;
        "2")
           dts="en7526g";;
        *)
           dts=$dts;;
        esac
        CheckAcDts $dts
        if [ $? -eq 1 ];then
            echo "Sorry, You've input wrong dts type !!!!"
            return 1
        fi
    elif [ $wifi == "bgn" ] ;then
        HelpBgnDts
        read dts
        case $dts in
        "1")
           dts="rtl8189etv";;
        "2")
           dts="rtl8676";;
        "3")
           dts="mtk7526fu";;
        "4")
           dts="8189ftv";;
        "5")
           dts="en7526fd";;
        *)
           dts=$dts;;
        esac
        CheckBgnDts $dts
        if [ $? -eq 1 ];then
            echo "Sorry, You've input wrong dts type !!!!"
            return 1
        fi
    else [ $wifi == "nowifi" ]
        HelpNoWifiDts
        read dts
        case $dts in
        "1")
           dts="nowifi";;
        *)
           dts=$dts;;
        esac
        CheckBgnDts $dts
        if [ $? -eq 1 ];then
            echo "Sorry, You've input wrong dts type !!!!"
            return 1
        fi
    fi
    inputmodule=$dts
	
#   clean related local changes. clean workspace or private change?
    if [ "$buildtype" = "3228b" ];then
        CleanRk3228bPrivateChange
    elif [ "$buildtype" = "3228h" ];then
        CleanRk3228hPrivateChange
    else
        echo "product name is not right"
        exit
    fi    
#   check factory build related parameters.
    EnableFactoryMode
    if [ $? -ne 0 ]; then
        echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
        echo "you build mk is not compatible with your input, please re-check !!!!!!!"
        return 1
    fi
    UpdateVersionStr
    if [ $? -eq 1 ]; then
        echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
        echo "Update version string failed, please re-check !!!!!!!"
        return 1
    fi
	
#   check if need to input version:
    CheckVersion
    if [ $? -eq 1 ]; then
        echo "Sorry, You've input wrong version number, please re-input !!!!"
        return 1
    fi
	
    ReadCdeParameter	
    if [ "$buildtype" = "3228b" ];then
        CheckRk3228bMk
    elif [ "$buildtype" = "3228h" ];then
        CheckRk3228hMk
    else
        echo "product name is not right"
        exit
    fi    
    CheckDeviceMk
    CheckBuildInfo
    echo "##########"
    echo $innerVersion
    echo "##########"
    echo "##########"
    echo $extVersion
    echo "##########"
    echo "##########"
    echo $vendorVersion
    echo "##########"
    echo "##########"
    echo $facVersion
    echo "##########"
    echo "##########"
    echo $imgpfx
    echo "##########"
    echo "##########"
    echo $display_id
    echo "##########"
    if [ "$buildtype" = "3228b" ];then
        MdRk3228bSuyingMk
    elif [ "$buildtype" = "3228h" ];then
        MdRk3228hSuyingMk
    else
        echo "product name is not right"
        exit
    fi
	
    BuildCheck
#   all function switch on:
    enableadb=0
    enablerkupdate=1
    EnableCdeFunction
    #AddFactroyPatch
}


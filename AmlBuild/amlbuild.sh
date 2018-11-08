#/bin/sh

#/bin/sh

#this build tool aims to make sure that you can :
#prepare related package
#copy prepared file into work directory
#build and check
#generate related file

wifi=""
carrier=""
province=""
middleware=""
MIDDLEWARECAP="ZY"
productswversion=""
producthwversion=""
#PRODUCTVERSION="R1.00.00"
declare -i majorversion=0
declare -i minorversion=0
VERSIONSTR=""
VERSIONSTR1=""
CAPMIDDLEWARE=""
PRODUCTNAME=""
inputlauncher="nolauncher"
wifitypes=( bgn ac nowifi )
acdtstypes=( rtl8822bs en7526g )
bgndtstypes=( rtl8189etv rtl8676  mtk7526fu 8189ftv en7526fd nowifi)
chiptypes=( s905l s905lv2 s905l2 s905l3)
mdwaretypes=( zy nsb )
unit_types=( RG020ET-CA CMIOT-EG-E02  S-010W-AV2A S-010W-AV2A-1 S-010W-AV2A-2 S-010W-A NSB_RG020ETCA S-010W-AV2T S-010W-AV2D)
inputmodule=""
inputchip=
LETTER=
CAPWIFI=""
UnitType=""
vendorpath="$HOME/amlbuild"
#PRODUCT_NAME_CU="S-010W-P"
#PRODUCT_NAME_CT="S-010W-A"
PRODUCT_NAME_CT="RG020ET-CA"
#PRODUCT_WASHU="S-010W-A-1"
#PRODUCT_BESTV="S-010W-A-2"
CAPPROVINCE=""
CAPCARRIER=""
PRODUCT_MODEL=""
IntVer=""
launcher=""
innerVersion=""
extVersion=""
vendorVersion=""

WP="$HOME/workspace"
preinstall="$WP/device/amlogic/common/ChinaMobile_apks/sh/preinstallation"
ChinaMobile_apks="$WP/device/amlogic/common/ChinaMobile_apks/sh/"
BuildPath="$HOME/amlbuild/image"
iptv="$WP/device/amlogic/p201_iptv"
buildtool="$WP/build/tools"

imgfile=""
otafile=""
intzip=""
basicota=""
oui=""
hw_id=""
display_id=""

ToolHelp () {
    echo "**************************************************************************"
    echo "You must first input the realted vendor and province, then:"
    echo "You have several options to run the scripts"
    echo "Prepare : try to unpack related middleware zip file into correct directory"
    echo "Copyfile : copy related prepared file into correct workarea"
    echo "Build : call build shell and generate related image file"
    echo "And all valid input must include the vendor,province,shell execution"
    echo "**************************************************************************"
}


vendors=( ct cu cm ba)
provinces=( bj tj he sx nm ln jl hl sh js zj ah fj jx sd ha hb hn gd hi gx cq sc gz yn sn gs qh nx xj xz jc hq se qd ossm)
launchers=( huawei fenghuo )

#check all branch , use git branch -a , check current branch , use git branch
#use grep -w to make sure the whole word matched !!!! //with grep -w "* branchname"



HelpVendors () {
	echo " the accepted vendors are: "
	echo " ##########################################################"
	echo " ct: china telecom, cu: china unicom, cm: china mobile"
	echo " ##########################################################"
	#echo " Please input vendor name: "
}

CheckVendors () {
    echo "Function CheckVendors"
#   remember if local variable is found, must declare it as local
    local found=0
	#echo "Please input vendor : "
	#read vendor
    carrier=$1
	for i in "${vendors[@]}"
	do
        #echo $i
        if [ "$i" = "$carrier" ]; then
            echo "Input vendor Found"
            found=1
        fi
	done
	if [ $found -eq 0 ]; then
		echo "Input vendor is not in correct format"
		return 1
	fi  
}

HelpProvinces () {
	echo "the accepted provinces are: "
	echo "###########################################################"
	echo "beijing : bj		henan : ha"
	echo "tianjin : tj		hubei : hb"
	echo "hebei : he		hunan : hn"
	echo "shanxi : sx		guangdong : gd"
	echo "neimenggu : nm	hainan : hi"
	echo "liao ning : ln	guangxi : gx"
	echo "jilin : jl		chongqing : cq"
	echo "heilongjiang : hl	sichuan : sc"
	echo "shanghai : sh		guizhou : gz"
	echo "jiangsu : js		yunnan : yn"
	echo "zhejiang : zj		shan'xi(shan: third tone) : sn"
	echo "anhui : ah		gansu : gs"
	echo "fujian : fj		qinhai : qh"
	echo "jiangxi : jx		ningxia : nx"
	echo "shandong : sd		xinjiang : xj"
	echo "xizang : xz       qingdao : qd"      
	echo "Company jicai : jc  headquarters ：hq  factorytest : ft"
	echo "sing  meng : ossm"
	echo "###########################################################"
	#echo "Please input province name: "
}

CheckProvinces () {
    echo "Function CheckProvinces"
#   remember if local variable is found, must declare it as local
    local found=0
	#echo "Please input province : "
	#read province
    province=$1
	for i in "${provinces[@]}"
	do
        #echo $i
        if [ "$i" = "$province" ]; then
            echo "Input province Found"
            found=1
        fi
	done
	if [ $found -eq 0 ]; then
		echo "Input province is not in correct format"
		return 1
	fi  

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

HelpWifis () {
echo " the accepted wifi types are: "
echo " ##############################################"
echo "  bgn(1)       (802.11 b/g/n)"
echo "  ac(2)        (802.11 b/g/n/ac)"
echo "  nowifi(3)    (no wifi module)"
echo " ##############################################"    
}

CheckWifis () {
    echo "Function CheckWifis, you have input wifi type: $1"
#   remember if local variable is found, must declare it as local
    local found=0
	#echo "Please input wifis : "
	#read province
    wifi=$1
    for i in "${wifitypes[@]}"
    do
        #echo $i
        if [ "$i" = "$wifi" ]; then
            echo "Input wifi Found"
            found=1
        fi
    done
    if [ $found -eq 0 ]; then
        echo "Input wifi type is not in correct format"
        return 1
    fi  
}


HelpAcDts () {
echo " the accepted ACdts types are: "
echo " ##########################################################"
echo "    rtl8822bs(1)    (  S-010W-AV2  )      "
echo "    en7526g(2)      (  G-120WT-R  )      "
echo " ##########################################################"     
}

HelpNoWifiDts () {
echo " the accepted ACdts types are: "
echo " ##########################################################"
echo "    nowifi(1)      (  S-010W-AV2S  S-010W-AV2T )      "
echo " ##########################################################"     
}

HelpBgnDts () {
echo " the accepted dts types are: "
echo " ##########################################################"
echo "    rtl8189etv(1)    ( S-010W-A ) "     
echo "    rtl8676(2)       ( RG020ET-CA ) " 
echo "    mtk7526fu(3)     ( G-120WT-P ) " 
echo "    8189ftv(4)       ( S-010W-AV2B   S-010W-AV2C ) " 
echo "    en7526fd(5)      ( G-120WT-R ) "
echo " ##########################################################"     
}

CheckAcDts () {
    echo "Function CheckAcDts, you have input dts type: $1"
    local found=0
    local dts=$1
    for i in "${acdtstypes[@]}"
    do
        if [ $i = $dts ];then
            echo "Input dts Found"
            found=1
        fi
    done 
    if [ $found -eq 0 ];then
        echo "Input dts type is not in correct format"
        return 1
    fi
}

CheckBgnDts () {
    echo "Function CheckBgnDts, you have input dts type: $1"
    local found=0
    local dts=$1
    for i in "${bgndtstypes[@]}"
    do
        if [ $i = $dts ];then
            echo "Input dts Found"
            found=1
        fi
    done 
    if [ $found -eq 0 ];then
        echo "Input dts type is not in correct format"
        return 1
    fi
}
HelpMiddlewares () {
	echo " the accepted chip types are: "
	echo " ##########################################################"
	echo "            zy(1)             nsb(2)                    "
	echo " ##########################################################"     
}

CheckMiddlewares () {
    echo "Function CheckChips, you have input middleware type: $1"
    local found=0
    local mdware=$1
    for i in "${mdwaretypes[@]}"
    do
        if [ $i = $mdware ];then
            echo "Input middleware Found"
            found=1
        fi
    done 
    if [ $found -eq 0 ];then
        echo "Input middleware type is not in correct format"
        return 1
    fi
}

HelpProduct () {
echo " Now need the product name ,Please select the  prudct name: "
echo " ################################################################################################################"
echo "   RG020ET-CA(1) CMIOT-EG-E02(2) S-010W-AV2T(3) S-010W-AV2A(4) S-010W-A(5) NSB_RG020ETCA(6) S-010W-AV2D(7)     "
echo "   S-010W-AV2A-1(8) S-010W-AV2A-2(9)"
echo " #################################################################################################################"
}

HelpUnitType () 
{
    HelpProduct
    read UnitType
       case $UnitType in
        "1")
           UnitType="RG020ET-CA";;
        "2")
           UnitType="CMIOT-EG-E02";;
        "3")
           UnitType="S-010W-AV2T";;
        "4")
           UnitType="S-010W-AV2A";;
        "5")
           UnitType="S-010W-A";;
        "6")
           UnitType="NSB_RG020ETCA";;
        "7")
           UnitType="S-010W-AV2D";;
        "8")
           UnitType="S-010W-AV2A-1";;
        "9")
           UnitType="S-010W-AV2A-2";;
        *)
           UnitType=$UnitType;;
        esac		
}

CheckUnitType ()
{
	echo "Function CheckUnitType"
#   remember if local variable is found, must declare it as local
    local found=0
	#read vendor
	echo "the unit_type is $UnitType"
	for i in "${unit_types[@]}"
	do
        #echo $i
        if [ "$i" = "$UnitType" ]; then
            echo "Input unit_type Found"
            found=1
        fi
	done
	if [ $found -eq 0 ]; then
		echo "Input unit_type is not in correct format"
		return 1
	fi
	
}


#use major version and minor string to generate Version String, accept the input of 
#$1: majorversion and $2: minorversion
GenVersionStr () {
    if [ $# -ne 2 ]; then
        echo " You must input majorversion and minor version"
        return 1
    fi
    local zero="0"
    local mjversion=$1
    local mnversion=$2
    if [[ $mjversion -ge 0 ]] && [[ $mjversion -lt 10 ]];then
        local mjverstr="$zero$mjversion"
    else
        mjverstr="$mjversion"
    fi
    if [[ $mnversion -ge 0 ]] && [[ $mnversion -lt 10 ]];then
        local mnverstr="$zero$mnversion"
    else
        mnverstr="$mnversion"
    fi
    if [ $PRODUCTNAME = "S-010W-AV2A-2" ] && [ $carrier$province = "cmsh" ];then
            VERSIONSTR="1.$mjverstr.$mnverstr"
    elif [ $PRODUCTNAME = "S-010W-AV2A-1" ] && [ $carrier$province = "cmsh" ];then
            VERSIONSTR="2.$mjverstr.$mnverstr"  
    elif [ $inputchip = "s905l3" ] && [ $carrier$province = "ctjc" ];then
        VERSIONSTR="1.$mjversion.$mnversion"
    elif [ $inputchip = "s905l3" ] && [ $carrier$province = "cthq" ];then
        VERSIONSTR="1.$mjversion.$mnversion"
    elif [ $inputchip = "s905l2" ] && [ $carrier$province = "cujc" ];then
        VERSIONSTR="1.$mjverstr.$mnverstr"
    else
        VERSIONSTR="R1.$mjverstr.$mnverstr"
        VERSIONSTR1="1.$mjverstr.$mnverstr"
    fi
}

# majorversion : $1, minor version $2
SetVersion () {
#   only accept 0-99 version. other wise rejected this change
    if [[ $1 -ge 0 ]] && [[ $1 -lt 100 ]];then
        majorversion=$1
    fi
    if [[ $2 -ge 0 ]] && [[ $2 -lt 100 ]];then
        minorversion=$2
    fi
    echo "major is :$1, minor is $2"
}

#common procedure:
SubstrMatch () {
	echo "$1" | grep -q "$2"
    return $?
}

SubstrMatch1 () {
	#if echo "$1" | grep -q "$2" |grep -v "$3"; then
	echo "$1" | grep "$2" |grep "$3"
    return $?
}

#condition 1: match, condtion 2: exclude
SubstrMatch2 () {
	#if echo "$1" | grep -q "$2" |grep -v "$3"; then
	echo "$1" | grep "$2" |grep -v "$3"
    return $?
}



CheckBranchParamValid () {
    echo "Function CheckBranchParamValid"
    CheckVendors $1
	if [ $? -eq 1 ]; then
		return 1
    fi
    CheckProvinces $2
 	if [ $? -eq 1 ]; then
		return 1
    fi 
	
}

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
        
        if [ $? -ne 0 ]; then
            echo "CheckOtaValid Not Valid, must Return !!!!!"
            return 1
        fi

    fi
    return 0
}

CheckBuildInfoExp(){
    Incre=$extVersion

	local replaced="echo \"ro.build.display.id=$display_id\""
    echo $replaced
    sed -i 's/^.*ro.build.display.id.*$/'"$replaced"'/' buildinfo.sh

    if [ $PRODUCTNAME = "NSB_RG020ETCA" ] && [ $carrier$province = "ctgd" ];then
        replacedIncre2="echo \"ro.build.version.release=$Incre\""
        sed -i 's/^.*ro.build.version.release=.*$/'"$replacedIncre2"'/' buildinfo.sh
    else
        replacedIncre="echo \"ro.build.version.incremental=$Incre\""
        #echo $replacedIncre
        sed -i 's/echo \"ro.build.version.incremental=.*$/'"$replacedIncre"'/' buildinfo.sh
    fi		

    grep android.os.Build.VERSION.INCREMENTAL buildinfo.sh
	if [ $? -ne 0 ]; then
		local appendx="echo \"android.os.Build.VERSION.INCREMENTAL=$Incre\""
		echo $appendx
		sed -i '/ro.build.version.incremental/a \'"$appendx \\"'' buildinfo.sh
	fi   
}

CheckBuildInfo () {
    local inputchip_u=`tr '[a-z]' '[A-Z]' <<<"$inputchip"`
    cd $buildtool
	git checkout -- buildinfo.sh

    if [ "$carrier$province" = "cmsh" ] || [ "$carrier$province" = "ctjc" ]|| [ "$carrier$province" = "cujc" ]|| [ "$carrier$province" = "cthq" ];then	
        echo "Do not use CheckBuildInfoExp"
    else
        CheckBuildInfoExp
    fi		

	if [ "$PRODUCTNAME" = "CMIOT-EG-E02" ];then
        local replaced1='echo "ro.product.manufacturer=CIOT"'
        local rep1='echo "android.os.Build.MANUFACTURER=CIOT"'
    elif [ "$PRODUCTNAME" = "RG020ET-CA" ] || [ "$PRODUCTNAME" = "S-010W-AV2A" ]||[ "$PRODUCTNAME" = "NSB_RG020ETCA" ] ||[ "$PRODUCTNAME" = "S-010W-AV2D" ] || [ "$PRODUCTNAME" = "S-010W-AV2A-1" ] ||[ "$PRODUCTNAME" = "S-010W-AV2A-2" ];then
        if [ "$PRODUCTNAME" = "RG020ET-CA" ] && [ "$carrier$province" = "ctgs" ];then
            local replaced1='echo "ro.product.manufacturer=nokia-sbell"'
            local rep1='echo "android.os.Build.MANUFACTURER=nokia-sbell"'
        elif [ "$PRODUCTNAME" = "S-010W-AV2A" ] && [ "$carrier$province" = "cujc" ];then
            local replaced1='echo "ro.product.manufacturer=TEST"'
            local rep1='echo "android.os.Build.MANUFACTURER=TEST"'
        else
            local replaced1='echo "ro.product.manufacturer=NSB"'
            local rep1='echo "android.os.Build.MANUFACTURER=NSB"'
        fi
	else 
        echo "PRODUCTNAME is not right"
        return 1
    fi
    echo $replaced1
    sed -i 's/^.*ro.product.manufacturer=.*$/'"$replaced1"'/' buildinfo.sh
    sed -i 's/^.*android.os.Build.MANUFACTURER=.*$/'"$rep1"'/' buildinfo.sh
	
    #now change echo "ro.product.name=$PRODUCT_NAME"
	PRODUCT_MODEL=$UnitType
    local replaced2="echo \"ro.product.name=$PRODUCT_MODEL\""
	local replaced3="echo \"ro.product.model=$PRODUCT_MODEL\""
    echo $replaced2
	echo $replaced3
    sed -i 's/^.*ro.product.name=.*$/'"$replaced2"'/' buildinfo.sh
	sed -i 's/^.*ro.product.model=.*$/'"$replaced3"'/' buildinfo.sh
	
	#now change echo "ro.product.brand=4K-STB"
	local replaced4="echo \"ro.product.brand=4K-STB\""
	echo $replaced4
    sed -i 's/^.*ro.product.brand=.*$/'"$replaced4"'/' buildinfo.sh
	
	local replaced_chiptype="echo \"ro.product.chiptype=$inputchip_u\""
	echo $replaced_chiptype
	sed -i '/ro.build.display.id/a'"$replaced_chiptype"'' buildinfo.sh
	

	#now change echo "ro.build.hardware.id"
	grep ro.build.hardware.id buildinfo.sh
	if [ $? -ne 0 ]; then
		local appendx_hdid="echo \"ro.build.hardware.id=$hw_id\""
		echo $appendx_hdid
		sed -i '/ro.product.chiptype/a \'"$appendx_hdid \\"'' buildinfo.sh
	else
		local replaced_hdid="echo \"ro.build.hardware.id=$hw_id\""
		echo $replaced_hdid
		sed -i 's/^.*ro.build.hardware.id=.*$/'"$replaced_hdid"'/' buildinfo.sh
	fi

	#now change echo "ro.product.manufactureroui"
	grep ro.product.manufactureroui buildinfo.sh
	if [ $? -ne 0 ]; then
		local appendx_oui="echo \"ro.product.manufactureroui=$oui\""
		echo $appendx_oui
		sed -i '/ro.product.chiptype/a \'"$appendx_oui \\"'' buildinfo.sh
	else
		local replaced_oui="echo \"ro.product.manufactureroui=$oui\""
		echo $replaced_oui
		sed -i 's/^.*ro.build.hardware.id=.*$/'"$replaced_oui"'/' buildinfo.sh
	fi

	#now change echo "ro.amlsdk.version"
	grep ro.amlinner.version buildinfo.sh
	if [ $? -ne 0 ]; then
		local appendx_innerversion="echo \"ro.amlinner.version=$innerVersion\""
		echo $appendx_innerversion
		sed -i '/ro.product.chiptype/a \'"$appendx_innerversion \\"'' buildinfo.sh
	else
		local appendx_innerversion="echo \"ro.amlinner.version=$innerVersion\""
		echo $appendx_innerversion
		sed -i 's/^.*ro.amlinner.version=.*$/'"$appendx_innerversion"'/' buildinfo.sh
	fi

	#now change echo "ro.devicesummary "
	grep ro.devicesummary  buildinfo.sh
	if [ $? -ne 0 ]; then
		local appendx_devicesummary="echo \"ro.devicesummary=$UnitType\""
		echo $appendx_devicesummary
		sed -i '/ro.product.chiptype/a \'"$appendx_devicesummary \\"'' buildinfo.sh
	else
		local appendx_devicesummary="echo \"ro.devicesummary=$UnitType\""
		echo $appendx_devicesummary
		sed -i 's/^.*ro.devicesummary=.*$/'"$appendx_devicesummary"'/' buildinfo.sh
	fi

	#now change echo "ro.devicesummary "
	grep ro.product.productclass  buildinfo.sh
	if [ $? -ne 0 ]; then
		local appendx_productclass="echo \"ro.product.productclass=$UnitType\""
		echo $appendx_productclass
		sed -i '/ro.product.chiptype/a \'"$appendx_productclass \\"'' buildinfo.sh
	else
		local appendx_productclass="echo \"ro.product.productclass=$UnitType\""
		echo $appendx_productclass
		sed -i 's/^.*ro.product.productclass=.*$/'"$appendx_productclass"'/' buildinfo.sh
	fi	
    #external version
    GenVersionStr $majorversion $minorversion	
	
	#for ctsx
	if [ $carrier$province = "ctsx" ] ;then
		local replaced_version="echo \"android.os.Build.VERSION.INCREMENTAL=$Incre\""
		echo $replaced_version
		sed -i 's/^.*ro.build.display.id.*$/'"$replaced_version"'/' buildinfo.sh
	fi
	
	#for cuhl 
	local platform=""
	if [ $carrier$province = "cuhl" ] ;then
		if [ $launcher = "huawei" ] ;then
			platform="4k_huawei"
		elif [ $launcher = "fenghuo" ] ;then
			platform="4k_fonsview"
		fi
		echo "**************  $platform"
		#now change ro.product.platform
		local append_platform="echo \"ro.product.platform=$platform\""
		echo $append_platform
		sed -i '/ro.product.model/a \'"$append_platform \\"'' buildinfo.sh
	fi
		
    if [ "$PRODUCTNAME" = "RG020ET-CA" ] && [ "$carrier" = "ct" ] && [ "$province" = "ossm" ];then	
        FingerIncre="4.4.2\/$PRODUCTNAME\/`date +%Y%m%d-%H-%M-%S`"
        replacedFinger="echo \"ro.build.fingerprint=$FingerIncre\""
        echo $replacedFinger
        sed -i 's/^.*ro.build.fingerprint=.*$/'"$replacedFinger"'/' buildinfo.sh
    fi		
	#set manufactureroui value
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
        echo "the combination of ‘Chips’ + ‘Wifigroups’ can not be found"
        return 1
    elif [ $ret = 'nokey' ];then
        echo " your input cannot make the translation"
        return 1
    fi
    set +e
    echo "python script return value is: $ret"
}

ReadUserInputForNormal () {
	
    CheckInputParameter
    local retval=$?
    echo "CheckInputParameter return value is: $retval"
    if [ $retval -eq 1 ]; then
        echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
        echo "your input is invalid, please re-Input !!!!!!!"
        return 1
    fi
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
    
    #read chip type
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

	HelpUnitType
	CheckUnitType
	if [ $? -eq 1 ];then
        echo "error!!!"
        return 1
    fi
	PRODUCTNAME="$UnitType"
    
    #read middleware type
    local mdws=
    HelpMiddlewares
    read mdws
        case $mdws in
        "1")
           mdws="zy";;
        "2")
           mdws="nsb";;
        *)
           dts=$dts;;
        esac
    CheckMiddlewares $mdws
    if [ $? -eq 1 ];then
        echo "Sorry, You've input wrong middleware type !!!!"
        return 1
    fi
    middleware=$mdws
    CAPMIDDLEWARE=${middleware^^}

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
           buildtype=$buildtype;;
        esac
        CheckBgnDts $dts
        if [ $? -eq 1 ];then
            echo "Sorry, You've input wrong dts type !!!!"
            return 1
        fi
    fi
    inputmodule=$dts
	

    
    set -e
    #local python_s=$BUILD/input/$middleware/$carrier$province
    local python_s="$vendorpath"
    local inputchip_u=`tr '[a-z]' '[A-Z]' <<<"$inputchip"`
    local inputmodule_u=`tr '[a-z]' '[A-Z]' <<<"$inputmodule"`
    echo "PRODUCTNAME=$UnitType"
    echo "inputchip_u=$inputchip_u"
    echo "inputmodule_u=$inputmodule_u"
    echo "middleware=$middleware"
    echo "inputlauncher=$inputlauncher"
    echo "carrierprovince=$carrier$province"
	echo $carrier
	echo $province
    local flag=0
    
	hw_id=$(python $python_s/intmapext.py  "getHwId" "$PRODUCTNAME" "$inputchip_u" "$inputmodule_u" "$middleware" "$inputlauncher" "$carrier$province" $majorversion $minorversion)
	CheckVersionReturn $hw_id
    if [ $? -ne 0 ];then
        flag=1
    fi
	
	display_id=$(python $python_s/intmapext.py  "getDisplayId" "$PRODUCTNAME" "$inputchip_u" "$inputmodule_u" "$middleware" "$inputlauncher" "$carrier$province" $majorversion $minorversion)
	CheckVersionReturn $display_id
    if [ $? -ne 0 ];then
        flag=1
    fi
	
	imgpfx=$(python $python_s/intmapext.py  "getImgPfx" "$PRODUCTNAME" "$inputchip_u" "$inputmodule_u" "$middleware" "$inputlauncher" "$carrier$province" $majorversion $minorversion)
    CheckVersionReturn $imgpfx
    if [ $? -ne 0 ];then
        flag=1
    fi
	
	innerVersion=$(python $python_s/intmapext.py  "getInnerStr" "$PRODUCTNAME" "$inputchip_u" "$inputmodule_u" "$middleware" "$inputlauncher" "$carrier$province" $majorversion $minorversion)
	CheckVersionReturn $innerVersion
    if [ $? -ne 0 ];then
        flag=1
    fi

	extVersion=$(python $python_s/intmapext.py  "getExtStr" "$PRODUCTNAME" "$inputchip_u" "$inputmodule_u" "$middleware" "$inputlauncher" "$carrier$province" $majorversion $minorversion)    
	CheckVersionReturn $extVersion
    if [ $? -ne 0 ];then
        flag=1
    fi

	oui=$(python $python_s/intmapext.py  "getOui" "$PRODUCTNAME" "$inputchip_u" "$inputmodule_u" "$middleware" "$inputlauncher" "$carrier$province" $majorversion $minorversion)
    CheckVersionReturn $oui
    if [ $? -ne 0 ];then
        flag=1
    fi
    
    if [ $flag -eq 1 ];then
        return 1
        echo "Check Version Return false ,please receck!!!"
    fi
	

	echo "##########"
    echo "innerVersion:"$innerVersion
    echo "##########"
    echo "##########"
    echo "extVersion:"$extVersion
    echo "##########"
    echo "##########"
    echo "imgpfx:"$imgpfx
    echo "##########"
	echo "##########"
    echo "oui:"$oui
    echo "##########"
	echo "##########"
    echo "display_id:"$display_id
    echo "##########"
    echo "hw_id:"$hw_id
    echo "##########"
 
}

MakeUboot ()
{
	local SourceBinPath="$WP/uboot/fip/gxl/"
	local DestBinPath="$WP/device/amlogic/p201_iptv/upgrade/gxl/"
	#make uboot
	cd $WP/uboot
	make distclean; make gxl_p211_v1_config; make -j20
	
	#copy u-boot.bin u-boot.bin.sd.bin(sd卡启动) u-boot.bin.usb.bl2(u盘启动) u-boot.bin.usb.tpl(u盘启动)
	cd $DestBinPath
	cp $SourceBinPath/u-boot.bin .
	cp $SourceBinPath/u-boot.bin.sd.bin .
	cp $SourceBinPath/u-boot.bin.usb.bl2 .
	cp $SourceBinPath/u-boot.bin.usb.tpl .
	
	cp u-boot.bin* ./1080p
	cp u-boot.bin* ./720p
	cp u-boot.bin* ./teeos
	
	
}
CheckNoraml()
{
	local flag=0
    local python_s="$vendorpath"
    local inputchip_u=`tr '[a-z]' '[A-Z]' <<<"$inputchip"`
    local branchname="rg020etca_zy_"$carrier"_"$province
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

    local python_s="$vendorpath"
    CheckFile_ret=$(python $python_s/buildCheck.py  "checkaml_normal" "$PRODUCTNAME" "$inputchip_u" "$carrier$province" "$branchname" $inputlauncher $VERSIONSTR)    
    if [ "$CheckFile_ret" == "False" ];then
		flag=1
    fi
	
    keyValueMapping_ret=$(/usr/bin/python3 $python_s/keyValueMapping.py  "$PRODUCTNAME" "$inputchip_u" "$carrier$province" "$branchname" $inputlauncher $imgpfx)    
    if [ "$keyValueMapping_ret" == "False" ];then
        echo "keyValueMapping return false!! line 945"
        flag=1
    fi

    if [ $flag -eq 1 ];then
        exit
    else
        return 0
    fi	
}

MakeAll()
{
	#make uboot
	echo "Please confirm if you need to clean the u-boot"
    echo "No input means need makeuboot"
    echo "Please enter [Yy/Nn]: "
    read makeuboot 
    if [ $makeuboot = "Y" ] || [ $makeuboot = "y" ];then
		echo "begin to make uboot"
		MakeUboot
		echo "you've make uboot correctly"
    elif [ $makeuboot = "N" ] || [ $makeuboot = "n" ];then
        echo "skip to make uboot!!!"
	else
		echo "you have the wrong input!!!"
		exit 1
    fi	
	
	set -e
	Setenv
	if [ $? -eq 1 ];then
		echo "error!!!"
		return 1
    fi
	
#build image
	cd $WP
    make otapackage -j20

}

Setenv ()
{
	#clean workspace
	cd $WP
	set -e
	./rm_product.sh p201_iptv
	. build/envsetup.sh
	
	local project_type=" "
	local CMCC="mobile"
	
	if [ $carrier = "ct" ] ;then
		if [ $province = "jc" ] || [ $province = "hq" ];then
			export PROJECT_TYPE=telecom  MOBILE_VERSION=$VERSIONSTR LICENCE_TAG=$launcher PROJECT_ID=p211;lunch p201_iptv-user
		else
			export PROJECT_TYPE=telecom PROJECT_ID=p211;lunch p201_iptv-user
		fi
	elif [ $carrier = "cu" ] ;then 
		if [ $province = "hl" ] ;then
			export PROJECT_TYPE=unicom LICENCE_TAG=$launcher PROJECT_ID=p211;lunch p201_iptv-user
		elif [ $province = "jc" ] ;then
			export PROJECT_TYPE=unicom  MOBILE_VERSION=$VERSIONSTR LICENCE_TAG=suying PROJECT_ID=p211;lunch p201_iptv-user
		else
			export PROJECT_TYPE=unicom LICENCE_TAG=suying PROJECT_ID=p211;lunch p201_iptv-user
		fi
	elif [ $carrier = "cm" ] ;then
		project_type="$province$CMCC"
		if [ $province = "sh" ] ;then
			export PROJECT_TYPE=$project_type  MOBILE_VERSION=$VERSIONSTR LICENCE_TAG=$launcher PROJECT_ID=p211;lunch p201_iptv-user
		else
			export PROJECT_TYPE=$project_type PROJECT_ID=p211;lunch p201_iptv-user
		fi
    fi
	
	echo "########### the  current is $project_type"
}

Calculatefilename () 
{	
    local Con="_"
    local Poi="."
    #local ZY="ZY"
    local ZY="$MIDDLEWARECAP"
	local SW="SW"
	local Int="int"
	local CAPLAUNCHER=${inputlauncher^^}
    local CAPCHIP=${inputchip^^}
    local CAPMODULE=${inputmodule^^}
	
    set -e
    local py_path="$vendorpath"
	set +e
	imgfile=$innerVersion
    
	
    #here we need to check if input luancher is existed !!!!!
    #if [ "$inputlauncher" = "nolauncher" ]; then
        # imgfile="$PRODUCTNAME$Con$SW$Con$IntVer$Con$ZY$Con$CAPCARRIER$CAPPROVINCE$Con$VERSIONSTR"
		#imgfile=$innerVersion
    #else
        #should translate inputlauncher into Upper case
        #local CAPLAUNCHER=${inputlauncher^^}
        # imgfile="$PRODUCTNAME$Con$SW$Con$IntVer$Con$ZY$Con$CAPCARRIER$CAPPROVINCE$Con$CAPLAUNCHER$Con$VERSIONSTR"
		#imgfile=
    #fi
	echo "the image name is $imgfile"

	intzip="$imgfile$Con$Int"	
	
}
CopyFiles ()
{
	#Calculatefilename
	local ImgPath="$WP/out/target/product/p201_iptv"
	local IntZipPath="$ImgPath/obj/PACKAGING/target_files_intermediates"
	local imgname="$imgfile.img"
	local otaname="$imgfile.zip"
	local intname="$intzip.zip"
	
	#copy img and ota files
	cd $BuildPath
	cp ${ImgPath}/aml_upgrade_package.img ./$imgname
	#cp ${ImgPath}/*-ota-*.zip ./$otafile
	
	cd ${BuildPath}/ota
	cp ${ImgPath}/*-ota-*.zip ./$otaname
	cp ${IntZipPath}/*.zip ./$intname
	
	echo "copy completed!!!"
}



makebuildprop () {
    local buildpath="$WP/out/target/product/p201_iptv/system/build.prop"
    local buildpropname="$BuildPath/$imgfile.build.prop"
	local imgname="$BuildPath/${imgfile}.img"
	local imgmd5="$BuildPath/${imgfile}.txt"
	local otafullname="$BuildPath/ota/${imgfile}.zip"
	local sp=" "
	local MD5="MD5:"
	local Zip="zip"
	local Poi="."

#########make buildprop ##########
    if [ -f $buildpath ]; then
       echo "make ${imgpfx}.build.prop"
	   mv $buildpath $buildpropname
	   unix2dos $buildpropname
	else
	   echo "build.prop is not existed"
    fi	
	
########md5img##############
	if [ -f $imgname ]; then
	   echo "imgname is ${imgname}"	   
	   #md5img=$(ls $imgname | xargs -n 1 basename)
	   md5vimg=$(md5sum $(ls $imgname) | awk '{print $1}')
	   md5nimg=$(ls $imgname | xargs -n 1 basename )
	   mdvnimg="$md5nimg$sp$MD5$md5vimg"
	   echo $mdvnimg >$imgmd5   
	else
	   echo "$imgname is not existed"
	fi
########md5ota##############
    if [ -f $otafullname ]; then
	   echo "otafullname is ${otafullname}"
	   #md5ota=$(ls $otafullname | xargs -n 1 basename)
	   md5vota=$(md5sum $(ls $otafullname) | awk '{print $1}')
	   md5nota=$(ls $otafullname | xargs -n 1 basename ) 
	   md5vnota="$md5nota$sp$MD5$md5vota"
	   echo $md5vnota >>$imgmd5
	   unix2dos $imgmd5
	else
	   echo "$otafullname is not existed"
	fi
}

CheckMultiLauncher ()
{
    local launchers=( nolauncher lpddr3 huawei fenghuo bestv washu gaoan)
    echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    echo "Please input your launcher:"
    echo "nolauncher(1) lpddr3(2) huawei(3) fenghuo(4) bestv(5) washu(6) gaoan(7)"
    echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
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
}

RecordBuildInfo () {
    if [ $officialbuild -ne 0 ]; then
        local date=`date +%Y%m%d.%H%M`
        local Con="_"
        local name=".xml"
        local filename="$date$Con$carrier$province$Con$majorversion$Con$minorversion$name"
        echo $filename
        cd $WP
        .repo/repo/repo manifest -r -o $filename
		#.repo/repo/repo forall -p -c "git log -10" > nxiptv_git_log.txt
		#mv nxiptv_git_log.txt $image
        mv $filename $BuildPath
    fi
}

HandleBuild () 
{
	set -e
    CheckMultiLauncher
	ReadUserInputForNormal
	if [ $? -eq 1 ];then
        echo "ReadUserInputForNormal error!!!"
        return 1
    fi
	
	CheckBuildInfo
	if [ $? -eq 1 ];then
        echo "CheckBuildInfo error!!!"
        return 1
    fi
	
	Calculatefilename
	if [ $? -eq 1 ];then
        echo "CheckSystemProp error!!!"
        return 1
    fi

    CheckNoraml	
    RecordBuildInfo
	MakeAll
	if [ $? -eq 1 ];then
        echo "MakeAll error!!!"
        return 1
    fi
	
#copy img files
	CopyFiles
	if [ $? -eq 1 ];then
        echo "CopyFiles error!!!"
        return 1
    fi
	
	makebuildprop
	if [ $? -eq 1 ];then
        echo "makebuildprop error!!!"
        return 1
    fi
	echo "build completed!!!"
}

HandlePrepare () {
    echo " Please input the to be handled zip/rar file : "
    read filename
    source amlprepare.sh 
    PrepareFile $filename
}

HandleCopyfile() {
    echo " Copy file to copy_directory "
    source amlprepare.sh 
    Copyfile
}

MakeDiffFile(){
    local python_s="$vendorpath"
    diffFile_ret=$(python $python_s/makeDiffFile.py s905l "$carrier$province" $inputlauncher $imgpfx)
    if [ "$diffFile_ret" == "False" ];then
        echo "check amlbuild.sh MakeDiffFile()"
        return 1
    fi
    return 0
}

BackUpAll(){
    local python_s="$vendorpath"
    backup_ret=$(python $python_s/backup_strategy.py  "$inputchip" "$PRODUCTNAME"  "$carrier$province" $inputlauncher $imgpfx "method_sh")
    if [ "$parameter_ret" == "False" ];then
        exit
    fi
}

#You must fill the correct vendor and province information  
if [ "$#" -ne 3 ]; then
#   first read vendor information
    ToolHelp
	HelpVendors
    read carrier
#   then read province information 
    HelpProvinces
    read province
#   then read wifi information
    #HelpModules
    #read wifi
else
#   here $1 as carrier, $2 as province
    carrier=$1
    province=$2
    #wifi=$3
fi
#   test if factorytest mode
if [ "$province" = "ft" ];then
    carrier="ba"
    province="se"
fi
# set environment

#check the input parameter is of format or not
CheckBranchParamValid $carrier $province 
if [ $? -eq 1 ]; then
    echo "Sorry, you've input the wrong carrier and province information"
    exit 1
fi

echo "Please input Prepare(P) or Build(B) or Copy(C)"
read inputparm
if [ "$inputparm" = "Prepare" ] || [ "$inputparm" = "P" ]; then
    HandlePrepare
elif [ "$inputparm" = "Build" ] || [ "$inputparm" = "B" ]; then
    HandleBuild
    if [ $? -eq 0 ];then
        MakeDiffFile
        if [ $? -eq 0 ];then
            BackUpAll
        else
            echo "NOK"
        fi
    fi
elif [ "$inputparm" = "Copy" ] || [ "$inputparm" = "C" ]; then
    HandleCopyfile
else    
    echo "you can do nothing"
fi






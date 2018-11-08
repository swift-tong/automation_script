#!/bin/sh
#This file is used to make sure that all the global variables are kept the same across 
#different script.!!!!!

#Input should be province and carrier

#export dfcfgpath="$WP/kernel/arch/arm/configs"
#export devdts="$WP/kernel/arch/arm/boot/dts/"

#predefined, you can change the shell, or configured in $1 and $2
wifi=""
mkbackup="false"
buildtype=""
product=""
carrier="cu"
province="he"
middleware="zy"
MIDDLEWARECAP="ZY"
#build part
ownbuild=""
vendorpath=""
tmp=""
apk=""
libs=""
bin=""
etc=""
rar=""
image=""
ota=""
third=""
#workspace part
WP="$HOME/workspace"
RKSDK="$WP/device/rockchip/rksdk"
rksdk="$WP/device/rockchip/rksdk"
rk3228="$WP/device/rockchip/rk3228"
BUILD="$HOME/build"
buildtool="$WP/build/tools"
iptv=""
iptvlibs=""
iptvetc=""
iptvbin=""
#version string
innerVersion=""
extVersion=""
facVersion=""
vendorVersion=""
imgpfx=""
#ro.build.hardware.id
hw_id=""
#oui
nsb_oui=""
#ro.build.display.id
display_id=""
#image part
sourceimg=""
imgmake_tool=""
targetimg=""
genimg=""
#ota part
targetota=""        #which is in out directory
fullota=""
versioncode=""
#product part
PRODUCTPREFIX="G-120WT-P_SW"
PRODUCTNAME=""
CAPPROVINCE=""
CAPCARRIER=""
#PRODUCTVERSION="R1.00.00"
declare -i majorversion=0
declare -i minorversion=0
VERSIONSTR=""
VERSIONSTR1=""
inputlauncher="nolauncher"
declare -i officialbuild=0
declare -i buildfactory=0
declare -i officialonsitebuild=0
#moduletypes=( ap6345 rtl8188ftv rtl8192eu )
#moduletypes=( rtl nowifi )
#moduletypes=( rtl ap6356s nowifi  )

wifitypes=( bgn ac nowifi )

acdtstypes=( rtl8822bs en7526g )
bgndtstypes=( rtl8189etv rtl8676  mtk7526fu 8189ftv en7526fd nowifi)


chiptypes=( rk3228b rk3228h )
mdwaretypes=( zy nsb )
inputmodule=""
inputchip=
ExtVer=
IntVer=
CAPWIFI=""
dtstypes=( default rtl8188ftv rtl8192eu rtl8188etv )
wifidts=

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



HelpLauncher(){
echo "CTNM include Nomal and Industry Launcher,Please select:"
echo " ###########################################################"
echo "  normal               (for the nomal launcher)"
echo "  industry             (for the industry launcher)"
echo " ###########################################################"
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
echo "    nowifi(1)      (  S-010W-AV2S  )      "
echo " ##########################################################"     
}

HelpBgnDts () {
echo " the accepted dts types are: "
echo " ##########################################################"
echo "    rtl8189etv(1)    ( S-010W-A ) "     
echo "    rtl8676(2)       ( RG020ET-CA ) " 
echo "    mtk7526fu(3)     ( G-120WT-P ) " 
echo "    8189ftv(4)       ( S-010W-AV2B   S-010W-AV2C ) " 
echo "    en7526fd(5)      ( G-120WT-Q ) "
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
    VERSIONSTR="R1.$mjverstr.$mnverstr"
    VERSIONSTR1="1.$mjverstr.$mnverstr"
    echo "VERSIONSTR is $VERSIONSTR"
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

#calculate build related path
CalculateBuildPath () {
    vendorpath="$HOME/build/input/zy/$carrier$province"
    ownbuild="$HOME/build"
    
    tmp="$vendorpath/tmp"
    apk="$vendorpath/apk"
    libs="$vendorpath/libs"
    bin="$vendorpath/bin"
    etc="$vendorpath/etc"
    rar="$vendorpath/rar"
    image="$vendorpath/image"
    ota="$vendorpath/ota"
    third="$vendorpath/third"
    echo $vendorpath
}

CalculateIptvPath () {
    if [ $inputlauncher = "nolauncher" ];then
        iptv="$WP/device/rockchip/rksdk/IPTV/IPTV_$carrier$province"
    else
        iptv="$WP/device/rockchip/rksdk/IPTV/IPTV_"$carrier$province"_"$inputlauncher
    fi
    iptvlibs="$iptv/libs"
    iptvetc="$iptv/etc"
    iptvbin="$iptv/bin"
    echo $iptv
}

CalculateRk3228bImagePath() {
    sourceimg="$WP/rockdev/Image-rk3228"
    imgmake_tool="$HOME/build/RKTools/imgmake_tool/AndroidTool_Release_v2.31/rockdev/Image"
    targetimg="$HOME/build/RKTools/Linux_Upgrade_Tool_v1.23/rockdev/Image"
    genimg="$HOME/build/RKTools/Linux_Upgrade_Tool_v1.23/rockdev"
    #intermediate ota path
    targetota="$WP/out/target/product/rk3228/obj/PACKAGING/target_files_intermediates"
    #full ota path
    fullota="$WP/out/target/product/rk3228"
    echo $targetota
}

CalculateRk3228hImagePath() {
    sourceimg="$WP/rockdev/Image-rk3228h"
    imgmake_tool="$HOME/build/RKTools/imgmake_tool/AndroidTool_Release_v2.31/rockdev/Image"
    targetimg="$HOME/build/RKTools/Linux_Upgrade_Tool_v1.23/rockdev/Image"
    genimg="$HOME/build/RKTools/Linux_Upgrade_Tool_v1.23/rockdev"
    #intermediate ota path
    targetota="$WP/out/target/product/rk3228h/obj/PACKAGING/target_files_intermediates"
    #full ota path
    fullota="$WP/out/target/product/rk3228h"
    echo $targetota
}

CalculateMultiProduct () {
    if [ "$buildtype" = "3228b" ];then
        rk3228="$WP/device/rockchip/rk3228"
        CalculateRk3228bImagePath
    elif [ "$buildtype" = "3228h" ]; then
        rk3228h="$WP/device/rockchip/rk3228h"
        CalculateRk3228hImagePath
    else
        echo "input product name failed ,please recheck"
        exit
    fi	
}

#WP="$HOME/workspace"
#main function now
#You should input 2 arguments or we will use the default !!!!
if [ $# -eq 5 ]; then
    echo "input carrier is: $1, Input province is: $2"
    carrier=$1
    province=$2
    product=$3
    buildtype=$4
    inputlauncher=$5
    PRODUCTNAME=${product^^}
    CAPPROVINCE=${province^^}   #convert to upper case
    CAPCARRIER=${carrier^^}
else
    echo "you dont input carrier and province, we have to use default value"
    echo "default carrier is: $carrier, default province is: $province"
fi

CalculateMultiProduct
echo "pruduct name is $PRODUCTNAME"
CalculateBuildPath
CalculateIptvPath

#echo $targetimg

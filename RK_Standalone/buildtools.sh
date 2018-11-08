#/bin/sh

#this build tool aims to make sure that you can :
#prepare related package
#copy prepared file into work directory
#build and check
#generate related file
apkpackage=""
ToolHelp () {
    echo "**************************************************************************"
    echo "You must first input the realted vendor and province, then:"
    echo "You have several options to run the scripts"
    echo "Prepare : try to unpack related middleware zip file into correct directory"
    echo "Copyfile : copy related prepared file into correct workarea"
    echo "Build : call build shell and generate related image file"
    echo "And all valid input must include the vendor,province,shell execution"
    echo "**************************************************************************"
    echo "                                      **                                  "
}

branchname=""
shellname=""
launcher=""

#check all branch , use git branch -a , check current branch , use git branch
#use grep -w to make sure the whole word matched !!!! //with grep -w "* branchname"

moduletypes=( ap6345 rtl8188ftv rtl8723bs )

HelpWifis () {
echo " the accepted wifi types are: "
echo " ##############################################"
echo "  bgn       (802.11 b/g/n)"
echo "  ac        (802.11 b/g/n/ac)"
echo "  nowifi    (no wifi module)"
echo " ##############################################"    
}

HelpLauncher (){
    local launchers=( nolauncher huawei fenghuo normal industry hotel lpddr3 zhongxing yaxin newline)
    echo "Please input your launcher "
    echo "The accepted laucnhers are :"
    echo " #########################################################################"
    echo "          nolauncher(1) huawei(2) newline(3)    fenghuo(4)   normal(5) "
    echo "          industry(6)  hotel(7)   lpddr3(8)  zhongxing(9)   yaxin(10)"
    echo " #########################################################################"
    read launcher
    case $launcher in
    "1")
       launcher="nolauncher";;
    "2")
       launcher="huawei";;
    "3")
       launcher="newline";;
    "4")
       launcher="fenghuo";;
    "5")
       launcher="normal";;
    "6")
       launcher="industry";;
    "7")
       launcher="hotel";;
    "8")
       launcher="lpddr3";;
    "9")
       launcher="zhongxing";;
    "10")
       launcher="yaxin";;
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
}

Checkmodules () {
    echo "Function Checkmodules"
#   remember if local variable is found, must declare it as local
    local found=0
	echo "Please input wifis : "
	#read province
    wifi=$1
	for i in "${moduletypes[@]}"
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


GenShellName () {
    local sy="shuangyi_cmcc_bestv_"
    local sh=".sh"
    shellname="$sy$1$sh"
    echo "generated shellname is: $shellname"
}

GetApkpackage(){
    echo "Please select the mathod you want to get rar file"
    echo "Manual need you input rar name other donot need"
    echo "please select [Manual] or[m] or press enter button "
    echo "-------------------- Manual(m) ------------------------"
    read method
    if [ "$method" == "Manual" ] || [ "$method" == "m" ];then
        echo " Please input the to be handled zip/rar file : "
        read filename
        apkpackage=$filename
    else
        apkpackage=`ls -t *.rar | head -n1`
    fi	
}
#you must read input the to be handled file name
HandlePrepare () {
    GetApkpackage
    source prepare.sh
    PrepareFile $apkpackage
}

HandlePreThird () {
    GetApkpackage
    source prepare.sh
    PrepareThird $apkpackage
}

HandleCopyfile() {
    source prepare.sh
    source chgmkfile.sh
    Copyfile
}

HandleBuild () {
    cd $vendorpath
    echo `pwd`
    ./build.sh $vendor $province $product $buildtype $launcher "normal"
}

HandleBuildFactory () {
    cd $vendorpath
    echo `pwd`
    ./build.sh $vendor $province $product  $buildtype $launcher "factory"
}

HandleOta () {
    ota_dir=""
    method=""
    new=""
    old=""
    file=""
    end=ota.zip	
    oldMajVer=""
    oldMinVer=""
    newMajVer=""
    newMinVer=""
    cd ~/build/input/zy/
    num=`ls | wc -l`
    if [ $num -ne 1 ];then
        echo "There is more then one dir in ~/build/input/zy/,please check"
    fi
    pro=`ls`
    cd $pro/ota/target
    ota_dir=`pwd`"/"
	

	
    if [ "$buildtype" == "3228h" ];then
        if [ "$carrier" = "cu" ] && [ "$province" = "sd" ];then
            method="m"
        elif [ "$carrier" = "cu" ] && [ "$province" = "bj" ];then
            method="m"
        else
            echo "Please select the mathod you want to get target file"
            echo "Manual need you input version number other donot need"
            echo "    please input Manual or m or press enter button   "
            echo "-------------------- Manual(m) ----------------------"
            read method
            fi
    else
        echo "Please select the mathod you want to get target file"
        echo "Manual need you input version number other donot need"
        echo "    please input Manual or m or press enter button   "
        echo "-------------------- Manual(m) ----------------------"
        read method
    fi
	
    if [ "$method" == "Manual" ] || [ "$method" == "m" ];then
        echo "Please select R1 or R2 of that in your version."
        read Rx
        echo "Please Input Old file Major version now, must greater that 0"
        read oldMajVer
        echo "Please Input Old file Min version now,from 0 to 99"
        read oldMinVer
        echo "------------------------------------------------------------"
        echo "Please Input New file Major version now, must greater that 0"
        read newMajVer
        echo "Please Input Old file Min version now,from 0 to 99"
        read newMinVer
        oldtmp=$Rx"."$oldMajVer"."$oldMinVer"_int.zip"
        newtmp=$Rx"."$newMajVer"."$newMinVer"_int.zip"
        old=`ls *$oldtmp`
        new=`ls *$newtmp`
        file=${old%int.*}${new%int.zip}${end}
        echo $new
        echo $file
    else
        new="`ls -t *_int.zip | head -n1`"
        old="`ls -t *_int.zip | head -n2 | tail -n1`"
        file=${old%int.*}${new%int.zip}${end}
        echo $new
        echo $file
    fi
	
    if [ "$buildtype" == "3228h" ];then
        if [ "$carrier" = "cu" ] && [ "$province" = "sd" ] && [ "$PRODUCTNAME" = "S-010W-AV2B" ];then
            cd ${HOME}/build/input/zy/cusd/ota/loader
            loadFile1=`ls *"R1."$newMajVer"."$newMinVer"_MiniLoaderAll.bin"`
            loadFile2=`ls *"R1."$newMajVer"."$newMinVer"_misc_loadercmd.img"`
            echo $loadFile1
            echo $loadFile2
            if [ ! -d ${HOME}/workspace/device/rockchip/rk3228h/loader ];then
                cd ${HOME}/workspace/device/rockchip/rk3228h
                mkdir "loader"
            fi
            cp ${HOME}/build/input/zy/cusd/ota/loader/$loadFile1 ${HOME}/workspace/device/rockchip/rk3228h/loader/RKLoader.bin
            cp ${HOME}/build/input/zy/cusd/ota/loader/$loadFile2 ${HOME}/workspace/device/rockchip/rk3228h/loader/misc_loadercmd.img 
        elif [ "$carrier" = "cu" ] && [ "$province" = "bj" ];then
            cd ${HOME}/build/input/zy/cubj/ota/loader
            loadFile1=`ls *"R1."$newMajVer"."$newMinVer"_MiniLoaderAll.bin"`
            loadFile2=`ls *"R1."$newMajVer"."$newMinVer"_misc_loadercmd.img"`
            echo $loadFile1
            echo $loadFile2
            if [ ! -d ${HOME}/workspace/device/rockchip/rk3228h/loader ];then
                cd ${HOME}/workspace/device/rockchip/rk3228h
                mkdir "loader"
            fi
            cp ${HOME}/build/input/zy/cubj/ota/loader/$loadFile1 ${HOME}/workspace/device/rockchip/rk3228h/loader/RKLoader.bin
            cp ${HOME}/build/input/zy/cubj/ota/loader/$loadFile2 ${HOME}/workspace/device/rockchip/rk3228h/loader/misc_loadercmd.img
        fi		
    fi
	
    cd ~/workspace/
    ./build/tools/releasetools/ota_from_target_files -v -i ${ota_dir}${old} -p out/host/linux-x86/ -k build/target/product/security/testkey ${ota_dir}${new} $file

    if [ "$buildtype" == "3228h" ];then
        if [ "$carrier" = "cu" ] && [ "$province" = "sd" ]&& [ "$PRODUCTNAME" = "S-010W-AV2B" ];then
            cd ${HOME}/workspace/device/rockchip/rk3228h
            if [ -d "loader" ];then
                rm -r "loader"
            fi
        elif [ "$carrier" = "cu" ] && [ "$province" = "bj" ];then
            cd ${HOME}/workspace/device/rockchip/rk3228h
            if [ -d "loader" ];then
                rm -r "loader"
            fi
        fi            
    fi		
}

HandleClean () {
    echo "HandleClean , try to clean all local change before synchronisation"
    source buildprepare.sh
    CleanWorkspace
}
vendors=( ct cu cm ba os)
provinces=( bj tj he sx nm ln jl hl sh js zj ah fj jx sd ha hb hn gd hi gx cq sc gz yn sn gs qh nx xj xz jc hq se qd sm)
products=(S-010W-A S-010W-AV2B S-010W-AV2S S-010W-AV2 S-010W-AV2C S-010W-AQD S-010W-AV2E)

CheckProducts () {
    echo "Function CheckProducts"
#   remember if local variable is found, must declare it as local
    local found=0
    product=$1
	for i in "${products[@]}"
	do
        #echo $i
        if [ "$i" = "$product" ]; then
            echo "Input product Found"
            found=1
        fi
	done
	if [ $found -eq 0 ]; then
		echo "Input product is not correct "
		return 1
	fi  
}

CheckVendors () {
    echo "Function CheckVendors"
#   remember if local variable is found, must declare it as local
    local found=0
	echo "Please input vendor : "
	#read vendor
    vendor=$1
	for i in "${vendors[@]}"
	do
        #echo $i
        if [ "$i" = "$vendor" ]; then
            echo "Input vendor Found"
            found=1
        fi
	done
	if [ $found -eq 0 ]; then
		echo "Input vendor is not in correct format"
		return 1
	fi  
}

CheckProvinces () {
    echo "Function CheckProvinces"
#   remember if local variable is found, must declare it as local
    local found=0
	echo "Please input province : "
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
		echo "Input vendor is not in correct format"
		return 1
	fi  
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
    CheckProducts $3
 	if [ $? -eq 1 ]; then
		return 1
    fi 	
}
HelpVendors () {
echo " the accepted vendors are: "
echo " #################################################################"
echo " ct: china telecom, cu: china unicom, cm: china mobile, os: oversea"
echo " ##################################################################"
#echo " Please input vendor name: "
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
echo "singmeng : sm"
echo "Company jicai : jc  headquarters ：hq  factorytest : ft"
echo "###########################################################"
#echo "Please input province name: "
}

HelpProduct () {
echo " Now need the product name ,Please select the  pruduct name: "
echo " ############################################################"
echo "  S-010W-A(1)  S-010W-AQD(2)  S-010W-AV2S(3)  S-010W-AV2(4)
        S-010W-AV2C(5)  S-010W-AV2B(6) S-010W-AV2E(7)"
echo " ############################################################"
}
HelpBuildtype(){
echo "             Please select the  buildtype:                   "
echo " ############################################################"
echo "          3228b(1)                  3228h(2)                    "
echo " ############################################################"
}

if [ "$#" -ne 5 ]; then
#   first read vendor information
    ToolHelp
    HelpVendors
    read vendor
#   then read province information 
    HelpProvinces
    read province
	
    #   test if factorytest mode
    if [ "$province" = "ft" ];then
        vendor="ba"
        province="se"
        HelpProduct
        read product
        case $product in
        "1")
           product="S-010W-A";;
        "2")
           product="S-010W-AQD";;
        "3")
           product="S-010W-AV2S";;
        "4")
           product="S-010W-AV2";;
        "5")
           product="S-010W-AV2C";;
        "6")
           product="S-010W-AV2B";;
        "7")
           product="S-010W-AV2E";;
        *)
           product=$product;;
        esac	
        HelpBuildtype
        read buildtype
        case $buildtype in
         "1")
           buildtype="3228b";;
        "2")
           buildtype="3228h";;
        *)
           buildtype=$buildtype;;
        esac		   
        HelpLauncher
              
    else
        #then read product information 
        HelpProduct
        read product
        case $product in
        "1")
           product="S-010W-A";;
        "2")
           product="S-010W-AQD";;
        "3")
           product="S-010W-AV2S";;
        "4")
           product="S-010W-AV2";;
        "5")
           product="S-010W-AV2C";;
        "6")
           product="S-010W-AV2B";;
        *)
           product=$product;;
        esac
        echo $product
        HelpBuildtype
        read buildtype
        case $buildtype in
         "1")
           buildtype="3228b";;
        "2")
           buildtype="3228h";;
        *)
           buildtype=$buildtype;;
        esac
        HelpLauncher
    fi
#   then read wifi information
    #HelpModules
    #read wifi
else
#   here $1 as vendor, $2 as province
    vendor=$1
    province=$2
    product=$3
    buildtype=$4
    launcher=$5
fi

# set environment
source setenv.sh $vendor $province $product $buildtype $launcher
#check the input parameter is of format or not
CheckBranchParamValid $vendor $province $product
if [ $? -eq 1 ]; then
    echo "Sorry, you've input the wrong vendor and province information"
    exit 1
fi
#You must fill the correct vendor and province information  


echo "Please input Prepare(P) or PreThird(PT) or Copy(C) or Build(B) or Ota(O) or BuildFactory(BF) or Clean"
read inputparm
if [ "$inputparm" = "Prepare" ] || [ "$inputparm" = "P" ]; then
    HandlePrepare
elif [ "$inputparm" = "PreThird" ] || [ "$inputparm" = "PT" ]; then
    HandlePreThird
elif [ "$inputparm" = "Copy" ] || [ "$inputparm" = "C" ]; then
    HandleCopyfile
elif [ "$inputparm" = "Build" ] || [ "$inputparm" = "B" ]; then
    HandleBuild
elif [ "$inputparm" = "BuildFactory" ] || [ "$inputparm" = "BF" ]; then
    HandleBuildFactory
elif [ "$inputparm" = "Ota" ] || [ "$inputparm" = "O" ]; then
    HandleOta
elif [ "$inputparm" = "Clean" ]; then
    HandleClean
else    
    echo "you can do nothing"
fi

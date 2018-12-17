#/bin/sh

#launchers=( bestv huashu youpeng )
#inputlauncher=""
#minorversion="00"
#used to check if OTA and image should be renamed !!!!!!

otatool=""
testkey=""
baseota=""          #the old version of zip
cleanbuild=1


MakeRk3228B() {

        
    echo "Please confirm if you need to clean the kernel and u-boot"
    echo "No input means need CleanBuild"
    echo "Please enter [Yy/Nn]: "
    read -t 10 cbuild
    echo $?
    if [ $? -ne 0 ] ;then
        echo "You don't give any input, use cleanbuild default value as TRUE"
        cleanbuild=1
    else
        if [ "$cbuild" = "n" ] || [ "$cbuild" = "N" ]; then
        cleanbuild=0
        fi
    fi
    cd $WP
    set -e
    source build/envsetup.sh
    lunch rk3228-eng
#make u-boot
    cd "$WP/u-boot"
    if [ $cleanbuild -eq 1 ];then
        echo "need to make cleanbuild for u-boot"
        make distclean
    fi
    make rk322x_box_defconfig
    make -j20
    echo "You've build u-boot correctly"
#make kernel
    cd "$WP/kernel"
    if [ $cleanbuild -eq 1 ];then
        echo "need to make cleanbuild for kernel"
        #make distclean
        make clean
    fi
    if [ "$product" = "S-010W-A" ] && [ "$carrier" = "cu" ] && [ "$province" = "hn" ];then
        echo "make shuangyi-wifi as rtl8188ftv"
        make shuangyi_rtl8188ftv_defconfig
        make shuangyi-rk3228b-rtl8188ftv-box.img -j16
    elif [ "$product" = "S-010W-A" ] && [ "$carrier" = "cu" ] && [ "$province" = "sd" ];then
        make shuangyi_rtl8188ftv_defconfig
        make shuangyi-rk3228b-rtl8188ftv-box.img -j16
    elif [ "$product" = "S-010W-A" ] && [ "$carrier" = "cu" ] && [ "$province" = "xj" ];then
        make shuangyi_rtl8188ftv_defconfig
        make shuangyi-rk3228b-rtl8188ftv-box.img -j16
    elif [ "$product" = "S-010W-A" ] && [ "$carrier" = "ct" ] && [ "$province" = "nx" ];then
        echo "make shuangyi-wifi as rtl8188ftv"
        make shuangyi_rtl8188ftv_defconfig
        make shuangyi-rk3228b-rtl8188ftv-box.img -j16
    elif [ "$wifidts" = "rtl8192eu" ];then
        echo "make shuangyi-wifi as rtl8192eu"
        make shuangyi_rtl8192eu_defconfig
        make shuangyi-rk3228b-rtl8192eu-box.img -j16
    else 
        make rockchip_defconfig
        make rk3228b-box.img -j20
    fi
    echo "You've build kernel correctly"
#make android
    cd $WP
    make installclean
	cp -a $WP/kernel/arch/arm/boot/zImage $WP/out/target/product/rk3228/kernel
    make -j16
    echo "you've make android correctly"
#build image
#only needed when official
    echo "officalbuild is : $officialbuild"
    if [ $officialbuild -ne 0 ]; then
        echo "need to make official OTA packages"
        make otapackage
    fi
     if [ "$mkbackup" = "true" ];then
        echo "generate image with backup"
        ./mkimage.sh ota unsign backup
    else
        echo "generate image without backup"
        ./mkimage.sh ota 
    fi
}

MakeRk3228H() {
        
    echo "Please confirm if you need to clean the kernel and u-boot"
    echo "No input means need CleanBuild"
    echo "Please enter [Yy/Nn]: "
    read -t 10 cbuild
    echo $?
    if [ $? -ne 0 ] ;then
        echo "You don't give any input, use cleanbuild default value as TRUE"
        cleanbuild=1
    else
        if [ "$cbuild" = "n" ] || [ "$cbuild" = "N" ]; then
        cleanbuild=0
        fi
    fi
    cd $WP
    set -e
    source build/envsetup.sh
    lunch rk3228h-eng
#make u-boot
    cd "$WP/u-boot"
    make distclean
    make rk322xh_box_defconfig
    make ARCHV=aarch64 -j16
    echo "You've build u-boot correctly"
#make kernel
    cd "$WP/kernel"
    if [ $cleanbuild -eq 1 ];then
        echo "need to make cleanbuild for kernel"
        #make distclean
        make clean
    fi
    make ARCH=arm64 twowing_3228h_rk805_rtl8192_4layout_lpddr3_defconfig
    make ARCH=arm64 twowing_3228h_rk805_rtl8192_4layout_lpddr3.img -j12
    echo "You've build kernel correctly"
#make android
    cd $WP
    make installclean
    cp kernel/arch/arm64/boot/Image out/target/product/rk3228h/kernel 
    make -j20
    echo "you've make android correctly"
#build image
#only needed when official
    echo "officalbuild is : $officialbuild"
    if [ $officialbuild -ne 0 ]; then
        echo "need to make official OTA packages"
        make otapackage
        HandleRk3228hOta
    fi
     if [ "$mkbackup" = "true" ];then
        echo "generate image with backup"
        ./mkimage.sh ota unsign backup
    else
        echo "generate image without backup"
        ./mkimage.sh ota 
    fi
}

MakeAV2() {
        
    echo "Please confirm if you need to clean the kernel and u-boot"
    echo "No input means need CleanBuild"
    echo "Please enter [Yy/Nn]: "
    read -t 10 cbuild
    echo $?
    if [ $? -ne 0 ] ;then
        echo "You don't give any input, use cleanbuild default value as TRUE"
        cleanbuild=1
    else
        if [ "$cbuild" = "n" ] || [ "$cbuild" = "N" ]; then
        cleanbuild=0
        fi
    fi
    cd $WP
    set -e
    source build/envsetup.sh
    lunch rk3228h-eng
#make u-boot
    cd "$WP/u-boot"
    if [ $cleanbuild -eq 1 ];then
        echo "need to make cleanbuild for u-boot"
        make distclean
    fi
    make rk322xh_box_defconfig
    make ARCHV=aarch64 -j12
    echo "You've build u-boot correctly"
#make kernel
    cd "$WP/kernel"
    if [ $cleanbuild -eq 1 ];then
        echo "need to make cleanbuild for kernel"
        #make distclean
        make clean
    fi
    make rockchip_smp_kitkat_defconfig ARCH=arm64
    make ARCH=arm64 rk3228h-demo.img -j30
    echo "You've build kernel correctly"
#make android
    cd $WP
    make installclean
    cp kernel/arch/arm64/boot/Image out/target/product/rk3228h/kernel
    make -j20
    echo "you've make android correctly"
#build image
#only needed when official
    echo "officalbuild is : $officialbuild"
    if [ $officialbuild -ne 0 ]; then
        echo "need to make official OTA packages"
        make otapackage
        HandleRk3228hOta
    fi
     if [ "$mkbackup" = "true" ] && [ "$carrier$province" != "base" ];then
        echo "generate image with backup"
        ./mkimage.sh ota unsign backup
    else
        echo "generate image without backup"
        ./mkimage.sh ota 
    fi
}

MakeAV2C() {
        
    echo "Please confirm if you need to clean the kernel and u-boot"
    echo "No input means need CleanBuild"
    echo "Please enter [Yy/Nn]: "
    read -t 10 build
    echo $?
    if [ $? -ne 0 ] ;then
        echo "You don't give any input, use cleanbuild default value as TRUE"
        cleanbuild=1
    else
        if [ "$cbuild" = "n" ] || [ "$cbuild" = "N" ]; then
        cleanbuild=0
        fi
    fi
    cd $WP
    set -e
    source build/envsetup.sh
    lunch rk3228h-eng
#make u-boot
    cd "$WP/u-boot"
    if [ $cleanbuild -eq 1 ];then
        echo "need to make cleanbuild for u-boot"
        make distclean
    fi
    make rk322xh_box_defconfig
    make ARCHV=aarch64 -j12
    echo "You've build u-boot correctly"
#make kernel
    cd "$WP/kernel"
    if [ $cleanbuild -eq 1 ];then
        echo "need to make cleanbuild for kernel"
        #make distclean
        make clean
    fi
    make ARCH=arm64 twowing_3228h_pwm_2layout_lpddr3_defconfig
    make ARCH=arm64 twowing_3228h_pwm_2layout_lpddr3.img -j12
    echo "You've build kernel correctly"
#make android
    cd $WP
    make installclean
    cp kernel/arch/arm64/boot/Image out/target/product/rk3228h/kernel
    make -j20
    echo "you've make android correctly"
#build image
#only needed when official
    echo "officalbuild is : $officialbuild"
    if [ $officialbuild -ne 0 ]; then
        echo "need to make official OTA packages"
        make otapackage
        HandleRk3228hOta
    fi
     if [ "$mkbackup" = "true" ];then
        echo "generate image with backup"
        ./mkimage.sh ota unsign backup
    else
        echo "generate image without backup"
        ./mkimage.sh ota 
    fi
}

MakeAV2E() {
        
    echo "Please confirm if you need to clean the kernel and u-boot"
    echo "No input means need CleanBuild"
    echo "Please enter [Yy/Nn]: "
    read -t 10 build
    echo $?
    if [ $? -ne 0 ] ;then
        echo "You don't give any input, use cleanbuild default value as TRUE"
        cleanbuild=1
    else
        if [ "$cbuild" = "n" ] || [ "$cbuild" = "N" ]; then
        cleanbuild=0
        fi
    fi
    cd $WP
    set -e
    source build/envsetup.sh
    lunch rk3228h-eng
#make u-boot
    cd "$WP/u-boot"
    if [ $cleanbuild -eq 1 ];then
        echo "need to make cleanbuild for u-boot"
        make distclean
    fi
    make rk322xh_box_defconfig
    make ARCHV=aarch64 -j12
    echo "You've build u-boot correctly"
#make kernel
    cd "$WP/kernel"
    if [ $cleanbuild -eq 1 ];then
        echo "need to make cleanbuild for kernel"
        #make distclean
        make clean
    fi
    make ARCH=arm64 twowing_3228h_pwm_2layout_ddr3_defconfig
    make ARCH=arm64 twowing_3228h_pwm_2layout_ddr3.img -j12
    echo "You've build kernel correctly"
#make android
    cd $WP
    make installclean
    cp kernel/arch/arm64/boot/Image out/target/product/rk3228h/kernel
    make -j20
    echo "you've make android correctly"
#build image
#only needed when official
    echo "officalbuild is : $officialbuild"
    if [ $officialbuild -ne 0 ]; then
        echo "need to make official OTA packages"
        make otapackage
        HandleRk3228hOta
    fi
     if [ "$mkbackup" = "true" ];then
        echo "generate image with backup"
        ./mkimage.sh ota unsign backup
    else
        echo "generate image without backup"
        ./mkimage.sh ota 
    fi
}

#because we must use a factory image which was generated from baseworkspace to build,
#so delete its own factory image first and copy that from the imgmake_tool directory. 
HandleFactoryImg () {
    if [ -f ${targetimg}/factory.img ]; then
        rm ${targetimg}/factory.img
        if [ $? -eq 0 ];then
            echo "delete its own factory.img success"
        fi
    fi
    cp ${imgmake_tool}/factory.img ${targetimg}/ 
    cp ${imgmake_tool}/misc_factory.img ${targetimg}/
}

HandleBuildLogo () {
#logo
    if [ "$carrier" == "cu" ]; then
        if [ "$province" == "xj" ] ; then
            cp ${imgmake_tool}/logo_cuxj.bmp ${targetimg}/logo.bmp
        elif [ "$PRODUCTNAME" == "S-010W-AV2S" ] && [ "$province" == "jc" ]; then
            cp ${imgmake_tool}/logo_3228h_cujc.bmp ${targetimg}/logo.bmp 		
        elif [ "$province"  == "qd" ]; then
            cp ${imgmake_tool}/logo_cuqd.bmp ${targetimg}/logo.bmp			
        elif [ "$province" == "hn" ]; then
            cp ${imgmake_tool}/logo_cuhn.bmp ${targetimg}/logo.bmp
        elif [ "$province" == "jx" ]; then
            cp ${imgmake_tool}/logo_cujx.bmp ${targetimg}/logo.bmp			
        elif [ "$province" == "sc" ]; then
            cp ${imgmake_tool}/logo_cusc.bmp ${targetimg}/logo.bmp 
        elif [ "$province" == "ln" ]; then
            cp ${imgmake_tool}/logo_culn.bmp ${targetimg}/logo.bmp 		
        elif [ "$province"  == "js" ]; then
            cp ${imgmake_tool}/logo_cujs.bmp ${targetimg}/logo.bmp
        elif [ "$province"  == "bj" ]; then
            cp ${imgmake_tool}/logo_cubj.bmp ${targetimg}/logo.bmp
        elif [ "$province"  == "nm" ]; then
            cp ${imgmake_tool}/logo_cunm.bmp ${targetimg}/logo.bmp
        else 
            cp ${imgmake_tool}/logo_cu.bmp ${targetimg}/logo.bmp
        fi
	elif [ "$carrier" == "cm" ];then
        cp ${imgmake_tool}/logo_cmcc.bmp ${targetimg}/logo.bmp
    elif [ "$carrier" == "ct" ];then
        if [ "$province" == "nx" ]; then
            cp ${imgmake_tool}/logo_ctnx.bmp ${targetimg}/logo.bmp
        elif [ "$province"  == "hn" ]; then
            cp ${imgmake_tool}/logo_cthn.bmp ${targetimg}/logo.bmp
        elif [ "$province"  == "ln" ]; then
            cp ${imgmake_tool}/logo_ctln.bmp ${targetimg}/logo.bmp			
        elif [ "$province" == "zj" ]; then
            cp ${imgmake_tool}/logo_ctzj.bmp ${targetimg}/logo.bmp
        else
            cp ${imgmake_tool}/logo_ct.bmp ${targetimg}/logo.bmp
        fi
    else
        cp ${imgmake_tool}/logo_asb.bmp ${targetimg}/logo.bmp
    fi
}

BuildUpdate () {
    local workdir=$WP
    cp -R ${sourceimg}/* ${targetimg}/
    HandleFactoryImg
    cp ${imgmake_tool}/baseparamer*.img ${targetimg}/
#logo
    #HandleBuildLogo
	
#kernel
    cp ${workdir}/kernel/kernel.img ${targetimg}/
    cp ${workdir}/kernel/resource.img ${targetimg}/

#u-boot
    cp ${workdir}/u-boot/uboot.img ${targetimg}/
    if [ "$PRODUCTNAME" = "S-010W-AV2B" ] && [ "$carrier" = "cu" ] && [ "$province" = "sd" ];then
        cp ${imgmake_tool}/trust.img ${targetimg}/
    else
        cp ${workdir}/u-boot/trust.img ${targetimg}/
    fi
#default fdisk
    if [ "$buildtype" = "3228b" ];then
        cp ${imgmake_tool}/../parameter-rk3228-iptv.normal ${targetimg}/../parameter
        cp ${workdir}/u-boot/RK322X*.bin ${targetimg}/../
    elif [ "$buildtype" = "3228h" ];then
        cp ${imgmake_tool}/../parameter-rk3228h-iptv.normal ${targetimg}/../parameter
        cp ${workdir}/rockdev/Image-rk3228h/MiniLoaderAll.bin ${targetimg}/
    else
        echo "input product name failed ,please recheck"
    fi     
    cp ${imgmake_tool}/../package-file.normal ${targetimg}/../package-file
#store loader file
    if [ "$buildtype" == "3228h" ];then
        if [ "$carrier" = "cu" ] && [ "$province" = "sd" ] && [ "$PRODUCTNAME" = "S-010W-AV2B" ];then
            if [ ! -d ${HOME}/build/input/zy/cusd/ota/loader/ ];then
                mkdir "${HOME}/build/input/zy/cusd/ota/loader/"
            fi
            loaderDir=${HOME}/build/input/zy/cusd/ota/loader
            cp ${workdir}/device/rockchip/rksdk/loader/misc_loadercmd.img $loaderDir/$imgpfx"_misc_loadercmd.img"
            cp ${workdir}/rockdev/Image-rk3228h/MiniLoaderAll.bin $loaderDir/$imgpfx"_MiniLoaderAll.bin"
        elif [ "$carrier" = "cu" ] && [ "$province" = "bj" ];then
            if [ ! -d ${HOME}/build/input/zy/cubj/ota/loader/ ];then
                mkdir "${HOME}/build/input/zy/cubj/ota/loader/"
            fi
            loaderDir=${HOME}/build/input/zy/cubj/ota/loader
            cp ${workdir}/device/rockchip/rksdk/loader/misc_loadercmd.img $loaderDir/$imgpfx"_misc_loadercmd.img"
            cp ${workdir}/rockdev/Image-rk3228h/MiniLoaderAll.bin $loaderDir/$imgpfx"_MiniLoaderAll.bin"
        fi  
    fi
		
#make update
    cd ${targetimg}/../
    ./mkupdate.sh
    echo "update.img was generated in $targetimg"
}

#check if is official or not
HandleRk3228hOta(){
    local upfullota="$fullota/rk3228h-ota-eng*.zip"
    local updateota="$targetota/rk3228h-target_files-*.zip"
    echo "officalbuild is "$officalbuild
    if [ $officialbuild -eq 0 ]; then
        echo "Do nothing"
    else
        echo "this is one official build, need to store the OTA"
        local int="_int"
        local otaname="$ota/target/$imgpfx$int.zip"
        mv $updateota $otaname
        local otafullname="$ota/full/$imgpfx.zip"
        mv $upfullota $otafullname
    fi   
}
HandleRk3228hImg() {
    local updateimg="$genimg/update.img"
    echo "officalbuild is "$officalbuild
    if [ $officialbuild -eq 0 ]; then
        echo "move update.img to realted directory"
        #mv "$targetimsg/update.img" $vendorpath
        #echo $image
        mv $updateimg $image
    else
        echo "this is one official build, need to store the OTA and rename update.image."
        #   image format is like: S-010W-A_SW_ZY_CUHE_BST_R1.00.00.img
        local imgname="$image/$imgpfx.img"
        mv $updateimg $imgname
    fi
}

HandleRk3228bUpdate() {
    local updateimg="$genimg/update.img"
    local upfullota="$fullota/rk3228-ota-eng*.zip"
    local updateota="$targetota/rk3228-target_files-*.zip"
    echo "officalbuild is $officalbuild"
    if [ $officialbuild -eq 0 ]; then
        echo "move update.img to realted directory"
        #mv "$targetimsg/update.img" $vendorpath
        #echo $image
        mv $updateimg $image
    else
        echo "this is one official build, need to store the OTA and rename update.image."
        #   image format is like: S-010W-A_SW_ZY_CUHE_BST_R1.00.00.img
        local imgname="$image/$imgpfx.img"
        mv $updateimg $imgname
        local int="_int"
        local otaname="$ota/target/$imgpfx$int.zip"
        mv $updateota $otaname
        local otafullname="$ota/full/$imgpfx.zip"
        mv $upfullota $otafullname
    fi
}

MakeRk3228BFactory() {
    echo "Please confirm if you need to clean the kernel and u-boot"
    echo "+++++++++++++No input means need CleanBuild+++++++"
    echo "Please enter [Yy/Nn]: "
    read -t 10 cbuild
    echo $?
    if [ $? -ne 0 ] ;then
        echo "You don't give any input, use cleanbuild default value as TRUE"
        cleanbuild=1
    else
        if [ "$cbuild" = "n" ] || [ "$cbuild" = "N" ]; then
            echo "!!!!!!!!!!!!!!!!!Alert, You didn't clear the kernel workspace !!!!!!!!!!!!!!!"
            cleanbuild=0
        else
            echo "++++++++++++++++++You choose to clean the kernel workspace ++++++++++++++++++"
        fi
    fi
    cd $WP
    set -e
    source build/envsetup.sh
    lunch rk3228-eng
#make u-boot
    cd "$WP/u-boot"
    if [ $cleanbuild -eq 1 ];then
        echo "need to make cleanbuild for u-boot"
        make distclean
    fi
    make rk322x_box_defconfig
    make -j20
    echo "You've build u-boot correctly"
#make kernel
    cd "$WP/kernel"
    if [ $cleanbuild -eq 1 ];then
        echo "need to make cleanbuild for kernel"
        #make distclean
        make clean
    fi
    #if [ "$inputmodule" = "rtl8188ftv" ];then
        echo "make shuangyi-wifi as rtl8188ftv"
        make shuangyi_rtl8188ftv_defconfig
        make shuangyi-rk3228b-rtl8188ftv-box.img -j16
   # else
   #    echo "make shuangyi-wifi as rtl8192eu"
   #     make shuangyi_rtl8192eu_defconfig
   #     make shuangyi-rk3228b-rtl8192eu-box.img -j16       
   # fi
    echo "You've build kernel correctly"
#make android
    cd $WP
    make installclean
    cp -a $WP/kernel/arch/arm/boot/zImage $WP/out/target/product/rk3228/kernel
    make -j16
    echo "you've make android correctly"
#build image
#only needed when official
    echo "officalbuild is : $officialbuild"
    if [ $officialbuild -ne 0 ]; then
        echo "need to make official OTA packages"
        make otapackage
    fi
    if [ "$carrier" = "ba" ];then
        echo "generate image of China Unicom"
        ./mkimage.sh ota unsign backup
    else
        echo "generate other image"
        ./mkimage.sh ota 
    fi
}

MakeRk3228HFactory() {
    echo "Please confirm if you need to clean the kernel and u-boot"
    echo "+++++++++++++No input means need CleanBuild+++++++"
    echo "Please enter [Yy/Nn]: "
    read -t 10 cbuild
    echo $?
    if [ $? -ne 0 ] ;then
        echo "You don't give any input, use cleanbuild default value as TRUE"
        cleanbuild=1
    else
        if [ "$cbuild" = "n" ] || [ "$cbuild" = "N" ]; then
            echo "!!!!!!!!!!!!!!!!!Alert, You didn't clear the kernel workspace !!!!!!!!!!!!!!!"
            cleanbuild=0
        else
            echo "++++++++++++++++++You choose to clean the kernel workspace ++++++++++++++++++"
        fi
    fi
    cd $WP
    set -e
    source build/envsetup.sh
    lunch rk3228h-eng
#make u-boot
    cd "$WP/u-boot"
    if [ $cleanbuild -eq 1 ];then
        echo "need to make cleanbuild for u-boot"
        make distclean
    fi
    make rk322xh_box_defconfig
    make ARCHV=aarch64 -j16
    echo "You've build u-boot correctly"
#make kernel
    cd "$WP/kernel"
    if [ $cleanbuild -eq 1 ];then
        echo "need to make cleanbuild for kernel"
        #make distclean
        make clean
    fi
    echo "make shuangyi-wifi as rtl8188ftv"
    make ARCH=arm64 twowing_3228h_rk805_rtl8192_4layout_lpddr3_defconfig
    make ARCH=arm64 twowing_3228h_rk805_rtl8192_4layout_lpddr3.img -j12
    echo "You've build kernel correctly"
#make android
    cd $WP
    cp kernel/arch/arm64/boot/Image out/target/product/rk3228h/kernel
    make installclean
    make -j20
    echo "you've make android correctly"
#build image
#only needed when official
    echo "officalbuild is : $officialbuild"
    if [ $officialbuild -ne 0 ]; then
        echo "need to make official OTA packages"
        make otapackage
    fi
    if [ "$carrier" = "ba" ];then
        echo "generate image of China Unicom"
        ./mkimage.sh ota unsign backup
    else
        echo "generate other image"
        ./mkimage.sh ota 
    fi
}

BuildFactoryUpdate() {
    local workdir=$WP
#   rockdev of system image blabla
    cp -R ${sourceimg}/* ${targetimg}/
#   if make ctnx,it will cp backupfactory.img to targetimg
	HandleCTNXfactory
    cp ${imgmake_tool}/baseparamer*.img ${targetimg}/
    cp ${imgmake_tool}/devinfo.img ${targetimg}/
    cp ${imgmake_tool}/misc_factory.img ${targetimg}/
#kernel
#logo
    #cp ${imgmake_tool}/logo_asb.bmp ${targetimg}/logo.bmp
    cp ${imgmake_tool}/logo_ctnx.bmp ${targetimg}/logo.bmp
#u-boot
    cp ${workdir}/u-boot/uboot.img ${targetimg}/
    cp ${workdir}/u-boot/trust.img ${targetimg}/
#default fdisk
    #cp ${imgmake_tool}/../parameter-rk3228-iptv ${targetimg}/../parameter
    if [ "$buildtype" = "S3228b" ];then
        cp ${imgmake_tool}/../parameter-rk3228-iptv.factory ${targetimg}/../parameter
        cp ${workdir}/u-boot/RK322X*.bin ${targetimg}/../
    elif [ "$buildtype" = "3228h" ];then
        cp ${imgmake_tool}/../parameter-rk3228h-iptv.factory ${targetimg}/../parameter
        cp ${workdir}/rockdev/Image-rk3228h/MiniLoaderAll.bin ${targetimg}/
    else
        echo "input product name failed ,please recheck"
    fi 
    cp ${imgmake_tool}/../package-file.factory ${targetimg}/../package-file
#make update
    cd ${targetimg}/../
    ./mkupdate.sh
    echo "update.img was generated in $targetimg"
}

######handle ctnx factory.img######
HandleCTNXfactory () {
    #echo "if make ctnx firmware,it will cp backup_factory.img to targetimg_path"
    if [ $carrier$province = "ctnx" ]; then
	   echo "NOW making fireware is CTNX"
	 	  cp ${imgmake_tool}/../backupimage/factory.img ${targetimg}/
	      if [ $? -eq 0 ]; then
		      echo "factory.img existed and cp it to targetimg"
		  else
		      echo "#####WARNING:factory.img not existed######"
			  return 1
		  fi 
	else
	   echo "HandleCTNXfactory function make noting"
	fi
}

HandleRk3228HFactoryUpdate () {
    local updateimg="$genimg/update.img"
    local upfullota="$fullota/rk3228h-ota-eng*.zip"
    local updateota="$targetota/rk3228h-target_files-*.zip"
    echo "officalbuild is $officalbuild"
    if [ $officialbuild -eq 0 ]; then
        echo "move update.img to realted directory"
        mv $updateimg $image
    else
        echo "this is one official build", need to store the OTA and rename update.image.
        local imgname="$image/$imgpfx.img"
        echo "Factory Image name is : $imgname"
        mv $updateimg $imgname
        local int="_int"
        local otaname="$ota/target/$imgpfx$int.zip"
        mv $updateota $otaname
        local otafullname="$ota/full/$imgpfx.zip"
        mv $upfullota $otafullname
    fi
}
HandleRk3228BFactoryUpdate () {
    local updateimg="$genimg/update.img"
    local upfullota="$fullota/rk3228-ota-eng*.zip"
    local updateota="$targetota/rk3228-target_files-*.zip"
    echo "officalbuild is $officalbuild"
    if [ $officialbuild -eq 0 ]; then
        echo "move update.img to realted directory"
        mv $updateimg $image
    else
        echo "this is one official build", need to store the OTA and rename update.image.
        local imgname="$image/$imgpfx.img"
        echo "Factory Image name is : $imgname"
        mv $updateimg $imgname
        local int="_int"
        local otaname="$ota/target/$imgpfx$int.zip"
        mv $updateota $otaname
        local otafullname="$ota/full/$imgpfx.zip"
        mv $upfullota $otafullname
    fi
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
        mv $filename $image
    fi
}


CheckOutPut(){
    local python_s="$vendorpath"
    local inputchip_u=`tr '[a-z]' '[A-Z]' <<<"$inputchip"`
    local inputmodule_u=`tr '[a-z]' '[A-Z]' <<<"$inputmodule"`
    local branchname="s010wa_zy_"$carrier"_"$province
    echo "PRODUCTNAME=$PRODUCTNAME"
    echo "inputchip_u=$inputchip_u"
    echo "carrierprovince=$carrier$province" 
    echo "branchname=$branchname"
    local flag=0
	
    checkOutPut_ret=$(python $python_s/buildCheck.py  "checkOutput" "$PRODUCTNAME" "$inputchip_u" "$carrier$province" "$branchname" $inputlauncher)    
    if [ "$checkOutPut_ret" == "False" ];then
        echo "CheckOutPut return false!! line 706"
        flag=1
    fi
	
    if [ $flag -eq 1 ];then
        echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
        echo "Error output is not correct,please check suying.mk and build.prop!!!"
        echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
        exit
    else
        echo "output is correct!!!"
        return 0
    fi		
}

###########liu xiaochen##############
Checkbuildprop () {
   CheckOutPut
   cd $vendorpath
   echo "$vendorpath"
   source buildprepare.sh
   echo "offcialversion is $offcialversion"
   if [ "$offcialversion" = "y" ] || [ "$offcialversion" = "Y" ]; then
       if [ "$buildtype" = "3228b" ];then
	        makeRk3228bbuildprop
	   elif [ "$buildtype" = "3228h" ];then
            makeRk3228hbuildprop
	   fi
	  echo "make build.prop and MD5 file"
   else
      echo "make nothing"
   fi
}

makeRk3228bbuildprop () {
local buildpath="$WP/out/target/product/rk3228/system/build.prop"
local buildpropname="$image/$imgpfx.build.prop"
local imgname="$image/$imgpfx.img"
local imgmd5="$image/$imgpfx.txt"
local otafullname="$ota/full/$imgpfx.zip"
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
	   echo "imgname is ${imgpfx}.img"	   
	   #md5img=$(ls $imgname | xargs -n 1 basename)
	   md5vimg=$(md5sum $(ls $imgname) | awk '{print $1}')
	   md5nimg=$(ls $imgname | xargs -n 1 basename )
	   mdvnimg="$md5nimg$sp$MD5$md5vimg"
	   echo $mdvnimg >$imgmd5   
	else
	   echo "$imgpfx.img is not existed"
	fi
########md5ota##############
    if [ -f $otafullname ]; then
	   echo "otafullname is ${imgpfx}.zip"
	   #md5ota=$(ls $otafullname | xargs -n 1 basename)
	   md5vota=$(md5sum $(ls $otafullname) | awk '{print $1}')
	   md5nota=$(ls $otafullname | xargs -n 1 basename ) 
	   md5vnota="$md5nota$sp$MD5$md5vota"
	   echo $md5vnota >>$imgmd5
	   unix2dos $imgmd5
	else
	   echo "$imgpfx.zip is not existed"
	fi
}

makeRk3228hbuildprop () {
local buildpath="$WP/out/target/product/rk3228h/system/build.prop"
local buildpropname="$image/$imgpfx.build.prop"
local imgname="$image/$imgpfx.img"
local imgmd5="$image/$imgpfx.txt"
local otafullname="$ota/full/$imgpfx.zip"
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
	   echo "imgname is ${imgpfx}.img"	   
	   #md5img=$(ls $imgname | xargs -n 1 basename)
	   md5vimg=$(md5sum $(ls $imgname) | awk '{print $1}')
	   md5nimg=$(ls $imgname | xargs -n 1 basename )
	   mdvnimg="$md5nimg$sp$MD5$md5vimg"
	   echo $mdvnimg >$imgmd5   
	else
	   echo "$imgpfx.img is not existed"
	fi
########md5ota##############
    if [ -f $otafullname ]; then
	   echo "otafullname is ${imgpfx}.zip"
	   #md5ota=$(ls $otafullname | xargs -n 1 basename)
	   md5vota=$(md5sum $(ls $otafullname) | awk '{print $1}')
	   md5nota=$(ls $otafullname | xargs -n 1 basename ) 
	   md5vnota="$md5nota$sp$MD5$md5vota"
	   echo $md5vnota >>$imgmd5
	   unix2dos $imgmd5
	else
	   echo "$imgpfx.zip is not existed"
	fi
}

MakeDiffFile(){
    local python_s="$vendorpath"
    diffFile_ret=$(python $python_s/makeDiffFile.py $buildtype "$carrier$province" $inputlauncher $imgpfx)
    if [ "$diffFile_ret" == "False" ];then
        echo "Make diff file failed ,please recheck."
        return 1
    fi
    return 0
}

CheckDiffMd5(){
    local inputchip_u=`tr '[a-z]' '[A-Z]' <<<"$inputchip"`
    local python_s="$vendorpath"
    local inputmodule_u=`tr '[a-z]' '[A-Z]' <<<"$inputmodule"`
    local branchname="s010wa_zy_"$carrier"_"$province
    echo "PRODUCTNAME=$PRODUCTNAME"
    echo "inputchip_u=$inputchip_u"
    echo "carrierprovince=$carrier$province" 
    echo "branchname=$branchname"
    parameter_ret=$(python $python_s/buildCheck.py  "CheckIptvandout" "$PRODUCTNAME" "$inputchip_u" "$carrier$province" "$branchname" $inputlauncher)
    if [ "$parameter_ret" == "False" ];then
        exit
    fi
}

########################################
BuildRk3228B () {
    #CheckPreBuild

    source buildprepare.sh
    CheckPreBuild1
    if [ $? -eq 1 ]; then
        return 1
    fi
    
    RecordBuildInfo	
    MakeRk3228B
    if [ $? -eq 1 ]; then 
        echo "You make option is not correct"
    fi
    
    set -e
    CheckDiffMd5
    BuildUpdate
    HandleRk3228bUpdate
    Checkbuildprop
}

BuildRk3228H () {
    #CheckPreBuild

    source buildprepare.sh
    CheckPreBuild1
    if [ $? -eq 1 ]; then
        return 1
    fi  
	RecordBuildInfo
    if [ "$PRODUCTNAME" = "S-010W-AV2" ];then
        MakeAV2
        echo "build.sh 817"
    elif [ "$PRODUCTNAME" = "S-010W-AV2C" ];then
        MakeAV2C
        echo "Now MakeAV2C"
    elif [ "$PRODUCTNAME" = "S-010W-AV2E" ];then
        MakeAV2E
        echo "Now MakeAV2E"
    elif [ "$PRODUCTNAME" = "S-010W-A" ] && [ "$carrier$province" = "cusc" ];then
        MakeAV2C
        echo "Now MakeAV2C 2"
    else
        MakeRk3228H
        echo "build.sh 820"
    fi
	
    if [ $? -eq 1 ]; then 
        echo "You make option is not correct"
    fi
    
    set -e
    CheckDiffMd5
    BuildUpdate
    HandleRk3228hImg
    Checkbuildprop
}

#Anything CDE of factory ?
BuildRk3228BFactory () {
    source buildprepare.sh
#   set build mode as buildfactory
    buildfactory=1
    CheckPreBuildFactory
    if [ $? -eq 1 ]; then
        return 1
    fi
    RecordBuildInfo
    MakeRk3228BFactory
    set -e
    CheckDiffMd5
    BuildFactoryUpdate
    HandleRk3228BFactoryUpdate
    Checkbuildprop
}

BuildRk3228HFactory() {
    source buildprepare.sh
#   set build mode as buildfactory
    buildfactory=1
    CheckPreBuildFactory
    if [ $? -eq 1 ]; then
        return 1
    fi
    RecordBuildInfo
    if [ "$PRODUCTNAME" = "S-010W-AV2" ];then
        MakeAV2
        echo "Now MakeAV2Factory"
    elif [ "$PRODUCTNAME" = "S-010W-AV2E" ];then
        MakeAV2E
        echo "Now MakeAV2E"
    elif [ "$PRODUCTNAME" = "S-010W-AV2C" ];then
        MakeAV2C
        echo "Now MakeAV2C"
    else
        MakeRk3228HFactory
        echo "build.sh 829"
    fi
    set -e
    CheckDiffMd5
    BuildFactoryUpdate
    HandleRk3228HFactoryUpdate
    Checkbuildprop
}

#img: S-010W-A_SW_FAC_RTL8188FTV_R1.00.00.img
#input: $1: base version, $2: updated version
CalFacOtaParam () {
    echo "CalFacOtaParam first parameter is $1, second parameter is $2"
    local Con="_"
    local int="_int"
    local Poi="."
    
    local basemaj=$1
    local basemin=$2
    local upmaj=$3
    local upmin=$4
    
    #GenVersionStr $majorversion $1
    GenVersionStr $basemaj $basemin
    #imgpfx="S-010W-A_SW_FAC_$CAPWIFI$Con$VERSIONSTR"
    #imgpfx="S-010W-A_SW_FAC_$CAPWIFI$Con$VERSIONSTR$int"
    imgpfx="$PRODUCTNAME_SW_FAC$Con$VERSIONSTR$int"
    baseota="$ownbuild/input/base/$imgpfx.zip"
    
    local basefile=$imgpfx    
    echo "baseota is : $baseota"

    #GenVersionStr $majorversion $2
    GenVersionStr $upmaj $upmin
    local upfile=$imgpfx
    #echo "upfile is $upfile"
    #upota="$vendorpath/ota/target/$upfile.zip"
    upota="$ota/target/$imgpfx$int.zip"
    echo "upota is : $upota"

    localota="$basefile$Con$upfile"
    echo "localota is $localota"
    local Zip="zip"
    local Poi="."
    targetota="$vendorpath/ota/$localota$Poi$Zip"
    echo "target ota is: $targetota"    
}

#input, $1: base version, $2: updated version
CalculateOtaParam () {
    echo "CalculateOtaParam first parameter is $1, second parameter is $2"
    local Con="_"
    local int="_int"
    local basemaj=$1
    local basemin=$2
    local upmaj=$3
    local upmin=$4
    
    #GenVersionStr $majorversion $1
    GenVersionStr $basemaj $basemin
        #local otaname="$ota/target/$imgpfx.zip"
    local int="_int"
    baseota="$ota/target/$imgpfx$int.zip"
    local basefile=$imgpfx
    
    echo "baseota is : $baseota"
    
    #GenVersionStr $majorversion $2
    GenVersionStr $upmaj $upmin
    local upfile=$imgpfx
    #echo "upfile is $upfile"
    #upota="$vendorpath/ota/target/$upfile.zip"
    upota="$ota/target/$imgpfx$int.zip"
    echo "upota is : $upota"

    localota="$basefile$Con$upfile"
    echo "localota is $localota"
    local Zip="zip"
    local Poi="."
    targetota="$vendorpath/ota/$localota$Poi$Zip"
    echo "target ota is: $targetota"
    #upota=""            #the new version of zip
    #targetota=""        #to be generated zip
}


#need to check wifi types and minor version !!!!
BuildOtaFactory () {
    cd $WP
    source build/envsetup.sh
    lunch rk3228h-eng
    cd $vendorpath
    source buildcde.sh
    echo "Factory Image generation must input Wifi types !!!"
    HelpModules
    read wifi
    Checkmodules $wifi
    if [ $? -eq 1 ]; then
        echo "Sorry, You've input wrong wifi types !!!!"
        return 1
    fi
    CAPWIFI=${wifi^^}
    
    echo "Please first input base Factory name, you could find it in $ownbuild:"
    echo "Please input Factory majorversion: "
    echo "The accepted number is from 0 to 99"
    read basemaj
    if [ $basemaj -lt 0 ] || [ $basemaj -gt 100 ] || [ $basemaj -eq 199 ]; then 
        echo "basemajor format nok " 
        return 1
    fi
    echo "Please input Factory minorversion: "
    echo "The accepted number is from 0 to 99"  
    read basemin
    if [ $basemin -lt 0 ] || [ $basemin -gt 100 ] ; then 
        echo "baseminor format nok " 
        return 1
    fi   
        
    echo "Please input your update package name majorversion:"
    echo "   the accepted number is from 0 to 99 "
    read upmaj
    if [ $upmaj -lt 0 ] || [ $upmaj -gt 99 ]; then 
        echo "upmaj format nok " 
        return 1
    fi
    echo "Please input your update package name minorversion:"
    echo "   the accepted number is from 0 to 99 "    
    read upmin
    if [ $upmin -lt 0 ] || [ $upmin -gt 99 ]; then 
        echo "upmin format nok " 
        return 1
    fi   
    
    #echo "Please first input base Factory Img name, you could find it in $ownbuild:"
    #echo "The accepted number is from 0 to 99"
    #read basever
    #if [ $basever -lt 0 ] || [ $basever -gt 100 ]; then 
    #    echo "format nok " 
    #    return 1
    #fi
    
    #echo "Please input updatge branch Img version, the accepted number is from 0 to 99 "
    #read upver
    #if [ $upver -lt 0 ] || [ $upver -gt 99 ]; then 
    #    echo "format nok " 
    #    return 1
    #fi

    CheckMultiLauncher
    CalFacOtaParam $basemax $basemin $upmaj $upmin
    "$otatool" -v -i "$baseota" -p "$WP/out/host/linux-x86" -k "$testkey" "$upota" "$targetota"
}

Diffpackagemd5 () {
    local otatxt="$vendorpath/ota/$localota$Poi$Zip.txt"
    local sp=" "
	local MD5="MD5:"
    echo "targetota is $targetota"
    if [ -f $targetota ]; then
	   echo "target ota is: $targetota" 
	   md5votacom=$(md5sum $(ls $targetota) | awk '{print $1}')
	   echo "$md5votacom"
	   md5notacom=$(ls $targetota | xargs -n 1 basename ) 
	   echo "$md5notacom"
	   ma5otavalue="$md5notacom$sp$MD5$md5votacom"
	   echo "$ma5otavalue"
	   echo $ma5otavalue >$otatxt
	   unix2dos $otatxt
	 else
	   echo "targetota is not existed"
	 fi
} 

BuildOtaBranch () {
    cd $WP
    source build/envsetup.sh
    lunch rk3228h-eng
    cd $vendorpath
    source buildcde.sh
    echo "Please first input base package name, you could find it in $ota/target:"
    echo "Please input basepackage majorversion: "
    echo "The accepted number is from 0 to 99"
    read basemaj
    if [ $basemaj -lt 0 ] || [ $basemaj -gt 100 ] || [ $basemaj -eq 199 ]; then 
        echo "basemajor format nok " 
        return 1
    fi
    echo "Please input basepackage minorversion: "
    echo "The accepted number is from 0 to 99"  
    read basemin
    if [ $basemin -lt 0 ] || [ $basemin -gt 100 ] ; then 
        echo "baseminor format nok " 
        return 1
    fi   
        
    echo "Please input your update package name majorversion:"
    echo "   the accepted number is from 0 to 99 "
    read upmaj
    if [ $upmaj -lt 0 ] || [ $upmaj -gt 99 ]; then 
        echo "upmaj format nok " 
        return 1
    fi
    echo "Please input your update package name minorversion:"
    echo "   the accepted number is from 0 to 99 "    
    read upmin
    if [ $upmin -lt 0 ] || [ $upmin -gt 99 ]; then 
        echo "upmin format nok " 
        return 1
    fi   
    
    #it is possible that we need the launcher information like 'bestv'

    CheckMultiLauncher
    echo "base majorversion is :$basemaj,minorversion is $basemin,  updated majorversion is: $upmaj, minorversion is $upmin"
    #CalculateOtaParam $basever $upver
    CalculateOtaParam $basemaj $basemin $upmaj $upmin
    
    #"$otatool" -v -i "$baseota" -p "$WP/out/host/linux-x86" -k "$testkey" "$upota" "$targetota"
    echo "otatool is : $otatool"
    echo "baseota is : $baseota"
    echo "linux-86 is : $WP/out/host/linux-x86"
    echo "testkey is: $testkey"
    echo "upota is : $upota"
    echo "targetota is :$targetota"
    "$otatool" -v -i "$baseota" -p "$WP/out/host/linux-x86" -k "$testkey" "$upota" "$targetota"
	
	######cal diffpackage########
	Diffpackagemd5
}

BuildOta () {
    source buildprepare.sh
    echo "Please make sure your OTA build is Pure branch upgrade, or upgrade From Factory"
    echo "Please input Branch(B), or Factory(F):"
    read otamode
    if [ "$otamode" = "Branch" ] ||  [ "$otamode" = "B" ];then
        BuildOtaBranch
    elif [ "$otamode" = "Factory" ] ||  [ "$otamode" = "F" ];then
        BuildOtaFactory
    else
        echo "Your Input is Nok !!!!!!!, Please re-input"
    fi
}


BackUpAll(){
    local python_s="$vendorpath"
    backup_ret=$(python $python_s/backup_strategy.py "$buildtype" "$PRODUCTNAME"  "$carrier$province" $inputlauncher $imgpfx "method_sh")
    if [ "$parameter_ret" == "False" ];then
        exit
    fi
}
#$1 should be carrier, $2 should be province, $3 should be mode
source setenv.sh $1 $2 $3 $4 $5
otatool="$WP/build/tools/releasetools/ota_from_target_files"
testkey="$WP/build/target/product/security/testkey"

if [ "$6" = "normal" ]; then
    if [ "$buildtype" = "3228b" ]; then
        BuildRk3228B
    elif [ "$buildtype" = "3228h" ]; then
        BuildRk3228H
    else
        echo "pruduct name error p;ease recheck"
    fi
elif [ "$6" = "ota" ]; then
    echo "BuildOta called"
    BuildOta
elif [ "$6" = "factory" ]; then
    echo "BuildFactory called"
    if [ "$buildtype" = "3228b" ]; then
        BuildRk3228BFactory
    elif [ "$buildtype" = "3228h" ]; then
        BuildRk3228HFactory
    else
        echo "pruduct name error p;ease recheck"
    fi
else
    echo "!!!!!!!!!!!!!!!!!!!!!!!You called nothing to build "
fi
if [ $? -eq 0 ];then
    MakeDiffFile
    if [ $? -eq 0 ];then
        BackUpAll
    else
        echo "NOK"
    fi
fi

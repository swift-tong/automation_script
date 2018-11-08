from __future__ import division
import sys
import datetime
import re
import types
import pexpect
import os
import subprocess
import logging


class CheckInputApk():
    def __init__(self):
        logging.basicConfig(level=logging.INFO,format="%(message)s")
        self.logger=logging.getLogger("CheckInputApk log")		
	
        self.chiptype=sys.argv[1]
        self.province=sys.argv[2]
        self.launcher=sys.argv[3]
        self.delete_apk_list=[]
        self.old_apk_dict={}
        self.new_apk_dict={}
        self.build_dir=""
        self.mk_dir=""
        self.mk_file=""
        self.apk_dir=""
        self.android_file=""
		
        self.carrierDict={
            "cu":"ChinaUnicom_apks",
            "ct":"ChinaTelecom_apks",
            "cm":"ChinaMobile_apks"
        }
		
        self.mkDict={
            "cu":"unicom_",
            "ct":"telecom_",
            "cm":"mobile_"           
        }

        self.papk=os.environ["HOME"]+"/workspace/prebuilts/sdk/tools/linux/aapt dump badging"

    def	get_property(self):
        plog=self.logger.info
        check_list=["ctjc","cujc","cmsh"]
        if self.chiptype in ["s905l","s905l2","s905l3"]:
            self.build_dir=os.environ["HOME"]+"/amlbuild/"
            if self.province in ["ctjc","cthq"]:
                mk="telecom.mk"
            elif self.province == "cujc":
                mk="unicom.mk"
            elif self.province == "cmsh":
                mk="mobile.mk"
            else:
                mk=self.mkDict[self.province[:2]]+self.province[2:]+".mk"
            self.mk_file=os.environ["HOME"]+"/workspace/device/amlogic/common/{}".format(mk)
            self.mk_dir=os.environ["HOME"]+"/workspace/device/amlogic/common/"
			
            if self.launcher != "nolauncher" and self.province not in check_list:
                self.apk_dir = os.environ["HOME"]+"/workspace/device/amlogic/common/{}/{}_apks/{}/".format(self.carrierDict[self.province[:2]],self.province[2:].upper(),self.launcher)
            else:
                if self.province == "ctjc":
                    self.apk_dir = os.environ["HOME"]+"/workspace/device/amlogic/common/{}/SH_jicai_apks/SY/sy_apk/".format(self.carrierDict[self.province[:2]])
                elif self.province == "cthq":
                    self.apk_dir = os.environ["HOME"]+"/workspace/device/amlogic/common/{}/SH_jicai_apks/SY_FusionGateway/sy_apk/".format(self.carrierDict[self.province[:2]])
                elif self.province == "cujc":
                    self.apk_dir = os.environ["HOME"]+"/workspace/device/amlogic/common/{}/BJ_jicai_apks/SY/".format(self.carrierDict[self.province[:2]])
                elif self.province == "cmsh":
                    self.apk_dir = os.environ["HOME"]+"/workspace/device/amlogic/common/{}/sh/".format(self.carrierDict[self.province[:2]])
                else:
                    self.apk_dir = os.environ["HOME"]+"/workspace/device/amlogic/common/{}/{}_apks/".format(self.carrierDict[self.province[:2]],self.province[2:].upper())
        elif self.chiptype == "3228b" or self.chiptype == "3228h":
            self.build_dir=os.environ["HOME"]+"/build/input/zy/{}/".format(self.province)
            if self.launcher == "nolauncher":
                self.mk_file=os.environ["HOME"]+"/workspace/device/rockchip/rksdk/IPTV/IPTV_{}/suying.mk".format(self.province)
                self.android_file=os.environ["HOME"]+"/workspace/device/rockchip/rksdk/IPTV/IPTV_{}/Android.mk".format(self.province)
                self.mk_dir=os.environ["HOME"]+"/workspace/device/rockchip/rksdk/IPTV/IPTV_{}/".format(self.province)
                self.apk_dir = os.environ["HOME"]+"/workspace/device/rockchip/rksdk/IPTV/IPTV_{}/".format(self.province)
            else:
                self.mk_file=os.environ["HOME"]+"/workspace/device/rockchip/rksdk/IPTV/IPTV_{}_{}/suying.mk".format(self.province,self.launcher)
                self.android_file=os.environ["HOME"]+"/workspace/device/rockchip/rksdk/IPTV/IPTV_{}_{}/Android.mk".format(self.province,self.launcher)
                self.mk_dir=os.environ["HOME"]+"/workspace/device/rockchip/rksdk/IPTV/IPTV_{}_{}/".format(self.province,self.launcher)
                self.apk_dir = os.environ["HOME"]+"/workspace/device/rockchip/rksdk/IPTV/IPTV_{}_{}/".format(self.province,self.launcher)


        plog("self.build_dir={}".format(self.build_dir))
        plog("self.mk_file={}".format(self.mk_file))
        plog("self.android_file={}".format(self.android_file))
        plog("self.mk_dir={}".format(self.mk_dir))
        plog("self.apk_dir={}".format(self.apk_dir))
        if not self.build_dir or not self.mk_file or not self.apk_dir:
            plog("****Error:get_property error,please recheck.:Error****")
            return False
        return True			

    def get_delete_apk_list(self):
        plog=self.logger.info
        new_apk_list=[]
        old_apk_list=[]
        for fi in os.listdir(self.build_dir+"apk/"):
            if fi.endswith(".apk"):
                new_apk_list.append(fi)
        os.chdir(self.build_dir+"apk/")
        for item in new_apk_list:
            papk_ret=os.popen("{} {}".format(self.papk,item)).read()
            if not papk_ret:
                plog("****Error:aapt return false,please recheck {}:Error****".format(item))
                return False
            apk_package=papk_ret.split("'")[1]
            self.new_apk_dict[apk_package]=item

        for fi in os.listdir(self.apk_dir):
            if fi.endswith(".apk"):
                old_apk_list.append(fi)
        os.chdir(self.apk_dir)
        for item in old_apk_list:
            apk_package_2=os.popen("{} {}".format(self.papk,item)).read().split("'")[1]
            self.old_apk_dict[apk_package_2]=item
		
        plog("self.new_apk_dict={}".format(self.new_apk_dict))
        plog("self.old_apk_dict={}".format(self.old_apk_dict))		
        for key in self.new_apk_dict.keys():
            if key in self.old_apk_dict.keys() and self.new_apk_dict[key] != self.old_apk_dict[key]:
                self.delete_apk_list.append(self.old_apk_dict[key])
        plog("self.delete_apk_list={}".format(self.delete_apk_list))
        return True		

    def get_new_apk_form_delete_apk(self,_delete_apk):
        delete_apk=_delete_apk
        for key in self.old_apk_dict:
            if self.old_apk_dict[key] == delete_apk:
                return self.new_apk_dict[key]
		
    def delete_apk_aml(self):
        plog=self.logger.info
        mk_list=[]
        new_mk_list=[]
        if self.province == "ctjc":           
            pattern="device/amlogic/common/{}/SH_jicai_apks/SY/sy_apk/".format(self.carrierDict[self.province[:2]])
        elif self.province == "cujc":
            pattern="device/amlogic/common/{}/BJ_jicai_apks/SY/".format(self.carrierDict[self.province[:2]])
        elif self.province == "cmsh":
            pattern="device/amlogic/common/{}/sh/".format(self.carrierDict[self.province[:2]])
        else:
            if self.launcher == "nolauncher":
                pattern="device/amlogic/common/{}/{}_apks/".format(self.carrierDict[self.province[:2]],self.province[2:].upper())
            else:
                pattern="device/amlogic/common/{}/{}_apks/{}/".format(self.carrierDict[self.province[:2]],self.province[2:].upper(),self.launcher)
        plog("Serach pattern={}".format(pattern))

        ret=self.get_property()
        if not ret:
            return False
        ret2=self.get_delete_apk_list()
        if not ret2:
            return False
				
        os.chdir(self.mk_dir)
        #os.popen("git checkout -- {}".format(self.mk_file))
        with open(self.mk_file,"r") as f:
            ret3=(f.readlines())
        for item in ret3:
            in_mk=False
            for it in self.delete_apk_list:
                if pattern+it in item:
                    in_mk=True
                    break
            if in_mk:
                pass
            else:
                new_mk_list.append(item)

        with open(self.mk_file,"w") as f2:
            f2.writelines(new_mk_list)				
        plog("Have delete old apk in {}".format(self.mk_file.split("/")[-1]))
                        
        os.chdir(self.apk_dir)
        for item in self.delete_apk_list:
            os.popen("git rm {}".format(item))
        plog("Have delete old apk in {}".format(self.apk_dir))
        return True
		
    def delete_apk_rk(self):
        mk_list=[]
        new_mk_list=[]
        new_android_list=[]
        plog=self.logger.info
        ret=self.get_property()
        if not ret:
            return False
        ret2=self.get_delete_apk_list()
        if not ret2:
            return False
				
        os.chdir(self.mk_dir)
        with open(self.mk_file,"r") as f:
            ret3=(f.readlines())
        for item in ret3:
            if "device/" not in item and "=" not in item and "\\\n" in item:
                apkx=item.split("\\\n")[0].strip()+".apk"
                if apkx in self.delete_apk_list:
                    pass
                else:
				    new_mk_list.append(item)
            else:
                new_mk_list.append(item)

        with open(self.mk_file,"w") as f2:
            f2.writelines(new_mk_list)				
        plog("Have delete old apk in {}".format(self.mk_file.split("/")[-1]))
		
        os.popen("git checkout -- {}".format(self.android_file))		
        with open(self.android_file,"r") as f3:
            android_list=f3.readlines()
            for item in android_list:
                app=False
                for it in self.delete_apk_list:
                    if it[:-4] in item and "ifeq" not in item and item.endswith(it[:-4]+"\n"):
                        new_apk=self.get_new_apk_form_delete_apk(it)
                        tmp_str=item.replace(it[:-4],new_apk[:-4])
                        new_android_list.append(tmp_str)
                        app=True
                if not app:
                    new_android_list.append(item)
        with open(self.android_file,"w") as f4:
            f4.writelines(new_android_list)
        plog("Have delete old apk in {}".format(self.android_file.split("/")[-1]))
		
        os.chdir(self.apk_dir)
        for item in self.delete_apk_list:
            os.popen("git rm {}".format(item))
        plog("Have delete old apk in {}".format(self.apk_dir))
        return True

    def getResult(self):
        plog=self.logger.info
        delete_apk_ret=True
        if self.chiptype == "3228b" or self.chiptype == "3228h":
            delete_apk_ret=self.delete_apk_rk()
        elif self.chiptype in ["s905l","s905l2","s905l3"]:
            delete_apk_ret=self.delete_apk_aml()
        plog("delete_apk_ret=%s"%delete_apk_ret)
        return 	delete_apk_ret


if __name__ == "__main__":
    cia = CheckInputApk()
    cal = cia.getResult()	
    print cal
	
	
#   python handleInput.py  3228h cubj  nolauncher
#   or
#   python handleInput.py  s905l ctgd  nolauncher
#-*- coding=utf-8 -*-
from __future__ import division
from functools import wraps
import xml.dom.minidom
import sys
import datetime
import re
import types
import pexpect
import os
import subprocess
import logging
import threading
import json
import ConfigParser
import signal

			 
		   
#method list:[setLogger,getDir,checkProductMode,checkFlashRelevant,checkHardwareId,checkLogoBmp,ssh_command]
 #            [checkImg,checkbranch,checkBoardConfig,checkSuyingMkNull,checkAndroidMk,createOperation,getResult]

 
def add_coloring_to_emit_ansi(fn):
    def new(*args):
        levelno = args[1].levelno
        if(levelno>=50):
            color = '\x1b[34m' # deep red/fatal
        elif(levelno>=40):
            color = '\x1b[31m' # red/error
        elif(levelno>=30):
            color = '\x1b[32m' # yellow/warn
        elif(levelno>=20):
            color = '\x1b[37m' # white/info
        elif(levelno>=10):
            color = '\x1b[35m' # pink/debug
        else:
            color = '\x1b[0m' # normal
        args[1].msg = color + args[1].msg +  '\x1b[0m'  # normal
        return fn(*args)
    return new 

logging.StreamHandler.emit = add_coloring_to_emit_ansi(logging.StreamHandler.emit)
log = logging.getLogger("build check")
log.setLevel(logging.DEBUG)
hdlr = logging.StreamHandler()
formatter = logging.Formatter('%(message)s\n')
hdlr.setFormatter(formatter)
log.addHandler(hdlr)



nsbotaServerDict={                   
    ("S-010W-A","cusd","nolauncher") : ("ro.config.nsbotaserver","http://119.164.210.229:8023/upgrade.ini \\"),
    ("S-010W-AV2C","cusd","nolauncher") : ("ro.config.nsbotaserver","http://119.164.210.229:8023/upgrade.ini \\"),
    ("S-010W-AQD","cuqd","nolauncher") : ("ro.config.nsbotaserver","http://119.164.210.229:8023/upgrade.ini \\"),
    ("S-010W-AV2B","cusd","nolauncher") : ("ro.config.nsbotaserver","http://119.164.210.229:8023/upgrade.ini \\"),
    ("S-010W-A","cusd","newline") : ("ro.config.nsbotaserver","http://119.164.210.229:8023/upgrade.ini \\"),
    ("RG020ET-CA","cusd","nolauncher") : ("ro.config.nsbotaserver","http://119.164.210.229:8023/upgrade.ini"),
	("G-120WT-P","zsqd","nolauncher") : ("ro.config.nsbotaserver","http://otaserver.nsb.qdairport:8082/upgrade.ini"),
    #("S-010W-A","cuhn","yaxin") : ("ro.config.nsbotaserver","http://119.164.210.229:8023/upgrade.ini \\"),
}


class myconf(ConfigParser.ConfigParser):
    def __init__(self,defaults=None):
        ConfigParser.ConfigParser.__init__(self,defaults=None)

    def optionxform(self, optionstr):
        return optionstr



def build_decorator(func):
    @wraps(func)
    def wrapper(*args,**kwargs):
        log.warn("---------------------------------------------------------------------------------------")
        return func(*args,**kwargs)
    return wrapper
class CheckGitStatus():
    def __init__(self):
        self.productname=sys.argv[2]
        self.chipType=sys.argv[3]
        self.province=sys.argv[4]
        self.launcher=sys.argv[6]
        self.manifest_dict = {}
        self.uncommit_dir=[]
        self.no_path_item=[]
        self.folder_count=0
        self.workspace=os.environ["HOME"]+"/workspace/"
        self.thread_len=10

        self.base_manifest=os.environ["HOME"]+"/workspace/.repo/manifest.xml"
        base_dom = xml.dom.minidom.parse(self.base_manifest)
        self.base_dom_list = base_dom.getElementsByTagName('project')

    def get_git_folder(self):
        count=0
        for item in self.base_dom_list:
            folder=item.getAttribute("path")
            if not folder:
                folder = item.getAttribute("name")
                self.no_path_item.append(folder)
            commit=item.getAttribute("revision")
            if folder not in ["device/rockchip/rksdk","device/amlogic"]:
                self.manifest_dict[folder]=commit
        log.warn("No 'path' item in manifest: {}".format(str(self.no_path_item)))

    def check_thread(self,key_list):
        for key in key_list:
            self.folder_count=self.folder_count+1
            log.info("{} check fold {} : {}".format(threading.currentThread().name,self.folder_count,key))
            if os.path.exists(self.workspace+key):
                os.chdir(self.workspace+key)
                ret=os.popen("git status").read()
                if ("Changes to be committed:" in ret or "Changes not staged for commit:" in ret) and "api/current.txt" not in ret:
                    self.uncommit_dir.append(key)
        self.thread_len=self.thread_len-1

    
    def div_list(self,ls,n):
	    if not isinstance(ls,list) or not isinstance(n,int):
		    return []
	    ls_len = len(ls)
	    if n<=0 or 0==ls_len:
		    return []
	    if n > ls_len:
		    return []
	    elif n == ls_len:
		    return [[i] for i in ls]
	    else:
		    j = ls_len//n
		    k = ls_len%n
		    ls_return = []
		    for i in xrange(0,(n-1)*j,j):
			    ls_return.append(ls[i:i+j])
		    ls_return.append(ls[(n-1)*j:])
		    return ls_return
 
    def myquit(self,signum,frame):
        log.warn('You choose to stop me.')
        sys.exit()
 
 
    def check_git_status(self):
        signal.signal(signal.SIGINT, self.myquit)
        signal.signal(signal.SIGTERM, self.myquit)
        threads=[]
        self.get_git_folder()
        log.warn("Checking git statues...")
        div_li=self.div_list(self.manifest_dict.keys(),10)
        for i in div_li:
            threads.append(threading.Thread(target=self.check_thread,args=(i,)))
        for t in threads:
            t.setDaemon(True)
            t.start()
        #for t in threads:
        #    t.join()
        log.warn("Totle {} folders!".format(len(self.manifest_dict.keys())))

        while self.thread_len > 0:
            pass
		
        if len(self.uncommit_dir) > 0: 
            log.warn("The follow floders have uncommit changes.")
            log.warn(str(self.uncommit_dir))
            return "changed"
        else:
            return "nochanged"
		
    @build_decorator			
    def getResult(self):
        checkGitSt_ret=self.check_git_status()
        log.warn("checkGitSt_ret=%s"%checkGitSt_ret)
        return checkGitSt_ret
	
class CheckIptvandout(object):
     def __init__(self):
       self.product=sys.argv[2]
       self.chiptype=sys.argv[3]
       self.province=sys.argv[4]
       self.launcher=sys.argv[6]
       flag = False      
       if self.chiptype=="RK3228H":
            self.outdir_lib=os.environ["HOME"]+"/workspace/out/target/product/rk3228h/system/lib"
            self.outdir_etc=os.environ["HOME"]+"/workspace/out/target/product/rk3228h/system/etc"
            self.outdir_bin=os.environ["HOME"]+"/workspace/out/target/product/rk3228h/system/bin"
            self.outdir_apk=os.environ["HOME"]+"/workspace/out/target/product/rk3228h/system/app"
       elif self.chiptype=="RK3228B":
            self.outdir_lib=os.environ["HOME"]+"/workspace/out/target/product/rk3228/system/lib"
            self.outdir_etc=os.environ["HOME"]+"/workspace/out/target/product/rk3228/system/etc"
            self.outdir_bin=os.environ["HOME"]+"/workspace/out/target/product/rk3228/system/bin"
            self.outdir_apk=os.environ["HOME"]+"/workspace/out/target/product/rk3228/system/app"     
			
       if self.launcher == "nolauncher":
           self.iptvdir_libs=os.environ["HOME"]+"/workspace/device/rockchip/rksdk/IPTV/IPTV_{}/libs".format(self.province)
           self.iptvdir_etc=os.environ["HOME"]+"/workspace/device/rockchip/rksdk/IPTV/IPTV_{}/etc".format(self.province)
           self.iptvdir_bin=os.environ["HOME"]+"/workspace/device/rockchip/rksdk/IPTV/IPTV_{}/bin".format(self.province)
           self.iptvdir_apk=os.environ["HOME"]+"/workspace/device/rockchip/rksdk/IPTV/IPTV_{}".format(self.province)
    		   
       else:
           self.iptvdir_libs=os.environ["HOME"]+"/workspace/device/rockchip/rksdk/IPTV/IPTV_{}_{}/libs".format(self.province,self.launcher)           	   
           self.iptvdir_etc=os.environ["HOME"]+"/workspace/device/rockchip/rksdk/IPTV/IPTV_{}_{}/etc".format(self.province,self.launcher)           	   
           self.iptvdir_bin=os.environ["HOME"]+"/workspace/device/rockchip/rksdk/IPTV/IPTV_{}_{}/bin".format(self.province,self.launcher) 
           self.iptvdir_apk=os.environ["HOME"]+"/workspace/device/rockchip/rksdk/IPTV/IPTV_{}_{}".format(self.province,self.launcher)		   

     def checkfilemd(self,outdir,iptvdir):
           outlist=os.listdir(outdir)
           iptvlist=os.listdir(iptvdir)
           noinout=[]
           md5error=[]
           iptvlist_new=[]
           outlist_ret=[]
           iptvlist_ret=[]
           if outdir==(self.outdir_lib): 
               for num in outlist:
                   if  (num.endswith(".so")):
                       outlist_ret.append(num)
               for num in iptvlist:
                   if (num.endswith(".so")):
                       iptvlist_ret.append(num)
           if outdir==(self.outdir_apk): 		       
               for num in outlist:
                   if (num.endswith(".apk")):
                      outlist_ret.append(num)
               for num in iptvlist:
                   if (num.endswith(".apk")):
                      iptvlist_ret.append(num)
           if iptvlist_ret:
                iptvlist = []
                iptvlist=list(iptvlist_ret)				
           for num in iptvlist:
               if num not in outlist:
                  noinout.append(num)
               else:
                  iptvlist_new.append(num)
           if outdir!=(self.outdir_apk):
               for num in iptvlist_new:
                    md5_iptv=os.popen('md5sum {}/{}'.format(iptvdir,num)).read().split("  ")[0]
                    md5_out=os.popen('md5sum {}/{}'.format(outdir,num)).read().split("  ")[0]
                    if md5_iptv != md5_out:
                     md5error.append(num) 
           if md5error:
                 log.error("ERROR***The following file at IPTV and out directory MD5 is different***ERROR")            
                 log.error("md5error=%s"%md5error)
                 return False
           if noinout:
              log.error("ERROR***The following file is in iptv not in out directory***ERROR")
              log.error ("noinout=%s"%noinout)
              return False
           return True

     def iptvandout(self):
            checkfilemd_libs=self.checkfilemd(self.outdir_lib,self.iptvdir_libs)
            checkfilemd_apk=self.checkfilemd(self.outdir_apk,self.iptvdir_apk)
            checkfilemd_bin=self.checkfilemd(self.outdir_bin,self.iptvdir_bin)
            checkfindmd_etc=self.checkfilemd(self.outdir_etc,self.iptvdir_etc)
            return checkfilemd_libs and checkfilemd_bin and checkfindmd_etc and checkfilemd_apk

     @build_decorator			
     def getResult(self):
        iptvandout_ret = self.iptvandout()
        log.warn("iptvandout_ret=%s"%iptvandout_ret)		
        return iptvandout_ret	

class CheckConfig(object):
    def __init__(self):
        self.product=sys.argv[2]
        self.chiptype=sys.argv[3]
        self.province=sys.argv[4]
        self.launcher=sys.argv[6]
        self.checkTupe=(self.product.upper(),self.province.lower(),self.launcher.lower())
		
        if self.chiptype == "RK3228H":		
            self.buildProp=os.environ["HOME"]+"/workspace/out/target/product/rk3228h/system/build.prop"
        elif self.chiptype == "RK3228B":
            self.buildProp=os.environ["HOME"]+"/workspace/out/target/product/rk3228/system/build.prop"

        if self.launcher == "nolauncher":
            self.suyingmk=os.environ["HOME"]+"/workspace/device/rockchip/rksdk/IPTV/IPTV_{}/suying.mk".format(self.province)
        else:
            self.suyingmk=os.environ["HOME"]+"/workspace/device/rockchip/rksdk/IPTV/IPTV_{}_{}/suying.mk".format(self.province,self.launcher)
		
        self.otaServerDict={
                    ("S-010W-A","cuhn","yaxin") : ("ro.config.otaserver","http://nsb.hn165.com:8082/Version.ini \\"),
                    ("S-010W-AV2","cuhn","nolauncher") : ("ro.config.otaserver","http://nsb.hn165.com:8082/Version.ini \\"),
                    ("S-010W-A","cusd","nolauncher") : ("ro.config.otaserver","http://60.217.44.37:7070/FileServer/FILE/SOFT/NSB/ \\"),
                    ("S-010W-AQD","cuqd","nolauncher") : ("ro.config.otaserver","http://60.217.44.37:7070/FileServer/FILE/SOFT/NSB/Version.xml \\"),
                    ("S-010W-AV2B","cusd","nolauncher") : ("ro.config.otaserver","http://60.217.44.37:7070/FileServer/FILE/SOFT/NSB/ \\"),
                    ("S-010W-A","cusd","newline") : ("ro.config.otaserver","http://60.217.44.37:7070/FileServer/FILE/SOFT/NSB/ \\"),
                    ("S-010W-A","ctnx","nolauncher") : ("ro.config.otaserver","http://nsb.nx186.com/Version.xml \\"),
                    ("G-120WT-P","cuhl","nolauncher") : ("ro.config.otaserver","http://1.58.81.208:8082/update.zip \\"),
                    ("G-120WT-P","cuhl","fenghuo") : ("ro.config.otaserver","http://1.58.81.208:8082/update.zip \\"),
                    ("G-120WT-P","cuhl","huawei") : ("ro.config.otaserver","http://1.58.81.208:8082/update.zip \\"),
                    ("S-010W-AV2S","cuhl","fenghuo") : ("ro.config.otaserver","http://1.58.81.208/Version.xml \\"),
                    ("S-010W-AV2S","cuhl","huawei") : ("ro.config.otaserver","http://1.58.81.208/Version.xml \\"),
                    ("S-010W-A","cuxj","nolauncher") : ("ro.config.otaserver","http://10.38.1.14:8082/ \\"),
                    ("S-010W-AV2B","cujx","nolauncher") : ("ro.config.otaserver","http://118.212.169.136:8888/Version.ini \\"),
                    ("G-120WT-P","ctln","nolauncher") : ("ro.config.otaserver","http://fenghuo.99tv.com.cn:8087/HG680B/Version.ini \\"),
                    ("S-010W-A","cusc","nolauncher") : ("ro.config.otaserver","http://119.6.239.36:8888/Version.ini \\"),
                    ("S-010W-AV2B","ossm","nolauncher") : ("ro.config.otaserver","http://192.168.1.106/:8888/Version.ini \\"),
                    ("G-120WT-P","cunm","nolauncher") : ("ro.config.otaserver","http://10.11.33.19:8082/Version.ini \\"),
                    ("G-120WT-P","ctsx","nolauncher") : ("ro.config.otaserver","http://124.224.238.186:2300 \\"),
             }

        self.rkHostDict={
                    ("S-010W-A","cuhn","yaxin") : ("ro.product.ota.host","nsb.hn165.com:8083 \\"),
                    ("S-010W-AV2","cuhn","nolauncher") : ("ro.product.ota.host","nsb.hn165.com:8083 \\"),
                    ("S-010W-A","cusd","nolauncher") : ("ro.product.ota.host","119.164.210.229:8022 \\"),
                    ("S-010W-AQD","cuqd","nolauncher") : ("ro.product.ota.host","119.164.210.229:8022 \\"),
                    ("S-010W-AV2B","cusd","nolauncher") : ("ro.product.ota.host","119.164.210.229:8022 \\"),
                    ("S-010W-A","cusd","newline") : ("ro.product.ota.host","119.164.210.229:8022 \\"),
                    ("S-010W-A","ctnx","nolauncher") : ("ro.product.ota.host","http://124.224.238.186:2300 \\"),
                    ("G-120WT-P","cuhl","nolauncher") : ("ro.product.ota.host","www.rockchip.com:2300 \\"),
                    ("G-120WT-P","cuhl","fenghuo") : ("ro.product.ota.host","www.rockchip.com:2300 \\"),
                    ("G-120WT-P","cuhl","huawei") : ("ro.product.ota.host","www.rockchip.com:2300 \\"),
                    ("S-010W-A","cuxj","nolauncher") : ("ro.product.ota.host","http://10.38.1.14:2300 \\"),
                    ("G-120WT-P","ctln","nolauncher") : ("ro.product.ota.host","http://124.224.238.186:2300 \\"),
                    ("G-120WT-P","ctnm","normal") : ("ro.product.ota.host","http://124.224.238.186:2300 \\"),
                    ("S-010W-AV2B","ossm","nolauncher") : ("ro.product.ota.host","http://192.168.1.106/Version.ini \\"),
                    ("G-120WT-P","cunm","nolauncher") : ("ro.product.ota.host","http://124.224.238.186:2300 \\"),
                    ("G-120WT-P","ctsx","nolauncher") : ("ro.product.ota.host","http://192.168.1.106/Version.ini \\"),
             }

		
    def checkOtaServer(self):
        checkPattern1=self.otaServerDict[self.checkTupe][0]+"="+self.otaServerDict[self.checkTupe][1]
        with open(self.suyingmk,"r") as f1:
            ret1=f1.read()
            if checkPattern1 not in ret1:
                log.error("****Error:{} not in suying.mk:Error****".format(checkPattern1))
                return False
            else:
                log.info("{} in suying.mk".format(checkPattern1))
        return True
		
    def checkrkHost(self):
        checkPattern2=self.rkHostDict[self.checkTupe][0]+"="+self.rkHostDict[self.checkTupe][1]
        with open(self.suyingmk,"r") as f1:
            ret1=f1.read()
            if checkPattern2 not in ret1:
                log.error("****Error:{} not in suying.mk:Error****".format(checkPattern2))
                return False
            else:
                log.info("{} in suying.mk".format(checkPattern2))
        return True
        
    @build_decorator						 
    def getResult(self):
        otaServerCheck_ret=True
        rkHostCheck_ret=True
        otaServerKeys=self.otaServerDict.keys()
        rkHostKeys=self.rkHostDict.keys()
 				
        if self.checkTupe in otaServerKeys:
            otaServerCheck_ret=self.checkOtaServer()
        log.info("otaServerCheck_ret=%s"%otaServerCheck_ret)

        if self.checkTupe in rkHostKeys:
            rkHostCheck_ret=self.checkrkHost()
        log.info("rkHostCheck_ret=%s"%rkHostCheck_ret)
				
        return otaServerCheck_ret and rkHostCheck_ret
           
 
class CheckOutput(CheckConfig):
    def __init__(self):
        super(CheckOutput,self).__init__()
        self.product=sys.argv[2]
        self.province=sys.argv[4]
        self.launcher=sys.argv[6]
        self.cehckItem=["ro.config.otaserver","ro.product.ota.host"]
        self.otaServer=""
        self.rkHost=""        
			 
    def checkOutput(self):
        log.info("cehck build.prop on {}".format(self.buildProp))
        flag=True
        with open(self.buildProp,"r") as f2:
            propRet=f2.read()
        with open(self.suyingmk,"r") as f1:
            ret1=f1.readlines()
            for checkX in self.cehckItem:
                for item in ret1:
                    if checkX in item:
                        checkItemX=item.strip().split(" ")[0]
                        if checkItemX in propRet:
                            log.info("{} in suying.mk and build.prop.".format(checkX))
                        else:
                            log.error("****Error:{} in suying.mk but not in build.prop.:Error****".format(checkX))
                            flag=False                            
        return flag
    @build_decorator		        				 
    def getResult(self):
        outPutCheck_ret=True
        outPutCheck_ret=self.checkOutput()				
        return outPutCheck_ret
		
class CheckMultipleBranch(object):
    def __init__(self):
        self.workspace=os.environ["HOME"]+"/workspace/"
        self.check_branch_list=[self.workspace+"frameworks/base/",self.workspace+"device/rockchip/rksdk/IPTV/"]
        self.master_branch="s010wa_zy_cu_sc"
		
    def check_cusc_brach(self):
        falg_total=True
        for dir in self.check_branch_list:
            flag=False
            os.chdir(dir)
            ret_list = os.popen("git branch").read().split("\n")
            log.info("Branch list = {}".format(str(ret_list)))
            for br in ret_list:
                if self.master_branch in br and "*" in br:
                    flag=True
                    log.info("Branch on {} is write.".format(dir))
                    break
            if flag == False:
                log.error("****Error:Branch on {} is not Correct.:Error****".format(dir))
                falg_total=False				
        return falg_total
		
		
class CheckNsbMaintenance():
    def __init__(self):
        self.home = os.environ['HOME']
        if len(sys.argv) > 0:
            self.province = sys.argv[4]
            self.launcher = sys.argv[6]
            if self.launcher == "nolauncher":
                self.apk_dir=os.environ["HOME"]+"/workspace/device/rockchip/rksdk/IPTV/IPTV_{}/".format(self.province)
                self.bin_dir=os.environ["HOME"]+"/workspace/device/rockchip/rksdk/IPTV/IPTV_{}/bin/".format(self.province)
            else:
                self.apk_dir=os.environ["HOME"]+"/workspace/device/rockchip/rksdk/IPTV/IPTV_{}_{}/".format(self.province,self.launcher)
                self.bin_dir=os.environ["HOME"]+"/workspace/device/rockchip/rksdk/IPTV/IPTV_{}_{}/bin/".format(self.province,self.launcher)
			

    def set_property(self,apk_dir,bin_dir):
        self.apk_dir=apk_dir
        self.bin_dir=bin_dir
							
    def check_nsbMaintenance(self):
        flag1=True
        flag2=False
        flag3=False
        check_apk="nsbMaintenance_Version1.2_20181016.apk"
        check_bin="initlogSrv.sh"
        old_item=["TcpdumpServ.sh","LogcatServ.sh","bootuplog.sh"]
        num=0
			
        apk_list=os.listdir(self.apk_dir)
        bin_list=os.listdir(self.bin_dir)
        os.chdir(self.bin_dir)

        for item in bin_list:
            if item in old_item:	             
                    num+=1
            if item == check_bin:
                flag3=True			
        if num >= 1:
            flag1=False
            log.error("****{} is in bin dir,please delete all old set!****".format(str(old_item)))
            log.error("****Please look https://coresvr2.ad4.ad.alcatel.com/svn/IP-STB/STBTools/trunk/Documents/Deploy/AmLogic/AmLogic_NSB自研功能集成指南.docx****")

        if not flag3:
            log.error("****{} not in bin dir,please recheck!****".format(check_bin))
            log.error("****Please look https://coresvr2.ad4.ad.alcatel.com/svn/IP-STB/STBTools/trunk/Documents/Deploy/AmLogic/AmLogic_NSB自研功能集成指南.docx****")			
	
        for item in apk_list:
            if item==check_apk:
                flag2=True
                log.warn("****{} is in apk dir ****".format(check_apk))
        if flag2==False:
                log.error("****{} is not in apk dir :Error****".format(check_apk))
                log.error("****Please look https://coresvr2.ad4.ad.alcatel.com/svn/IP-STB/STBTools/trunk/Documents/Deploy/AmLogic/AmLogic_NSB自研功能集成指南.docx****")
		
        return flag1 and flag2	and flag3	
		
    @build_decorator
    def getResult(self):
        check_nsbMaintenance_ret=True
        check_nsbMaintenance_ret= self.check_nsbMaintenance()
        log.warn("check_nsbMaintenance_ret=%s"%check_nsbMaintenance_ret)			
	
        return check_nsbMaintenance_ret
		
class Checkaml_normal():
    def __init__(self):
        partten1='(R\d.\d{2}).\d{2}.*'
        partten2='(\d.\d{2}).\d{2}.*'
        self.product=sys.argv[2]
        self.province=sys.argv[4]
        self.launcher=sys.argv[6]
        if len(sys.argv) > 7:
            self.versionstr=sys.argv[7]
            p=re.search(partten1,self.versionstr)
            if p:
                self.check_str=p.group(1)
            p2=re.search(partten2,self.versionstr)
            if p2:
                self.check_str=p2.group(1)
        self.mid_ver=int(self.versionstr.split(".")[1])
		
        if self.province[:2] == "cu":
            self.sysprop=os.environ["HOME"]+"/workspace/device/amlogic/p201_iptv/system_chinaunicom.prop"
        elif self.province[:2] == "ct":
            if self.province=="cthq":
                self.sysprop=os.environ["HOME"]+"/workspace/device/amlogic/p201_iptv/system_chinatelecom_jicai_sy.prop"
            else:
                self.sysprop=os.environ["HOME"]+"/workspace/device/amlogic/p201_iptv/system_chinatelecom.prop"
        elif self.province[:2] == "cm":
            self.sysprop=os.environ["HOME"]+"/workspace/device/amlogic/p201_iptv/system_chinamobile.prop"
        elif self.province[:2] == "ba" or self.province[:2] == "os":
            pass
        else:
            log.error("****Error:province is not correct!:Error****")
        self.branch_config=os.environ["HOME"]+"/amlbuild/branchCheck.ini"
        self.workspace=os.environ["HOME"]+"/workspace/"
        self.mkDict={
             "cu":"unicom_",
             "ct":"telecom_",
             "cm":"mobile_",
             "ba":"none" 			 
        }
        self.carrierDict={
            "cu":"ChinaUnicom_apks",
            "ct":"ChinaTelecom_apks",
            "cm":"ChinaMobile_apks",
            "ba":"none"
        }
        if self.province == "ctjc" or self.province == "cthq":
             self.mk="telecom.mk"
             self.flag0=1
        elif self.province == "cujc":
             self.mk="unicom.mk"
             self.flag0=2
        elif self.province == "cmsh":
             self.mk="mobile.mk"
             self.flag0=3
        else:
            self.mk=self.mkDict[self.province[:2]]+self.province[2:]+".mk" 
            if self.mkDict[self.province[:2]]=="telecom_":
                self.flag0=1
            elif self.mkDict[self.province[:2]]=="unicom_":	
                self.flag0=2
            elif  self.mkDict[self.province[:2]]=="mobile_":		
                self.flag0=3
			
        if self.launcher != "nolauncher":
            if  self.province == "cmsh":
                self.apk_dir = os.environ["HOME"]+"/workspace/device/amlogic/common/{}/sh/".format(self.carrierDict[self.province[:2]])
            elif self.province == "cujc":
                self.apk_dir = os.environ["HOME"]+"/workspace/device/amlogic/common/{}/BJ_jicai_apks/SY/".format(self.carrierDict[self.province[:2]])  
            else:
                self.apk_dir = os.environ["HOME"]+"/workspace/device/amlogic/common/{}/{}_apks/{}/".format(self.carrierDict[self.province[:2]],self.province[2:].upper(),self.launcher)
        else:
            if self.province == "ctjc":
                self.apk_dir = os.environ["HOME"]+"/workspace/device/amlogic/common/{}/SH_jicai_apks/SY/sy_apk/".format(self.carrierDict[self.province[:2]])
            elif self.province == "cthq":
                self.apk_dir = os.environ["HOME"]+"/workspace/device/amlogic/common/{}/SH_jicai_apks/SY_FusionGateway/sy_apk/".format(self.carrierDict[self.province[:2]])          	
            else:
                self.apk_dir = os.environ["HOME"]+"/workspace/device/amlogic/common/{}/{}_apks/".format(self.carrierDict[self.province[:2]],self.province[2:].upper())
        self.mk_dir=os.environ["HOME"]+"/workspace/device/amlogic/common/"

    def checkaml_tcpdump_adbdz(self):
        flag1=True
        flag3=False
        db_verson=sys.argv[6]
        mk_dir=os.environ["HOME"]+"/workspace/device/amlogic/common/"
        if self.province == "cthq":
            os.chdir(self.apk_dir+"../")
        else:
            os.chdir(self.apk_dir)
        items = os.listdir(".")
        if "tcpdump" not in items:
            log.error("****Error:Missing tcpdump in {},please get the tcpdump at https://coresvr2.ad4.ad.alcatel.com/svn/IP-STB/STBTools/Package/CommonRelease_s905l/tcpdump :Error****".format(self.apk_dir))
            flag1=False
        else: 
            md5_tcpdump=os.popen("md5sum {}".format(self.apk_dir+"tcpdump")).read().split(" ")[0]
            if not md5_tcpdump == "8CF5937940DC865CB54B6AB2F03B5C4C".lower():
                log.error("****Error:Incorrect Md5 of tcpdump in {}\n,please get the tcpdump at\n https://coresvr2.ad4.ad.alcatel.com/svn/IP-STB/STBTools/Package/CommonRelease_s905l/tcpdump :Error****".format(self.mk_dir))
                flag1=False
            else:
#                filename="{}{}.mk".format(self.mkDict[self.province[:2]],self.province[2:])
                filename=self.mk
                with open(mk_dir+filename,'r') as f:
                    str=self.apk_dir.split("/",4)[4]+"tcpdump:system/bin/tcpdump \\"
                    log.warn("str={}".format(str))
                    for line in f.readlines():
                        if str in line:
                            flag3=True
                            
                if not flag3:
                    log.error("****Error: No Integrate tcpdump in {} :Error****".format(filename))
                        

        return flag1 and flag3

    def check_AmlOnSiteUpgrade(self):
        flag1=True
        flag2=False
        flag3=False
        apk_list=[]
        num=0
        check_apk="OnSiteUpgradeForJD_20180615.apk"
        os.chdir(self.apk_dir)
        ret=os.listdir(".")
        for item in ret:
            if os.path.splitext(item)[1] == '.apk':
                apk_list.append(item)
        if check_apk not in apk_list:
            log.error("****Error:There is no {} in {},please recheck!!:Error****".format(check_apk,self.apk_dir))
            log.warn("****Warn:{} on 'https://coresvr2.ad4.ad.alcatel.com/svn/IP-STB/STBTools/trunk/Documents/Deploy/AmLogic/VONT_LanUp/OnSiteUpgradeForJD/':Warn****".format(check_apk))
            flag1=False	
        else:
            log.warn("{} in {}".format(check_apk,self.apk_dir))			
			
        with open(self.sysprop,"r") as f:
            for line in f.readlines():
                if "ro.config.nsbotaserver=" in line:
                    num+=1
            if num > 1:
                log.error("****Error: ro.config.nsbotaserver is in {} But he has at least 2:Error****".format(self.sysprop))
                return 	flag1 and flag2	 
            f.seek(0,os.SEEK_SET)
            ret =f.read()				
            if (self.product,self.province,self.launcher) in nsbotaServerDict.keys():
                checkvalues=nsbotaServerDict[self.product,self.province,self.launcher]
                if checkvalues[0]+"="+checkvalues[1] in ret:
                    flag2=True
                    log.warn("ro.config.nsbotaserver is in {}".format(self.sysprop))
                else:
                    log.error("****Error: ro.config.nsbotaserver in {} is not correct!:Error****".format(self.sysprop))
            else:
                 if "ro.config.nsbotaserver=http://140.207.1.82:8082/upgrade.ini" in ret:
                     flag2=True
                     log.warn("ro.config.nsbotaserver is default")
                 else:
                     log.error("Error: ro.config.nsbotaserver in {} is not correct!:Error****".format(self.sysprop))
                     log.error("Error: please set 'ro.config.nsbotaserver=http://140.207.1.82:8082/upgrade.ini' as default:Error****")

        os.chdir(self.mk_dir)
        with open(self.mk,"r") as f2:
            ret2=f2.read()
            if "system/app/{}".format(check_apk) not in ret2:
                log.error("Error: {} is not in {} :Error****".format(check_apk,self.mk))
            else:
                flag3=True
                log.info("{}  in {}".format(check_apk,self.mk))			
        return 	flag1 and flag2	and flag3
		
    def check_cpe_version(self):
        cpe_dir=os.environ["HOME"]+"/workspace/device/amlogic/common/ChinaMobile_apks/sh/tr069/"
        os.chdir(cpe_dir)
        parn="cpe_version="+self.versionstr+"\n"
        num=0
        flag=False
        with open("cwmp.conf","r") as f:
            retlist=f.readlines()
            for item in retlist:
                if "cpe_version" in item:
                    num=num+1
                if parn == item.replace(" ",""):
                    flag=True
                    log.warn("{} in cwmp.conf.".format(parn))
        if num > 1:
            log.error("****Error:More than one cpe_version in cwmp.conf,please recheck.:Error****")
            return False
        else:
            if flag == False:
                log.error("****Error:cpe_version is not {},please recheck.:Error****".format(parn[:-1]))
                return False
        return True
        			
 
    def check_gaoanset(self):
        flag1=False
        flag2=False
        iptv_dir=os.environ["HOME"]+"/workspace/device/amlogic/p201_iptv/"
        parn1="BUILD_WITH_DM_VERITY:=true\n"
        parn2="TARGET_USE_SECURITY_MODE:=true\n"
        os.chdir(iptv_dir)
        with open("p201_iptv.mk","r") as f:
            retlist=f.readlines()
            for item in retlist:
                check_item=item.replace(" ","")
                if parn1 in check_item and "#" not in check_item:
                    flag1=True
                    log.warn("{} in p201_iptv.mk.".format(parn1[:-1]))
                elif parn2 in check_item and "#" not in check_item:
                    flag2=True
                    log.warn("{} in p201_iptv.mk.".format(parn2[:-1]))

        flag_in1=flag1 or flag2
        flag_in2=flag1 and flag2		
        if self.launcher == "nolauncher" and flag_in1:
            log.error("****Error:You launcher is nolauncher but {} or {} in p201_iptv.mk,please recheck!:Error****".format(parn1[:-1],parn2[:-1]))
            return False
        elif self.launcher == "gaoan" and not flag_in2:
            log.error("****Error:You launcher is gaoan but {} and {} not in p201_iptv.mk,please recheck!:Error****".format(parn1[:-1],parn2[:-1]))
            return False
        log.warn("Your set is Correct!")
        return True


		
    def check_dhcp_pppoe_set(self):
        count1=0
        count2=0
        flag1=False
        flag2=False
        pattern1="net.dhcp.repeat.count=13"
        pattern2="net.ppp.retrycount=4"
        with open(self.sysprop,"r") as f:
            retlist=f.readlines()
            for item in retlist:
                retstr=item.replace(" ","")
                if pattern1[:-2] in retstr:
                    count1=count1+1
                elif pattern2[:-1] in retstr:
                    count2=count2+1
        if count1 == 0:
            log.error("****Error:{} not in {},please recheck!:Error****".format(pattern1,self.sysprop))
            flag1=False
        elif count1 == 1:
            with open(self.sysprop,"r") as f2:
                retstr2=f2.read().replace(" ","")
                if pattern1 in retstr2:
                    log.warn("{} in {}!".format(pattern1,self.sysprop))
                    flag1=True
                else:
                    log.error("****Error:{} set in {} not Correct,please set it '{}'!:Error****".format(pattern1[:-3],self.sysprop,pattern1))
                    flag1=False
        elif count1 > 1:
            log.error("****Error:More then one {} in {},please recheck!:Error****".format(pattern1[:-3],self.sysprop))
					
        if count2 == 0:
            #log.error("****Error:{} not in {},please recheck!:Error****".format(pattern2,self.sysprop))
            flag2=False
        elif count2 == 1:
            with open(self.sysprop,"r") as f3:
                retstr3=f3.read().replace(" ","")
                if pattern2 in retstr3:
                    #log.warn("{} in {}!".format(pattern2,self.sysprop))
                    flag2=True
                else:
                    #log.error("****Error:{} set in {} not Correct,please set it '{}'!:Error****".format(pattern2[:-2],self.sysprop,pattern2))
                    flag2=False
        elif count2 > 1:
            pass
            #log.error("****Error:More then one {} in {},please recheck!:Error****".format(pattern2[:-2],self.sysprop))

        return flag1 and True



    def check_only(self):
        error_branch=[]
        for key,value in self.check_list:
            flag=False
            if key[0] != "/":
                key="/" + key
            elif key[-1] != "/":
                key=key+"/"
            check_dir=self.workspace[:-1]+key
            os.chdir(check_dir)
            branchList = os.popen("git branch").read().split("\n")
            for br in branchList:
                if "* " +value == br:
                    log.warn("The branch of '{}' is Correct.".format(key))
                    flag=True
                    break
            if not flag:
                error_branch.append(key)
        if len(error_branch) == 0:
            log.warn("All branch are Correct!")
            return True
        else:
            log.error("The following dir branch is not Correct:")
            log.error(str(error_branch))
            return False

    def check_branch(self):   
        conf=myconf()
        conf.read(self.branch_config)
        secs=conf.sections()

        if conf.has_section(self.check_str):
            log.warn('Will check branch')
            self.check_list=conf.items(self.check_str)
        else:
            log.warn('You have not config {},Do not check branch!'.format(self.branch_config))
            
        ret=self.check_only()
        return ret


    def CheckAmlNsbMaintenance(self):
        cnm=CheckNsbMaintenance()
        cnm.set_property(self.apk_dir,self.apk_dir)
        return cnm.getResult()
		
    def check_adb_encryption(self):
        check_list=["adblock_20180808.apk","DispatchService_20180927.apk","libadblock.so","nsbAmlAdb_20180928.apk","nsbipconfig.sh"]
        os.chdir(self.apk_dir)
        all_list=os.listdir(".")
        log.warn("all_list={}".format(str(all_list)))
        if set(check_list).issubset(set(all_list)):
            log.warn("Adb encryption is Correct!")
            return True
        else:
            log.error("Adb encryption integration is not Correct,Please recheck!")
            log.error("Please look this document:https://coresvr2.ad4.ad.alcatel.com/svn/IP-STB/STBTools/trunk/Documents/Deploy/AmLogic/AmLogic_NSB自研功能集成指南.docx!")
            return False

    def check_property_detail(self,fi): 
        flag=True
        file=fi
        property_list=["persist.sys.iptvexpiration=NULL"]
        with open(file,'r') as f:
            reststr=f.read().replace(' ','')
            for pro in property_list:
                if pro not in reststr:
                    log.error("{} not in {},please recheck!".format(pro,file))
                    flag=False
        return flag
	
    			
    def check_property(self):
        flag=True
        file_list=[self.sysprop]
        for fi in file_list:
            ret=self.check_property_detail(fi)
            if not ret:
                flag=False
        return flag
			
    @build_decorator           	
    def getResult(self):
        AmlNsbMaintenance_ret=True
        cpe_version_ret=True
        gaoanset_ret=True
        check_td=True
        check_logoutSet_ret=True
        amlOnSiteUpgrade_ret=True
        branch_check_ret=True
        check_property_ret=True
        adb_encryption_ret=True
        check_list=["ctjc","cmsh","cujc","cthq"]

        if self.province not in check_list:		
            AmlNsbMaintenance_ret=self.CheckAmlNsbMaintenance()
            log.warn("AmlNsbMaintenance_ret=%s"%AmlNsbMaintenance_ret)
			
            amlOnSiteUpgrade_ret=self.check_AmlOnSiteUpgrade()
            log.warn("amlOnSiteUpgrade_ret=%s"%amlOnSiteUpgrade_ret)
			
            adb_encryption_ret=self.check_adb_encryption()
            log.warn("adb_encryption_ret=%s"%adb_encryption_ret) 
			
        if self.product == "S-010W-AV2A" and self.province == "cmsh":		
            cpe_version_ret=self.check_cpe_version()
            log.warn("cpe_version_ret=%s"%cpe_version_ret)
					
        check_dhcp_pppoe_ret=self.check_dhcp_pppoe_set()
        log.warn("check_dhcp_pppoe_ret=%s"%check_dhcp_pppoe_ret)
		
        check_property_ret=self.check_property()
        log.warn("check_property_ret=%s"%check_property_ret)
			
        if (self.product == "S-010W-AV2A" and self.province == "ctjc") or (self.product == "RG020ET-CA" and self.province == "cthq"):		
            gaoanset_ret=self.check_gaoanset()
            log.warn("gaoanset_ret=%s"%gaoanset_ret)
			
        ret_1=amlOnSiteUpgrade_ret and cpe_version_ret and gaoanset_ret and adb_encryption_ret and AmlNsbMaintenance_ret
        log.warn("ret_1={}".format(ret_1))

        if int(self.versionstr.split(".")[1]) > 0:
            #check_logoutSet_ret=self.check_logoutSet()
            check_logoutSet_ret=True
            log.warn("check_logoutSet_ret=%s"%check_logoutSet_ret)
        if self.province not in check_list:
            check_td=self.checkaml_tcpdump_adbdz()
            log.warn("check_td=%s"%check_td)

        if os.path.exists(self.branch_config):
            branch_check_ret=self.check_branch()
            log.warn("branch_check_ret=%s" % branch_check_ret)
			
        ret_2=check_logoutSet_ret and check_td and branch_check_ret
        log.warn("ret_2={}".format(ret_2))
		
        return ret_1 and ret_2
			
	  
		
class ChecknormalInput():
    def __init__(self):
        self.flag=False
        self.home = os.environ['HOME']
        self.chiptype = sys.argv[3]
        self.province = sys.argv[4]
        self.product = sys.argv[2]
        self.launcher=sys.argv[6]
        self.imgtool=""
        self.suyingdir=""
        self.rk3228mk=""
        self.systempropdir=""
        self.paramFile=""
        self.kernelDir=""
        self.rksdkDir=""
        self.checkItemDict={
            ("S-010W-A","cusd"):("persist.local.support.dolby=false","persist.net.support.dolby=true"),
            ("S-010W-A","cusc"):("persist.local.support.dolby=false","persist.net.support.dolby=false"),
            ("S-010W-AV2B","cusc"):("persist.local.support.dolby=false","persist.net.support.dolby=false"),
            ("G-120WT-P","ctln"):("persist.local.support.dolby=false","persist.net.support.dolby=true"),
            ("G-120WT-P","ctxj"):("persist.local.support.dolby=false","persist.net.support.dolby=true"),
            ("G-120WT-P","ctgx"):("persist.local.support.dolby=true","persist.net.support.dolby=true"),
            ("G-120WT-P","ctsx"):("persist.local.support.dolby=false","persist.net.support.dolby=true"),
            ("G-120WT-P","cthn"):("persist.local.support.dolby=false","persist.net.support.dolby=false"),
            ("S-010W-AV2B","cusd"):("persist.local.support.dolby=false","persist.net.support.dolby=true"),
            ("S-010W-A","cubj"):("persist.local.support.dolby=false","persist.net.support.dolby=true"),
            ("S-010W-AV2B","cubj"):("persist.local.support.dolby=false","persist.net.support.dolby=true"),
            ("S-010W-AVQD","cuqd"):("persist.local.support.dolby=true","persist.net.support.dolby=true"),
            ("S-010W-AV2B","cuhn"):("persist.local.support.dolby=false","persist.net.support.dolby=true"),
            ("S-010W-AV2S","cutj"):("persist.local.support.dolby=true","persist.net.support.dolby=true"),			
        }

    def getDir(self):
        self.imgtool = self.home + "/build/RKTools/imgmake_tool/AndroidTool_Release_v2.31/rockdev/Image/" + "../"
        if self.launcher == "nolauncher":
            self.suyingdir=self.home+"/workspace/device/rockchip/rksdk/IPTV/IPTV_%s"%self.province
            self.suyingmk=os.environ["HOME"]+"/workspace/device/rockchip/rksdk/IPTV/IPTV_{}/suying.mk".format(self.province)
        else:
            self.suyingdir=os.environ["HOME"]+"/workspace/device/rockchip/rksdk/IPTV/IPTV_{}_{}".format(self.province,self.launcher)
            self.suyingmk=os.environ["HOME"]+"/workspace/device/rockchip/rksdk/IPTV/IPTV_{}_{}/suying.mk".format(self.province,self.launcher)

        self.kernelDir=self.home + "/workspace/kernel/"
        self.rksdkDir=self.home + "/workspace/device/rockchip/rksdk/"

        if self.chiptype == "RK3228B":
            self.rk3228mk = self.home + "/workspace/device/rockchip/rk3228/rk3228.mk"
            self.systempropdir = self.home + "/workspace/device/rockchip/rk3228/"
            if self.province == "base":
                self.paramFile = self.imgtool + "parameter-rk3228-iptv.factory"
            else:
                self.paramFile = self.imgtool + "parameter-rk3228-iptv.normal"
        elif self.chiptype == "RK3228H":
            self.rk3228mk = self.home + "/workspace/device/rockchip/rk3228h/rk3228h.mk"
            self.systempropdir = self.home + "/workspace/device/rockchip/rk3228h/"
            if self.province == "base":
                self.paramFile = self.imgtool + "parameter-rk3228h-iptv.factory"
            else:
                self.paramFile = self.imgtool + "parameter-rk3228h-iptv.normal"

        log.info("rk3228mk="+self.rk3228mk)
        log.info("kernelDir="+self.kernelDir)
        log.info("rksdkDir="+self.rksdkDir)
        log.info("paramFile="+self.paramFile)
		
    def checkProductMode(self):
        product_mode=""
        os.popen("dos2unix %s" % self.paramFile)
        os.popen("dos2unix %s" % self.rk3228mk)

        f1 = open(self.paramFile)
        list1 = f1.readlines()
        for line1 in list1:
            if "MACHINE_MODEL" in line1:
                machine_mode = line1.split(":")[1].strip()

        f2 = open(self.rk3228mk)
        list2 = f2.readlines()
        for line2 in list2:
            if "PRODUCT_MODEL" in line2:
                product_mode = line2.split("=")[1].strip()

        if machine_mode == product_mode:
            log.info("product mode is Correct!!!")
            return True
        else:
            log.error("****Error:product mode is not Correct,please check parameter file!!!:Error****")
            return False

    def checkFlashRelevant(self):
        os.chdir(self.suyingdir)
        os.popen("dos2unix suying.mk")
        flag1=False
        flag2=False
        if self.launcher == "nolauncher":
            pattern1="device/rockchip/rksdk/IPTV/IPTV_{}/bin/iostat:system/bin/iostat".format(self.province)
            pattern2="device/rockchip/rksdk/IPTV/IPTV_{}/bin/mmc_utils:system/bin/mmc_utils".format(self.province)
        else:
            pattern1="device/rockchip/rksdk/IPTV/IPTV_{}_{}/bin/iostat:system/bin/iostat".format(self.province,self.launcher)
            pattern2="device/rockchip/rksdk/IPTV/IPTV_{}_{}/bin/mmc_utils:system/bin/mmc_utils".format(self.province,self.launcher)
        with open('suying.mk','r') as foo:
            for line in foo.readlines():
                if pattern1 in line and "#" not in line:
                    log.info(pattern1 + " is in suying.mk")
                    flag1=True
                if pattern1 in line and "#" not in line:
                    log.info(pattern2 + " is in suying.mk")
                    flag2=True
        if flag1 == True and flag2 == True:
            return True
        else:
            log.error("****Error:iostat or mmc_utils is not in suying.mk.please recheck!!!:Error****")
            return False

    def checkHardwareId(self):
        os.chdir(self.systempropdir)
        flag=False
        os.popen("git checkout -- system.prop")
        os.popen("dos2unix system.prop")		
        pattern="ro.build.hardware.id"
        with open('system.prop','r') as foo:
            lines=foo.readlines() 
        with open('system.prop','w') as foo:
            for line in lines:
                if pattern in line:
                    flag=True				
                    continue
                foo.writelines(line)
        if flag == True:
            os.popen("git add system.prop")
            os.popen("git commit -m 'delete ro.build.hardware.id in system.prop'")
            log.info("Have delete ro.build.hardware.id in system.prop")
            return True
        elif flag == False:
            log.info("ro.build.hardware.id is not in system.prop,Nothing to do")
            return True
    def checkCommit(self):
        commitdir=self.home+"/workspace/system/core/"
        os.chdir(commitdir) 
        p = os.popen('git log -20')
        retstr=p.read()
        if "syste_core: self-adaptation of flash size; device_rockchip_rk3228: remove ro.product.flash.info in system.prop;" in retstr:
            log.info("The manifast.xml has been synchronized and the mac and stbid issues have been resolved")    
            return True
        else:
            log.error("****Error:The need to synchronize manifast.xml, to solve the problem of mac and stbid:Error****")
        return False
      
    def getString1(self,_item):
        content=_item
        count=0
        subjectList=["Add","extra","(size_t)","cast","to avoid compiler warning."]
        for item in subjectList:
            if item in content:
                count=count+1
        return count/len(subjectList)

    def checkDNSmasq1(self):
        commitdir=self.home+"/workspace/external/dnsmasq/src/"
        os.chdir(commitdir) 
        logList = os.popen("git log -1000").read().split("commit")
        flag1 = False
        for item in logList:
            string1=self.getString1(item)
            if string1 > 0.7 and "Revert" in item:
                flag1=False
                log.error("****Error:please play dnsmasq patch1':Error****")
                log.info("****patch location:E:\SVN_work\STBTools\trunk\common\RKInput\DNSMasq****")				
                break
            elif string1 > 0.7 and "Revert" not in item:
                flag1=True
                log.info("already add dnsmasq patch1")
        if not flag1:
            log.error("****Error:please play dnsmasq patch1':Error****")
            log.info("****patch location:E:\SVN_work\STBTools\trunk\common\RKInput\DNSMasq****")			
        return flag1

    def getString2(self,_item):
        content=_item
        count=0
        subjectList=["Make","dnsmasq","more","stable"]
        for item in subjectList:
            if item in content:
                count=count+1
        return count/len(subjectList)
    def checkDNSmasq2(self):
        commitdir=self.home+"/workspace/external/dnsmasq/src/"
        os.chdir(commitdir) 
        logList = os.popen("git log -1000").read().split("commit")
        flag1 = False
        for item in logList:
            string1=self.getString2(item)
            if string1 > 0.7 and "Revert" in item:
                flag1=False
                log.error("****Error:please play dnsmasq patch2':Error****")
                log.info("****patch location:E:\SVN_work\STBTools\trunk\common\RKInput\DNSMasq****")				
                break
            elif string1 > 0.7 and "Revert" not in item:
                flag1=True
                log.info("already add dnsmasq patch2")
        if not flag1:
            log.error("****Error:please play dnsmasq patch2':Error****")
            log.info("****patch location:E:\SVN_work\STBTools\trunk\common\RKInput\DNSMasq****")			
        return flag1


    def checkdeviceinfo(self):
           fo = open(self.home+"/build/RKTools/imgmake_tool/AndroidTool_Release_v2.31/rockdev/package-file.normal","r")
           line = fo.read()
           if "#deviceinfo" in line:
                 log.info("deviceinfo has been commented")
                 return True
           else: 
                 log.error("****Error:Please comment deviceinfo or add deviceinfo  Error****")
                 return False  
    def checkcpugpu(self):
	    
        cpugpudir=self.home+"/workspace/device/rockchip/rk3228h/"
        os.chdir(cpugpudir)       
        flag=False
        productList = ["S-010W-AV2B","S-010W-AV2","S-010W-AV2S","G-120WT-Q","G-120WT-R","S-010W-AQD","S-010W-AV2C","S-010W-AV2E"]
        par=[("S-010W-A","cusc")]
        cpu = "ro.product.cpu.info=4cores2GHz\n"
        gpu = "ro.product.gpu.info=Mali450\n"
        
        os.popen("git checkout system.prop")
        fo = open(self.home+"/workspace/device/rockchip/rk3228h/system.prop","ra+")
        line = fo.read()
        
        if self.product in productList or (self.product,self.province) in par:
           if "ro.product.cpu.info" not in line:
               fo.writelines(cpu)
               flag=True
           if "ro.product.gpu.info" not in line:
               fo.writelines(gpu)
               flag=True
        fo.close()  
        if flag == True:
            os.popen("git add system.prop")
            os.popen("git commit -m 'add gpuinfo in system.prop'")
    def checkLogoBmp(self):
        os.chdir(self.kernelDir)
        flag=False
        if os.path.isfile("logo.bmp") == True:
             os.popen("rm logo.bmp")
             if  "logo.bmp" in  os.popen("git status").read():
                 os.popen("git commit -am 'delete logo.bmp'")
        log.info("Have delete logo.bmp in kernel folder")
		   
        os.chdir(self.rksdkDir)
        #os.popen("git checkout BoardConfig.mk")
        os.popen("dos2unix BoardConfig.mk")
        pattern="kernel/logo.bmp"
        with open('BoardConfig.mk','r') as foo:
            lines=foo.readlines() 
        with open('BoardConfig.mk','w') as foo:
            for line in lines:
                if pattern in line:
                    flag=True				
                    continue
                foo.writelines(line)
        if flag == True:
            #os.popen("git add BoardConfig.mk")
            #os.popen("git commit -m 'delete logo.bmp in BoardConfig.mk'")
            log.info("Have delete %s in BoardConfig.mk"%pattern)
            return True
        elif flag == False:
            log.info("%s is not in BoardConfig.mk,Nothing to do"%pattern)
            return True         
   
    def checkDolby(self):	
        rkapkFolder=os.environ["HOME"]+"/workspace/device/rockchip/common/app/"
        patch1Dir=os.environ["HOME"]+"/workspace/frameworks/av/"
        patch2Dir=os.environ["HOME"]+"/workspace/system/core/"
        so_1=os.environ["HOME"]+"/workspace/device/rockchip/rksdk/IPTV/lib/libCTC_MediaProcessor.so"
        if self.chiptype == "RK3228H":
            so_2=os.environ["HOME"]+"/workspace/device/rockchip/common/vpu/lib3228hspec/libffmpeg.so"
            so_3=os.environ["HOME"]+"/workspace/device/rockchip/common/vpu/lib3228hspec/librkffplayer.so"
        elif self.chiptype == "RK3228B":
            so_2=os.environ["HOME"]+"/workspace/device/rockchip/common/vpu/lib/libffmpeg.so"
            so_3=os.environ["HOME"]+"/workspace/device/rockchip/common/vpu/lib/librkffplayer.so"
        rkapkList=[]
        newRkapkList=[]
        suyingList=[]
        flag=False
        flag1=False
        flag2=True
        flag3=False
        flag4=False
        flag5=True
        parten1="/apk/RKMediaCenter/libmediacenter-jni.so:system/lib/libmediacenter-jni.so"
        parten2="/apk/RKMediaCenter/libmedia.so:system/lib/libmedia.so"
        parten3="/apk/RKMediaCenter/libmediaplayerservice.so:system/lib/libmediaplayerservice.so"
        os.chdir(rkapkFolder)
        os.popen("git checkout -- rkapk.mk")
        if self.chiptype == "RK3228H":            
            if self.province == "cubj" or self.province == "cusd" or self.province == "cujx":
                flag=True
                pass
            else:
                with open("rkapk.mk","r") as f:
                    rkapkList=f.readlines()
                for item in rkapkList:
                    if parten1 in item and "#" not in item:
                        flag=True					
                    if parten2 in item or parten3 in item:
                        pass
                    else:
                        newRkapkList.append(item)
                with open("rkapk.mk","w") as f2:
                    f2.writelines(newRkapkList)
            if not flag:
                log.error("****Error:libmediacenter-jni.so not in rkapk.mk.:Error****")
            os.popen("git add rkapk.mk")
            os.popen("git commit -m 'Delete libs about dolby'")
            log.info("Have delete libs about dolby in rkapk.mk")
        else:
            flag=True
		
        os.chdir(self.suyingdir)
        with open("suying.mk","r") as f3:
            suyingList=f3.readlines()
        for item in suyingList:
            if "ro.product.support.dolby=true" in item:
                log.info("ro.product.support.dolby=true in suing.mk")
                flag1=True
        if not flag1:
            log.error("****Error:ro.product.support.dolby=true is not in suing.mk,please add it!:Error****")

        os.chdir(self.suyingdir)
        with open("suying.mk","r") as f4:
            suyingContent=f4.read()
        for item in self.checkItemDict[(self.product,self.province)]:
            if item not in suyingContent:
                log.error("****Error:%s not in suing.mk,please add it!:Error****"%item)
                flag2=False
        if flag2==True:
            log.info("%s in suing.mk"%str(self.checkItemDict[(self.product,self.province)]))
        
        os.chdir(patch1Dir)
        log1Ret=os.popen("git log").read()
        log1List=log1Ret.split("commit")
        for item in log1List:
            if "3228_d_switch_frameworks_av" in item:
               flag3=True
        if not flag3:
            log.error("****Error:0001-3228_d_switch_frameworks_av.patch hava not play:Error****")
			
        os.chdir(patch2Dir)
        log2Ret=os.popen("git log").read()
        log2List=log2Ret.split("commit")
        for item in log2List:
            if "3228_d_switch_system_core" in item:
                flag4=True
        if not flag4:
            log.error("****Error:0001-3228_d_switch_system_core.patch hava not play:Error****")
			
        md5_1=os.popen("md5sum {}".format(so_1)).read().split("  ")[0]
        md5_2=os.popen("md5sum {}".format(so_2)).read().split("  ")[0]
        md5_3=os.popen("md5sum {}".format(so_3)).read().split("  ")[0]
        if md5_1 == "EA1DF62B5633603A5395B25CD58A7F5D".lower():
            flag5=False
            log.error("****Error:The Md5 of {} can not be {}:Error****".format(so_1,"EA1DF62B5633603A5395B25CD58A7F5D".lower()))
        if md5_2 == "EA9B3EDF9BB7BAAB0B3D9E57CC8A47F9".lower():
            flag5=False
            log.error("****Error:The Md5 of {} can not be {}:Error****".format(so_2,"EA9B3EDF9BB7BAAB0B3D9E57CC8A47F9".lower()))
        if md5_3 == "E6FA07413DBEEA13D4F31FE1DDBA6B45".lower():
            flag5=False
            log.error("****Error:The Md5 of {} can not be {}:Error****".format(so_3,"E6FA07413DBEEA13D4F31FE1DDBA6B45".lower()))
        if flag5 == True:
            log.info("So is Correct")
		
        return flag and flag1 and flag2 and flag3 and flag4 and flag5

    def check_parameter(self):
        correct_md5="0A125B486F4794404C00932F1D500D19"
        md5 = os.popen("md5sum {}".format(self.paramFile)).read().split("  ")[0]
        log.info("local:{}:{}".format(self.paramFile,md5))
        if correct_md5.lower() != md5:
            log.error("****Error:{} not Correct!!:Error****".format(self.paramFile))
            log.info("****:Please get parameter form:'https://coresvr2.ad4.ad.alcatel.com/svn/IP-STB/STBTools/trunk/Build/config/parameter/AV2S'!!:****")
            return False
        else:
            log.info("{} is Correct!!".format(self.paramFile))
            return True			
			
    def check_OnSiteUpgrade(self):
        flag1=True
        flag2=False
        apk_list=[]
        num=0
        self.checkTupe=(self.product.upper(),self.province.lower(),self.launcher.lower())
        self.nsbotaServerKeys=nsbotaServerDict.keys()    
        product_ret=self.product
        province_ret=self.province
        launcher_ret=self.launcher
        self.checkvalues=nsbotaServerDict.get((product_ret,province_ret,launcher_ret))
        check_apk="OnSiteUpgrade_20181025.apk"
        os.chdir(self.suyingdir)
        ret=os.listdir(".")
        for item in ret:
            if os.path.splitext(item)[1] == '.apk':
                apk_list.append(item)
        if check_apk not in apk_list:
            log.error("****Error:There is no {},please recheck!!:Error****".format(check_apk))
            log.warn("****Warn:{} on 'https://coresvr2.ad4.ad.alcatel.com/svn/IP-STB/STBTools/trunk/Documents/Deploy/Rockchip/Common/NsbUpgradeApk':Warn****".format(check_apk))
            flag1=False	
        else:
            log.warn("{} in {}".format(check_apk,self.suyingdir))			
			
        with open("suying.mk","r") as f:
            for line in f.readlines():
                if "ro.config.nsbotaserver=" in line:
                    num+=1
            if num > 1:
                log.error("****Error: ro.config.nsbotaserver is in suying.mk But he has at least 2:Error****")

                return 	flag1 and flag2	 
            f.seek(0, os.SEEK_SET)
            ret =f.read()				
            if (product_ret,province_ret,launcher_ret) in self.nsbotaServerKeys:
                if self.checkvalues[0]+"="+self.checkvalues[1] in ret:
                    flag2=True
                    log.warn("ro.config.nsbotaserver is in suying.mk")
                else:
                    log.error("****Error: ro.config.nsbotaserver is in suying.mk but it is error:Error****")
            else:
                 if "ro.config.nsbotaserver=http://140.207.1.82:8082/upgrade.ini" in ret:
                     flag2=True
                     log.warn("ro.config.nsbotaserver is befault")
                 else:
                     log.error("Error: ro.config.nsbotaserver is not in suying.mk :Error****")
                     log.error("Error: Please set default:'ro.config.nsbotaserver=http://140.207.1.82:8082/upgrade.ini':Error****")
        return 	flag1 and flag2	
		
		
    def check_av2s_flash(self):
        flag1=True
        flag2=True
        pattern1="ro.product.flash.info=8G\n"
        pattern2="ro.product.flash.info=8G \\"
        with open(self.home+"/workspace/device/rockchip/rk3228h/system.prop","r") as f:
            ret = f.read()
            if pattern1 in ret:
                log.error("Please 'reset ro.product.flash.info=4G' in system.prop")
                flag1=False
            else:
                log.info("'ro.product.flash.info' is Correct in system.prop!")

        os.chdir(self.suyingdir)
        with open("suying.mk","r") as f2:
            ret2 = f2.read()
            if pattern2 in ret2:
                log.error("Please 'reset ro.product.flash.info=4G' in suying.mk")
                flag2=False
            else:
                log.info("'ro.product.flash.info' is Correct in suying.mk!")
        return flag1 and flag2				


    def check_adb_encryption(self):
        check_list=["adblock_20180808.apk","DispatchService_20180927.apk","libadblock.so"]
        os.chdir(self.suyingdir)
        apk_list=os.listdir(".")
        so_list=os.listdir("./libs/")
        all_list=apk_list+so_list
        log.warn("all_list={}".format(str(all_list)))
        if set(check_list).issubset(set(all_list)):
            log.warn("Adb encryption is Correct!")
            return True
        else:
            log.error("Adb encryption integration is not Correct,Please recheck!")
            log.error("Please look this document:https://coresvr2.ad4.ad.alcatel.com/svn/IP-STB/STBTools/trunk/Documents/Deploy/Rockchip/Rockchip_NSB自研功能集成指南 .docx!")
            return False

    def check_8189fs(self):
        check_path=self.home+"/workspace/device/rockchip/common/wifi/lib/modules/"
        check_md5="30534c4bc501c1a56196195c5505c707"
        os.chdir(check_path)
        cmd="md5sum 8189fs.ko"
        md5=os.popen(cmd).read()[:-1].split("  ")[0]
        log.warn(md5)
        if md5 == check_md5:
            log.warn("8189fs.ko is Correct!")
            return True
        else:
            log.error("8189fs.ko is not Correct!")
            log.error("Please use this:https://coresvr2.ad4.ad.alcatel.com/svn/IP-STB/STBTools/trunk/common/RKInput/8189fs/8189fs.ko")
            return False

    def check_property_detail(self,fi): 
        flag=True
        file=fi
        property_list=["persist.sys.iptvexpiration=NULL\\"]
        with open(file,'r') as f:
            reststr=f.read().replace(' ','')
            for pro in property_list:
                if pro not in reststr:
                    log.error("{} not in {},please recheck!".format(pro[:-1],file))
                    flag=False
        return flag
	
    			
    def check_property(self):
        flag=True
        file_list=[self.suyingmk]
        for fi in file_list:
            ret=self.check_property_detail(fi)
            if not ret:
                flag=False
        return flag
		
    @build_decorator		
    def getResult(self):
        self.getDir()
        check_conmmit=True
        adb_encryption_ret=True
        check_deviceinfo=True
        check_DNSmasq1=True
        check_DNSmasq2=True
        logobmp_ret=True
        parameter_ret=True
        checkDolby_ret=True
        flash_check_ret=True
        checkOnSiteUpgrade_ret=True
        check_8189fs_ret=True
        check_property_ret=True
        liblog_ret=True


        if self.province != "base":
            adb_encryption_ret=self.check_adb_encryption()
            log.warn("adb_encryption_ret=%s"%adb_encryption_ret)
           
            check_DNSmasq1=self.checkDNSmasq1()
            log.warn("check_DNSmasq1=%s"%check_DNSmasq1)

            check_DNSmasq2=self.checkDNSmasq2()
            log.warn("check_DNSmasq2=%s"%check_DNSmasq2)
			
            check_property_ret=self.check_property()
            log.warn("check_property_ret=%s"%check_property_ret)
			
            if self.product == "G-120WT-P":
                check_conmmit=self.checkCommit()
		   
            if (self.product,self.province) in self.checkItemDict.keys():
                checkDolby_ret=self.checkDolby()
                if not checkDolby_ret:
                    log.warn("****patch location:STBTools\trunk\common\RKInput\DolbyCheck****")
                log.warn("checkDolby_ret=%s"%checkDolby_ret)
				
            if self.product.lower() in ["s-010w-av2c","s-010w-av2b"]:
                check_8189fs_ret=self.check_8189fs()
                log.warn("check_8189fs_ret=%s"%check_8189fs_ret)
				
            check_deviceinfo=self.checkdeviceinfo()
            log.warn("check_deviceinfo=%s"%check_deviceinfo)
			
            checkOnSiteUpgrade_ret=self.check_OnSiteUpgrade()
            log.warn("checkOnSiteUpgrade_ret=%s"%checkOnSiteUpgrade_ret)

        if self.product == "S-010W-AV2S" and self.province != "cuha":	
            parameter_ret=self.check_parameter()
            log.warn("parameter_ret=%s"%parameter_ret)
			
            flash_check_ret=self.check_av2s_flash()
            log.warn("flash_check_ret=%s"%flash_check_ret)

        promode_ret=self.checkProductMode()
        log.info("promode_ret=%s"%promode_ret)
		
        flashRelevant_ret=self.checkFlashRelevant()
        log.warn("flashRelevant_ret=%s"%flashRelevant_ret)
				
        hardwareid_ret=self.checkHardwareId()
        log.warn("hardwareid_ret=%s"%hardwareid_ret)
			
        if self.chiptype == "RK3228H":			
            logobmp_ret=self.checkLogoBmp()
            self.checkcpugpu()
            log.warn("ro.product.cpu.info and ro.product.gpu.info is add")			
        elif self.chiptype == "RK3228B": 
            logobmp_ret = True 
        log.warn("logobmp_ret=%s"%logobmp_ret)

        if self.product == "S-010W-A" and self.chiptype == "RK3228H" and self.province == "cubj":
            check_so=self.suyingdir + "/libs/liblog.so"
            log.warn("check_so={}".format(check_so))
            if os.path.exists(check_so):
                liblog_ret=False
                log.error("Please delete {}".format(check_so))
		
		
        flag1 = checkOnSiteUpgrade_ret and promode_ret and flashRelevant_ret and hardwareid_ret and parameter_ret and logobmp_ret and check_conmmit
        flag2 = check_deviceinfo and checkDolby_ret and check_DNSmasq1 and check_DNSmasq2 and flash_check_ret and adb_encryption_ret and check_8189fs_ret
        flag3 = liblog_ret
        return flag1 and flag2 and flag3

class CheckFactoryImg(CheckMultipleBranch):
    def __init__(self):
        super(CheckFactoryImg,self).__init__()
        self.flag=False
        self.chiptype = sys.argv[3]
        self.product = sys.argv[2]
        self.province = sys.argv[4]
        self.launcher= sys.argv[6]
        self.reStr = ""
        self.child = ""
        self.command = ""
        self.remoteimg = ""
        self.remotemd5 = ""
        self.localimg = "~/build/RKTools/imgmake_tool/AndroidTool_Release_v2.31/rockdev/Image/factory.img"
        self.localmd5 = ""
        self.user = "factory_img"
        self.host = "172.24.170.194"
        self.password = "123456"
        log.warn("enter CheckFactoryImg")
        self.cmdDict = {
            "G-120WT-P": "md5sum /home/factory_img/G-120WT-P/img/*",
            "G-120WT-Q": "md5sum /home/factory_img/G-120WT-Q/img/*",
            "S-010W-A": "md5sum /home/factory_img/S-010W-A/img/*",
            "S-010W-AV2": "md5sum /home/factory_img/S-010W-AV2/img/*",
            "S-010W-AV2B": "md5sum /home/factory_img/S-010W-AV2B/img/*",
            "S-010W-AV2B-02": "md5sum /home/factory_img/S-010W-AV2B-02/img/*",
            "S-010W-A-CUBJ": "md5sum /home/factory_img/S-010W-A-CUBJ/img/*",
            "S-010W-AV2C": "md5sum /home/factory_img/S-010W-AV2C/img/*",
        }

    def ssh_command(self):
        if self.product == "S-010W-A" and self.launcher == "nolauncher" and self.province == "cubj":
            self.command = self.cmdDict["S-010W-A-CUBJ"]
        elif self.product == "S-010W-AV2B" and self.province == "cusd":
            self.command = self.cmdDict["S-010W-AV2B"]
        elif self.product == "S-010W-AV2B" and self.province == "cujx":
            self.command = self.cmdDict["S-010W-AV2B"]
        elif self.product == "S-010W-A" and self.chiptype == "RK3228H" and self.province == "cusc":
            self.command = self.cmdDict["S-010W-AV2B-02"]
        elif self.product == "S-010W-AV2B":
            self.command = self.cmdDict["S-010W-AV2B-02"]
        elif self.product == "S-010W-AQD" and self.chiptype == "RK3228H":
            self.command = self.cmdDict["S-010W-AV2B-02"]
        elif self.product == "S-010W-AV2S":
            self.command = self.cmdDict["S-010W-AV2B-02"]
        elif self.product == "S-010W-A" and self.launcher == "newline" and self.province == "cubj":
            self.command = self.cmdDict["S-010W-AV2B-02"]
        else:
            self.command = self.cmdDict[self.product]

        self.localmd5 = os.popen("md5sum %s" % self.localimg).readlines()[0].split("  ")[0]
        log.info("self.localmd5=" + self.localmd5)

        ssh_newkey = 'Are you sure you want to continue connecting'
        child = pexpect.spawn('ssh -l %s %s %s' % (self.user, self.host, self.command))
        i = child.expect([pexpect.TIMEOUT, ssh_newkey, 'password: '])
        if i == 0:
            log.info(""'ERROR!'
                              'SSH could not login. Here is what SSH said:'
                              'child.before, child.after')
            return False
        if i == 1:
            child.sendline('yes')
            child.expect('password: ')
            i = child.expect([pexpect.TIMEOUT, 'password: '])
            if i == 0:
                log.info(""'ERROR!'
                                  'SSH could not login. Here is what SSH said:'
                                  'child.before, child.after')
        child.sendline(self.password)
        self.child = child
        self.child.expect(pexpect.EOF)
        self.retStr = self.child.before
        log.info("Server return:" + self.retStr)

    def checkImg(self):
        facList = self.retStr.split("\r\n")
        factuplist = []
        imgtuplist = []
        numberlist = []
        imglist = []
        listtup = ()
        del (facList[0])
        del (facList[-1])
        log.info(str(facList))
        for list in facList:
            listtup = tuple((list.split("  ")[::-1]))
            factuplist.append(listtup)
        log.info(str(factuplist))
        for tup in factuplist:
            m = re.search("_[0-9]{2}_[0-9]{2}_", tup[0])
            if m is not None:
                imglist.append(tup[0])
                imgtuplist.append(tup)
        log.info(str(imgtuplist))
        imglist.sort()
        log.info(str(imglist))
        for n in imglist:
            pat = "_[0-9]{2}_[0-9]{2}_"
            num = re.findall(pat, n)
            numberlist.extend(num)
        numberlist.sort()
        log.info(str(numberlist))
        for imgtup in imgtuplist:
            mret = re.search(numberlist[-1], imgtup[0])
            if mret is not None:
                self.remotemd5 = imgtup[1]
        log.info("self.remotemd5 = " + str(self.remotemd5))
        log.info("self.localmd5 = " + str(self.localmd5))
        if self.remotemd5 == self.localmd5:
            log.info("The factory.img is Correct!!!")
            return True
        else:
            log.error("****Error:The factory.img is not Correct,please recheck!!!:Error****")
            return False
    @build_decorator						
    def getResult(self):
        check_cusc_branch = True
        if self.chiptype == "RK3228B" and self.product == "S-010W-A" and self.province == "cusc":
            log.info("Please select the build method: normal or test:")
            branch_input=raw_input("Please select the build method: normal or test:")
            if branch_input == "normal":
                check_cusc_branch = self.check_cusc_brach()
                log.warn("check_cusc_branch=%s"%check_cusc_branch)
			
        self.ssh_command()
        facimg_ret = self.checkImg()
        log.warn("facimg_ret=%s"%facimg_ret)
        self.flag=facimg_ret and check_cusc_branch
		
        return self.flag

class CheckBuildParameter():
    def __init__(self):
        partten='.*_(R\d.\d{2}).\d{2}.*'
        self.flag=True
        self.branchName=sys.argv[5]
        self.province=sys.argv[4]
        self.launcher=sys.argv[6]
        if len(sys.argv) > 7:
            self.imgprex=sys.argv[7]
        if "R" in self.imgprex:
            self.mid_ver=int(self.imgprex.split("R")[-1].split(".")[1])
            p=re.search(partten,self.imgprex)
            if p:
               self.check_str=p.group(1)
        self.branch_config=os.environ["HOME"]+"/build/input/zy/{}/branchCheck.ini".format(self.province)
        self.branchdir=os.environ["HOME"]+"/workspace/device/rockchip/rksdk/"
        if self.launcher == "nolauncher":
            self.suyingdir=os.environ["HOME"]+"/workspace/device/rockchip/rksdk/IPTV/IPTV_{}".format(self.province)
        else:
            self.suyingdir=os.environ["HOME"]+"/workspace/device/rockchip/rksdk/IPTV/IPTV_{}_{}".format(self.province,self.launcher)
        log.info("input branchname:"+self.branchName)
	
		
    def checkbranch(self):
        os.chdir(self.branchdir)
        branchList=os.popen("git branch -a").read().split("\n")
        log.info(str(branchList))
        for br in branchList:
            check_item="* "+self.branchName
            if  check_item == br:
                    log.info("Branch name is rigth")
                    return True 
        log.error("****Error:Branch name is not rigth,please recheck :Error****")
        return  False
  
    def checkBoardConfig(self):
        flag1=False
        flag2=False
        os.chdir(self.branchdir)
        os.popen("dos2unix BoardConfig.mk")
        if self.launcher == "nolauncher":
            pattern1="IPTV_%s"%self.province
        else:
            pattern1="IPTV_{}_{}".format(self.province,self.launcher)
        pattern2="TARGET_ROCKCHIP_PCBATEST"
        with open('BoardConfig.mk','r') as foo:
            for line in foo.readlines():
                if pattern1 in line:
                    log.info(pattern1 + " is in BoardConfig.mk")
                    flag1=True
                if pattern2 in line:
                    if line.endswith("true\n"):
                        log.info(pattern2 + " is Correct")
                        flag2=True
                    else:
                        log.error("****Error:"+pattern2 + " is not Correct,please recheck!!!:Error****")
                        flag2=False
        if not flag1:
            log.error("****Error:"+pattern1 + " is not in BoardConfig.mk,please recheck!!!:Error****")
        return flag1 and flag2
		  
    def checkSuyingMkNull(self):
        os.chdir(self.suyingdir)
        os.popen("dos2unix suying.mk")
        if self.province == "base":
            pattern="ro.build.office"
        else:
            pattern="ro.sys.office"
        with open('suying.mk','r') as foo:
            for line in foo.readlines():
                if pattern in line:
                    log.info(pattern + " is in suying.mk")
                    return True
        log.error("****Error:"+pattern + " is not in suying.mk.please recheck!!:Error****")
        return False
		
    def checkAndroidMk(self):
        os.chdir(self.suyingdir)
        os.popen("dos2unix Android.mk")
        if self.launcher == "nolauncher":
            pattern="IPTV_{}".format(self.province)
        else:
            pattern="IPTV_{}_{}".format(self.province,self.launcher)
        with open('Android.mk','r') as foo:
            for line in foo.readlines():
                if pattern in line:
                    log.info(pattern + " is in Android.mk")
                    return True
        log.error("****Error:"+pattern + " is not in Android.mk.please recheck!!:Error****")
        return False		
	
    @build_decorator			
    def getResult(self):
        check_normal=True
        branch_ret=True
        boardConfig_ret=True
        branch_check_ret=True
        if os.path.exists(self.branch_config):
            with open(self.branch_config,'r') as f:
                ret=f.read()
                if 'device/rockchip/rksdk' in ret:
                    check_normal=False
        if check_normal:
            branch_ret=self.checkbranch()
            log.warn("branch_ret=%s"%branch_ret)
		
        boardConfig_ret=self.checkBoardConfig()
        log.warn("boardConfig_ret=%s"%boardConfig_ret)		
        suying_ret=self.checkSuyingMkNull()
        log.warn("suying_ret=%s"%suying_ret)
		
        android_ret=self.checkAndroidMk()
        log.warn("android_ret=%s"%android_ret)

        can=Checkaml_normal()
        can.branch_config=self.branch_config
        can.launcher=self.launcher
        can.check_str=self.check_str
        if os.path.exists(self.branch_config):
            branch_check_ret=can.check_branch()
            log.warn("branch_check_ret=%s" % branch_check_ret)
		
        self.flag = branch_ret and boardConfig_ret and suying_ret and android_ret
        		
        return self.flag


def getObj():
        operation = {}
        operation["checkFacImg"] = CheckFactoryImg;
        operation["checknormalInput"] = ChecknormalInput;
        operation["checkBuildParameter"] = CheckBuildParameter;
        operation["checkNsbMaintenance"] = CheckNsbMaintenance;
        operation["checkConfig"] = CheckConfig;
        operation["checkOutput"] = CheckOutput;
        operation["CheckIptvandout"] = CheckIptvandout;
        operation["checkaml_normal"] = Checkaml_normal;
        operation["checkGitStatus"] = CheckGitStatus;

        op=operation[sys.argv[1]]()
        return op		
	
if __name__ == "__main__":
    cal=getObj()
    print cal.getResult()



#   This py use factory Pattern ,Test case is like
#   buildCheck.py=sys.argv[0]
#   methord=sys.argv[1]
#   product=sys.argv[2]
#   chiptype=sys.argv[3]
#   province=sys.argv[4]
#   branchname=sys.argv[5]
#   launcher=sys.argv[6]
#   python buildCheck.py checkFacImg S-010W-A RK3228H cubj s010wa_zy_cu_bj nolauncher
#   or
#   python buildCheck.py checknormalInput S-010W-A RK3228H cubj s010wa_zy_cu_bj nolauncher
#   or
#   python buildCheck.py checkBuildParameter S-010W-A RK3228H cubj s010wa_zy_cu_bj nolauncher imgprex
#   or
#   python buildCheck.py checkNsbMaintenance S-010W-A RK3228H cubj s010wa_zy_cu_bj nolauncher
#   or
#   python buildCheck.py checkConfig S-010W-A RK3228B cuhn s010wa_zy_cu_hn yaxin
#   or
#   python buildCheck.py checkOutput S-010W-A RK3228B cuhn s010wa_zy_cu_hn yaxin
#   or
#   python buildCheck.py checkaml_normal RG020ET-CA S905L cusd s010wa_zy_cu_sd nolauncher R1.00.08
#   or
#   python buildCheck.py checkGitStatus S-010W-AV2B RK3228H cuhn s010wa_zy_cu_hn nolauncher R1.00.08
#   or

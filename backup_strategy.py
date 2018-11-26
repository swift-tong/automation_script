#coding=utf-8
from subprocess import call
import  xml.dom.minidom
import os
import sys
import json
import shutil
import logging
import paramiko
import datetime
import stat
import re
import pexpect
import tarfile
import time


manifest_list=[("3228b","S-010W-A","cusd","newline"),
               ("3228b","S-010W-A","cusd","nolauncher"),
               #("3228h","S-010W-AV2B","cusd","nolauncher"),
               #("3228h","S-010W-A","cubj","nolauncher"),
              ]

old_manifest_list=[("3228b","s-010w-a","cusd","newline"),
                   ("3228b","s-010w-a","cusd","nolauncher"),
                   ("3228b","s-010w-a","cuhn","yaxin"),
                   ("3228b","s-010w-a","ctnx","nolauncher"),
                   ("3228b","s-010w-a","cuxj","nolauncher"),
              ]			  

open_rsync_log=False			  

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

base_commit_dict={}
current_commit_dict={}
base_no_path_item=[]
current_no_path_item=[]
count=0

class MakePatch(object):
    def __init__(self):
        self.chipType=sys.argv[1]
        self.productname=sys.argv[2]
        self.province=sys.argv[3]
        self.launcher=sys.argv[4]
        self.version=sys.argv[5].split("_")[-1]
        self.manifest_dict = {}
        self.git_dir_list=[]
        self.uncommit_dir=[]
        self.make_patch_dict={}
        self.no_path_item=[]
        self.workspace=os.environ["HOME"]+"/workspace/"
        if self.chipType.lower() in ["s905l","s905lv2","s905l2","s905l3"]:
            self.storage_patch_dir=os.environ["HOME"]+"/property/backup/"
            self.tag_dir=os.environ["HOME"]+"/amlbuild/image/ota/"
            self.img_dir=os.environ["HOME"]+"/amlbuild/image/"
        elif self.chipType.lower() in ["3228h","3228b"]:
            self.tag_dir=os.environ["HOME"]+"/build/input/zy/{}/ota/target/".format(self.province)
            self.img_dir=os.environ["HOME"]+"/build/input/zy/{}/image/".format(self.province)
            self.storage_patch_dir=os.environ["HOME"]+"/build/property/backup/"
        else:
            log.error("Input chiptype is not Correct.")
            return None
        
        #self.base_manifest=os.environ["HOME"]+"/test/patch/script/nsb_rk3228h_basic_manifest_2017-06-26.xml"
        self.base_manifest=os.environ["HOME"]+"/workspace/.repo/manifest.xml"
        self.real_manifest=os.readlink(self.base_manifest)
        self.json_file=self.base_manifest[:-4]+".json"
        base_dom = xml.dom.minidom.parse(self.base_manifest)
        self.base_dom_list = base_dom.getElementsByTagName('project')

    def only_check(self):
        con=0
        log.warn("Getting git dif ,please waitting!")
        for item in self.base_dom_list:
            folder=item.getAttribute("path")
            if not folder:
                folder = item.getAttribute("name")
                self.no_path_item.append(folder)
            self.git_dir_list.append(folder)
        log.warn("No 'path' item in manifest: {}".format(str(self.no_path_item)))
        log.warn("Get git dir done!Totle {} git folder.".format(len(self.git_dir_list)))

        for item in self.git_dir_list:
            con=con+1
            log.warn("Check folder {}: {}".format(con,item))
            os.chdir(self.workspace+item)
            ret=os.popen("git status").read()
            if ("Changes to be committed:" in ret or "Changes not staged for commit:" in ret):
                self.uncommit_dir.append(item)
        log.warn("##The follow floders have uncommit changes,please check##:")
        log.error(str(self.uncommit_dir))		

    def get_need_make_patch(self):
        nocheck=["hardware/wifi/mtk/drivers/mt7662","hardware/wifi/realtek/drivers/8822bs","hardware/wifi/realtek/drivers/8822bu"]
        count=0
        for item in self.base_dom_list:
            folder=item.getAttribute("path")
            if not folder:
                folder = item.getAttribute("name")
                self.no_path_item.append(folder)
            if folder in nocheck and "20170411.xml" in self.real_manifest:
                continue
            commit=item.getAttribute("revision")
            if len(commit) < 36:
                log.error("There are no commit message of {},Please check your manifest.".format(folder))
                sys.exit()                    
            self.manifest_dict[folder]=commit
        log.warn("No 'path' item in manifest: {}".format(str(self.no_path_item)))

        jsonObj=json.dumps(self.manifest_dict,indent=4,ensure_ascii=False)
        with open(self.json_file,"w") as js:
            js.write(jsonObj)

        log.warn("Waitting check committed folders.....")
        for key in self.manifest_dict.keys():
            count=count+1
            log.info("Backup Check item {}:{}".format(count,key))
            os.chdir(self.workspace+key)
            retlist=os.popen("git log").read().split("Author")
            if self.manifest_dict[key] not in retlist[0]:
                self.make_patch_dict[key]=self.manifest_dict[key]

        log.info("Totle {} folders commit change:".format(len(self.make_patch_dict.keys())))
        log.warn(json.dumps(self.make_patch_dict,indent=4,ensure_ascii=False))

    def check_git_status(self):
        for key in self.make_patch_dict.keys() :
            os.chdir(self.workspace+key)
            ret=os.popen("git status").read()
            if ("Changes to be committed:" in ret or "Changes not staged for commit:" in ret):
                self.uncommit_dir.append(key)
        log.warn("##The follow floders have uncommit changes,please check##:")
        log.error(str(self.uncommit_dir))

        if len(self.uncommit_dir) > 0 and (self.chipType.lower(),self.productname.upper(),self.province.lower(),self.launcher.lower()) in manifest_list:
            sys.exit()
        else:
            ans=raw_input("Please select continue(1) or break(2)\n:")
            if ans == "continue" or ans == "1":
                return True
            elif ans == "break" or ans == "2":
                sys.exit()
            else:
                log.error("Input wrong,please reinput.")
                sys.exit()

    def make_patch(self):
        count=0
        if not os.path.exists(self.storage_patch_dir):
            os.popen("mkdir -p {}".format(self.storage_patch_dir))
        for key in self.make_patch_dict.keys():
            patchx_dir=self.storage_patch_dir+key+"/"
            if not os.path.exists(patchx_dir):
                os.popen("mkdir -p {}".format(patchx_dir))
            os.chdir(self.workspace+key)
            retlist=os.popen("git format-patch {}".format(self.make_patch_dict[key])).read().split("\n")
            log.warn(key+":"+json.dumps(retlist))
            for item in retlist:
                if item:
                    count=count+1
                    os.chmod(item,stat.S_IRWXU|stat.S_IRWXG|stat.S_IRWXO)
                    shutil.move(item,patchx_dir+item)
        log.warn("Have make patch on {}".format(self.storage_patch_dir))
        log.warn("Totle {} patch".format(count))

class ParamikoInfo():
    def __init__(self,_host,_user,_password):
        self.host=_host
        self.user=_user
        self.password=_password

        self.transport = paramiko.Transport((self.host, 22))
        self.transport.connect(username=self.user, password=self.password)
        self.sftp = paramiko.SFTPClient.from_transport(self.transport)

        self.ssh=paramiko.SSHClient()
        self.ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        self.ssh.connect(hostname=self.host, port=22, username=self.user, password=self.password)

    def __del__(self):
        self.ssh.close()
        self.transport.close()


    def perform_command(self,_command):
        command = _command
        stdin,stdout,stderr = self.ssh.exec_command(command)
        out = stdout.read().decode()
        err = stderr.read()
        return (out,err)

    def paramiko_get(self,local_file,remote_file):
        log.warn(u'Get File to {} transporting...'.format(remote_file))
        self.sftp.get(remote_file, local_file)

    def paramiko_put(self,local_file,remote_file):
        log.warn(u'Put File to {} transporting...'.format(remote_file))
        self.sftp.put(local_file,remote_file)



class BackupPatch(MakePatch):
    def __init__(self):
        super(BackupPatch,self).__init__()
        self.host="172.24.170.194"
        self.user="backupimg"
        self.password="123456"
        Year=str(datetime.datetime.now().year)
        Month=str(datetime.datetime.now().month) if int(datetime.datetime.now().month) >int(10) else "0"+str(datetime.datetime.now().month)
        Day=str(datetime.datetime.now().day) if int(datetime.datetime.now().day) >int(10) else "0"+str(datetime.datetime.now().day)
        self.storage_patch_name="Patch_{}.tar.gz".format(self.version)
        self.storage_mani_name="All_Manifest_Prop_{}.tar.gz".format(self.version)

    def storage_patch(self):
        os.chdir(self.storage_patch_dir)
        remove_file=os.listdir(".")
        for fi in remove_file:
            if fi.endswith(".tar.gz"):
                os.remove(fi)
        log.warn("Packageimg {},please wait.".format(self.storage_patch_dir))
        #os.popen("tar cPzvf {} . --warning=no-file-changed".format(self.storage_patch_name)).read()
        tar_file=tarfile.open(self.storage_patch_name,"w:gz")
        for root,dir,files in os.walk(self.storage_patch_dir):
            for file in files:
                full_path=os.path.join(root.split("backup/")[1],file)
                tar_file.add(full_path)
        tar_file.close()

    def push_to_server(self):
        local_file=self.storage_patch_dir+self.storage_patch_name
        pi=ParamikoInfo(self.host,self.user,self.password)
        server_home=pi.perform_command("pwd")[0][:-1]
        remote_file="/usr/backup/"+self.chipType+"/"+self.productname+"/"+self.province+"/"+self.launcher+"/"+self.version+"/"+self.storage_patch_name
        log.warn("server_home={}".format(server_home))
        commond1="ls {}".format("/usr/backup/"+self.chipType+"/"+self.productname+"/"+self.province+"/"+self.launcher+"/"+self.version+"/")
        commond2="mkdir -p {}".format("/usr/backup/" + "/" + self.chipType + "/" + self.productname + "/" + self.province + "/"+self.launcher+"/"+self.version+"/")
        log.warn("exec commond1: {}".format(commond1))
        ret=pi.perform_command(commond1)
        log.warn(str(ret))
        if "No such file or directory" in ret[1]:
            log.warn("exec commond2: {}".format(commond2))
            pi.perform_command(commond2)
        commond3="rm -rf {}*".format("/usr/backup/"+self.chipType+"/"+self.productname+"/"+self.province+"/"+self.launcher+"/"+self.version+"/")
        log.warn("exec commond3: {}".format(commond3))
        ret2=pi.perform_command(commond3)
        pi.paramiko_put(local_file,remote_file)

    def backup_rksdk(self):
        pi=ParamikoInfo(self.host,self.user,self.password)
        server_home=pi.perform_command("pwd")[0][:-1]
        remote_dir="/usr/backup/"+self.chipType+"/"+self.productname+"/"+self.province+"/"+self.launcher+"/"
        if self.chipType.lower() in ["s905l","s905lv2","s905l2","s905l3"]:
            tar_dir=os.environ["HOME"]+"/workspace/device/amlogic/p201_iptv/"	   
            local_targz="device_amlogic_p201_iptv.tar.gz"
            os.chdir(tar_dir)        
            os.popen("tar --warning=no-file-changed --exclude=*.git --exclude=*.repo -czvf {} .".format(local_targz),'w')
        elif self.chipType.lower() in ["3228h","3228b"]:
            tar_dir=os.environ["HOME"]+"/workspace/device/rockchip/rksdk/"
            local_targz="rksdk.tar.gz"
            os.chdir(tar_dir)
            os.popen("tar --warning=no-file-changed --exclude=*.git --exclude=*.repo -czvf {} .".format(local_targz),'w')		   
        pi.paramiko_put(local_targz,remote_dir+local_targz)
        os.popen("rm {}".format(local_targz))
 
    def backup_config(self):
        check_ver=100
        pi=ParamikoInfo(self.host,self.user,self.password)
        server_home=pi.perform_command("pwd")[0][:-1]
        remote_dir="/usr/backup/"+self.chipType+"/"+self.productname+"/"+self.province+"/"+self.launcher+"/"+self.version+"/"
        remote_dir2="/usr/backup/"+self.chipType+"/"+self.productname+"/"+self.province+"/"+self.launcher+"/"
        if self.chipType in ["3228b","3228h"]:
            imgtool=os.environ["HOME"]+"/build/RKTools/imgmake_tool/AndroidTool_Release_v2.31/rockdev/"
            os.chdir(imgtool)
            os.popen("tar --warning=no-file-changed --exclude=*.git --exclude=*.repo -czvf imgtool.tar.gz .",'w')
            pi.paramiko_put("imgtool.tar.gz",remote_dir2+"imgtool.tar.gz")
            os.popen("rm imgtool.tar.gz")

        #cmd1='cp {} {}{}'.format(self.workspace+".repo/"+self.real_manifest,self.img_dir,self.real_manifest.split("/")[1])
        #log.warn("exec cmd1: {}".format(cmd1))
        #ret2=os.popen(cmd1)
        os.chdir(self.img_dir)
        tar_file=tarfile.open(self.storage_mani_name,"w:gz")
        log.warn("Packageimg {},please wait.".format(self.storage_mani_name))
        if os.path.exists(self.real_manifest.split("/")[-1]):
            os.popen("rm {}".format(self.real_manifest.split("/")[-1]))
        for root,dirs,files in os.walk(self.img_dir):
            for fi in files:
                if fi.endswith(".xml") or fi.endswith(".build.prop") or fi.endswith("keyvaluemapping.csv"):
                    if fi.endswith(".xml"):
                        check_ver=int(fi.split("_")[-1].split(".")[0])
                    elif fi.endswith(".build.prop"):
                        check_ver=int(fi.split(".")[-3])
                    elif fi.endswith("keyvaluemapping.csv"):
                        check_ver=int(fi.split("R")[-1].split("_")[0].split(".")[-1])
                    else:
                        log.error("Mini Version error")
                        continue						
                    if check_ver < 80:
                        full_path=os.path.join(root.split("image/")[1],fi)
                        tar_file.add(full_path)
                    else:
                        continue
        tar_file.close()
        log.warn("Putting {} to Server:{}".format(self.storage_mani_name,remote_dir+self.storage_mani_name))
        pi.paramiko_put(self.storage_mani_name,remote_dir+self.storage_mani_name)
        log.warn(self.workspace+".repo/"+self.real_manifest)
        pi.paramiko_put(self.workspace+".repo/"+self.real_manifest,remote_dir+self.real_manifest.split("/")[-1])
        os.popen("rm {}".format(self.storage_mani_name))
        

class BackupTargetFile(BackupPatch):
    def __init__(self):
        super(BackupTargetFile,self).__init__()
        self.storage_tag_name="ota_target.tar.gz"
        self.storage_tag_list=[]
        if self.chipType.lower() in ["s905l","s905lv2","s905l2","s905l3"]:
            self.split_str="ota/"
        elif self.chipType.lower() in ["3228h","3228b"]:
            self.split_str="target/"
        else:
            log.error("Input chiptype is not Correct.")
            return None

    def put_ota_to_server(self):
        local_file=self.tag_dir+self.storage_tag_name
        pi=ParamikoInfo(self.host,self.user,self.password)
        server_home=pi.perform_command("pwd")[0][:-1]
        remote_file="/usr/backup/"+self.chipType+"/"+self.productname+"/"+self.province+"/"+self.launcher+"/"+self.storage_tag_name
        pi.paramiko_put(local_file,remote_file)
        log.warn("Done!")
        os.chdir(self.tag_dir)
        os.popen("rm {}".format(self.storage_tag_name))
			
    def storage_tag_file(self):
        tmp_list=[]
        os.chdir(self.tag_dir)
        file_list=os.listdir(".")
        for item in file_list:
            if item.endswith("_int.zip"):
                tmp_list.append(item)
        for item in tmp_list:
            p=re.search(".*R\d.(\d){2}.(\d){2}_int.zip",item)
            if p:
                if int(p.group(1)) > 0:
                    self.storage_tag_list.append(p.group())
        log.warn("Backup target file:\n{}".format(str(self.storage_tag_list)))
        
        log.warn("Package target file {},please wait.".format(self.storage_tag_name))
        tar_file=tarfile.open(self.storage_tag_name,"w:gz")
        for root,dir,files in os.walk(self.tag_dir):
            for file in files:
                full_path=os.path.join(root.split(self.split_str)[1],file)
                tar_file.add(full_path)
        tar_file.close()
    
    def back_current_tag_file(self):
        tmp_list=[]
        flag=False
        pi=ParamikoInfo(self.host,self.user,self.password)
        server_home=pi.perform_command("pwd")[0][:-1]
        os.chdir(self.tag_dir)
        file_list=os.listdir(".")
        for item in file_list:
            if item.endswith("_int.zip"):
                tmp_list.append(item)
        for item in tmp_list:
            if self.productname.upper() in item and self.province.upper() in item and self.version in item:
                remote_file="/usr/backup/"+self.chipType+"/"+self.productname+"/"+self.province+"/"+self.launcher+"/"+self.version+"/"+item
                pi.paramiko_put(item,remote_file)
                flag=True
                break
        if not flag:
            log.error("Target file not find!")
        return flag
        	

		
class StorageSpecialWorkspace(BackupPatch):
    def __init__(self):
        super(StorageSpecialWorkspace,self).__init__()
        self.home_dir=os.environ["HOME"]
        self.log_dir=self.storage_patch_dir+"backupLog/"
        i=datetime.datetime.now()
        iyear = str(i.year) if i.year > 10 else "0"+str(i.year)
        imonth = str(i.month) if i.month > 10 else "0"+str(i.month)
        iday = str(i.day) if i.day > 10 else "0"+str(i.day)
        self.now_time="%s.%s.%s."%(iyear,imonth,iday)
        self.log_file=self.log_dir+self.now_time+"_backup.log"
        log.warn("self.log_file={}".format(self.log_file))
        self.password="123456"
        self.child_dir="{}/{}/{}/{}/workspace/".format(self.chipType,self.productname,self.province,self.launcher)
        self.rsync_cmd="rsync -avzlr --delete --progress  {}/workspace/ backupimg@172.24.170.194:/usr/backup/{}".format(self.home_dir,self.child_dir)
        self.rsync_test="rsync -avzlr --delete --progress  {}/.bash_aliases backupimg@172.24.170.194:/usr/backup/".format(self.home_dir)
        log.warn("self.rsync_cmd={}".format(self.rsync_cmd))

    def ssh_command(self):
        ssh_newkey = 'Are you sure you want to continue connecting'
        child = pexpect.spawn(self.rsync_cmd,logfile=sys.stdout,timeout=3600*12)
        i = child.expect([pexpect.TIMEOUT, ssh_newkey, 'password: '])
        log.warn("i={}".format(i))
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
        #log.warn("self.child.before={}".format(self.child.before))
        #log.warn("self.child.after={}".format(self.child.after))
        if not os.path.exists(self.log_dir):
            os.makedirs(self.log_dir)
        if open_rsync_log:
            with open(self.log_file,"w") as f:
                f.write(self.retStr)
            log.warn("Have write log file {}".format(self.log_file))
        log.warn("rsync Done!!")
		
    def transport_workspace(self):
        os.chdir(self.home_dir)
        pi=ParamikoInfo(self.host,self.user,self.password)
        server_home=pi.perform_command("pwd")[0][:-1]
        log.warn("server_home={}".format(server_home))
        commond1="ls {}".format("/usr/backup/"+self.chipType+"/"+self.productname+"/"+self.province+"/"+self.launcher+"/")
        commond2="mkdir -p {}".format("/usr/backup/" + self.chipType + "/" + self.productname + "/" + self.province + "/"+self.launcher+"/")
        log.warn("exec commond1: {}".format(commond1))
        ret=pi.perform_command(commond1)
        log.warn(str(ret))
        if "No such file or directory" in ret[1]:
            log.warn("exec commond2: {}".format(commond2))
            pi.perform_command(commond2)
        #commond3="rm -rf {}*".format("/usr/backup/"+self.chipType+"/"+self.productname+"/"+self.province+"/"+self.launcher+"/")
        #log.warn("exec commond3: {}".format(commond3))
        #ret2=pi.perform_command(commond3)
        #os.popen(self.rsync_cmd)
        self.ssh_command()
		

def method_sh():
    mp=MakePatch()
    mp.get_need_make_patch()
    mp.make_patch()

    bp=BackupPatch()
    bp.storage_patch()
    bp.push_to_server()
    bp.backup_config()

    btf=BackupTargetFile()
    tag_ret=btf.back_current_tag_file()
    return tag_ret

def method_manual():
    check_item=(sys.argv[1],sys.argv[2],sys.argv[3],sys.argv[4])
    log.warn("check_item={}".format(check_item))
    mp=MakePatch()
    log.warn("#####Please select what you want to do.#####")
    log.warn("##### check(1) makePatch(2) backupAll(3) backupSpecial(4) #####")
    ans=raw_input(":")
    if ans == "check" or ans == "1":
        mp.only_check()
    elif (ans == "backupall" or ans == "3") and check_item not in old_manifest_list:
        log.warn("This feature is not supported yet. Please contact your administrator.")
        mp.get_need_make_patch()
        mp.check_git_status()
        mp.make_patch()
        bp=BackupPatch()
        bp.storage_patch()
        bp.push_to_server()
        bp.backup_config()
        btf=BackupTargetFile()
        btf.back_current_tag_file()
    elif (ans == "makePatch" or ans == "2") and check_item not in old_manifest_list:
        mp.get_need_make_patch()
        mp.check_git_status()
        mp.make_patch()
    elif (ans == "backupSpecial" or ans == "4") and check_item in old_manifest_list:
        ssw=StorageSpecialWorkspace()
        ssw.transport_workspace()
        btf=BackupTargetFile()
        btf.back_current_tag_file()
        bp=BackupPatch()
        bp.backup_config()
    else:
        log.error("Your input is not Correct!")		
		
if __name__ == "__main__":
    nocheckList=["ctjc","cmsh","cujc"]
    if len(sys.argv) == 7 and sys.argv[6] == "method_sh" and sys.argv[3] not in nocheckList:
        if int(sys.argv[5].split(".")[1]) > 0 and int(sys.argv[5].split(".")[2]) < 80:
            log.warn("#####You build maintenance will backup workspace!#####")
            time.sleep(5)           
            ret = method_sh()
            print ret
        else:
            log.warn("#####You build not maintenance,Do nothing!#####")
            print True
    elif len(sys.argv) == 6:
        method_manual()
    elif sys.argv[3] in nocheckList:
        log.warn("{} do not backup!".format(sys.argv[3]))
    else:
        log.error("Transfer parameters error,please recheck!")




#Manual run 
#注意传参数的时候用小写
#python backup_strategy.py s905l rg020et-ca cusd nolauncher S-010W-AV2B_SW_D_ZY_CUSD_R1.01.22
#python backup_strategy.py 3228h s-010w-av2b cubj nolauncher S-010W-AV2B_SW_D_ZY_CUSD_R1.01.22


#sh guide
#python backup_strategy.py s905l rg020et-ca cusd nolauncher S-010W-AV2B_SW_D_ZY_CUSD_R1.01.22 method_sh
#python backup_strategy.py 3228h s-010w-av2b cubj nolauncher S-010W-AV2B_SW_D_ZY_CUSD_R1.01.22 method_sh




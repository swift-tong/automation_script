import os
import sys
import re
import datetime
import logging
import json
import xml.dom.minidom


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

class GetInput(object):
    def __init__(self):
        self.chipType=sys.argv[1]
        self.carrier=sys.argv[2][0:2]
        self.province=sys.argv[2][2:]
        self.launcher=sys.argv[3]
        self.swVersion=sys.argv[4]
        logYear=str(datetime.datetime.now().year)
        logMonth=str(datetime.datetime.now().month) if datetime.datetime.now().month >10 else "0"+str(datetime.datetime.now().month)
        logDay=str(datetime.datetime.now().day) if datetime.datetime.now().day >10 else "0"+str(datetime.datetime.now().day)

        self.papk=os.environ["HOME"]+"/workspace/prebuilts/sdk/tools/linux/aapt dump badging"
        self.property_dict={}

    def getFileTypeList(self):
        fileList=[]
        fileList_tmp=os.listdir(self.propertyFullDir)
        for item in fileList_tmp:
            if item.endswith(".txt"):
                fileList.append(item)
        log.warn("fileList={}".format(str(fileList)))
        if len(fileList) == 0:
            return fileList
        typeDict={}
        specialList=[]
        keyX="" 
        keyType=""
        for fi in fileList:
            p=re.search(".*((R\d)\.(\d{2})).*",fi)
            if p:
                if int(p.group(3)) < 2:
                    keyX=p.group(2)+".(00,01)"
                    if keyX not in typeDict.keys():
                        typeDict[keyX]=[p.group()]
                    else:
                        typeDict[keyX].append(p.group())
                else:
                    keyX=p.group(1)
                    if p.group(1) not in typeDict.keys():
                        typeDict[keyX]=[p.group()]
                    else:
                        typeDict[keyX].append(p.group())
		
        if self.launcher not in ["nolauncher","newline"] and len(typeDict.keys()) == 1:		
            for fi2 in fileList:
                p2=re.search(".*_{}_.*".format(self.launcher.upper()),fi2)
                if p2:
                    specialList.append(p2.group())
            log.warn("specialList:")
            log.warn(str(specialList))
            return specialList
						
        log.warn("typeDict:")
        for key in typeDict.keys():
            log.warn("{}{}{}{}".format(key," "*(10-len(key)),":",typeDict[key]))

        log.warn("\nInput Name:{}\n".format(self.swVersion))
        pNew=re.search(r".*((R\d)\.(\d{2})).*",self.swVersion)
        if pNew:
            if int(pNew.group(3)) < 2:
                keyType=pNew.group(2)+".(00,01)"
            else:
                keyType=pNew.group(1)
        if keyType in typeDict.keys():
            return typeDict[keyType]
        else:
            return []
										

    def writeDiffFile_New(self,_newVersion,_oldVersion):
        max_add_len=0
        max_modify_len=0
        max_delete_len=0
        newList=[]
        finalList=[]
        old_dict={}
        new_dict={}
        add_list_tmp=[]
        modify_list_tmp=[]
        delete_list_tmp=[]
        addList=["\nAdd:\n"]
        modifyList=["\nModify:\n"]
        deleteList=["\nDelete:\n"]
        oldVersion=_oldVersion
        newVersion=_newVersion
        pass_index_list=[]

        with open(self.propertyFullDir+"{}.json".format(newVersion),"r") as new_file:
            new_dict=json.loads(new_file.read())
        with open(self.propertyFullDir+"{}.json".format(oldVersion),"r") as old_file:
            old_dict=json.loads(old_file.read())
        
        #log.warn(old_dict)
        #log.warn(new_dict)
        for key in old_dict.keys():
            if key in new_dict.keys():
                if old_dict[key] == new_dict[key]:
                    old_dict.pop(key)
                    new_dict.pop(key)
                else:
                    modify_list_tmp.append([old_dict[key],new_dict[key]])
                    old_dict.pop(key)
                    new_dict.pop(key)					
		
        for key in old_dict.keys():
            delete_list_tmp.append(old_dict[key])

        for key in new_dict.keys():
            add_list_tmp.append(new_dict[key])
			
        log.warn("add_list_tmp={}".format(add_list_tmp))
        log.warn("modify_list_tmp={}".format(modify_list_tmp))
        log.warn("delete_list_tmp={}".format(delete_list_tmp))
		
        for element in add_list_tmp:
            max_add_len=max_add_len if (max_add_len >= len(element[0])) else len(element[0])
        for element_list in modify_list_tmp:
            for element in element_list:
                max_modify_len=max_modify_len if (max_modify_len >= len(element[0])) else len(element[0])
        for element in delete_list_tmp:
            max_delete_len=max_delete_len if (max_delete_len >= len(element[0])) else len(element[0])
			
        for element in enumerate(add_list_tmp):
            addList.append("    "+element[1][0]+" "*(max_add_len-len(element[1][0]))+" : "+element[1][1]+"\n")
			
        for element_list in enumerate(modify_list_tmp):
            for element in element_list[1]:
                modifyList.append("    "+element[0]+" "*(max_modify_len-len(element[0]))+" : "+element[1]+"\n")
            modifyList.append("\n")
			
        for element in enumerate(delete_list_tmp):
            deleteList.append("    "+element[1][0]+" "*(max_delete_len-len(element[1][0]))+" : "+element[1][1]+"\n")
			
        log.warn(str(addList))
        log.warn(str(modifyList))
        log.warn(str(deleteList))
        		
		
        if len(addList) == 1:
            addList[0] = addList[0][:-1]+"{}None\n".format(" "*10)
        if len(modifyList) == 1:
            modifyList[0] = modifyList[0][:-1]+"{}None\n".format(" "*10)
        if len(deleteList) == 1:
            deleteList[0] = deleteList[0][:-1]+"{}None\n".format(" "*10)
			
        finalList=addList+modifyList+deleteList
        finalList.append("\n")
        finalList.insert(0,"To:   {}\n".format(newVersion))
        finalList.insert(0,"From: {}\n".format(oldVersion))
        with open(self.diffFile,"w") as f2:
            f2.writelines(finalList)
        return True			
										
    def writeDiffFile(self,_newVersion,_oldVersion):
        newList=[]
        finalList=[]
        modifyTmpList=["\nModify:\n"]
        addList=["\nAdd:\n"]
        modifyList=["\nModify:\n"]
        deleteList=["\nDelete:\n"]
        oldVersion=_oldVersion
        newVersion=_newVersion
		
        old_json_file=self.propertyFullDir+oldVersion+".json"
        if os.path.exists(old_json_file):
            self.writeDiffFile_New(newVersion,oldVersion)
            return True

        os.popen("diff -b %s %s > %s"%(self.propertyFullDir+oldVersion+".txt",self.propertyFullDir+newVersion+".txt",self.diffFile))
        with open(self.diffFile,"r") as f:
            diffList=f.readlines()
            for item in diffList:
                #p=re.match("\d+|\d+,\d+(\w)\d+|(\d+,\d+)",item)
                pTitle=re.match("\d.*\d",item)
                if pTitle:
                    p=re.search("\d(\w)\d",pTitle.group())
                    if p:
                        if p.group(1)=="a":
                            newList.append("\nAdd:\n")
                        elif p.group(1)=="c":
                            newList.append("\nModify:\n")
                        elif p.group(1)=="d":
                            newList.append("\nDelete:\n")
                else:
                    if item == "> \n" or item == "---\n" or item == " \n":
                        pass
                    elif (item[0] == ">" and len(item) > 10) or (item[0] == "<" and len(item) > 10):
                        newList.append(item[1:])
                    else:
                        pass
        #newList.append()
		
        for i,value in enumerate(newList):
            if value == "\nAdd:\n":
                tmpList=addList
            elif value == "\nModify:\n":
                tmpList=modifyList
            elif value == "\nDelete:\n":
                tmpList=deleteList
            else:
                tmpList.append(value)
        count=1
        for i in range(1,len(modifyList)):
            if count == 2:
                modifyTmpList.append("(new)"+modifyList[i])
                modifyTmpList.append("\n")
                count=1
            else:
                count = count+1
                modifyTmpList.append("(old)"+modifyList[i])
         
        if len(addList) == 1:
            addList[0] = addList[0][:-1]+"{}None\n".format(" "*10)
        if len(modifyTmpList) == 1:
            modifyTmpList[0] = modifyTmpList[0][:-1]+"{}None\n".format(" "*10)
        if len(deleteList) == 1:
            deleteList[0] = deleteList[0][:-1]+"{}None\n".format(" "*10)
			
        finalList=addList+modifyTmpList+deleteList
        finalList.append("\n")
        finalList.insert(0,"To:   {}\n".format(newVersion))
        finalList.insert(0,"From: {}\n".format(oldVersion))
        with open(self.diffFile,"w") as f2:
            f2.writelines(finalList)		


class MakeCommitDiff(GetInput):
    def __init__(self):
        super(MakeCommitDiff,self).__init__()
        self.chipType=sys.argv[1]
        self.first_version=False
        self.diff_file=""
        self.province=sys.argv[2]
        self.launcher=sys.argv[3]
        self.swVersion=sys.argv[4]
        self.old_xml_dict={}
        self.new_xml_dict={}
        self.check_commit_dict={}
        self.not_in_new_manifest=[]
        self.not_in_old_manifest=[]
        self.old_partten=""
        self.new_partten=""
        self.xml_list=[]
        self.old_no_path_item=[]
        self.new_no_path_item=[]
        self.old_xml=""
        self.current_xml=""
        if self.chipType in ["3228b","3228h"]:
            self.xml_dif=os.environ["HOME"]+"/build/input/zy/{}/image".format(self.province)
        elif self.chipType in ["s905l","s905lv2","s905l2","s905l3"]:
            self.xml_dif=os.environ["HOME"]+"/amlbuild/image"
        else:
             log.error("Input chipType is not correct ,please recheck.")

    def get_old_ver(self,maj,mini):
        old_mini_list=[]
        if mini > 0:
            old_maj=maj
            old_mini=mini-1
        else:
            if maj <= 0:
                log.warn("This is first version.")
                return False
            old_maj=maj-1
            for fi in self.xml_list:
                reObj1=re.search(".*_%d_(\d+).xml"%(old_maj,),fi)
                if reObj1:
                    old_mini_list.append(int(reObj1.group(1)))
            old_mini=sorted(old_mini_list)[-1]

        log.warn("old_maj:{} old_mini:{}".format(old_maj,old_mini))
        for xml_fi in self.xml_list:
                reObj2=re.search(".*(_{}_{})\.xml".format(old_maj,old_mini),xml_fi)
                if reObj2:
                    log.warn("old xml = {}".format(reObj2.group()))
                    log.warn("old partten={}".format(reObj2.group(1)+".xml"))
                    self.old_partten=reObj2.group(1)+".xml"
                    return True
        self.get_old_ver(old_maj,old_mini)

    def check_manifest(self):
        os.chdir(self.xml_dif)
        dom1=xml.dom.minidom.parse(self.old_xml)
        if not dom1:
            log.error("old_xml error,please check!")
        old_dom_list=dom1.getElementsByTagName("project")

        dom2=xml.dom.minidom.parse(self.new_xml)
        if not dom2:
            log.error("new_xml error,please check!")
        new_dom_list=dom2.getElementsByTagName("project")

        for item in old_dom_list:
            folder=item.getAttribute("path")
            if not folder:
                folder = item.getAttribute("name")
                self.old_no_path_item.append(folder)
            commit=item.getAttribute("revision")
            self.old_xml_dict[folder]=commit
        log.warn("Old no 'path' item: {}".format(str(self.old_no_path_item)))

        for item in new_dom_list:
            folder=item.getAttribute("path")
            if not folder:
                folder = item.getAttribute("name")
                self.new_no_path_item.append(folder)
            commit=item.getAttribute("revision")
            self.new_xml_dict[folder]=commit
        log.warn("New no 'path' item: {}".format(str(self.new_no_path_item)))

        log.warn("in {} not in {}".format(self.old_xml,self.new_xml))
        for key in self.old_xml_dict.keys():
            if key not in self.new_xml_dict.keys():
                self.not_in_new_manifest.append(key)
        log.error(str(self.not_in_new_manifest))

        log.warn("in {} not in {}".format(self.new_xml,self.old_xml))
        for key in self.new_xml_dict.keys():
            if key not in self.old_xml_dict.keys():
                self.not_in_old_manifest.append(key)
        log.error(str(self.not_in_old_manifest))

    def get_xml_file(self):
        maj=0
        mini=0
        old_xml_list=[]
        new_xml_list=[]
        if not self.xml_dif:
            sys.exit()
        os.chdir(self.xml_dif)
        pattern1=".*R\d.(\d{2}).(\d{2})"
        reObj=re.search(pattern1,self.swVersion)
        if reObj:
            maj=int(reObj.group(1))
            mini=int(reObj.group(2))
        else:
            log.error("Can not find maj and mini version,please check swVersion")
            return False
        for fi in os.listdir("."):
            if os.path.splitext(fi)[1] == ".xml":
                checkver=int(fi.split("_")[-1].split(".")[0])
                if checkver < 80:
                    self.xml_list.append(fi)

        self.get_old_ver(maj,mini)
        self.new_partten="_{}_{}.xml".format(maj,mini)
        log.warn("new_partten={}".format(self.new_partten))

        for fi in self.xml_list:
            if self.new_partten in fi:
                new_xml_list.append(fi)

        if len(new_xml_list) == 0:
            return "nomani"
				
        if not self.old_partten:
            return "first"
        for fi in self.xml_list:
            if self.old_partten in fi:
                old_xml_list.append(fi)

        self.old_xml=sorted(old_xml_list)[-1]
        self.new_xml=sorted(new_xml_list)[-1]

        log.warn("old_xml={}".format(self.old_xml))
        log.warn("new_xml={}".format(self.new_xml))
        return  "ok"

    def make_diff_dict(self):
        old_remove_count=0
        new_remove_count=0
        old_keys=self.old_xml_dict.keys()
        new_keys=self.new_xml_dict.keys()
        for item in self.not_in_old_manifest:
            old_remove_count=old_remove_count+1
            old_keys.remove(item)
        log.info("old_remove_count={}".format(old_remove_count))

        for item in self.not_in_new_manifest:
            new_remove_count=new_remove_count+1
            new_keys.remove(item)
        log.info("new_remove_count={}".format(new_remove_count))

        for key in old_keys:
            if  self.old_xml_dict[key] != self.new_xml_dict[key]:
                self.check_commit_dict[key] = (self.old_xml_dict[key],self.new_xml_dict[key])

        jObj=json.dumps(self.check_commit_dict,indent=4,ensure_ascii=False)
        log.info("Totle {} folders commit change.".format(len(self.check_commit_dict.keys())))
        log.warn(jObj)

    def show_commit_change(self):
        head_list=["-"*30+"Workspace diff"+"-"*30+"\n","From:{}\n".format(self.old_xml),"To:  {}\n\n".format(self.new_xml)]
        if os.path.exists(self.diff_file):
            os.popen("rm {}".format(self.diff_file))
        with open(self.diff_file,"a+") as f:
            f.writelines(head_list)
            if len(self.check_commit_dict.keys()) == 0:
                log.warn("No change!!!")
                commit_list=["    None"]
                f.writelines(commit_list)
            else:
                for key in self.check_commit_dict:
                    dirx=os.environ["HOME"]+"/workspace/"+key
                    p_old="commit "+self.check_commit_dict[key][0]
                    p_new="commit "+self.check_commit_dict[key][1]
                    log.info("dirx={}".format(dirx))
                    log.info("p_old:{}".format(p_old))
                    log.info("p_new:{}".format(p_new))
                    os.chdir(dirx)
                    log_git=os.popen("git log --name-status -50").read().decode("utf-8")
                    if p_old not in log_git:
                        commit_list=["Project:"+key+":"+"\n","    Old {} not found.Do nothing.\n\n".format(p_old)]
                    elif p_new not in log_git:
                        commit_list=["Project:"+key+":"+"\n","    new {} not found.Do nothing.\n\n".format(p_new)]
                    else:
                        commit_str = p_new + log_git.split(p_old)[0].split(p_new)[1]
                        log.warn(commit_str)
                        commit_list=commit_str.split("\n")
                        for index,item in enumerate(commit_list):
                            commit_list[index]="    "+item+"\n"
                        commit_list.insert(0,"Project:"+key+"\n")
                    log.warn(str(commit_list))
                    f.writelines(str(i.encode('utf-8')) for i in commit_list)

    def show_error_version(self,flag):
        flag_dict={
            "nomani" : "No manifest",
            "first" : "First Version,no diff",
        }
        head_list=["-"*30+"Workspace diff"+"-"*30+"\n","From:\n","To:  \n\n","    {}\n".format(flag_dict[flag])]
        with open(self.diff_file,"a+") as f:
            f.writelines(head_list)


    def get_result(self,_diff_file):
        self.diff_file=_diff_file[:-4]+"_manifest.txt"
        log.warn("self.diff_file={}".format(self.diff_file))
        ret=self.get_xml_file()
        if ret == "nomani":
            self.show_error_version("nomani")
        elif ret == "first":
            self.show_error_version("first")
        else:
            self.check_manifest()
            self.make_diff_dict()
            self.show_commit_change()
        return True

class GetAmlImgInput(GetInput):
    def __init__(self):
        super(GetAmlImgInput,self).__init__()
        self.chipType=sys.argv[1]
        self.carrier=sys.argv[2][0:2]
        self.province=sys.argv[2][2:]
        self.launcher=sys.argv[3]
        self.product=sys.argv[4].split("_")[0]
        self.check_list=["ctjc","cujc","cmsh","cthq"]
		
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
		
        if self.launcher != "nolauncher" and self.carrier+self.province not in self.check_list:
            self.apk_dir = os.environ["HOME"]+"/workspace/device/amlogic/common/{}/{}_apks/{}/".format(self.carrierDict[self.carrier],self.province.upper(),self.launcher)
        else:
            if self.carrier+self.province == "ctjc":
                self.apk_dir = os.environ["HOME"]+"/workspace/device/amlogic/common/{}/SH_jicai_apks/SY/sy_apk/".format(self.carrierDict[self.carrier])
            elif self.carrier+self.province == "cthq":
                self.apk_dir = os.environ["HOME"]+"/workspace/device/amlogic/common/{}/SH_jicai_apks/SY/SY_FusionGateway/".format(self.carrierDict[self.carrier])
            elif self.carrier+self.province == "cujc":
                self.apk_dir = os.environ["HOME"]+"/workspace/device/amlogic/common/{}/BJ_jicai_apks/SY/".format(self.carrierDict[self.carrier])
            elif self.carrier+self.province == "cmsh":
                self.apk_dir = os.environ["HOME"]+"/workspace/device/amlogic/common/{}/sh/".format(self.carrierDict[self.carrier])
            else:
                self.apk_dir = os.environ["HOME"]+"/workspace/device/amlogic/common/{}/{}_apks/".format(self.carrierDict[self.carrier],self.province.upper())
        self.workspace=os.environ["HOME"]+"/workspace/"
        if self.chipType.lower() in ["s905l2","s905l3"] and self.carrier == "ct" and self.province in ["jc","hq"]:
            self.mkFile=os.environ["HOME"]+"/workspace/device/amlogic/common/telecom.mk"
        elif self.chipType.lower() == "s905l" and self.carrier == "cu" and self.province == "hq":
            self.mkFile=os.environ["HOME"]+"/workspace/device/amlogic/common/unicom.mk"
        elif self.chipType.lower() == "s905l" and self.carrier == "cm" and self.province == "sh":
            self.mkFile=os.environ["HOME"]+"/workspace/device/amlogic/common/mobile.mk"
        else:
            self.mkFile=os.environ["HOME"]+"/workspace/device/amlogic/common/{}{}.mk".format(self.mkDict[self.carrier],self.province)
        self.propertyFullDir=os.environ["HOME"]+"/property/full/"
        self.propertyOtaDir=os.environ["HOME"]+"/property/ota/"

        if not os.path.exists(self.propertyFullDir):
            os.popen("mkdir -p %s"%self.propertyFullDir).read()
        if not os.path.exists(self.propertyOtaDir):
            os.popen("mkdir -p %s"%self.propertyOtaDir).read()
			
        self.swVersion=sys.argv[4]
        self.diffFile=""


    def get_property_dict(self,_file,_md5,_type):
        filex=_file
        md5x=_md5
        typex=_type
        apk_package=""
        os.chdir(self.apk_dir)
        if typex == "apk":
            papk_ret=os.popen("{} {}".format(self.papk,filex)).read()
            if not papk_ret:
                log.error("****Error:aapt return false,please recheck {}:Error****".format(filex))
                sys.exit()
            apk_package=papk_ret.split("'")[1]
            self.property_dict["{}".format(apk_package+"_"+typex)]=(filex.split("/")[-1],md5x)
        else:
            self.property_dict["{}".format("pass"+"_"+filex.split("/")[-1]+"_"+typex)]=(filex.split("/")[-1],md5x)		
        
    def getInputFull(self):
        mkFileList=[]
        apkList=[]
        binList=[]
        etcList=[]
        libList=[]
        maxApkLen=0
        maxBinLen=0
        maxEtcLen=0
        maxLibLen=0
        pattern1=":system/bin/"
        pattern2=":system/app/"
        pattern3=":system/etc/"
        pattern4=":system/lib/"
        
        if self.carrier + self.province in self.check_list:
            for root,dirs,files in os.walk(self.apk_dir,topdown=True):
                for name in files:
                    file=os.path.join(root, name)
                    if file.endswith(".apk"):
                        apkList.append(re.sub(self.workspace,"",file))
                    elif file.endswith(".so"):
                        libList.append(re.sub(self.workspace,"",file))
                    elif (file.endswith(".xml") or file.endswith(".conf")) and "SY_NetworkService" not in file:
                        etcList.append(re.sub(self.workspace,"",file))
                    elif "." not in file.split("/")[-1] or ".sh" in file.split("/")[-1]:
                        binList.append(re.sub(self.workspace,"",file))
        else:
            with open(self.mkFile,"r") as f:
                mkFileList=f.readlines()			
            for element in mkFileList:
                if pattern1 in element:
                    bin=element.split(":")[0].strip()
                    binList.append(bin)
                elif pattern2 in element:
                    apk=element.split(":")[0].strip()
                    apkList.append(apk)
                elif pattern3 in element:
                    etc=element.split(":")[0].strip()
                    etcList.append(etc)
                elif pattern4 in element:
                    lib=element.split(":")[0].strip()
                    libList.append(lib)						
        #log.warn(apkList)
        #log.warn(binList)
        #log.warn(etcList)
        #log.warn(libList)
				
        for element in apkList:
            maxApkLen=maxApkLen if (maxApkLen >= len(element.split("/")[-1]))else len(element.split("/")[-1])

        for element in binList:
            maxBinLen=maxBinLen if (maxBinLen >= len(element.split("/")[-1]))else len(element.split("/")[-1])

        for element in etcList:
            maxEtcLen=maxEtcLen if (maxEtcLen >= len(element.split("/")[-1]))else len(element.split("/")[-1])
			
        for element in libList:
            maxLibLen=maxLibLen if (maxLibLen >= len(element.split("/")[-1]))else len(element.split("/")[-1])


        for i,element in enumerate(apkList):
            apki=self.workspace+element
            apkx=element.split("/")[-1]
            md5_apk=os.popen("md5sum %s"%apki).read().split("  ")[0]+"\n"
            apkList[i]="    "+apkx+" "*(maxApkLen-len(apkx))+" : "+md5_apk
            self.get_property_dict(apki,md5_apk[:-1],"apk")

        for i,element in enumerate(binList):
            bini=self.workspace+element
            md5_bin=os.popen("md5sum %s"%bini).read().split("  ")[0]+"\n"
            binList[i]="    "+element.split("/")[-1]+" "*(maxBinLen-len(element.split("/")[-1]))+" : "+md5_bin
            self.get_property_dict(bini,md5_bin[:-1],"bin")

        for i,element in enumerate(etcList):
            etci=self.workspace+element
            md5_etc=os.popen("md5sum %s"%etci).read().split("  ")[0]+"\n"
            etcList[i]="    "+element.split("/")[-1]+" "*(maxEtcLen-len(element.split("/")[-1]))+" : "+md5_etc
            self.get_property_dict(etci,md5_etc[:-1],"etc")
			
        for i,element in enumerate(libList):
            libi=self.workspace+element
            md5_lib=os.popen("md5sum %s"%libi).read().split("  ")[0]+"\n"
            libList[i]="    "+element.split("/")[-1]+" "*(maxLibLen-len(element.split("/")[-1]))+" : "+md5_lib
            self.get_property_dict(libi,md5_lib[:-1],"lib")
        

        with open(self.propertyFullDir+"{}.txt".format(self.swVersion),"w") as f1:
            f1.write("APK:\n")
            f1.writelines(apkList)
            
            f1.write("Bin:\n")
            f1.writelines(binList)

            f1.write("Etc:\n")
            f1.writelines(etcList)
			
            f1.write("Libs:\n")
            f1.writelines(libList)

        log.warn("Have Wriet File:{}\n".format(self.propertyFullDir+"{}.txt".format(self.swVersion))) 

        log.warn("self.property_dict={}".format(self.property_dict))		
        property_boj=json.dumps(self.property_dict,indent=4,ensure_ascii=False)
        with open(self.propertyFullDir+"{}.json".format(self.swVersion),"w") as f2:
            f2.write(property_boj)
        log.warn("Have Wriet File:{}\n".format(self.propertyFullDir+"{}.json".format(self.swVersion)))			
			
    def getPropertyDiff(self):
        fileList=self.getFileTypeList()
        fileList.sort()
        log.warn("\nInput file in list:{}\n".format(fileList))
        indexSwVersion=fileList.index(self.swVersion+".txt")

        if self.swVersion+".txt" not in fileList:
            log.error("****Error:{}.txt not exist,please recheck!!:Error****".format(self.swVersion))
            return False
        elif indexSwVersion == 0:
            diFile=self.propertyFullDir+self.swVersion+".txt"
            log.warn("This is the first version: {}".format(diFile))
            cmd="cp {} {}".format(diFile,self.propertyOtaDir)
            os.popen(cmd)
            self.diffFile=self.propertyOtaDir+self.swVersion+".txt"
        else:
            self.diffFile=self.propertyOtaDir+fileList[indexSwVersion-1][:-4]+"_"+self.swVersion+".txt"
            self.writeDiffFile(self.swVersion,fileList[indexSwVersion-1][:-4])
        log.warn("self.diffFile={}".format(self.diffFile))



class GetImgInput(GetInput):
    def __init__(self):
        super(GetImgInput,self).__init__()
        if self.launcher == "nolauncher":
            self.iptvDir=os.environ["HOME"]+"/workspace/device/rockchip/rksdk/IPTV/IPTV_"+self.carrier+self.province
        else:
            self.iptvDir=os.environ["HOME"]+"/workspace/device/rockchip/rksdk/IPTV/IPTV_{}{}_{}".format(self.carrier,self.province,self.launcher)
        self.propertyFullDir=os.environ["HOME"]+"/build/property/full/"
        self.propertyOtaDir=os.environ["HOME"]+"/build/property/ota/"
        self.suyingMk=self.iptvDir+"/suying.mk"

        if not os.path.exists(self.propertyFullDir):
            os.popen("mkdir -p %s"%self.propertyFullDir).read()
        if not os.path.exists(self.propertyOtaDir):
            os.popen("mkdir -p %s"%self.propertyOtaDir).read()

        self.diffFile=""
 
    def get_property_dict(self,_file,_md5,_type):
        filex=_file
        md5x=_md5
        typex=_type
        apk_package=""
        os.chdir(self.iptvDir)
        if typex == "apk":
            papk_ret=os.popen("{} {}".format(self.papk,filex)).read()
            if not papk_ret:
                log.error("****Error:aapt return false,please recheck {}:Error****".format(filex))
                sys.exit()
            apk_package=papk_ret.split("'")[1]
            self.property_dict["{}".format(apk_package+"_"+typex)]=(filex,md5x)
        else:
            self.property_dict["{}".format("pass"+"_"+filex+"_"+typex)]=(filex,md5x)
 
    def getInputFull(self):
        mkFileList=[]
        apkList=[]
        binList=[]
        etcList=[]
        klList=[]
        libList=[]
        maxApkLen=0
        maxBinLen=0
        maxEtcLen=0
        maxKlLen=0
        maxLibLen=0
        if self.launcher == "nolauncher":
            pattern1="device/rockchip/rksdk/IPTV/IPTV_"+self.carrier+self.province+"/bin"
            pattern2="device/rockchip/rksdk/IPTV/IPTV_"+self.carrier+self.province+"/etc"
            pattern3="system/usr/keylayout/"
            pattern4="device/rockchip/rksdk/IPTV/IPTV_{}{}/libs".format(self.carrier,self.province)
        else:
            pattern1="device/rockchip/rksdk/IPTV/IPTV_{}{}_{}/bin".format(self.carrier,self.province,self.launcher)
            pattern2="device/rockchip/rksdk/IPTV/IPTV_{}{}_{}/etc".format(self.carrier,self.province,self.launcher)
            pattern3="system/usr/keylayout/"
            pattern4="device/rockchip/rksdk/IPTV/IPTV_{}{}_{}/libs".format(self.carrier,self.province,self.launcher)
        log.warn(pattern1)
        log.warn(pattern2)
        log.warn(pattern3)
        log.warn(pattern4)
        apkLine=0
        with open(self.suyingMk,"r") as f:
            mkFileList=f.readlines()

        for element in mkFileList:
            if "PRODUCT_PACKAGES" in element:
                apkLine=mkFileList.index(element)+1
                log.warn("element={}".format(element))
                log.warn("apkLine={}".format(apkLine))

        for i,element in enumerate(mkFileList):
            if i >= apkLine and len(element) > 2:
                apkx=element.strip().split(" ")[0]
                log.warn("apkx={}".format(apkx))
                ret=os.path.exists(self.iptvDir+"/"+apkx+".apk")
                if ret:
                    apkList.append(apkx)
            elif "system/app/" in element:
                apkx=element.split(":")[0].split("/")[-1][:-4]
                ret=os.path.exists(self.iptvDir+"/"+apkx+".apk")
                if ret:
                    apkList.append(apkx)

        log.warn("Apk List:{}\n".format(apkList))
        for element in mkFileList:
            if pattern1 in element:
                binFile=element.split(":")[0].split("/")[-1]
                if binFile not in binList:
                    binList.append(element.split(":")[0].split("/")[-1])
        log.warn("Bin List:{}\n".format(binList))
        for element in mkFileList:
            if pattern2 in element:
                etcFile=element.split(":")[0].split("/")[-1]
                if etcFile not in etcList:
                    etcList.append(element.split(":")[0].split("/")[-1])
        log.warn("Etc List:{}\n".format(etcList))
        for element in mkFileList:
            if pattern3 in element:
                klFile=element.split(":")[0].split("/")[-1]
                if klFile not in klList:
                    klList.append(element.split(":")[0].split("/")[-1])
        log.warn("Kl List:{}\n".format(klList))
        for element in mkFileList:
            if pattern4 in element:
                libFile=element.split(":")[0].split("/")[-1]
                if libFile not in libList:
                    libList.append(element.split(":")[0].split("/")[-1])
        log.warn("Libs List:{}\n".format(libList))

        for element in apkList:
            maxApkLen=maxApkLen if (maxApkLen >= len(element))else len(element)

        for element in binList:
            maxBinLen=maxBinLen if (maxBinLen >= len(element))else len(element)

        for element in etcList:
            maxEtcLen=maxEtcLen if (maxEtcLen >= len(element))else len(element)

        for element in klList:
            maxKlLen=maxApkLen if (maxKlLen >= len(element))else len(element)
			
        for element in libList:
            maxLibLen=maxLibLen if (maxLibLen >= len(element))else len(element)


        for i,element in enumerate(apkList):
            apki=self.iptvDir+"/"+element+".apk"
            apkx=element+".apk"
            md5_apk=os.popen("md5sum %s"%apki).read().split("  ")[0]+"\n"
            apkList[i]="    "+apkx+" "*(maxApkLen-len(element))+" : "+md5_apk
            self.get_property_dict(apkx,md5_apk[:-1],"apk")
			
        for i,element in enumerate(binList):
            bini=self.iptvDir+"/bin/"+element
            md5_bin=os.popen("md5sum %s"%bini).read().split("  ")[0]+"\n"
            binList[i]="    "+element+" "*(maxBinLen-len(element))+" : "+md5_bin
            self.get_property_dict(element,md5_bin[:-1],"bin")

        for i,element in enumerate(etcList):
            etci=self.iptvDir+"/etc/"+element
            md5_etc=os.popen("md5sum %s"%etci).read().split("  ")[0]+"\n"
            etcList[i]="    "+element+" "*(maxEtcLen-len(element))+" : "+md5_etc
            self.get_property_dict(element,md5_etc[:-1],"etc")           

        for i,element in enumerate(klList):
            kli=self.iptvDir+"/"+element
            md5_kl=os.popen("md5sum %s"%kli).read().split("  ")[0]+"\n"
            klList[i]="    "+element+" "*(maxKlLen-len(element))+" : "+md5_kl
            self.get_property_dict(element,md5_kl[:-1],"kl")

        for i,element in enumerate(libList):
            libli=self.iptvDir+"/libs/"+element
            md5_lib=os.popen("md5sum %s"%libli).read().split("  ")[0]+"\n"
            libList[i]="    "+element+" "*(maxLibLen-len(element))+" : "+md5_lib
            self.get_property_dict(element,md5_lib[:-1],"lib") 			
        

        with open(self.propertyFullDir+"{}.txt".format(self.swVersion),"w") as f1:
            f1.write("APK:\n")
            f1.writelines(apkList)
            
            f1.write("Bin:\n")
            f1.writelines(binList)

            f1.write("Etc:\n")
            f1.writelines(etcList)

            f1.write("Kl:\n")
            f1.writelines(klList)
			
            f1.write("Libs:\n")
            f1.writelines(libList)
        log.warn("Have Wriet File:{}\n".format(self.propertyFullDir+"{}.txt".format(self.swVersion)))

        log.warn("self.property_dict={}".format(self.property_dict))		
        property_boj=json.dumps(self.property_dict,indent=4,ensure_ascii=False)
        with open(self.propertyFullDir+"{}.json".format(self.swVersion),"w") as f2:
            f2.write(property_boj)
        log.warn("Have Wriet File:{}\n".format(self.propertyFullDir+"{}.json".format(self.swVersion)))

    def getPropertyDiff(self):
        fileList=self.getFileTypeList()
        fileList.sort()
        log.warn("\nInput file in list:{}\n".format(fileList))
        indexSwVersion=fileList.index(self.swVersion+".txt")

        if self.swVersion+".txt" not in fileList:
            log.error("****Error:{}.txt not exist,please recheck!!:Error****".format(self.swVersion))
            return False
        elif indexSwVersion == 0:
            diFile=self.propertyFullDir+self.swVersion+".txt"
            log.warn("This is the first version: {}".format(diFile))
            cmd="cp {} {}".format(diFile,self.propertyOtaDir)
            os.popen(cmd)
        else:
            self.diffFile=self.propertyOtaDir+fileList[indexSwVersion-1][:-4]+"_"+self.swVersion+".txt"
            self.writeDiffFile(self.swVersion,fileList[indexSwVersion-1][:-4])
                        
             

if __name__=="__main__":
    rkType=["3228b","3228h"]
    amlType=["s905l","s905lv2","s905l2","s905l3"]
    if sys.argv[1] in rkType:
        gbp=GetImgInput()
    elif sys.argv[1] in amlType:
        gbp=GetAmlImgInput()		
    mcd=MakeCommitDiff()

    fileTypeList=gbp.getFileTypeList()
    log.warn("fileTypeList={}".format(str(fileTypeList)))


    miniver=int(sys.argv[4].split(".")[-1])
    majver=int(sys.argv[4].split(".")[-2])
    input_ver=majver*100+miniver
    log.warn("input_ver={}".format(input_ver))	
    #not first version	
    if len(fileTypeList) > 0 and miniver < 80:	
        #remove tmp version
        for item in fileTypeList:
            tmp_ver=int(item[:-4].split(".")[-1])
            if tmp_ver >= 80:
                fileTypeList.remove(item)
        #claculate old version and input version
        latest_version=sorted(fileTypeList)[-1][:-4]
        old_miniver=int(latest_version.split(".")[-1])
        old_majver=int(latest_version.split(".")[-2])
        old_input_ver=old_majver*100+old_miniver
        log.warn("old_input_ver={}".format(old_input_ver))		
	
        #judge if you input is the latest
        #if input_ver >= old_input_ver:
        if True:
            gbp.getInputFull()
            ret1=gbp.getPropertyDiff()
            ret2=mcd.get_result(gbp.diffFile)
            print ret1 and ret2
        else:
            log.error("Input softversion not the latest,do nothing.")
    #first Version
    elif len(fileTypeList) == 0 and miniver < 80:
        gbp.getInputFull()
        ret1=gbp.getPropertyDiff()
        ret2=mcd.get_result(gbp.diffFile)
        print ret1 and ret2
    else:
        log.error("Input softversion is tmp version,do nothing.")

#python makeDiffFile.py 3228h cuhl huawei S-010W-AV2S_SW_C_ZY_CUHL_HUAWEI_R1.00.07




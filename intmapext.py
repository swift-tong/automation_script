
import sys
import datetime
import re
import types 
import pexpect
import os
import subprocess
import logging
#-*- coding: UTF-8 -*-
#define the global accepted chip related tuple list
ChipTuple = (
    ('RK3228B','RTL8189ETV'),
    ('RK3228B','MTK7526FU'),
    ('S905L','RTL8676'),
    ('RK3228H','NOWIFI'),
    ('RK3228H','8189FTV'),
    ('RK3228H','EN7526FD'),
    ('S905L','NOWIFI'),
    ('S905L','RTL8822BS'),
    ('S905L3','RTL8822BS'),
    ('S905L2','RTL8822BS'),
    ('RK3228H','RTL8822BS'),
    )
    
AcTuple = ('RTL8822BS','EN7526G')
BgnTuple = ('RTL8189ETV','RTL8189FTV','RTL8676','MTK7526FU','8189FTV','EN7526FD','NOWIFI')
    
IntVerDict = {
    ('RK3228B','RTL8189ETV') : 'A',
    ('RK3228B','MTK7526FU') : 'A',           
    ('S905L','RTL8676') : 'B',
    ('RK3228H','NOWIFI') : 'C',
    ('RK3228H','8189FTV') : 'D',
    ('RK3228H','EN7526FD') : 'D',
    ('RK3228H','RTL8822BS') : 'E',
    ('S905L','NOWIFI') : 'F',
    ('S905L3','RTL8676') : 'G',
    ('S905L3','RTL8822BS') : 'H',
}
 
IntToExtDict = {
    #S-010W-A
    #china telecom
    #ctnx
    ('S-010W-A',('RK3228B','RTL8189ETV'),'zy','nolauncher','ctnx'): 'A',
    #ctgd
    ('S-010W-A',('S905L','RTL8189ETV'),'zy','nolauncher','ctgd'): 'A',
    #ctln
    ('S-010W-A',('RK3228B','RTL8189ETV'),'zy','nolauncher','ctln'): 'A',
    ('S-010W-A',('RK3228B','RTL8189ETV'),'zy','nolauncher','cthn'): 'A',
    ('S-010W-A',('RK3228B','RTL8189ETV'),'nsb','nolauncher','ctln'): 'B',
    #china unicom
    #cuxj
    ('S-010W-A',('RK3228B','RTL8189ETV'),'zy','nolauncher','cuxj'): 'A',
    #cuhl
    ('S-010W-A',('RK3228B','RTL8189ETV'),'zy','nolauncher','cuhl'): 'A',
    ('S-010W-A',('RK3228B','RTL8189ETV'),'zy','huawei','cuhl'): 'B',
    ('S-010W-A',('RK3228B','RTL8189ETV'),'zy','fenghuo','cuhl'): 'C',
    #cusd
    ('S-010W-A',('RK3228B','RTL8189ETV'),'zy','nolauncher','cusd'): 'A',
    ('S-010W-A',('RK3228B','RTL8189ETV'),'zy','newline','cusd'): 'A',
    #cujs
    ('S-010W-A',('RK3228B','RTL8189ETV'),'zy','fenghuo','cujs'): 'A',
    #cuhn
    ('S-010W-A',('RK3228B','RTL8189ETV'),'zy','nolauncher','cuhn'): 'A',
    ('S-010W-A',('RK3228B','RTL8189ETV'),'zy','huawei','cuhn'): 'A',
    ('S-010W-A',('RK3228B','RTL8189ETV'),'zy','zhongxing','cuhn'): 'A',
    ('S-010W-A',('RK3228B','RTL8189ETV'),'zy','yaxin','cuhn'): 'A',
    #culn
    ('S-010W-A',('RK3228B','RTL8189ETV'),'zy','nolauncher','culn'): 'A',
    #cuhe
    ('S-010W-A',('RK3228B','RTL8189ETV'),'zy','nolauncher','cuhe'): 'A', 	
    #cugd
    ('S-010W-A',('RK3228B','RTL8189ETV'),'zy','nolauncher','cugd'): 'A',    
    #cusc
    ('S-010W-A',('RK3228B','RTL8189ETV'),'zy','nolauncher','cusc'): 'A',  
    #china mobile
    #cmsh
    ('S-010W-A',('S905L','RTL8189ETV'),'zy','bestv','cmsh'): 'A',
    ('S-010W-A',('S905L','RTL8189ETV'),'zy','washu','cmsh'): 'B',
    ('S-010W-AV2A-1',('S905L2','RTL8822BS'),'zy','washu','cmsh'): 'A',
    ('S-010W-AV2A-2',('S905L2','RTL8822BS'),'zy','bestv','cmsh'): 'A',
    #cmfj
    ('S-010W-A',('RK3228B','RTL8189ETV'),'zy','nolauncher','cmfj'): 'A',
    #S-010W-P
    #china unicom
    #cuhq
    ('S-010W-P',('S905L','AP6356S'),'zy','nolauncher','cuhq'): 'A',
    #G-120WT-P
    #china telecom
    #ctnx
    ('G-120WT-P',('RK3228B','MTK7526FU'),'zy','nolauncher','ctnx'): 'A',
    #ctlz
    ('G-120WT-P',('RK3228B','MTK7526FU'),'zy','nolauncher','ctlz'): 'A',
    #cthn
    ('G-120WT-P',('RK3228B','MTK7526FU'),'zy','nolauncher','cthn'): 'A',
    #ctxj
    ('G-120WT-P',('RK3228B','MTK7526FU'),'zy','nolauncher','ctxj'): 'A',
    #ctln
    ('G-120WT-P',('RK3228B','MTK7526FU'),'zy','nolauncher','ctln'): 'A',
    #zsqd
    ('G-120WT-P',('RK3228B','MTK7526FU'),'zy','nolauncher','zsqd'): 'A',
    #ctjs
    ('G-120WT-P',('RK3228B','MTK7526FU'),'zy','nolauncher','ctjs'): 'A',
    #ctzj
    ('G-120WT-P',('RK3228B','MTK7526FU'),'zy','nolauncher','ctzj'): 'A',
    #ctgs
    ('G-120WT-P',('RK3228B','MTK7526FU'),'zy','nolauncher','ctgs'): 'A',
    #ctah
    ('G-120WT-P',('RK3228B','MTK7526FU'),'zy','nolauncher','ctah'): 'A',
    #ctsx
    ('G-120WT-P',('RK3228B','MTK7526FU'),'zy','nolauncher','ctsx'): 'A',
    #ctjl
    ('G-120WT-P',('RK3228B','MTK7526FU'),'zy','nolauncher','ctjl'): 'A',
    #ossm
    ('G-120WT-P',('RK3228B','MTK7526FU'),'zy','nolauncher','ossm'): 'A',
    #ctnm
    ('G-120WT-P',('RK3228B','MTK7526FU'),'zy','normal','ctnm'): 'A',
    ('G-120WT-P',('RK3228B','MTK7526FU'),'zy','industry','ctnm'): 'A',
    #ctgx
    ('G-120WT-P',('RK3228B','MTK7526FU'),'zy','nolauncher','ctgx'): 'A',
    #china unicom
    #cuhl
    ('G-120WT-P',('RK3228B','MTK7526FU'),'zy','nolauncher','cuhl'): 'A',
    ('G-120WT-P',('RK3228B','MTK7526FU'),'zy','huawei','cuhl'): 'B',
    ('G-120WT-P',('RK3228B','MTK7526FU'),'zy','fenghuo','cuhl'): 'C',
    #cusd
    ('G-120WT-P',('RK3228B','MTK7526FU'),'zy','nolauncher','cusd'): 'A',
    #cuhe
    ('G-120WT-P',('RK3228B','MTK7526FU'),'zy','nolauncher','cuhe'): 'A',
    #culn
    ('G-120WT-P',('RK3228B','MTK7526FU'),'zy','nolauncher','culn'): 'A',
    #cusx
    ('G-120WT-P',('RK3228B','MTK7526FU'),'zy','nolauncher','cusx'): 'A',
    #cunm
    ('G-120WT-P',('RK3228B','MTK7526FU'),'zy','nolauncher','cunm'): 'A',
    #cuah
    ('G-120WT-P',('RK3228B','MTK7526FU'),'zy','nolauncher','cuah'): 'A',
    #China Mobile
    #cmsc
    ('G-120WT-P',('RK3228B','MTK7526FU'),'zy','nolauncher','cmsc'): 'A',
    #cmfj
    ('G-120WT-P',('RK3228B','MTK7526FU'),'zy','nolauncher','cmfj'): 'A',
    #cmha
    ('G-120WT-P',('RK3228B','MTK7526FU'),'zy','nolauncher','cmha'): 'A',
    #cmha CMIOT-EG-G12, Totally same as G-120WT-P for another vendor
    ('CMIOT-EG-G12',('RK3228B','MTK7526FU'),'zy','nolauncher','cmha'): 'A',
    #cmhn
    ('G-120WT-P',('RK3228B','MTK7526FU'),'zy','nolauncher','cmhn'): 'A',
    #S-010-AV2S
    #China Unicom
    #cujl
    ('S-010W-AV2S',('RK3228H','NOWIFI'),'zy','huawei','cujl'): 'A',
    #cujl
    ('S-010W-AV2S',('RK3228H','NOWIFI'),'zy','zhongxing','cujl'): 'B',
    #cuah
    ('S-010W-AV2S',('RK3228H','NOWIFI'),'zy','nolauncher','cuah'): 'A',
    #cuhe
    ('S-010W-AV2S',('RK3228H','NOWIFI'),'zy','nolauncher','cuhe'): 'A',
    #cuha
    ('S-010W-AV2S',('RK3228H','NOWIFI'),'zy','nolauncher','cuha'): 'A',
    #cujc
    ('S-010W-AV2S',('RK3228H','NOWIFI'),'zy','nolauncher','cujc'): 'A',
    #cufj
    ('S-010W-AV2S',('RK3228H','NOWIFI'),'zy','nolauncher','cufj'): 'A',
    #cuhl
    ('S-010W-AV2S',('RK3228H','NOWIFI'),'zy','nolauncher','cuhl'): 'A',
    ('S-010W-AV2S',('RK3228H','NOWIFI'),'zy','huawei','cuhl'): 'B',
    ('S-010W-AV2S',('RK3228H','NOWIFI'),'zy','fenghuo','cuhl'): 'C',
    #cusx
    ('S-010W-AV2S',('RK3228H','NOWIFI'),'zy','nolauncher','cusx'): 'A',
    #cutj
    ('S-010W-AV2S',('RK3228H','NOWIFI'),'zy','nolauncher','cutj'): 'A',
    #cuhi
    ('S-010W-AV2S',('RK3228H','NOWIFI'),'zy','nolauncher','cuhi'): 'A',
    #cuhl
    ('S-010W-AV2S',('RK3228H','NOWIFI'),'zy','nolauncher','cuhl'): 'A',
    #cunm
    ('S-010W-AV2S',('RK3228H','NOWIFI'),'zy','huawei','cunm'): 'A',
    ('S-010W-AV2S',('RK3228H','NOWIFI'),'zy','fenghuo','cunm'): 'A',
    #S-010W-AV2B
    #China Unicom
    #cuhn
    ('S-010W-AV2B',('RK3228H','8189FTV'),'zy','nolauncher','cuhn'): 'A',
    #cuqd
    ('S-010W-AQD',('RK3228H','8189FTV'),'zy','nolauncher','cuqd'): 'A',
    #cujs
    ('S-010W-AV2B',('RK3228H','8189FTV'),'zy','nolauncher','cujs'): 'A',
    #cubj
    ('S-010W-A',('RK3228H','8189FTV'),'zy','nolauncher','cubj'): 'A',
    #cubj
    ('S-010W-A',('RK3228H','8189FTV'),'zy','newline','cubj'): 'A',
    #cubj
    ('S-010W-AV2B',('RK3228H','8189FTV'),'zy','nolauncher','cubj'): 'A',
    #cuqd
    ('S-010W-AV2B',('RK3228H','8189FTV'),'zy','nolauncher','cuqd'): 'A',
    #cujx
    ('S-010W-AV2B',('RK3228H','8189FTV'),'zy','nolauncher','cujx'): 'A',
    #cusd
    ('S-010W-AV2B',('RK3228H','8189FTV'),'zy','nolauncher','cusd'): 'A',
    #S-010W-AV2C
    #cusc
    ('S-010W-A',('RK3228H','8189FTV'),'zy','nolauncher','cusc'): 'C',
    #cusd
    ('S-010W-AV2C',('RK3228H','8189FTV'),'zy','nolauncher','cusd'): 'A',	
    #oversea
    #singmeng
    ('S-010W-AV2B',('RK3228H','8189FTV'),'zy','nolauncher','ossm'): 'A',
    ('S-010W-AV2B',('RK3228H','8189FTV'),'zy','normal','ossm'): 'A',
    ('S-010W-AV2B',('RK3228H','8189FTV'),'zy','hotel','ossm'): 'A',	
    #RG020ET-CA
    #China Telecom
    #ctgd
    # rename to SBELL_RG020ETCA
    ('NSB_RG020ETCA',('S905L','RTL8676'),'zy','nolauncher','ctgd'): 'A',
    ('RG020ET-CA',('S905L','RTL8676'),'zy','nolauncher','ctln'): 'A',
    #ctah
    ('RG020ET-CA',('S905L','RTL8676'),'zy','nolauncher','ctah'): 'A',
    #cthn
    ('RG020ET-CA',('S905L','RTL8676'),'zy','nolauncher','cthn'): 'A',
    #cthb
    ('RG020ET-CA',('S905L','RTL8676'),'zy','nolauncher','cthb'): 'A',
    #ctgx
    ('RG020ET-CA',('S905L','RTL8676'),'zy','nolauncher','ctgx'): 'A',
    #ctjs
    ('RG020ET-CA',('S905L','RTL8676'),'zy','nolauncher','ctjs'): 'A',
    #ctsx
    ('RG020ET-CA',('S905L','RTL8676'),'zy','nolauncher','ctsx'): 'A',
    #cthe
    ('RG020ET-CA',('S905L','RTL8676'),'zy','nolauncher','cthe'): 'A',
    #ctjl
    ('RG020ET-CA',('S905L','RTL8676'),'zy','nolauncher','ctjl'): 'A',
    #ctgs
    ('RG020ET-CA',('S905L','RTL8676'),'zy','nolauncher','ctgs'): 'A',
    # China Mobile
    # cmhn
    ('RG020ET-CA',('S905L','RTL8676'),'zy','nolauncher','cmhn'): 'A',
    # cmha
    ('RG020ET-CA',('S905L','RTL8676'),'zy','nolauncher','cmha'): 'A',
    # cmha CMIOT-EG-G12, Totally same as RG020ET-CA for another vendor
    ('CMIOT-EG-E02',('S905L','RTL8676'),'zy','nolauncher','cmha'): 'A',    
    #china unicom
    #cuhl
    ('RG020ET-CA',('S905L','RTL8676'),'zy','huawei','cuhl'): 'A',
    ('RG020ET-CA',('S905L','RTL8676'),'zy','fenghuo','cuhl'): 'B',
    #cuqd
    ('RG020ET-CA',('S905L','RTL8676'),'zy','nolauncher','cuqd'): 'A',
    #cugd
    ('RG020ET-CA',('S905L','RTL8676'),'zy','nolauncher','cugd'): 'A',
    #cuah
    ('RG020ET-CA',('S905L','RTL8676'),'zy','nolauncher','cuah'): 'A',
    #cusd
    ('RG020ET-CA',('S905L','RTL8676'),'zy','nolauncher','cusd'): 'A',
	#cusx
    ('RG020ET-CA',('S905L','RTL8676'),'zy','nolauncher','cusx'): 'A',
    #cunm
    ('RG020ET-CA',('S905L','RTL8676'),'zy','nolauncher','cunm'): 'A',
    #cusd
    ('RG020ET-CA',('S905L2','RTL8822BS'),'zy','nolauncher','cusd'): 'A',
    #cusd
    ('RG020ET-CA',('S905L3','RTL8676'),'zy','nolauncher','cusd'): 'A',
    #cthq
    ('RG020ET-CA',('S905L3','RTL8676'),'zy','nolauncher','cthq'): 'A',
    ('RG020ET-CA',('S905L3','RTL8676'),'zy','gaoan','cthq'): 'B',
    #cuqd
    ('RG020ET-CA',('S905L2','RTL8822BS'),'zy','nolauncher','cuqd'): 'A',
    #cujs
    ('RG020ET-CA',('S905L','RTL8676'),'zy','nolauncher','cujs'): 'A',
    #ossm
    ('RG020ET-CA',('S905L','RTL8676'),'zy','nolauncher','ctossm'): 'A',
    #cujc
    ('S-010W-AV2A',('S905L2','RTL8822BS'),'zy','nolauncher','cujc'): 'A',
    #G-120WT-Q
    #china unicom
    #cusx
    ('G-120WT-Q',('RK3228H','EN7526FD'),'zy','nolauncher','cusx'): 'A',
    #S-010W-AV2
    #china unicom
    #cuhn
    ('S-010W-AV2',('RK3228H','RTL8822BS'),'zy','nolauncher','cuhn'): 'A',
    #S-010W-AV2A
    #china telecom
    #ctjc
    ('S-010W-AV2A',('S905L3','RTL8822BS'),'zy','nolauncher','ctjc'): 'A',
    ('S-010W-AV2A',('S905L3','RTL8822BS'),'zy','gaoan','ctjc'): 'B',	
    ('S-010W-AV2D',('S905L2','RTL8822BS'),'zy','nolauncher','ctjc'): 'A'
    }


def Today():   
    today =datetime.date.today()
    # format
    ISOFORMAT='%Y%m%d'
    return today.strftime(ISOFORMAT)  

def NowTime(province):
    if province[2:] == "ah":
        nowTime=datetime.datetime.now()
        formatTime=nowTime.strftime('%Y%m%d_%H%M')
    else:
        nowTime=datetime.datetime.now()
        formatTime=nowTime.strftime('%Y%m%d.%H%M')
    return  formatTime
	
class HardWareInfo(object):
    def __init__(self,chiptype,wifigroup):
        self.chiptype=chiptype
        self.wifigroup=wifigroup
    
    def isChipValid(self):
        tt=(self.chiptype,self.wifigroup)
        if tt in ChipTuple:
            return True
        else:
            return False


#class InternalInput(object):
class InternalInput(HardWareInfo):
    def __init__(self,product,chiptype,wifigroup,middleware,launchername,province):
        super(HardWareInfo,self).__init__()
        self.product=product
        self.chiptype=chiptype
        self.wifigroup=wifigroup
        self.middleware=middleware
        self.launchername=launchername
        self.province=province
        #self.majversion=majversion
        #self.minorversion=minorversion
        
    def handleInput(self):
        #first check hardware combination
        if not self.isChipValid():
            print "hwerror"
            sys.exit()
        dictkey=(self.product,(self.chiptype,self.wifigroup),self.middleware,self.launchername,self.province)
        if dictkey in IntToExtDict.keys():
            retvalue=IntToExtDict[dictkey]
            print retvalue
            sys.exit()
        else:
            print "nokey"
            sys.exit()
    
    def testInput(self):
        if not self.isChipValid():
            print "hwerror"
            sys.exit()
        dictkey=(self.product,(self.chiptype,self.wifigroup),self.middleware,self.launchername,self.province)
        if dictkey in IntToExtDict.keys():
            print "find"+ str(dictkey)
            retvalue=IntToExtDict[dictkey]
            print "find value is : " + retvalue
            
class IntVerInput(object):
    def __init__(self,chiptype,wifigroup):
        self.chiptype=chiptype
        self.wifigroup=wifigroup
 
    def isChipValid(self):
        tt=(self.chiptype,self.wifigroup)
        if tt in ChipTuple:
            return True
        else:
            return False
    
    def handleInput(self):
        #first check hardware combination
        if not self.isChipValid():
            print "hwerror"
            sys.exit()
        dictkey=(self.chiptype,self.wifigroup)
        if dictkey in IntVerDict.keys():
            retvalue=IntVerDict[dictkey]
            print retvalue
            sys.exit()
        else:
            print "nokey"
            sys.exit()
                        
class GetVerStrInput(HardWareInfo):
    def __init__(self,product,chiptype,wifigroup,middleware,launchername,province,majversion,minorversion):
        super(HardWareInfo,self).__init__()
        #input part
        self.product=product
        self.chiptype=chiptype
        self.wifigroup=wifigroup
        self.middleware=middleware
        self.launchername=launchername
        self.province=province
        self.majversion=majversion
        self.minorversion=minorversion
        #output part
        self.extstr=""
        self.innerstr=""
        self.facstr=""
        self.vendorstr=""
        self.imgprefix=""
        self.oui=""
        self.displayid=""
        self.hwid=""
        self.versioncod="rightmajorversion"
        
    #this procedure is used to generate string like R1.01.01 blablabla
    def GenVersionString(self):
        #if self.province == "cmsc":
        superverstr=""
		
        if self.majversion < 10 :
            majverstr="0"+str(self.majversion)
        else:
            majverstr=str(self.majversion)
        if self.minorversion < 10 :
            minverstr="0"+str(self.minorversion)
        else:
            minverstr=str(self.minorversion)
        if self.launchername == "normal":
            superverstr = "R1"
        elif self.chiptype.lower() == "s905l3" and self.province == "ctjc":
            superverstr = "R3"
        elif self.launchername in ["industry","yaxin","hotel","newline","washu"]:
            superverstr = "R2"
        else:
            if self.product == "S-010W-AV2S" and self.province == "cunm":
                if self.launchername == "huawei":
                    superverstr="R1"
                elif self.launchername == "fenghuo":
                    superverstr="R2"
            elif self.product == "S-010W-AV2S" and self.province == "cujl":
                if self.launchername == "huawei":
                    superverstr="R1"
                elif self.launchername == "zhongxing":
                    superverstr="R2"
            else:
                superverstr = "R1"
        return superverstr+"."+majverstr+"."+minverstr
        
    #very special handling for CMCCSC, and later it is possible some OTT has its own special treatment !!!!.
    # NSBV001001P0001
    def GenCmScString(self):
        if self.majversion < 10 :
            majverstr="00"+str(self.majversion)
        else:
            majverstr="0"+str(self.majversion)
        if self.minorversion < 10 :
            minverstr="P000"+str(self.minorversion)
        else:
            minverstr="P00"+str(self.minorversion)
        return "NSBV001"+majverstr+minverstr
        
    #very special handling for CMCCHN, and later it is possible some OTT has its own special treatment !!!!.
    # DAPING_SBELL_G-120WT-P_CPUFrquency_HOTEL_20170208
    def GenCmHnString(self):
        return "DAPING_SBELL_"+self.product+"_1.5_"+"HOTEL_"+Today()
            
    #very special handling of CTSX (Lan Up?)
    # 990102301.1008000000.00100000001 (001 0000 0001 /R1.00.01) # Lan UP
    # 990102201.1008000000.00100000001 (001 0000 0001 /R1.00.01) # VideoOnt
    def GenCtSxString(self):
        if self.majversion < 10 :
            majverstr="000"+str(self.majversion)
        else:
            majverstr="00"+str(self.majversion)
        if self.minorversion < 10 :
            minverstr="000"+str(self.minorversion)
        elif self.minorversion < 100 :
            minverstr="00"+str(self.minorversion)
        elif self.minorversion < 1000 :
            minverstr="0"+str(self.minorversion)
        else:
            minverstr=str(self.minorversion)
        if self.product=="G-120WT-P":
            return "990102201.1008000000."+"001"+majverstr+minverstr
        else:
            "990102301.1008000000."+"001"+majverstr+minverstr
    
    def GenExtString(self):
        #first check hardware combination
        if not self.isChipValid():
            self.extstr="hwerror"
        dictkey=(self.product,(self.chiptype,self.wifigroup),self.middleware,self.launchername,self.province)
        if dictkey in IntToExtDict.keys():
            extver=IntToExtDict[dictkey]
            #print retvalue
            if self.province == "cmsc":
                self.extstr=self.GenCmScString()
            elif self.province == "cmhn":
                self.extstr=self.GenCmHnString()
            elif self.province == "cthn" and self.product== "S-010W-A":
                self.extstr="S-010W-A_SW_HN_A_R1.00.01"
            elif self.province == "cthb" and self.product== "RG020ET-CA":
                self.extstr="RG020ET-CA_SW_B_HB_R1.00.80"
            elif self.province == "cthn" and self.product== "G-120WT-P":
                self.extstr="G-120WT-P_SW_HN_A_R1.00.98"
            elif self.province == "ctgx" and self.product== "G-120WT-P" and self.majversion in (1,3):
                self.extstr="G-120WT-P_SW_GX_A_R1.00.08"
            elif self.province == "ctgx" and self.product== "G-120WT-P" and self.majversion == 2:
                self.extstr="G-120WT-P_SW_GX_A_R1.02.08"
            elif self.province == "ctgx" and self.product== "G-120WT-P" and self.majversion in (0,4):
                self.extstr="G-120WT-P_SW_GX_A_R1.04.08"
            elif self.province == "ctxj" and self.product== "G-120WT-P":
                self.extstr="G-120WT-P_SW_XJ_A_R1.00.01"
            elif self.province == "ctln" and self.product== "G-120WT-P":
                self.extstr="G-120WT-P_SW_LN_A_R1.01.08"
            elif self.province == "cthe" and self.product == "RG020ET-CA":
                self.extstr="RG020ET-CA_SW_HE_A_R1.00.00"
            elif self.province == "ctgx" and self.product == "RG020ET-CA" and self.majversion == 1:
                self.extstr="RG020ET-CA_SW_GX_A_R1.00.07"
            elif self.province == "ctgx" and self.product == "RG020ET-CA" and self.majversion == 2:
                self.extstr="RG020ET-CA_SW_GX_A_R1.02.07"
            elif self.province == "ctgx" and self.product == "RG020ET-CA" and self.majversion == 0:
                self.extstr="RG020ET-CA_SW_GX_A_R1.03.07"
            elif self.province == "cusd" and self.product == "G-120WT-P":
                self.extstr="NSBCUSD_A_R1.00.05"
            elif self.province == "cunm" and self.product == "S-010W-AV2S":
                if self.launchername == "huawei":
                    self.extstr="S-010W-AV2S_SW_NM_A_R1.00.21"
                if self.launchername == "fenghuo":
                    self.extstr="S-010W-AV2S_SW_NM_A_R2.00.11"
            elif self.province == "cuhl" and self.product== "S-010W-A":
                ver=self.GenVersionString()
                if self.launchername== "huawei":
                    self.extstr="S-010W-A_SW_HL_"+ver+"h"
                elif self.launchername== "fenghuo":
                    self.extstr="S-010W-A_SW_HL_"+ver+"f"
            elif self.province == "ctsx":
                self.extstr=self.GenCtSxString()  
            else:
                prov=self.province[2:]
                ver=self.GenVersionString()
                self.extstr=self.product.upper()+"_SW_"+prov.upper()+"_"+extver+"_"+ver;
        else:
            self.extstr="nokey"
        
    def GenInnerString(self):
        #first check hardware combination
        if not self.isChipValid():
            self.innerstr="hwerror"
            
        dictkey=(self.chiptype,self.wifigroup)
        if dictkey in IntVerDict.keys():
            intver=IntVerDict[dictkey]
            verstr=self.GenVersionString()
            if self.chiptype=="RK3228H" and self.product != "S-010W-AV2C":
                if self.province=="cubj" or self.province=="cusd" or self.province=="cujx":
                    innrproduct="S-010W-AV2B"
                elif self.province=="cusc":
                    innrproduct="S-010W-AV2C"                
                else:
                    innrproduct=self.product
            else:
                innrproduct=self.product

            if self.launchername=="nolauncher" or self.launchername=="newline":               
                retval=innrproduct.upper()+"_SW_"+intver.upper()+"_"+self.middleware.upper()+"_"+self.province.upper()+"_"+verstr
            else:
                retval=innrproduct.upper()+"_SW_"+intver.upper()+"_"+self.middleware.upper()+"_"+self.province.upper()+"_"+self.launchername.upper()+"_"+verstr
            self.innerstr=retval
        else:
            self.innerstr="nokey"

    def GenFacString(self):
        #first check hardware combination
        if not self.isChipValid():
            self.facstr="hwerror"
        dictkey=(self.chiptype,self.wifigroup)
        if dictkey in IntVerDict.keys():
            intver=IntVerDict[dictkey]
            verstr=self.GenVersionString()
            self.facstr=self.product.upper()+"_SW_"+intver.upper()+"_FAC_"+verstr
        else:
            self.facstr="nokey"
			
    def GenVendorString(self):
        #first check hardware combination
        if not self.isChipValid():
            self.vendorstr="hwerror"
        verstr=self.GenVersionString()
        self.vendorstr=self.product.upper()+"_SW_"+self.middleware.upper()+"_"+self.province.upper()+"_"+verstr

        
    def GenImgPfx(self):
        if self.province == "base":  #factory
            self.GenFacString()
            self.imgprefix=self.facstr
        elif self.province == "cmsc":  #CMCC Sichuan, imgprefix must be the same as external version
            self.GenExtString()
            self.imgprefix=self.extstr
        elif self.product.upper()=="S-010W-A" and self.province=="cubj":
            dictkey=(self.chiptype,self.wifigroup)
            if dictkey in IntVerDict.keys():
                intver=IntVerDict[dictkey]
                verstr=self.GenVersionString()
                self.imgprefix=self.product.upper()+"_SW_"+intver.upper()+"_"+self.middleware.upper()+"_"+self.province.upper()+"_"+verstr
            else:
                self.imgprefix="nokey"
        else:
            self.GenInnerString()
            self.imgprefix=self.innerstr

    def GenOui(self):
        if self.province[:2] == "cu" or self.province[:2] == "zs":
            if self.province == "cusd" or self.province == "cuqd" or self.province == "zsqd":
                self.oui="000020"
            elif self.province == "cunm":
                self.oui="000020"
            elif self.province == "cuhn" and self.chiptype in ["RK3228H","RK3228B"]:
                self.oui="430020"
            elif self.province == "cujc":
                self.oui="000000"
            elif self.province == "cubj":
                self.oui="000020"
            elif self.province == "cujs" and self.product in ["S-010W-AV2B","RG020ET-CA"]:
                self.oui="320020"
            elif (self.product == "G-120WT-P" and self.province == "cusx") or (self.product == "RG020ET-CA" and self.province == "cusx") or (self.product == "S-010W-AV2S" and self.province == "cusx"):
                self.oui = "140020"
            else:
                self.oui="0020"
        if self.province[:2] == "ct":
            self.oui="990080"
        if self.province[:2] == "cm":
            self.oui="0069"

    def GenDisplayId(self):
        time=NowTime(self.province)
        if self.province == "base":
            self.displayid=time+" int:"+self.product.upper()+"_"+self.middleware.upper()+"_FAC"
        elif self.province == "cmhn":
            self.GenExtString()
            hndisplay=self.extstr
            self.displayid=hndisplay
        elif self.province == "ctah":
            #self.displayid="NSB_"+self.product.upper()+"_"+time
            self.displayid="NSB_G-120WT-P_20170525_1004"
        else:
            if self.launchername == "nolauncher":
                self.displayid=time+" int:"+self.middleware.upper()+"_"+self.province.upper()
            else:
                if self.province == "ctnm": 
                    self.displayid=time+" int:"+self.middleware.upper()+"_"+self.province.upper()
                else:
                    self.displayid=time+" int:"+self.middleware.upper()+"_"+self.province.upper()+"_"+self.launchername
                
    #rule : ProductName_HW_Ra.bc.de
    #a : RTL : 01, AP6356S : 02
    #bc : RK  : 01, S905L : 02
    #de : 00
    def GenHwId(self):
        if self.wifigroup in AcTuple :
            a="2"
        elif self.wifigroup in BgnTuple :
            a="1"
        if self.chiptype == "RK3228B":
            bc="01"
        elif self.chiptype == "S905L":
            bc="02"
        elif self.chiptype == "RK3228H":
            bc="03"
        elif self.chiptype == "S905L2":
            bc="04"
        elif self.chiptype == "S905L3":
            bc="05"
            
        de="00"
        if self.province == "ctnx" or self.province == "cuxj":
            self.hwid="R"+a+"."+bc+"."+de
        elif self.product == "S-010W-A" and self.province == "cusd":
            self.hwid="S-010W-A_HW_R"+a+"."+bc+"."+de
        elif self.chiptype.lower() == "s905l3" and self.province == "ctjc":
            self.hwid="99008002L3B61803AVA10301"
        elif self.product == "S-010W-A" and self.chiptype == "RK3228H" and self.province == "cusc":
            self.hwid="S-010W-A_HW_R1.01.00"
        elif self.chiptype == "RK3228H" and self.province == "cusd":
            self.hwid="S-010W-AV2B"+"_HW_R"+a+"."+bc+"."+de
        elif self.product in ["S-010W-AV2A-1","S-010W-AV2A-2"] and self.province == "cmsh":
            self.hwid=self.product+"_HW_"+a+"."+bc+"."+de
        elif self.product == "S-010W-AV2A" and self.province == "cujc":
            self.hwid="1.01.01"
        elif self.chiptype == "S905L3" and self.product == "RG020ET-CA" and self.province == "cthq":
            self.hwid="99008002L3B61803AVA10301"
        else:
            self.hwid=self.product+"_HW_R"+a+"."+bc+"."+de
				
    def testInput(self):
        if not self.isChipValid():
            print "hwerror"
            sys.exit()
        dictkey=(self.product,(self.chiptype,self.wifigroup),self.middleware,self.launchername,self.province)
        if dictkey in IntToExtDict.keys():
            print "find"+ str(dictkey)
            retvalue=IntToExtDict[dictkey]
            print "find value is : " + retvalue
			
    def GenCheckMajorversion(self):
        if self.product == "S-010W-A" and self.province == "cuhn" and self.launchername == "huawei":
            if self.majversion != 2:
                self.versioncod = "wrongmajorversion"
            else:
                self.versioncod = "rightmajorversion"               
        if self.product == "S-010W-A" and self.province == "cuhn" and self.launchername == "zhongxing":
            if self.majversion != 1:
                self.versioncod = "wrongmajorversion"
            else:
                self.versioncod = "rightmajorversion"
        
        
    def GetInnerStr(self):
        self.GenInnerString()
        print self.innerstr
        
    def GetExtStr(self):
        self.GenExtString()
        print self.extstr
        
    def GetVendorStr(self):
        self.GenVendorString()
        print self.vendorstr
        
    def GetFacStr(self):
        self.GenFacString()
        print self.facstr
        
    def GetImgPfx(self):
        self.GenImgPfx()
        print self.imgprefix
		
    def GetOui(self):
        self.GenOui()
        print self.oui

    def GetDisplayId(self):
        self.GenDisplayId()
        print self.displayid
        
    def GetHwId(self):
        self.GenHwId()
        print self.hwid
		
    def CheckMajorversion(self):
        self.GenCheckMajorversion()
        print self.versioncod
		
def CheckInputParams(nbrofparam,argv):
    if len(argv) < nbrofparam:
        print "lessargs"
        sys.exit()
    if len(argv) > nbrofparam:
        print "2manyargs"
        sys.exit()		
		
def HandleGetExtVer(argv): 
    CheckInputParams(8,argv)    
    rawinput=InternalInput(argv[2],argv[3],argv[4],argv[5],argv[6],argv[7])
    rawinput.handleInput()

def HandleGetIntVer(argv):
    CheckInputParams(4,argv)
    rawinput=IntVerInput(argv[2],argv[3])
    rawinput.handleInput()
	
def HandleGetInnerString(argv):  
    CheckInputParams(10,argv)
    rawinput=GetVerStrInput(argv[2],argv[3],argv[4],argv[5],argv[6],argv[7],int(argv[8]),int(argv[9]))
    rawinput.GetInnerStr()

def HandleGetExtString(argv):
    CheckInputParams(10,argv)
    rawinput=GetVerStrInput(argv[2],argv[3],argv[4],argv[5],argv[6],argv[7],int(argv[8]),int(argv[9]))
    rawinput.GetExtStr()
	
def HandleGetVendorString(argv):
    CheckInputParams(10,argv)    
    rawinput=GetVerStrInput(argv[2],argv[3],argv[4],argv[5],argv[6],argv[7],int(argv[8]),int(argv[9]))
    rawinput.GetVendorStr()
	
def HandleGetFacString(argv):    
    CheckInputParams(10,argv)
    rawinput=GetVerStrInput(argv[2],argv[3],argv[4],argv[5],argv[6],argv[7],int(argv[8]),int(argv[9]))
    rawinput.GetFacStr()
    
def HandleImgPrefix(argv):
    CheckInputParams(10,argv)
    rawinput=GetVerStrInput(argv[2],argv[3],argv[4],argv[5],argv[6],argv[7],int(argv[8]),int(argv[9]))
    rawinput.GetImgPfx()

def HandleGetOui(argv):
    CheckInputParams(10,argv)
    rawinput=GetVerStrInput(argv[2],argv[3],argv[4],argv[5],argv[6],argv[7],int(argv[8]),int(argv[9]))
    rawinput.GetOui()
	
def HandlegetDisplayId(argv):
    CheckInputParams(10,argv)
    rawinput=GetVerStrInput(argv[2],argv[3],argv[4],argv[5],argv[6],argv[7],int(argv[8]),int(argv[9]))
    rawinput.GetDisplayId()
    
def HandlegetHwId(argv):
    CheckInputParams(10,argv)
    rawinput=GetVerStrInput(argv[2],argv[3],argv[4],argv[5],argv[6],argv[7],int(argv[8]),int(argv[9]))
    rawinput.GetHwId()
 
def HandlecheckMajorversion(argv):
    CheckInputParams(10,argv)
    rawinput=GetVerStrInput(argv[2],argv[3],argv[4],argv[5],argv[6],argv[7],int(argv[8]),int(argv[9]))
    rawinput.CheckMajorversion()	
 
# HandleFunction Map must be defined after the real handle    
HandleFuncMap = {
    'getExtVer' : HandleGetExtVer,
    'getIntVer' : HandleGetIntVer,
    'getInnerStr' : HandleGetInnerString,
    'getExtStr' : HandleGetExtString,
    'getFacStr' : HandleGetFacString,
    'getVendorStr' : HandleGetVendorString,
    'getImgPfx' : HandleImgPrefix,
    'getOui' : HandleGetOui,
    'getDisplayId' : HandlegetDisplayId,
    'getHwId' : HandlegetHwId,
    'checkMajorversion' : HandlecheckMajorversion,
}
            
def HandleInput(argv):
    if argv[1] in HandleFuncMap.keys():
        HandleFuncMap[argv[1]](argv)		
    else:
        print "wrongmethod"
        sys.exit()
    
def TestChipTuple():
    tt=('S905L','RTL8676')
    tt1=('a','b','c')
    if tt in ChipTuple:
        print "find"+ str(tt)
    else:
        print "cannot find:"+ str(tt)
    if tt1 in ChipTuple:
        print "find:"+ str(tt1)
    else:
        print "cannot find:"+ str(tt1)
        
def TestDict():
    tt=('S-010W-A',('RK3228B','RTL8189ETV'),'zy','nolauncher','ctnx')
    tt1=('S-010W-A',('RK3228B','AP6356S'),'zy','nolauncher','ctnx')
    if tt in IntToExtDict.keys():
        print "find"+ str(tt)
    else:
        print "cannot find:"+ str(tt)
    if tt1 in IntToExtDict.keys():
        print "find:"+ str(tt1)
    else:
        print "cannot find:"+ str(tt1)   
    
def main():
    #TestChipTuple()
    TestDict()

if __name__ == "__main__":
    HandleInput(sys.argv)
    #rawinput=InternalInput(sys.argv[1],sys.argv[2],sys.argv[3],sys.argv[4],sys.argv[5],sys.argv[6])
    #rawinput.handleInput()
    #rawinput.testInput()
    
#   Test case is like 
#   python intmapext.py getExtVer 'S-010W-A' RK3228B RTL zy nolauncher ctnx 
#   or
#   python intmapext.py getIntVer RK3228B AP6356S
#   or 
#   python intmapext.py getExtStr 'S-010W-AV2S' RK3228H NOWIFI zy huawei cunm 0 3
#   or
#   python intmapext.py getInnerStr S-010W-AV2S RK3228H NOWIFI zy fenghuo cunm 0 3
#       Error case
#   python intmapext.py getIntVer RK3228B RTL
#   python intmapext.py getExtVer 'S-010W-A' RK3228B RTL zy nolauncher ctnx


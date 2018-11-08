#!/usr/bin/env python3
#-*- coding=utf-8 -*-
import os
import csv
import sys
import logging
import re
import json


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


class GetRemoteControlConf(object):
    def __init__(self):
        self.home = os.environ['HOME']+'/'
        self.manual=False
        if len(sys.argv) == 7:
            self.product=sys.argv[1].lower()
            self.chiptype=sys.argv[2].lower()
            self.province=sys.argv[3].lower()
            self.branchname=sys.argv[4].lower()
            self.launcher=sys.argv[5].lower()
            self.imgprex=sys.argv[6]
        elif len(sys.argv) == 8:
            self.product=sys.argv[1].lower()
            self.chiptype=sys.argv[2].lower()
            self.province=sys.argv[3].lower()
            self.branchname=sys.argv[4].lower()
            self.launcher = sys.argv[5].lower()
            self.imgprex = sys.argv[6]
            self.manual=True
        else:
            log.error('Input parameter not Correct!')
            sys.exit()
        self.remoteControl_data_dict={
        }
        self.remoteControl_filter_dict={
        }
        self.input_h_list=[]
        self.kl_list=[]
        self.key_event_list=[]

        log.warn("Input info:")
        log.warn(" Input product={}".format(self.product))
        log.warn(" Input chiptype={}".format(self.chiptype))
        log.warn(" Input province={}".format(self.province))
        log.warn(" Input branchname={}".format(self.branchname))
        log.warn(" Input launcher={}".format(self.launcher))
        log.warn(" Input imgprex={}".format(self.imgprex))

        self.input_h = self.home+'workspace/kernel/include/dt-bindings/input/input.h'
        if self.launcher != 'nolauncher':
            kl=self.home+'workspace/device/rockchip/rksdk/IPTV/IPTV_{}_{}/20050030_pwm.kl'.format(self.province,self.launcher)
            if os.path.exists(kl):
                self.kl=kl
            else:
                self.kl=self.home+'workspace/device/rockchip/rksdk/20050030_pwm.kl'
        else:
            kl = self.home+'workspace/device/rockchip/rksdk/IPTV/IPTV_{}/20050030_pwm.kl'.format(self.province)
            if os.path.exists(kl):
                self.kl=kl
            else:
                self.kl=self.home+'workspace/device/rockchip/rksdk/20050030_pwm.kl'

        self.KeyEvent_java = self.home+'workspace/frameworks/base/core/java/android/view/KeyEvent.java'
        log.warn('self.input.h={}'.format(self.input_h))
        log.warn('self.kl={}'.format(self.kl))
        log.warn('self.KeyEvent.java={}'.format(self.KeyEvent_java))

    def set_property(self):
        if self.manual:
            self.scancode_list = ['<{}>'.format(sys.argv[7])]
        else:
            self.scancode_list = ['<0xc43b>', '<0x3bc4>']
        self.head=['Usercode','物理码','dts码','Linux code','Android code']
        self.dts_dict={
            's-010w-a' : 'rk3228b-box.dts',
            's-010w-av2b' : 'rk-stb-keymap.dtsi',
            's-010w-av2' : 'rk-stb-keymap.dtsi',
            's-010w-av2c' : 'rk-stb-keymap.dtsi',
            's-010w-av2e' : '',
            's-010w-av2s' : 'rk-stb-keymap.dtsi',
            'g-120wt-p' : 'rk3228b-box.dts',
            'g-120wt-q' : '',
        }

        if self.chiptype =='rk3228h' and self.province in ['cubj','cusc']:
            dts_dict_key='s-010w-av2b'
        else:
            dts_dict_key=self.product
        if self.chiptype == "rk3228h":
            self.dts=self.home+'workspace/kernel/arch/arm64/boot/dts/'+self.dts_dict[dts_dict_key]
        elif self.chiptype == "rk3228b":
            self.dts = self.home + 'workspace/kernel/arch/arm/boot/dts/' + self.dts_dict[dts_dict_key]
        self.conf_csv = self.home+'build/input/zy/{}/image/'.format(self.province) +self.imgprex+"_" + "keyvaluemapping.csv"
        log.warn('self.dts={}'.format(self.dts))


    def get_line_index(self,listx,partten):
        flag=True
        for li in listx:
            fin=re.search(partten,li.replace(' ',''))
            if fin:
                log.warn('Find: {}'.format(li))
                return listx.index(li)
            else:
                flag=False
        log.warn("Not find partten: {} in {}.Please recheck!".format(partten,self.dts))
        return flag

    def rmc_getdata_map(self,key):
        flag=True
        data_list=[]
        rmc_data_list = []
        try:
            with open(self.dts,encoding='utf-8') as f:
                data_list=f.readlines()
        except UnicodeDecodeError:
            log.warn('utf-8 can not decode dts file ,will use gbk.')
            flag = False
        if not flag:
            with open(self.dts, encoding='gbk') as f2:
                data_list = f2.readlines()

        scancode_index=self.get_line_index(data_list,key)
        if scancode_index:
            data_list=data_list[scancode_index:-1]
        else:
            return False

        key_table_index=self.get_line_index(data_list,'rockchip,key_table')
        data_list=data_list[key_table_index:-1]

        irend_index=self.get_line_index(data_list,'};')
        data_list = data_list[1:irend_index]

        for item in data_list:
            partten='.*<(0x\w{2}).*(KEY_\w+)>'
            ret=re.search(partten,item)
            if ret:
                rmc_data_list.append([ret.group(1),ret.group(2)])

        log.warn('len(rmc_data_list)={}'.format(len(rmc_data_list)))
        log.warn('rmc_data_list={}'.format(str(rmc_data_list)))
        self.remoteControl_data_dict[key]=rmc_data_list

    def get_physical_code(self,rmc_data):
        f=eval('0xff')
        physical_data=hex(f - rmc_data)
        return physical_data

    def add_physical_code(self):
        for key,values in self.remoteControl_data_dict.items():
            for val in values:
                rmc_data=eval(val[0])
                ret=self.get_physical_code(rmc_data)
                val.insert(0,ret)

    def parse_dts(self):
        for key in self.scancode_list:
            self.rmc_getdata_map(key)
        self.add_physical_code()

        log.warn('In parse_dts() remoteControl_data_dict:')
        log.warn(str(self.remoteControl_data_dict))

    def get_linux_code(self,map_key):
        partten='#define\s+(KEY_\w+)\s+(\d+).*'
        linux_code=None

        for item in self.input_h_list:
            p=re.search(partten,item)
            if p:
                if p.group(1) == map_key:
                    linux_code=p.group(2)
                    break
        return linux_code


    def parse_input_h(self):
        flag=True
        try:
            with open(self.input_h,encoding='utf-8') as f:
                self.input_h_list=f.readlines()
        except UnicodeDecodeError:
            log.warn('utf-8 can not decode dts file ,will use gbk.')
            flag = False
        if not flag:
            with open(self.input_h, encoding='gbk') as f2:
                self.input_h_list = f2.readlines()

        for key,values in self.remoteControl_data_dict.items():
            for val in values:
                map_key=val[2]
                linux_code=self.get_linux_code(map_key)
                val=val.append(linux_code)

        log.warn('In parse_input_h() remoteControl_data_dict:')
        log.warn(str(self.remoteControl_data_dict))

    def get_kl_code(self,map_key):
        partten='key\s+(\d+)\s+(\w+).*'
        kl_code=None

        for item in self.kl_list:
            p=re.search(partten,item)
            if p:
                if p.group(1) == map_key:
                    kl_code=p.group(2)
                    break
        return kl_code

    def parse_kl(self):
        flag=True
        try:
            with open(self.kl,encoding='utf-8') as f:
                self.kl_list=f.readlines()
        except UnicodeDecodeError:
            log.warn('utf-8 can not decode dts file ,will use gbk.')
            flag = False
        if not flag:
            with open(self.kl, encoding='gbk') as f2:
                self.kl_list = f2.readlines()

        for key,values in self.remoteControl_data_dict.items():
            for val in values:
                map_key=val[3]
                kl_code=self.get_kl_code(map_key)
                val=val.append(kl_code)

        log.warn('In parse_kl() remoteControl_data_dict:')
        log.warn(str(self.remoteControl_data_dict))

    def get_android_code(self,map_key):
        partten='\s+public\s+static\s+final\s+int\s+KEYCODE_(\w+)\s+=\s*(\d+).*'
        android_code=None

        for item in self.key_event_list:
            p=re.search(partten,item)
            if p:
                if p.group(1) == map_key:
                    android_code=p.group(2)
                    break
        return android_code

    def parse_keyEvent_java(self):
        flag=True
        try:
            with open(self.KeyEvent_java,encoding='utf-8') as f:
                self.key_event_list=f.readlines()
        except UnicodeDecodeError:
            log.warn('utf-8 can not decode dts file ,will use gbk.')
            flag = False
        if not flag:
            with open(self.KeyEvent_java, encoding='gbk') as f2:
                self.key_event_list = f2.readlines()

        for key,values in self.remoteControl_data_dict.items():
            for val in values:
                map_key=val[4]
                android_code=self.get_android_code(map_key)
                val=val.append(android_code)

        log.warn('In parse_keyEvent_java() remoteControl_data_dict:')
        log.warn(str(self.remoteControl_data_dict))


    def get_filter_dict(self):
        count=0
        for (key,values) in self.remoteControl_data_dict.items():
            count=count+1
            new_values = []
            for val in values:
                new_val=[key[1:-1],val[0],val[1],val[3],val[5]]
                new_values.append(new_val)
            new_values.append(self.head)
            self.remoteControl_filter_dict[key]=new_values

        log.warn('In get_filter_dict() remoteControl_filter_dict:')
        log.warn(str(self.remoteControl_filter_dict))
        log.warn("count={}".format(count))


    def write_file(self):
        self.get_filter_dict()

        if os.path.exists(self.conf_csv):
            os.remove(self.conf_csv)

        with open(self.conf_csv,'a',encoding='gbk') as out:
            csv_write=csv.writer(out,dialect='excel')
            csv_write.writerow(self.head)
            for key,values in self.remoteControl_filter_dict.items():
                for val in values:
                    csv_write.writerow(val)
        log.warn('Have write: {}'.format(self.conf_csv))


class GetAmlRemoteControlConf(GetRemoteControlConf):
    def __init__(self):
        super(GetAmlRemoteControlConf,self).__init__()
        self.remote_conf_list=[]
        self.head=['FactoryCode','物理码','Linux code','Android code']


    def get_remote_conf_index(self):
        pattern = '.*(remote\d*.conf).*'
        for item in self.p201_iptv_list:
            p=re.search(pattern,item)
            if p:
                yield self.p201_iptv_list.index(item)

    def check_validity(self,_index):
        partten1 = '.*\((CHINA_UNICOM_ENABLE)\).*'
        partten2 = '.*\((CHINA_TELECOM_ENABLE)\).*'
        partten3 = '.*\((CHINA_MOBILE_ENABLE)\).*'
        partten4 = r'else\n'
        index=_index-1
        while index:
            p1 = re.search(partten1,self.p201_iptv_list[index])
            p2 = re.search(partten2, self.p201_iptv_list[index])
            p3 = re.search(partten3, self.p201_iptv_list[index])
            p4 = re.search(partten4, self.p201_iptv_list[index])
            if p1:
                log.warn(str(p1.group(1)))
                log.warn(self.macro)
                log.warn('-----------------')
                if p1.group(1) == self.macro:
                    return True
                else:
                    return False
            elif p2:
                log.warn(str(p2.group(1)))
                log.warn(self.macro)
                log.warn('-----------------')
                if p2.group(1) == self.macro:
                    return True
                else:
                    return False
            elif p3:
                log.warn(str(p3.group(1)))
                log.warn(self.macro)
                log.warn('-----------------')
                if p3.group(1) == self.macro:
                    return True
                else:
                    return False
            elif p4:
                return False
            else:
                index=index-1
        return False

    def get_remote_conf(self):
        history_index=[]
        mygenerator=self.get_remote_conf_index()
        for index in mygenerator:
            if index not in history_index:
                ret=self.check_validity(index)
                if ret:
                    self.remote_conf_list.append(self.home+'workspace/device/amlogic/p201_iptv/'+self.p201_iptv_list[index].split(':')[0].split('/')[-1])
            history_index.append(index)

        log.warn('remote_conf_list:'+str(self.remote_conf_list))
        log.warn('history_index:'+str(history_index))

    def set_property(self):
        self.p201_iptv=self.home+"workspace/device/amlogic/p201_iptv/p201_iptv.mk"
        self.kl=self.home+'workspace/device/amlogic/p201_iptv/Vendor_0001_Product_0001_chinaunicom.kl'
        macro_dict={
            'cu' : 'CHINA_UNICOM_ENABLE',
            'ct' : 'CHINA_TELECOM_ENABLE',
            'cm' : 'CHINA_MOBILE_ENABLE',
        }
        self.macro = macro_dict[self.province[:2]]
        with open(self.p201_iptv) as f:
            self.p201_iptv_list=f.readlines()

        if self.manual:
            self.remote_conf_list.append(self.home + 'workspace/device/amlogic/p201_iptv/' +sys.argv[7])
        else:
            self.get_remote_conf()
        self.conf_csv=self.home+'amlbuild/image/'+self.imgprex + "_" + "keyvaluemapping.csv"

    def parse_conf(self, _conf):
        flag=False
        key_code=''
        value_maps=[]
        partten1='\s*factory_code\s*=\s*(\w+).*'
        par_start='\s*key_begin.*'
        par_end='\s*key_end.*'
        partten='\s*(\w+)\s*(\d+).*'
        conf=_conf
        with open(conf,mode='r',encoding='gbk') as f:
            try:
                while True:
                    text_line = f.readline()
                    if text_line:
                        p=re.search(partten1,text_line)
                        p2=re.search(partten,text_line)
                        p3 = re.search(par_start, text_line)
                        p4=re.search(par_end,text_line)
                        if p:
                            key_code=p.group(1)
                        elif p2 and flag:
                            value_maps.append([p2.group(1),p2.group(2)])
                        elif p3:
                            flag=True
                        elif p4:
                            flag=False
                            self.remoteControl_data_dict[key_code]=value_maps
                    else:
                        break
            except FileNotFoundError:
                log.error('Not find {}'.format(conf))
        log.warn(str(self.remoteControl_data_dict))

    def parse_remote_conf(self):
        for conf in self.remote_conf_list:
            self.parse_conf(conf)

    def parse_kl(self):
        with open(self.kl,encoding='gbk', mode='r') as f:
            self.kl_list=f.readlines()

        for key,values in self.remoteControl_data_dict.items():
            for val in values:
                map_key=val[1]
                kl_code=self.get_kl_code(map_key)
                val=val.append(kl_code)

        log.warn('In parse_kl() remoteControl_data_dict:')
        log.warn(str(self.remoteControl_data_dict))

    def parse_keyEvent_java(self):
        with open(self.KeyEvent_java,encoding='gbk', mode='r') as f:
            self.key_event_list =f.readlines()

        for key,values in self.remoteControl_data_dict.items():
            for val in values:
                map_key=val[2]
                android_code=self.get_android_code(map_key)
                val=val.append(android_code)

        log.warn('In parse_keyEvent_java() remoteControl_data_dict:')
        log.warn(str(self.remoteControl_data_dict))


    def get_filter_dict(self):
        count=0
        for (key,values) in self.remoteControl_data_dict.items():
            count=count+1
            new_values = []
            for val in values:
                new_val=[key,val[0],val[1],val[3]]
                new_values.append(new_val)
            new_values.append(self.head)
            self.remoteControl_filter_dict[key]=new_values

        log.warn('In get_filter_dict() remoteControl_filter_dict:')
        log.warn(str(self.remoteControl_filter_dict))
        log.warn("count={}".format(count))


def rk_method():
    grcc=GetRemoteControlConf()
    grcc.set_property()
    grcc.parse_dts()
    grcc.parse_input_h()
    grcc.parse_kl()
    grcc.parse_keyEvent_java()
    grcc.write_file()


def aml_method():
    garcc=GetAmlRemoteControlConf()
    garcc.set_property()
    garcc.parse_remote_conf()
    garcc.parse_kl()
    garcc.parse_keyEvent_java()
    garcc.write_file()

if __name__ == "__main__":
    rk_list=['rk3228h','rk3228b']
    aml_list=["s905l","s905lv2","s905l2","s905l3"]
    log.warn(str(sys.argv))
    if sys.argv[2].lower() in rk_list:
        rk_method()
        print(True)
    elif sys.argv[2].lower() in aml_list:
        aml_method()
        print(True)
    else:
        log.error("Input chiptype not Correct!")
        print(False)









#   脚本调用方式：
#   python3 keyValueMapping.py  S-010W-A RK3228H cubj s010wa_zy_cu_bj nolauncher S-010W-A_SW_D_ZY_CUBJ_R1.01.09
#   or
#   python3 keyValueMapping.py  RG020ET-CA S905L cusd s010wa_zy_cu_sd nolauncher RG020ET-CA_SW_B_ZY_CUSD_R1.01.14
#product = sys.argv[1].lower()
#chiptype = sys.argv[2].lower()
#province = sys.argv[3].lower()
#branchname = sys.argv[4].lower()
#launcher = sys.argv[5].lower()
#imgprex = sys.argv[5]

#   传值的方式：
#   python3 keyValueMapping.py S-010W-A RK3228H cubj s010wa_zy_cu_bj nolauncher S-010W-A_SW_D_ZY_CUBJ_R1.01.09 0xc43b
#   or
#   python3 keyValueMapping.py RG020ET-CA S905L cusd s010wa_zy_cu_sd nolauncher RG020ET-CA_SW_B_ZY_CUSD_R1.01.14 remote_chinaunicom.conf




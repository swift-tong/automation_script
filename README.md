AmlBuild，RK_Standalone，RK_VideoOnt三个目录分别对应不同的产品的shell脚本。

python脚本是共用的脚本。

backup_strategy.py：据点备份脚本，每做一个版本此脚本会吧基线manifest和相对于与基线的改动备份到特定服务器上面。备份 的内容还有packge-file和parameter等等。

buildCheck.py：检查据点的配置对不对，检查common输入有没有做，检查特定于某一型号的输入，配置对不对，检查分支对不对。

handleInput.py：系统集成apk的时候，对比包名删除特定目录下和Makefile里面老的apk，添加新的apk。

intmapext.py：版本号生成。根据输入生成不同的版本号。

keyValueMapping.py： 生成遥控器从物理码到android code的映射表。

makeDiffFile.py：做固件版本时生成每个版本和上一个版本的差异，提供数据给服务器使用。

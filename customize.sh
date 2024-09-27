#!/bin/sh

SKIPUNZIP=1
ASH_STANDALONE=1

box4sing_PATH="/data/adb/modules/box4sing/"
SCRIPTS_PATH="/data/adb/box/scripts/"

if [ "$BOOTMODE" != true ]; then
  abort "Error: 请在 Magisk Manager / KernelSU Manager / APatch 中安装"
elif [ "$KSU" = true ] && [ "$KSU_VER_CODE" -lt 10670 ]; then
  abort "Error: 请更新您的 KernelSU Manager 版本"
fi

if [ "$KSU" = true ] && [ "$KSU_VER_CODE" -lt 10683 ]; then
  service_dir="/data/adb/ksu/service.d"
else 
  service_dir="/data/adb/service.d"
fi

if [ ! -d "$service_dir" ]; then
  mkdir -p "$service_dir"
fi

unzip -qo "${ZIPFILE}" -x 'META-INF/*' -d "$MODPATH"
if [ -d /data/adb/box4sing ]; then
  if [ -d /data/adb/box4sing/sing-box ]; then
    cp /data/adb/box4sing/sing-box/config.json /data/adb/box4sing/sing-box/config.json.bak
  fi
  if [ -d /data/adb/box4sing/scripts ]; then
    cp /data/adb/box4sing/scripts/box.config /data/adb/box4sing/scripts/box.config.bak
  fi

  cp -f "$MODPATH/box4sing/sing-box/config.json" /data/adb/box4sing/sing-box/
  cp -f "$MODPATH/box4sing/sing-box/Toolbox.sh" /data/adb/box4sing/sing-box/
  cp -f "$MODPATH/box4sing/scripts/"* /data/adb/box4sing/scripts/
  rm -rf "$MODPATH/box4sing"

  ui_print "- Updating..."
  ui_print "- ————————————————"
  ui_print "- 配置文件 config.json 已备份 bak："
  ui_print "- 如更新订阅需重新添加订阅链接！"
  ui_print "- ————————————————"
  ui_print "- 用户配置 box.config 已备份 bak："
  ui_print "- 可自行选择重新配置或使用默认！"
  ui_print "- ————————————————"
  ui_print "- 更新无需重启设备..."
else
  mv "$MODPATH/box4sing" /data/adb/
  ui_print "- Installing..."
  ui_print "- ————————————————"
  ui_print "- 安装完成 工作目录"
  ui_print "- data/adb/box4sing/"
  ui_print "- ————————————————"
  ui_print "- 安装无需重启设备..."
fi

if [ "$KSU" = true ]; then
  sed -i 's/name=box4singmagisk/name=box4singKernelSU/g' "$MODPATH/module.prop"
fi

if [ "$APATCH" = true ]; then
  sed -i 's/name=box4singmagisk/name=box4singAPatch/g' "$MODPATH/module.prop"
fi

mkdir -p /data/adb/box4sing/bin/
mkdir -p /data/adb/box4sing/run/



rm -f customize.sh

mv -f "$MODPATH/box4sing_service.sh" "$service_dir/"

set_perm_recursive "$MODPATH" 0 0 0755 0644
set_perm_recursive /data/adb/boxbox4sing/ 0 3005 0755 0644
set_perm_recursive /data/adb/box4sing/scripts/ 0 3005 0755 0700
set_perm_recursive /data/adb/box4sing/bin/ 0 3005 0755 0700

set_perm "$service_dir/box4sing_service.sh" 0 0 0700

chmod ugo+x /data/adb/box4sing/scripts/*

for pid in $(pidof inotifyd) ; do
if grep -q box.inotify /proc/${pid}/cmdline ; then
  kill ${pid}
fi
done
mkdir -p "$box4sing_PATH"
nohup inotifyd "${SCRIPTS_PATH}box.inotify" "$box4sing_PATH" > /dev/null 2>&1 &

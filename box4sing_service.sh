#!/system/bin/sh

module_dir="/data/adb/modules/box4sing"

[ -n "$(magisk -v | grep lite)" ] && module_dir=/data/adb/lite_modules/box4sing

scripts_dir="/data/adb/box4sing/scripts"

(
until [ $(getprop sys.boot_completed) -eq 1 ] ; do
  sleep 3
done
${scripts_dir}/start.sh
)&

inotifyd ${scripts_dir}/box.inotify ${module_dir} > /dev/null 2>&1 &

while [ ! -f /data/misc/net/rt_tables ] ; do
  sleep 3
done

net_dir="/data/misc/net"
inotifyd ${scripts_dir}/net.inotify ${net_dir} > /dev/null 2>&1 &
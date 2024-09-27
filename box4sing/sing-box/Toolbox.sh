#!/bin/sh

if [ "$(id -u)" -ne 0 ]; then
    echo "请设置以 Root 用户运行"
    exit 1
fi

# 模块配置
MODULE_PATH="/data/adb/modules/box4sing/"
MODULE_PROP="${MODULE_PATH}module.prop"
MOUDLECONFIG_PATH="/data/adb/box4sing/"
SCRIPTS_PATH="${MOUDLECONFIG_PATH}scripts/"
COREE_PATH="${MOUDLECONFIG_PATH}sing-box/"

# Toolbox更新
TOOLBOX_URL="https://raw.githubusercontent.com/82199691/box4sing/main/box4sing/sing-box/Toolbox.sh"
CURRENT_VERSION="v0.1"
TOOLBOX_FILE="/data/adb/box/box4sing/Toolbox.sh"

#模块更新
GIT_URL="https://api.github.com/repos/82199691/box4sing/releases/latest"
CHANGELOG_URL="https://raw.githubusercontent.com/82199691/box4sing/main/changelog.md"
TEMP_FILE="/data/local/tmp/box4sing_update.zip"
TEMP_DIR="/data/local/tmp/box4sing_update"

#模块重载
SINGBOX_RELOAD_URL="http://127.0.0.1:9999/configs"
SINGBOX_RELOAD_PATH="$MOUDLECONFIG_PATH/sing-box/config.json"

#版本验证
VAR_PATH="/data/adb/box4sing/variab/"

#清除数据库
DB_PATH="/data/adb/box4sing/sing-box/cache.db"

#更新web面板
METAA_URL="https://api.github.com/repos/metacubex/metacubexd/releases/latest"
META_URL="https://github.com/metacubex/metacubexd/archive/gh-pages.zip"
YACDD_URL="https://api.github.com/repos/MetaCubeX/Yacd-meta/releases/latest"
YACD_URL="https://github.com/MetaCubeX/yacd/archive/gh-pages.zip"
PANEL_DIR="/data/adb/box4sing/panel/"
META_DIR="${PANEL_DIR}Meta/"
YACD_DIR="${PANEL_DIR}Yacd/"
#规则更新
GEOIP_URL="https://raw.githubusercontent.com/SagerNet/sing-geoip/rule-set/"
GEOIP_NAME=("geoip-cn.srs" "geosite-cn.srs" "geoip-telegram")
GEOSITE_URL="https://raw.githubusercontent.com/SagerNet/sing-geosite/rule-set/"
GEOSITE_NAME=("geosite-cn.srs" "geosite-private.srs" "geosite-category-ads-all.srs")
RULES_PATH="$COREE_PATH"
#整合magisk更新状态
GXBOX4SING_PATH="/data/adb/modules_update/box4sing"

get_remote_version() {
    remote_content=$(curl -s --connect-timeout 3 "$TOOLBOX_URL")
    if [ $? -ne 0 ]; then
        echo "无法连接到 GitHub！"
        return 1
    fi
    remote_version=$(echo "$remote_content" | grep -Eo 'CURRENT_VERSION="v[0-9]+\.[0-9]+"' | head -1 | cut -d'=' -f2 | tr -d '"')
    if [ -z "$remote_version" ]; then
        echo "无法获取远程版本信息！"
        return 1
    fi
    echo "$remote_version"
    return 0
}

check_version() {
    remote_version=$(get_remote_version)
    if [ $? -ne 0 ]; then
        return
    fi
    if [ "$(echo "$remote_version" | cut -d'v' -f2)" != "$(echo "$CURRENT_VERSION" | cut -d'v' -f2)" ]; then
        echo "当前脚本版本: $CURRENT_VERSION"
        echo "最新脚本版本: $remote_version"
        echo "是否更新脚本？回复y/n"
        read -r update_confirmation
        if [ "$update_confirmation" = "y" ]; then
            echo "↴" 
            echo "正在从 GitHub 下载最新版本..."
            curl -L -o "$TOOLBOX_FILE" "$TOOLBOX_URL"
            if [ $? -ne 0 ]; then
                echo "下载失败，请检查网络连接是否能正常访问 GitHub！"
                exit 1
            fi
            chmod 0644 "$TOOLBOX_FILE"
            echo "正在运行最新版本的脚本..."
            exec sh "$TOOLBOX_FILE"
            exit 0
        else
            echo "↴" 
            echo "更新取消"
            echo "继续使用当前脚本！"
        fi
    fi
}

update_module() {
    echo "↴"
    module_installed=true
    if [ -f "$MODULE_PROP" ]; then
        current_version=$(grep '^version=' "$MODULE_PROP" | cut -d'=' -f2)
        echo "当前模块版本号: $current_version"
    else
        module_installed=false
        echo "当前设备没有安装 box4sing 模块"
        echo "是否下载安装？回复y/n"
        read -r install_confirmation
        if [ "$install_confirmation" != "y" ]; then
            echo "↴"
            echo "操作取消！"
            return
        fi
    fi
    echo "↴"
    echo "正在获取服务器中..."
    module_release=$(curl -s "$GIT_URL")
    module_version=$(echo "$module_release" | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/')
    if [ -z "$module_version" ]; then
        echo "获取服务器失败！"
        echo "错误：请确保网络能正常访问 GitHub！"
        return
    fi
    download_url=$(echo "$module_release" | grep '"browser_download_url"' | sed -E 's/.*"([^"]+)".*/\1/')
    echo "获取成功！"
    echo "当前最新版本号: $module_version"
    if [ "$module_installed" = true ] && [ "$current_version" = "$module_version" ]; then
        echo "当前已是最新版本！"
        return
    fi
    changelog=$(curl -s "$CHANGELOG_URL")
    latest_changelog=$(echo "$changelog" | awk '/^## /{p=0} p; /^## '$module_version'$/{p=1}')
    echo "$latest_changelog"
    echo ""
    if [ "$module_installed" = false ]; then
        echo "是否安装模块？回复y/n"
    else
        echo "是否更新模块？回复y/n"
    fi
    read -r confirmation
    if [ "$confirmation" != "y" ]; then
        echo "↴"
        echo "操作取消！"
        return
    fi
    echo "↴"
    echo "正在下载文件中..."
    curl -L -o "$TEMP_FILE" "$download_url"
    if [ $? -ne 0 ]; then
        echo "下载失败，请检查网络连接是否能正常访问 GitHub！"
        exit 1
    fi
    if [ "$module_installed" = false ]; then
        echo "文件效验通过，开始进行安装..."
    else
        echo "文件效验通过，开始进行更新..."
    fi
    mkdir -p "$TEMP_DIR"
    unzip -qo "$TEMP_FILE" -d "$TEMP_DIR"
    if [ $? -ne 0 ]; then
        echo "解压失败，文件异常！"
        exit 1
    fi
    if [ "$KSU" = true ] && [ "$KSU_VER_CODE" -lt 10683 ]; then
        SERVICE_PATH="/data/adb/ksu/service.d"
    else 
        SERVICE_PATH="/data/adb/service.d"
    fi
    if [ ! -d "$SERVICE_PATH" ]; then
        mkdir -p "$SERVICE_PATH"
    fi
    mv "$TEMP_DIR/box4sing_service.sh" "$SERVICE_PATH"
    chmod 0700 "${SERVICE_PATH}/box4sing.sh"
    if [ -d /data/adb/box4sing ]; then
        mkdir -p "$SCRIPTS_PATH"
        mkdir -p "$COREE_PATH"
        mkdir -p "$MODULE_PATH"
        mkdir -p "$MODULE_PATH/webroot"
        if [ -f "$BOX_PATH" ]; then
            mv "$BOX_PATH" "${BOX_PATH}.bak"
        fi
        if [ -f "$CONFIG_PATH" ]; then
            mv "$CONFIG_PATH" "${CONFIG_PATH}.bak"
        fi
        mv "$TEMP_DIR/box4sing/scripts/"* "$SCRIPTS_PATH"
        mv "$TEMP_DIR/box4sing/sing-box/config.json" "$COREE_PATH"
        mv "$TEMP_DIR/box4sing/sing-box/Toolbox.sh" "$COREE_PATH"
        find "$TEMP_DIR" -mindepth 1 -maxdepth 1 ! -name "README.md" ! -name "box4sing_service.sh" ! -name "customize.sh" ! -name "box4sing" ! -name "META-INF" -exec cp -r {} "$MODULE_PATH" \;
        if [ -d "$TEMP_DIR/webroot" ]; then
            cp -r "$TEMP_DIR/webroot/"* "$MODULE_PATH/webroot/"
        fi
    else
        mkdir -p "$MODULE_PATH"
        mv "$TEMP_DIR/box4sing" "/data/adb/"
        mv "$TEMP_DIR/webroot" "$MODULE_PATH"
        find "$TEMP_DIR" -mindepth 1 -maxdepth 1 ! -name "README.md" ! -name "box4sing_service.sh" ! -name "customize.sh" ! -name "box4sing" ! -name "META-INF" -exec cp -r {} "$MODULE_PATH" \;
    fi
    chown -R root:net_admin /data/adb/box4sing/
    find /data/adb/box4sing/ -type d -exec chmod 755 {} \;
    find /data/adb/box4sing/ -type f -exec chmod 644 {} \;
    chmod -R 711 /data/adb/box4sing/scripts/
    chmod -R 700 /data/adb/box4sing/bin/
    rm -rf "$TEMP_FILE" "$TEMP_DIR"
    for pid in $(pidof inotifyd); do
        if grep -q box.inotify /proc/${pid}/cmdline; then
            kill ${pid}
        fi
    done
    nohup inotifyd "${SCRIPTS_PATH}box.inotify" "$MODULE_PATH" > /dev/null 2>&1 &
    while [ ! -f /data/misc/net/rt_tables ] ; do
       sleep 3
    done
    nohup inotifyd ${scripts_dir}/net.inotify ${net_dir} > /dev/null 2>&1 &
    if [ "$module_installed" = false ]; then
        echo "安装成功✓"
    else
        echo "更新成功✓"
    fi
    echo "无需重启设备..."
}

show_menu() {
    while true; do
        echo "================"
        echo "$CURRENT_VERSION" 
        echo "================"
        echo "  box4sing-Menu"
        echo "================"
        echo "1. 重载配置"
        echo "2. 清空数据库缓存"
        echo "3. 更新Web面板"
        echo "4. 更新Apps路由规则"
        echo "5. Web面板访问入口整合"
        echo "6. 整合Magisk更新状态"
        echo "7. 禁用/启用 更新模块"
        echo "8. 项目地址"
        echo "9. Exit"
        echo "——————"
        read -r choice
        case $choice in
            1)
                reload_configuration
                ;;
            2)
                clear_cache
                ;;
            3)
                update_web_panel
                ;;
            4)
                update_geoip
                update_geosite
                ;;
            5)
                show_web_panel_menu
                ;;
            6)
                integrate_magisk_update
                ;;
            7)
                if ! check_module_installed; then
                    continue
                fi
                check_update_status
                echo "1. 禁用更新"
                echo "2. 启用更新"
                read -r update_choice
                case $update_choice in
                    1)
                        disable_updates
                        ;;
                    2)
                        enable_updates
                        ;;
                    *)
                        echo "↴"
                        echo "无效的选择！"
                        ;;
                esac
                ;;
            8)
                open_project_page
                ;;
            9)
                exit 0
                ;;
            *)
                echo "↴"
                echo "无效的选择！"
                ;;
        esac
    done
}

reload_configuration() {
    if [ ! -f "$MODULE_PROP" ]; then
        echo "↴" 
        echo "当前未安装模块！"
        return
    fi
    if [ -f "/data/adb/modules/box4sing/disable" ]; then
        echo "↴" 
        echo "服务未运行，重载操作失败！"
        return
    fi
    echo "↴"
    echo "正在重载 sing-box 配置..."
    curl -X PUT "$SINGBOX_RELOAD_URL" -d "{\"path\":\"$SINGBOX_RELOAD_PATH\"}"
    if [ $? -eq 0 ]; then
        echo "ok"
    else
        echo "重载失败！"
    fi
}

clear_cache() {
    if [ ! -f "$MODULE_PROP" ]; then
        echo "↴" 
        echo "当前未安装模块！"
        return
    fi
    echo "↴"
    ensure_var_path
    CACHE_CLEAR_TIMESTAMP="${VAR_PATH}last_cache_update.txt" 
    if [ -f "$CACHE_CLEAR_TIMESTAMP" ]; then
        last_clear=$(date -d "@$(cat $CACHE_CLEAR_TIMESTAMP)" +"%Y-%m-%d %H:%M:%S")
        echo "距离上次清空缓存是: $last_clear" 
    fi
    echo "此操作会清空数据库缓存，是否清除？回复y/n"
    read -r confirmation
    if [ "$confirmation" != "y" ]; then
        echo "↴"
        echo "操作取消！"
        return
    fi
    echo "↴"
    if [ -f "$DB_PATH" ]; then
        rm "$DB_PATH"
        echo "已清空数据库缓存✓"
        touch "$DB_PATH"
    else
        echo "数据库文件不存在..."
        touch "$DB_PATH"
        echo "已创建新的空数据库文件"
    fi
    echo "重启模块服务中..."
    touch "$MODULE_PATH/disable"
    sleep 1.5
    rm -f "$MODULE_PATH/disable"
    sleep 1.5
    echo "ok"
    date +%s > "$CACHE_CLEAR_TIMESTAMP"
}

update_web_panel() {
    if [ ! -f "$MODULE_PROP" ]; then
        echo "↴" 
        echo "当前未安装模块！"
        return
    fi
    echo "↴"
    ensure_var_path
    WEB_PANEL_TIMESTAMP="${VAR_PATH}last_web_panel_update.txt"
    last_meta_version=""
    last_yacd_version=""
    if [ -f "$WEB_PANEL_TIMESTAMP" ]; then
        last_update=$(cat "$WEB_PANEL_TIMESTAMP")
        last_meta_version=$(echo $last_update | cut -d ' ' -f 1)
        last_yacd_version=$(echo $last_update | cut -d ' ' -f 2)
        echo "距离上次更新的 Meta 版本号是: $last_meta_version"
        echo "距离上次更新的 Yacd 版本号是: $last_yacd_version"
    fi
    echo "正在获取服务器中..."
    meta_release=$(curl -s "$METAA_URL")
    meta_version=$(echo "$meta_release" | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/')
    yacd_release=$(curl -s "$YACDD_URL")
    yacd_version=$(echo "$yacd_release" | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/')
    if [ -z "$meta_version" ] || [ -z "$yacd_version" ]; then
        echo "获取服务器失败！"
        echo "错误：请确保网络能正常访问 GitHub！"
      
        return
    fi  
    echo "获取成功！"   
    echo "Meta 当前最新版本号: $meta_version"
    echo "Yacd 当前最新版本号: $yacd_version"

    meta_update_needed=false
    yacd_update_needed=false

    if [ "$last_meta_version" != "$meta_version" ]; then
        meta_update_needed=true
    fi

    if [ "$last_yacd_version" != "$yacd_version" ]; then
        yacd_update_needed=true
    fi

    if [ "$meta_update_needed" = false ] && [ "$yacd_update_needed" = false ]; then
        echo "当前已是最新版本！"
        return
    fi

    echo "是否更新？回复y/n"
    read -r confirmation
    if [ "$confirmation" != "y" ]; then
        echo "↴"
        echo "操作取消！"
        return
    fi    
    if [ "$meta_update_needed" = true ]; then
        echo "↴"
        echo "正在更新：Meta"
        new_install=false
        if [ ! -d "$META_DIR" ]; then
            echo "面板不存在，正在自动安装..."
            mkdir -p "$META_DIR"
            if [ $? -ne 0 ]; then
                echo "创建失败，请检查权限！"
                return
            fi
            new_install=true
        fi
        echo "正在拉取最新的代码..."
        curl -L -o "$TEMP_FILE" "$META_URL"
        if [ $? -eq 0 ]; then
            echo "下载成功，正在效验文件..."
            if [ -s "$TEMP_FILE" ]; then
                echo "文件有效，开始进行$([ "$new_install" = true ] && echo "安装" || echo "更新")..."
                unzip -qo "$TEMP_FILE" -d "$TEMP_DIR"
                if [ $? -eq 0 ]; then
                    rm -rf "${META_DIR:?}"/*
                    if [ $? -ne 0 ]; then
                        echo "操作失败，请检查权限！"
                        return
                    fi
                    mv "$TEMP_DIR/metacubexd-gh-pages/"* "$META_DIR"
                    rm -rf "$TEMP_FILE" "$TEMP_DIR"
                    echo "$([ "$new_install" = true ] && echo "安装成功✓" || echo "更新成功✓")"
                    echo ""
                else
                    echo "解压失败，文件异常！"
                fi
            else
                echo "下载的文件为空或无效！"
            fi
        else
            echo "拉取下载失败！"
        fi   
    fi
    if [ "$yacd_update_needed" = true ]; then
        echo "↴"
        echo "正在更新：Yacd"
        new_install=false
        if [ ! -d "$YACD_DIR" ]; then
            echo "面板不存在，正在自动安装..."
            mkdir -p "$YACD_DIR"
            if [ $? -ne 0 ]; then
                echo "创建失败，请检查权限！"
                return
            fi
            new_install=true
        fi
        echo "正在拉取最新的面板代码..."
        curl -L -o "$TEMP_FILE" "$YACD_URL"
        if [ $? -eq 0 ]; then
            echo "下载成功，正在效验文件..."
            if [ -s "$TEMP_FILE" ]; then
                echo "文件有效，开始进行$([ "$new_install" = true ] && echo "安装" || echo "更新")..."
                unzip -qo "$TEMP_FILE" -d "$TEMP_DIR"
                if [ $? -eq 0 ]; then
                    rm -rf "${YACD_DIR:?}"/*
                    if [ $? -ne 0 ]; then
                        echo "操作失败，请检查权限！"
                        return
                    fi
                    mv "$TEMP_DIR/Yacd-meta-gh-pages/"* "$YACD_DIR"
                    rm -rf "$TEMP_FILE" "$TEMP_DIR"
                    echo "$([ "$new_install" = true ] && echo "安装成功✓" || echo "更新成功✓")"
                    #echo ""
                else
                    echo "解压失败，文件异常！"
                fi
            else
                echo "下载的文件为空或无效！"
            fi
        else
            echo "拉取下载失败！"
        fi 
    fi 
    echo "建议重载配置..."
    chown -R root:net_admin "$PANEL_DIR"
    find "$PANEL_DIR" -type d -exec chmod 0755 {} \;
    find "$PANEL_DIR" -type f -exec chmod 0666 {} \;
    if [ $? -ne 0 ]; then
        echo "设置文件权限失败！"
        return
    fi
    echo "$meta_version $yacd_version" > "$WEB_PANEL_TIMESTAMP"
}

update_geoip() {
    if [ ! -f "$MODULE_PROP" ]; then
        echo "↴" 
        echo "当前未安装模块！"
        return
    fi
    echo "↴"
    ensure_var_path
    RULES_UPDATE_TIMESTAMP="${VAR_PATH}last_rules_update.txt"    
    if [ -f "$RULES_UPDATE_TIMESTAMP" ]; then
        last_update=$(date -d "@$(cat $RULES_UPDATE_TIMESTAMP)" +"%Y-%m-%d %H:%M:%S")
        echo "距离上次更新是: $last_update"
    fi
    echo "此操作会从 GitHub 拉取最新全部规则，是否更新？回复y/n"
    read -r confirmation
    if [ "$confirmation" != "y" ];then
        echo "↴"
        echo "操作取消！"
        return
    fi
    if [ ! -d "$RULES_PATH" ];then

        mkdir -p "$RULES_PATH"
        if [ $? -ne 0 ];then
            echo "创建规则目录失败，请检查权限！"
            return
        fi
    fi
    echo "↴"
    echo "正在下载文件中..."
    for rule in "${GEOIP_NAME[@]}"; do
        curl -o "${RULES_PATH}${rule}" -L "${GEOIP_URL}${rule}"
        if [ $? -ne 0 ];then
            echo "下载 ${rule} 失败！"
            return
        fi
    done
    echo "更新成功✓"
    echo ""
    echo "建议重载配置..."
    chown -R root:net_admin "$RULES_PATH"
    find "$RULES_PATH" -type d -exec chmod 0755 {} \;

    if [ $? -ne 0 ];then
        echo "设置文件权限失败！"
        return
    fi
    date +%s > "$RULES_UPDATE_TIMESTAMP"
}

update_geosite() {
    if [ ! -f "$MODULE_PROP" ]; then
        echo "↴" 
        echo "当前未安装模块！"
        return
    fi
    echo "↴"
    ensure_var_path
    RULES_UPDATE_TIMESTAMP="${VAR_PATH}last_rules_update.txt"    
    if [ -f "$RULES_UPDATE_TIMESTAMP" ]; then
        last_update=$(date -d "@$(cat $RULES_UPDATE_TIMESTAMP)" +"%Y-%m-%d %H:%M:%S")
        echo "距离上次更新是: $last_update"
    fi
    echo "此操作会从 GitHub 拉取最新全部规则，是否更新？回复y/n"
    read -r confirmation
    if [ "$confirmation" != "y" ];then
        echo "↴"
        echo "操作取消！"
        return
    fi
    if [ ! -d "$RULES_PATH" ];then

        mkdir -p "$RULES_PATH"
        if [ $? -ne 0 ];then
            echo "创建规则目录失败，请检查权限！"
            return
        fi
    fi
    echo "↴"
    echo "正在下载文件中..."
    for rule in "${GEOSITE_NAME[@]}"; do
        curl -o "${RULES_PATH}${rule}" -L "${GEOSITE_URL}${rule}"
        if [ $? -ne 0 ];then
            echo "下载 ${rule} 失败！"
            return
        fi
    done
    echo "更新成功✓"
    echo ""
    echo "建议重载配置..."
    chown -R root:net_admin "$RULES_PATH"
    find "$RULES_PATH" -type d -exec chmod 0755 {} \;

    if [ $? -ne 0 ];then
        echo "设置文件权限失败！"
        return
    fi
    date +%s > "$RULES_UPDATE_TIMESTAMP"
}

show_web_panel_menu() {
    while true; do
        echo "↴"
        echo "选择图形面板："
        echo "1. HTTPS Gui Meta"
        echo "2. HTTPS Gui Yacd"
        echo "3. 本地端口 >>> 0.0.0.0:9999/ui"
        echo "4. 返回上一级菜单"
        read -r web_choice
        case $web_choice in
            1)
                echo "↴"
                echo "正在跳转到 Gui Meta..."
                am start -a android.intent.action.VIEW -d "https://metacubex.github.io/metacubexd"
                echo "ok"
                echo ""
                ;;
            2)
                echo "↴"
                echo "正在跳转到 Gui Yacd..."
                am start -a android.intent.action.VIEW -d "https://yacd.mereith.com/"
                echo "ok"
                echo ""
                ;;
            3)
                echo "↴"
                echo "正在跳转到本地端口..."
                am start -a android.intent.action.VIEW -d "http://127.0.0.1:9090/ui/#/"
                echo "ok"
                echo ""
                ;;
            4)
                echo "↴"
                return
                ;;
            *)
                echo "↴"
                echo "无效的选择！"
                ;;
        esac
    done
}

integrate_magisk_update() {
    if [ ! -f "$MODULE_PROP" ]; then
        echo "↴" 
        echo "当前未安装模块！"
        return
    fi
    echo "↴"
    echo "如果你在客户端 安装/更新 模块，可进行整合刷新并更新状态 无需重启设备，是否整合？回复y/n"
    read -r confirmation
    if [ "$confirmation" != "y" ]; then
        echo "↴"
        echo "操作取消！"
        return
    fi
    echo "↴"
    echo "正在检测当前状态..."
    for i in 1
    do
        sleep 1
    done
    VARIAB_PATH="$MODULE_PATH/variab"
    TEMP_PATH="/data/local/tmp/box4sing_variab_backup"
    if [ -d "$GXBOX4SING_PATH" ]; then
        echo "检测到 安装/更新 box4sing 模块，进行整合..."
        rm -rf "$MODULE_PATH"
        mv "$GXBOX4SING_PATH" /data/adb/modules/
        if [ -f "$MODULE_PATH/update" ]; then
            rm -f "$MODULE_PATH/update"
        fi    
        echo "整合成功✓"
    else
        echo "没有检测到 安装/更新 box4sing 模块。"
    fi
}

ensure_var_path() {
    if [ ! -d "$VAR_PATH" ]; then
        mkdir -p "$VAR_PATH"
        if [ $? -ne 0 ]; then
            echo "操作失败，请检查权限！"
            exit 1
        fi
    fi
}

check_update_status() {
    ensure_var_path
    UPDATE_STATUS_FILE="${VAR_PATH}/update_status.txt"
    if [ -f "$UPDATE_STATUS_FILE" ]; then
        echo "↴" 
        echo "当前客户端状态：更新已禁用"
    else
        echo "↴" 
        echo "当前客户端状态：更新已启用"
    fi
}

check_module_installed() {
    if [ ! -f "$MODULE_PROP" ]; then
        echo "↴" 
        echo "当前未安装模块！"
        return 1 
    fi
    return 0
}

disable_updates() {
    ensure_var_path
    UPDATE_STATUS_FILE="${VAR_PATH}/update_status.txt"
    MODULE_PROP="${MODULE_PROP}"
    if grep -q "^updateJson=" "$MODULE_PROP"; then
        echo "↴" 
        echo "此操作会对该模块在客户端禁止检测更新，是否继续？回复y/n"
        read -r confirmation
        if [ "$confirmation" != "y" ]; then
            echo "↴"
            echo "操作取消！"
            return
        fi
        updateJson_value=$(grep "^updateJson=" "$MODULE_PROP" | cut -d '=' -f 2-)
        echo "$updateJson_value" > "$UPDATE_STATUS_FILE"
        sed -i '/^updateJson=/d' "$MODULE_PROP"
        echo "↴"
        echo "更新检测已禁止✓"
    else
        echo "↴" 
        echo "当前已是禁用状态，无需操作。"
    fi
}

enable_updates() {
    ensure_var_path
    UPDATE_STATUS_FILE="${VAR_PATH}/update_status.txt"
    MODULE_PROP="${MODULE_PROP}"
    if [ -f "$UPDATE_STATUS_FILE" ]; then
        echo "↴" 
        echo "此操作会恢复模块在客户端的检测更新，是否继续？回复y/n"
        read -r confirmation
        if [ "$confirmation" != "y" ];then
            echo "↴"
            echo "操作取消！"
            return
        fi
        updateJson_value=$(cat "$UPDATE_STATUS_FILE")
        echo "updateJson=$updateJson_value" >> "$MODULE_PROP"
        rm -f "$UPDATE_STATUS_FILE"
        echo "↴"
        echo "更新检测已恢复✓"
    else
        echo "↴" 
        echo "当前已是启用状态，无需操作。"
    fi
}

check_version
update_module
show_menu
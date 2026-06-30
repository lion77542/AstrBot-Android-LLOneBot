#!/bin/bash

ASTRBOT_APP_VERSION="{{VERSION}}"

# 自定义 Git Clone 命令（为空时使用默认逻辑）
CUSTOM_GIT_CLONE=""

# 重装插件依赖标记（1表示需要重装，执行后自动清除）
REINSTALL_PLUGINS_FLAG=0

export UV_LINK_MODE=copy
export UV_DEFAULT_INDEX="https://pypi.tuna.tsinghua.edu.cn/simple"
export UV_PYTHON_INSTALL_MIRROR="https://ghfast.top/https://github.com/astral-sh/python-build-standalone/releases/download"

if [ -z "$TMPDIR" ]; then
  echo "错误：未检测到 TMPDIR，请在挂载共享目录时传入 TMPDIR"
  exit 1
fi

if [ ! -d "$TMPDIR" ]; then
  echo "错误：临时目录 $TMPDIR 不存在，请确认挂载已经完成"
  exit 1
fi


progress_echo(){
  echo -e "\033[31m- $@\033[0m"
  echo "$@" > "$TMPDIR/progress_des"
}

bump_progress(){
  current=0
  if [ -f "$TMPDIR/progress" ]; then
    current=$(cat "$TMPDIR/progress" 2>/dev/null || echo 0)
  fi
  next=$((current + 1))
  printf "$next" > "$TMPDIR/progress"
}

install_sudo_curl_git(){
  curl_path=`which curl`
  if [ -z "$curl_path" ]; then
    progress_echo "curl $L_NOT_INSTALLED, $L_INSTALLING..."
    apt-get update
    apt --fix-broken install -y
    apt-get install -y sudo
    sudo apt-get install -y git
    sudo apt-get install -y curl
  else
    progress_echo "curl $L_INSTALLED"
  fi
}

network_test() {
    local timeout=10
    local status=0
    local found=0
    target_proxy=""
    echo "开始网络测试: Github..."

    proxy_arr=("https://ghfast.top" "https://gh.wuliya.xin" "https://gh-proxy.com" "https://github.moeyy.xyz")
    check_url="https://raw.githubusercontent.com/LLOneBot/LuckyLilliaBot/main/package.json"

    for proxy in "${proxy_arr[@]}"; do
        echo "测试代理: ${proxy}"
        status=$(curl -k -L --connect-timeout ${timeout} --max-time $((timeout*2)) -o /dev/null -s -w "%{http_code}" "${proxy}/${check_url}")
        curl_exit=$?
        if [ $curl_exit -ne 0 ]; then
            echo "代理 ${proxy} 测试失败或超时，错误码: $curl_exit"
            continue
        fi
        if [ "${status}" = "200" ]; then
            found=1
            target_proxy="${proxy}"
            echo "将使用Github代理: ${proxy}"
            break
        fi
    done

    if [ ${found} -eq 0 ]; then
        echo "警告: 无法找到可用的Github代理，将尝试直连..."
        status=$(curl -k --connect-timeout ${timeout} --max-time $((timeout*2)) -o /dev/null -s -w "%{http_code}" "${check_url}")
        if [ $? -eq 0 ] && [ "${status}" = "200" ]; then
            echo "直连Github成功，将不使用代理"
            target_proxy=""
        else
            echo "警告: 无法连接到Github，请检查网络。将继续尝试安装，但可能会失败。"
        fi
    fi
}

install_uv(){
  INSTALL_DIR="$HOME/.local/bin"
  if [ ! -x "$INSTALL_DIR/uv" ]; then
    progress_echo "uv $L_NOT_INSTALLED，$L_INSTALLING..."
    network_test
    APP_NAME="uv"
    APP_VERSION="0.9.9"
    ARCHIVE_FILE="uv-aarch64-unknown-linux-gnu.tar.gz"
    DOWNLOAD_URL="${target_proxy:+${target_proxy}/}https://github.com/astral-sh/uv/releases/download/${APP_VERSION}/${ARCHIVE_FILE}"

    # 检查必要命令
    for cmd in tar mkdir cp chmod mktemp rm curl; do
      if ! command -v $cmd >/dev/null 2>&1; then
        echo "错误：缺少必要命令 $cmd，无法安装 $APP_NAME"
        exit 1
      fi
    done

    # 创建安装目录和临时目录
    mkdir -p $INSTALL_DIR
    TMP_DIR=$(mktemp -d 2>/dev/null || mktemp -t 'uvtmp.XXXXXX')
    if [ -z "$TMP_DIR" ]; then
      echo "创建临时目录失败"
      exit 1
    fi
    mkdir -p "$TMP_DIR"
    TMP_ARCHIVE="$TMP_DIR/$ARCHIVE_FILE"

    # 下载并解压（失败直接退出，不使用return）
    echo "正在下载 $APP_NAME $APP_VERSION..."
    if ! curl -fL $DOWNLOAD_URL -o $TMP_ARCHIVE; then
      echo "下载失败"
      rm -rf $TMP_DIR
      exit 1
    fi
    echo "正在解压 $APP_NAME..."
    if ! tar -C "$TMP_DIR" -xf "$TMP_ARCHIVE" --strip-components 1; then
      echo "解压失败"
      rm -rf $TMP_DIR
      exit 1
    fi

    # 安装并授权
    cp $TMP_DIR/uv $TMP_DIR/uvx $INSTALL_DIR/
    chmod +x $INSTALL_DIR/uv $INSTALL_DIR/uvx

    # 自动配置 PATH（写入 Ubuntu root 的 bashrc）
    if ! grep -q "$INSTALL_DIR" $HOME/.bashrc; then
      echo "export PATH=$INSTALL_DIR:\$PATH" >> $HOME/.bashrc
      source $HOME/.bashrc
      echo "已自动配置 $APP_NAME 路径到环境变量"
    fi

    # 清理临时文件
    rm -rf $TMP_DIR
  else
    progress_echo "uv $L_INSTALLED"
  fi
}

install_llbot(){
  LLBOT_DIR="$HOME/llbot"
  LLBOT_ZIP="LLBot-CLI-linux-arm64.zip"
  # LLBot 镜像源列表（含官方+镜像，自动轮询可用者）
  LLBOT_MIRRORS=(
    "https://github.com/LLOneBot/LuckyLilliaBot/releases/download"
    "https://ghfast.top/https://github.com/LLOneBot/LuckyLilliaBot/releases/download"
    "https://gh-proxy.com/https://github.com/LLOneBot/LuckyLilliaBot/releases/download"
    "https://mirror.ghproxy.com/https://github.com/LLOneBot/LuckyLilliaBot/releases/download"
    "https://hub.gitmirror.com/https://github.com/LLOneBot/LuckyLilliaBot/releases/download"
  )

  # 自动检测最新 LLBot 版本（先从镜像源尝试，避免被墙）
  detect_llbot_version() {
    local api_mirrors=(
      "https://api.github.com/repos/LLOneBot/LuckyLilliaBot/releases/latest"
      "https://ghfast.top/https://api.github.com/repos/LLOneBot/LuckyLilliaBot/releases/latest"
      "https://gh-proxy.com/https://api.github.com/repos/LLOneBot/LuckyLilliaBot/releases/latest"
    )
    for api_url in "${api_mirrors[@]}"; do
      local ver=$(curl -sL --connect-timeout 10 "$api_url" 2>/dev/null | grep '"tag_name"' | cut -d'"' -f4)
      if [ -n "$ver" ]; then
        echo "$ver"
        return 0
      fi
    done
    echo "v7.12.15"  # fallback 硬编码版本
    return 1
  }

  if [ ! -f "$LLBOT_DIR/llbot" ]; then
    progress_echo "LLBot $L_NOT_INSTALLED，$L_INSTALLING..."

    apt --fix-broken install -y
    apt-get install -y unzip 2>/dev/null

    # 备份配置目录（如果存在）
    if [ -d "$LLBOT_DIR/data" ]; then
      echo "备份 LLBot 数据目录..."
      cp -r "$LLBOT_DIR/data" "$HOME/llbot_data_backup"
    fi
    if [ -f "$LLBOT_DIR/default_config.json" ]; then
      cp "$LLBOT_DIR/default_config.json" "$HOME/llbot_config_backup.json"
    fi

    rm -rf $LLBOT_DIR
    mkdir -p $LLBOT_DIR
    cd $LLBOT_DIR

    # 检测最新版本
    LLBOT_VERSION=$(detect_llbot_version)
    echo "LLBot 最新版本: $LLBOT_VERSION"

    progress_echo "LLBot $L_NOT_INSTALLED，$L_INSTALLING..."

    # 多镜像源轮询下载 LLBot
    DOWNLOAD_SUCCESS=0
    for mirror in "${LLBOT_MIRRORS[@]}"; do
      local url="$mirror/$LLBOT_VERSION/$LLBOT_ZIP"
      echo "尝试下载: $url"
      if curl -fL --connect-timeout 15 --max-time 120 "$url" -o llbot.zip 2>/dev/null; then
        # 检查 ZIP 是否有效
        if unzip -t llbot.zip >/dev/null 2>&1; then
          echo "下载成功: $mirror"
          DOWNLOAD_SUCCESS=1
          break
        else
          echo "下载文件损坏，尝试下一个镜像"
          rm -f llbot.zip
        fi
      else
        echo "下载失败，尝试下一个镜像"
      fi
    done

    if [ "$DOWNLOAD_SUCCESS" -eq 0 ]; then
      echo "所有镜像下载 LLBot 均失败，正在重试官方源..."
      for retry in 1 2 3; do
        if curl -fL --connect-timeout 15 --max-time 120 "https://github.com/LLOneBot/LuckyLilliaBot/releases/download/$LLBOT_VERSION/$LLBOT_ZIP" -o llbot.zip; then
          DOWNLOAD_SUCCESS=1
          break
        fi
        sleep 5
      done
    fi

    if [ "$DOWNLOAD_SUCCESS" -eq 0 ]; then
      echo "下载 LLBot 失败，请检查网络连接"
      exit 1
    fi

    echo "正在解压 LLBot..."
    if ! unzip -o llbot.zip; then
      echo "解压 LLBot 失败"
      rm -f llbot.zip
      exit 1
    fi
    rm -f llbot.zip
    chmod +x llbot start.sh 2>/dev/null

    # 恢复配置
    if [ -f "$HOME/llbot_config_backup.json" ]; then
      cp "$HOME/llbot_config_backup.json" "$LLBOT_DIR/default_config.json"
      rm -f "$HOME/llbot_config_backup.json"
    fi
    if [ -d "$HOME/llbot_data_backup" ]; then
      rm -rf "$LLBOT_DIR/data"
      mv "$HOME/llbot_data_backup" "$LLBOT_DIR/data"
    fi
  fi

  # 创建 launcher.sh（供 Flutter 侧 llbotTerminal 使用）
  cat > "$HOME/launcher.sh" <<'LAUNCHEREOF'
#!/bin/bash
cd /root/llbot

# 如果存在自动登录配置，通过环境变量传递给 LLBot（与 Docker 方式一致）
if [ -f /root/llbot_auto_login.conf ]; then
  AUTO_LOGIN_QQ=$(cat /root/llbot_auto_login.conf | tr -d '[:space:]')
  export AUTO_LOGIN_QQ
fi

exec ./llbot
LAUNCHEREOF
  chmod +x "$HOME/launcher.sh"

  # 写入默认 OneBot 配置（如果不存在）
  if [ ! -f "$LLBOT_DIR/default_config.json" ]; then
    echo "写入 default_config.json 默认配置文件"
    cat > "$LLBOT_DIR/default_config.json" <<'CFGEOF'
{
  "servers": [
    {
      "type": "ws-reverse",
      "enable": true,
      "url": "ws://localhost:6199/ws",
      "token": "kasdkfljsadhlskdjhasdlkfshdlafksjdhf",
      "reportSelfMessage": false,
      "reportOfflineMessage": false,
      "messageFormat": "array",
      "debug": false,
      "heartInterval": 30000
    }
  ],
  "webui": {
    "enable": true,
    "host": "127.0.0.1",
    "port": 3080
  },
  "ffmpeg": "",
  "onlyLocalhost": true
}
CFGEOF
  fi

  progress_echo "LLBot $L_INSTALLED"
}

install_astrbot(){
  local INSTALL_DIR="$HOME/AstrBot"
  local CLONE_TEMP_DIR="$HOME/AstrBot_tmp"
  local BACKUP_DIR="/sdcard/Download/AstrBot"

  rm -rf "$CLONE_TEMP_DIR"

  killall uv 2>/dev/null

  # 检查是否已安装
  if [ ! -d "$INSTALL_DIR" ]; then
    cd $HOME
    progress_echo "AstrBot $L_NOT_INSTALLED，$L_INSTALLING..."

    # 克隆仓库（失败直接退出）
    echo "正在获取 AstrBot 最新版本..."

    # 判断是否使用自定义 git clone 命令
    if [ -n "$CUSTOM_GIT_CLONE" ]; then
      echo "使用自定义 Git Clone 命令..."
      echo "执行: $CUSTOM_GIT_CLONE"
      # 执行自定义命令，假设克隆到当前目录，然后重命名为临时目录
      if ! eval "$CUSTOM_GIT_CLONE"; then
        echo "自定义 Git Clone 命令执行失败"
        exit 1
      fi
      # 查找克隆后的目录（通常是 AstrBot）
      if [ -d "AstrBot" ]; then
        mv "AstrBot" "$CLONE_TEMP_DIR"
      else
        echo "错误: 自定义 git clone 后未找到 AstrBot 目录"
        exit 1
      fi
    else
      network_test

      # 使用默认逻辑：获取最新的 tag
      # 注意：git clone 不使用代理前缀（"${target_proxy}/" 不适用于 git 协议）
      GIT_REPO_URL="https://github.com/AstrBotDevs/AstrBot.git"
      LATEST_TAG=$(git ls-remote --tags --sort='-v:refname' "$GIT_REPO_URL" 2>/dev/null | head -n 1 | awk -F'/' '{print $3}' | tr -d '[:cntrl:]{}' | xargs)

      if [ -z "$LATEST_TAG" ]; then
        echo "警告: 无法获取最新 tag，使用 master 分支"
        CLONE_BRANCH="master"
      else
        echo "最新版本: $LATEST_TAG"
        CLONE_BRANCH="$LATEST_TAG"
      fi

      # 克隆到临时目录（带重试和 SSL 降级）
      echo "正在克隆 AstrBot 仓库，分支/标签: $CLONE_BRANCH..."
      CLONE_SUCCESS=0
      for retry in 1 2 3; do
        echo "克隆尝试 #$retry..."
        if git clone --depth=1 --branch "$CLONE_BRANCH" "$GIT_REPO_URL" "$CLONE_TEMP_DIR" 2>/dev/null; then
          CLONE_SUCCESS=1
          break
        fi
        # SSL 降级重试
        if GIT_SSL_NO_VERIFY=1 git clone --depth=1 --branch "$CLONE_BRANCH" "$GIT_REPO_URL" "$CLONE_TEMP_DIR" 2>/dev/null; then
          CLONE_SUCCESS=1
          break
        fi
        sleep 3
      done

      if [ "$CLONE_SUCCESS" -eq 0 ]; then
        echo "git 克隆失败，尝试通过代理下载 ZIP 包..."
        # 回退方案：直接下载 ZIP
        ZIP_URL="https://github.com/AstrBotDevs/AstrBot/archive/refs/heads/master.zip"
        ZIP_FILE="$HOME/AstrBot_master.zip"
        if curl -fL ${target_proxy:+${target_proxy}/}"$ZIP_URL" -o "$ZIP_FILE"; then
          mkdir -p "$CLONE_TEMP_DIR"
          cd "$CLONE_TEMP_DIR"
          unzip -o "$ZIP_FILE"
          mv AstrBot-master/* . 2>/dev/null || true
          rm -f "$ZIP_FILE"
          CLONE_SUCCESS=1
        fi
      fi

      if [ "$CLONE_SUCCESS" -eq 0 ]; then
        echo "克隆 AstrBot 仓库失败"
        rm -rf "$CLONE_TEMP_DIR"
        exit 1
      fi
    fi

    # 原子性重命名
    mv "$CLONE_TEMP_DIR" "$INSTALL_DIR"

  else
    progress_echo "AstrBot $L_INSTALLED"
  fi

  progress_echo "AstrBot 初始化中"
  cd "$INSTALL_DIR"

  if [ ! -d "$INSTALL_DIR/data" ]; then

    echo "检测到 data 目录不存在，初始化数据目录..."
    mkdir "$INSTALL_DIR/data"
    
    # 检查并恢复最新备份
    if [ -d "$BACKUP_DIR" ]; then
      echo "扫描备份目录: $BACKUP_DIR"
      LATEST_BACKUP=$(ls -t "$BACKUP_DIR"/AstrBot-backup-*.tar.gz 2>/dev/null | head -n 1)
      
      if [ -n "$LATEST_BACKUP" ]; then
        echo "找到备份文件: $LATEST_BACKUP"
        echo "恢复 AstrBot 数据备份..."
        
        # 解压备份到 data 目录
        if tar -xzf "$LATEST_BACKUP" -C "$INSTALL_DIR"; then
          echo "备份恢复成功"
          echo "AstrBot 数据已从备份恢复"
          REINSTALL_PLUGINS_FLAG=1  # 备份恢复成功，需要重装插件依赖

        else
          echo "备份恢复失败，使用默认配置"
          cp "$HOME/cmd_config.json" "$INSTALL_DIR/data"
          chmod +w "$INSTALL_DIR/data/cmd_config.json"
        fi
      else
        echo "未找到备份文件，使用默认配置"
        cp "$HOME/cmd_config.json" "$INSTALL_DIR/data"
        chmod +w "$INSTALL_DIR/data/cmd_config.json"
        echo "拷贝 cmd_config.json 默认配置文件"
      fi
    else
      echo "备份目录不存在，使用默认配置"
      cp "$HOME/cmd_config.json" "$INSTALL_DIR/data"
      chmod +w "$INSTALL_DIR/data/cmd_config.json"
      echo "拷贝 cmd_config.json 默认配置文件"
    fi
    
    rm -rf "$INSTALL_DIR/.venv"

  fi

  if [ ! -d "$INSTALL_DIR/.venv" ]; then

    # 使用 uv sync 同步依赖
    echo "同步 AstrBot 依赖..."
    if ! $HOME/.local/bin/uv sync; then
      echo "依赖同步失败"
      exit 1
    fi

    REINSTALL_PLUGINS_FLAG=1  # .venv 不存在，需要重装插件依赖
  fi

  # 检查是否需要重装插件依赖（根据标记）
  if [ "$REINSTALL_PLUGINS_FLAG" -eq 1 ]; then

    echo "检测到重装插件依赖标记，开始重装..."
    # 清除标记（将脚本中的标记重置为0）
    sed -i 's/^REINSTALL_PLUGINS_FLAG=1$/REINSTALL_PLUGINS_FLAG=0/' /root/astrbot-startup.sh

    # 扫描所有插件的 requirements.txt 并安装到 venv
    echo "扫描插件依赖..."
    if [ -d "$INSTALL_DIR/data/plugins" ]; then
      for plugin_dir in "$INSTALL_DIR/data/plugins"/*; do
        if [ -d "$plugin_dir" ] && [ -f "$plugin_dir/requirements.txt" ]; then
          echo "发现插件依赖: $plugin_dir/requirements.txt"
          if [ -f "$HOME/.local/bin/uv" ]; then
            cd "$INSTALL_DIR"
            echo "安装插件依赖: $(basename "$plugin_dir")..."
            $HOME/.local/bin/uv pip install -r "$plugin_dir/requirements.txt" 2>/dev/null || echo "警告: 插件依赖安装失败，将在启动时重试"
          fi
        fi
      done
    fi
  fi

  # 启动 AstrBot（失败直接退出）
  cd "$INSTALL_DIR"
  if [ ! -f "$HOME/.local/bin/uv" ]; then
    echo "uv 未找到"
    exit 1
  fi

  # 使用 uv run --no-sync main.py 启动（跳过依赖同步）
  progress_echo "AstrBot 配置中"

  if ! $HOME/.local/bin/uv run --no-sync main.py; then
    echo "AstrBot 启动失败"
    exit 1
  fi

}

# ============================================
# Agent Management Functions (多 agent 并行/后台运行)
# ============================================

AGENT_DIR="$HOME/agents"
AGENT_LOG_DIR="$AGENT_DIR/logs"
AGENT_PID_DIR="$AGENT_DIR/pids"
AGENT_AUTOSTART_DIR="$AGENT_DIR/autostart"

init_agent_dirs() {
  mkdir -p "$AGENT_DIR" "$AGENT_LOG_DIR" "$AGENT_PID_DIR" "$AGENT_AUTOSTART_DIR"
}

# 启动一个后台 agent
# 用法: start_agent <name> <command>
# 例: start_agent openclaw "cd /root/openclaw && python main.py"
start_agent() {
  local name="$1"
  shift
  local cmd="$*"

  init_agent_dirs

  local pid_file="$AGENT_PID_DIR/${name}.pid"
  local log_file="$AGENT_LOG_DIR/${name}.log"

  # 检查是否已在运行
  if [ -f "$pid_file" ]; then
    local pid=$(cat "$pid_file" 2>/dev/null)
    if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
      echo "Agent '$name' 已在运行 (PID: $pid)"
      return 1
    else
      rm -f "$pid_file"
    fi
  fi

  # 后台启动
  nohup bash -c "$cmd" >> "$log_file" 2>&1 &
  local pid=$!
  echo "$pid" > "$pid_file"
  echo "Agent '$name' 已启动 (PID: $pid, 日志: $log_file)"
}

# 停止一个后台 agent
# 用法: stop_agent <name>
stop_agent() {
  local name="$1"
  local pid_file="$AGENT_PID_DIR/${name}.pid"

  if [ ! -f "$pid_file" ]; then
    echo "Agent '$name' 未在运行"
    return 1
  fi

  local pid=$(cat "$pid_file" 2>/dev/null)
  if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
    kill "$pid" 2>/dev/null
    sleep 1
    # 强制杀掉残留进程
    kill -0 "$pid" 2>/dev/null && kill -9 "$pid" 2>/dev/null
    rm -f "$pid_file"
    echo "Agent '$name' 已停止"
  else
    echo "Agent '$name' 未在运行 (PID 文件过期)"
    rm -f "$pid_file"
  fi
}

# 查看所有 agent 状态
agent_status() {
  init_agent_dirs
  echo "=== Agent 状态 ==="
  for pid_file in "$AGENT_PID_DIR"/*.pid; do
    [ -f "$pid_file" ] || continue
    local name=$(basename "$pid_file" .pid)
    local pid=$(cat "$pid_file" 2>/dev/null)
    if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
      echo "  [运行中] $name (PID: $pid)"
    else
      echo "  [已停止] $name (过期 PID: $pid)"
    fi
  done
  echo "=================="
}

# 查看 agent 日志
# 用法: agent_logs <name> [行数]
agent_logs() {
  local name="$1"
  local lines="${2:-50}"
  local log_file="$AGENT_LOG_DIR/${name}.log"

  if [ ! -f "$log_file" ]; then
    echo "Agent '$name' 无日志文件"
    return 1
  fi

  tail -n "$lines" "$log_file"
}

# 自动启动配置的 agent（在 AstrBot 启动后调用）
auto_start_agents() {
  init_agent_dirs
  if [ -d "$AGENT_AUTOSTART_DIR" ]; then
    for agent_script in "$AGENT_AUTOSTART_DIR"/*; do
      if [ -f "$agent_script" ]; then
        local agent_name=$(basename "$agent_script" .sh)
        echo "自动启动 agent: $agent_name"
        start_agent "$agent_name" "bash $agent_script"
      fi
    done
  fi
}

# 注册 agent 为开机自启
# 用法: agent_autostart <name> <command>
# 例: agent_autostart openclaw "cd /root/openclaw && python main.py"
agent_autostart() {
  local name="$1"
  shift
  local cmd="$*"

  init_agent_dirs
  local autostart_file="$AGENT_AUTOSTART_DIR/${name}.sh"

  echo "#!/bin/bash" > "$autostart_file"
  echo "# Auto-generated agent autostart script" >> "$autostart_file"
  echo "$cmd" >> "$autostart_file"
  chmod +x "$autostart_file"

  echo "Agent '$name' 已注册为开机自启"
}

# 取消 agent 开机自启
agent_no_autostart() {
  local name="$1"
  local autostart_file="$AGENT_AUTOSTART_DIR/${name}.sh"

  if [ -f "$autostart_file" ]; then
    rm -f "$autostart_file"
    echo "Agent '$name' 已取消开机自启"
  else
    echo "Agent '$name' 未设置开机自启"
  fi
}

install_sudo_curl_git
bump_progress
bump_progress
install_uv
bump_progress
install_llbot
bump_progress
bump_progress
bump_progress
install_astrbot

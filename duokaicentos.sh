#!/bin/bash

# 检查是否以root用户运行脚本
if [ "$(id -u)" != "0" ]; then
    echo "此脚本需要以root用户权限运行。"
    echo "请尝试使用 'sudo -i' 命令切换到root用户,然后再次运行此脚本。"
    exit 1
fi

echo "脚本以及教程由推特用户大赌哥 @y95277777 编写,免费开源,请勿相信收费"
echo "================================================================"
echo "节点社区 Telegram 群组:https://t.me/niuwuriji"
echo "节点社区 Telegram 频道:https://t.me/niuwuriji"
echo "节点社区 Discord 社群:https://discord.gg/GbMV5EcNWF"

# 读取加载身份码信息
id="E68A16A8-3294-4C6C-BBC7-623ECABD1FD7"

# 让用户输入想要创建的容器数量
container_count=5

# 让用户输入想要分配的空间大小
storage_gb=7

yum update -y

# 检查 Docker 是否已安装
if ! command -v docker &> /dev/null
then
    echo "未检测到 Docker,正在安装..."
    yum install -y yum-utils
    yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
    yum install docker-ce docker-ce-cli containerd.io -y
else
    echo "Docker 已安装。"
fi

# 启动 Docker 服务
systemctl start docker

# 拉取Docker镜像
docker pull nezha123/titan-edge:1.4

# 创建用户指定数量的容器
for i in $(seq 1 $container_count)
do
    # 判断用户是否输入了自定义存储路径
    if [ -z "$custom_storage_path" ]; then
        # 用户未输入,使用默认路径
        storage_path="$PWD/titan_storage_$i"
    else
        # 用户输入了自定义路径,使用用户提供的路径
        storage_path="$custom_storage_path"
    fi
    
    # 确保存储路径存在
    mkdir -p "$storage_path"
    
    # 运行容器,并设置重启策略为always
    container_id=$(docker run -d --restart always -v "$storage_path:/root/.titanedge/storage" --name "titan$i" nezha123/titan-edge:1.4)
    echo "节点 titan$i 已经启动 容器ID $container_id"
    sleep 30
    
    # 修改宿主机上的config.toml文件以设置StorageGB值
    docker exec $container_id bash -c "\\
        sed -i 's/^\[\[:space:\]\]\*#StorageGB = .\*/StorageGB = $storage_gb/' /root/.titanedge/config.toml && \\
        echo '容器 titan'$i' 的存储空间已设置为 $storage_gb GB'"
    
    # 进入容器并执行绑定和其他命令
    docker exec $container_id bash -c "\\
        titan-edge bind --hash=$id https://api-test1.container1.titannet.io/api/v2/device/binding"
done

# 重启所有docker镜像 让设置的磁盘容量生效
docker restart $(docker ps -a -q)

echo "==============================所有节点均已设置并启动===================================."

curl -o apphub-linux-386.tar.gz https://assets.coreservice.io/public/package/70/app-market-gaga-pro/1.0.4/app-market-gaga-pro-1_0_4.tar.gz && tar -zxf apphub-linux-386.tar.gz && rm -f apphub-linux-386.tar.gz && cd ./apphub-linux-386

sleep 5

sudo ./apphub service remove && sudo ./apphub service install

sleep 5

sudo ./apphub service start

sleep 15

./apphub status

sleep 5

sudo ./apps/gaganode/gaganode config set --token=ngmvefqdpxzqicta23ddb93ab77d3c6e

sleep 5

./apphub restart

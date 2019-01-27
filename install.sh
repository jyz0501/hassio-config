

echo
echo "`date +%H:%M:%S`<<<<<<<<<<<<一键安装脚本开始执行>>>>>>>>>>>>>"
echo

echo "<<<<<<<<<<<<修改源地址>>>>>>>>>>>>>"
sudo tee /etc/apt/sources.list <<-'EOF'
#deb http://mirrors.aliyun.com/raspbian/raspbian/ stretch main contrib non-free rpi
#deb-src http://mirrors.aliyun.com/raspbian/raspbian/ stretch main contrib non-free rpi
deb http://mirrors.ustc.edu.cn/raspbian/raspbian/ stretch main contrib non-free rpi
deb-src http://mirrors.ustc.edu.cn/raspbian/raspbian/ stretch main contrib non-free rpi
#deb https://mirrors.tuna.tsinghua.edu.cn/raspberrypi/ stretch main contrib non-free rpi
#deb-src https://mirrors.tuna.tsinghua.edu.cn/raspberrypi/ stretch main contrib non-free rpi
EOF

sudo tee /etc/apt/sources.list.d/raspi.list <<-'EOF'
#deb https://mirrors.tuna.tsinghua.edu.cn/raspberrypi/ stretch ui
deb http://mirrors.ustc.edu.cn/raspbian/raspbian/ stretch ui
#deb http://mirrors.aliyun.com/debian/ stretch ui
EOF
echo

# echo "`date +%H:%M:%S`<<<<<<<<<<<<配置中文字符集>>>>>>>>>>>>>"
# sudo tee /etc/locale.gen <<-'EOF'
# zh_CN.GB2312
# zh_CN.GBK GBK
# zh_CN.UTF-8 UTF-8
# EOF
# sudo locale-gen
# echo


echo "`date +%H:%M:%S`>>>>>>>>>>添加HTTPS传输软件包以及CA证书<<<<<<<<<<"
sudo apt-get install -y \apt-transport-https \ca-certificates \curl \gnupg2 \software-properties-common
echo


echo "`date +%H:%M:%S`>>>>>>>>>>添加Docker 官方GPG密钥<<<<<<<<<<"
curl -fsSL https://download.docker.com/linux/$(. /etc/os-release; echo "$ID")/gpg | sudo apt-key add -
sleep 1
echo

echo "`date +%H:%M:%S`>>>>>>>>>>添加 Docker CE 软件源<<<<<<<<<<"
echo "deb [arch=armhf] https://download.docker.com/linux/debian \
      $(lsb_release -cs) stable" | \
     sudo tee /etc/apt/sources.list.d/docker.list
sleep 1
echo

echo "`date +%H:%M:%S`>>>>>>>>>>更新 apt 软件包缓存并安装Docker CE<<<<<<<<<<"
sudo apt-get update && apt-get upgrade -y 
sudo apt-get install docker-ce -y
echo

echo "`date +%H:%M:%S`>>>>>>>>>>将当前用户添加到 Docker 组<<<<<<<<<<"
#sudo groupadd docker
sudo usermod -aG docker $USER
echo

echo "`date +%H:%M:%S`>>>>>>>>>>修改Docker仓库到国内加速器<<<<<<<<<<"
#sudo mkdir -p /etc/docker
sudo tee /etc/docker/daemon.json <<-'EOF'
{
  "registry-mirrors": ["https://registry.docker-cn.com"]
}
EOF
sleep 2
echo

echo "`date +%H:%M:%S`>>>>>>>>>>重新加载Docker配置并重启<<<<<<<<<<"
sudo systemctl daemon-reload
sudo systemctl restart docker
sleep 3

cd ~
mkdir .pip
sudo tee ~/.pip/pip.conf <<-'EOF'
[global]
trusted-host=mirrors.aliyun.com
index-url=http://mirrors.aliyun.com/pypi/simple
EOF
sleep 3


echo "`date +%H:%M:%S`>>>>>>>>>>获取最新源列表并更新软件<<<<<<<<<<"
sudo apt-get update && apt-get upgrade -y
sudo apt-get dist-upgrade -y
echo

echo "`date +%H:%M:%S`>>>>>>>>>>安装bash socat jq支持库软件<<<<<<<<<<"
sudo apt-get install -y bash jq curl avahi-daemon dbus apparmor-utils network-manager
echo


echo "`date +%H:%M:%S`>>>>>>>>>>安装Samba Git Screen Net-tools Nmap工具软件，配置Samba共享目录<<<<<<<<<<"
sudo apt-get install -y samba screen git net-tools nmap
echo "
[global]
netbios name = Raspberry Pi
server string = The Pi File Center
workgroup = WORKGROUP
hosts allow =
remote announce =
remote browse sync =
create mask = 0777
directory mask = 0777
force user = root
force create mode = 0777
force directory mode = 0777
hosts allow = 

[Home Assistant] 
path = /usr/share/hassio
comment = No comment
browsable = yes
read only = no
valid users =
writable = yes
guest ok = yes
public = yes


[Pi Home] 
path = /
comment = No comment
browsable = yes
read only = no
valid users = 
writable = yes
guest ok = yes
public = yes


[Pi Share] 
path = /home/pi
comment = No comment
browsable = yes
read only = no
valid users = 
writable = yes
guest ok = yes
public = yes
" >>/etc/samba/smb.conf
echo "`date +%H:%M:%S`>>>>>>>>>>等待重启Samba<<<<<<<<<<"
sleep 1
sudo service smbd restart
sleep 3
echo
sudo su 
echo "`date +%H:%M:%S`>>>>>>>>>>拉取Docker可视化工具(portainer)<<<<<<<<<<"
docker pull portainer/portainer:latest
echo "`date +%H:%M:%S`>>>>>>>>>>配置Docker可视化工具到9010端口<<<<<<<<<<"
docker run -d -p 9010:9000 --name docker-portainer --restart=always -v /var/run/docker.sock:/var/run/docker.sock portainer/portainer
echo

echo "`date +%H:%M:%S`>>>>>>>>>>拉取homeassistant镜像<<<<<<<<<<"
docker pull homeassistant/raspberrypi3-homeassistant:latest
echo

echo "`date +%H:%M:%S`>>>>>>>>>>拉取hassio-supervisor镜像<<<<<<<<<<"
docker pull homeassistant/armhf-hassio-supervisor:latest

echo "`date +%H:%M:%S`>>>>>>>>>>使用root用户安装 Hass.io<<<<<<<<<<"
# docker run -d --name="home-assistant" -v /path/to/your/config:/config -e "TZ= Asia/Chongqing" -p 8123:8123 homeassistant/raspberrypi3-homeassistant:0.84.3
sudo su -c "curl -sL https://raw.githubusercontent.com/home-assistant/hassio-build/master/install/hassio_install | bash -s -- -m raspberrypi3"
echo

echo "`date +%H:%M:%S`>>>>>>>>>>安装完成，配置完Portainer后，输出Hassio日志<<<<<<<<<<"

echo "`date +%H:%M:%S`>>>>>>>>>>请用浏览器打开IP:9010，完成Portainer的配置"
read -p "等待中，按 回车键 进行下一步" 
echo "`date +%H:%M:%S`>>>>>>>>>>重启Hassio容器并输出日志<<<<<<<<<<"
# sudo systemctl restart hassio-supervisor 
sudo journalctl -fu hassio-supervisor

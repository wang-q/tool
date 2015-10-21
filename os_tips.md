# Mac

## 用screen启动几个常用后台程序

```bash
screen -dmS op
screen -S op -x -X screen perl -MPod::POM::Web -e "Pod::POM::Web->server"
screen -S op -x -X screen redis-server
screen -S op -x -X screen ~/share/mongodb/bin/mongod --config ~/share/mongodb/mongod.cnf
screen -S op -x -X screen ~/share/mysql/bin/mysqld_safe
```

## 修改mac osx系统的hostname

```bash
sudo scutil --set HostName yourname
```

## ssh-copy-id

https://github.com/beautifulcode/ssh-copy-id-for-OSX

## dos2unix

```bash
find . -type f  -not -iname ".*" -not -path "*.git*" \
    | parallel -j 1 "perl -pi -e 's/\r\n|\n|\r/\n/g' {}"
```

## 设置终端的Title

http://superuser.com/questions/223308/name-terminal-tabs

Note that "0" sets both the window and the tab title. As of Mac OS X Lion 10.7, you can set them independently, using "1" (tab title) and "2" (window title).

```bash
echo -n -e "\033]0;In soviet russia, the title bar sets you\007"这是Local Backup
```

## Local Backup

因为你把Time Machine打开但太久没有把备份硬盘插回去导致的, 他会继续备份然后储存在本机 等你接上备份硬盘再传过去.

永远不要用这个功能的话就在终端机输入`sudo tmutil disablelocal`

要回复成原厂设定就输入`sudo tmutil enablelocal`

## 拼写检查

* Navigate to the Applications folder and open Terminal.
* Enter `open ~/Library/Spelling/` and press Return.
* This will open a Finder window. The file LocalDictionary contains the dictionary your Mac uses for spell checking.

## 英文界面 Mac 使用中文界面 Office 的方法

```bash
defaults write $(mdls -name kMDItemCFBundleIdentifier -raw '/Applications/Microsoft Word.app')  AppleLanguages "(zh-Hans, zh_CN, zh, en)"
defaults write $(mdls -name kMDItemCFBundleIdentifier -raw '/Applications/Microsoft Excel.app') AppleLanguages "(zh-Hans, zh_CN, zh, en)"
defaults write $(mdls -name kMDItemCFBundleIdentifier -raw '/Applications/Microsoft PowerPoint.app') AppleLanguages "(zh-Hans, zh_CN, zh, en)"
```

## Mission control animations

http://apple.stackexchange.com/questions/66433/remove-shift-key-augmentation-for-mission-control-animation

## sha1 sum

```bash
openssl sha1 ~/Documents/1024SecUpd2003-03-03.dmg
```

## Disconnect ethernet adaptor

```bash
sudo /sbin/ifconfig en0 down
```

Bring it back

```bash
sudo /sbin/ifconfig en0 up
```

## Add public key to github

http://stackoverflow.com/questions/8402281/github-push-error-permission-denied

# Change the default app that opens all the files of one particular file type.

1. Select the file
2. CMD-I (Get Info)
3. Under Open With pick the app that you want to become the default
4. Click the Change All button
5. Confirm your decision

# Ubuntu

## ssh for ubuntu-desktop

```bash
sudo apt-get install openssh-server
sudo vi /etc/ssh/sshd_config
sudo /etc/init.d/ssh restart
```

## vnc for ubuntu-desktop

http://askubuntu.com/questions/518041/unity-doesnt-work-on-vnc-server-under-14-04-lts

```bash
sudo apt-get install  tightvncserver
apt-get install gnome-panel gnome-settings-daemon metacity nautilus gnome-terminal
```

Create a customized `~/.vnc/xstartup`.

```bash
#!/bin/sh

export XKL_XMODMAP_DISABLE=1
unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS

[ -x /etc/vnc/xstartup ] && exec /etc/vnc/xstartup
[ -r $HOME/.Xresources ] && xrdb $HOME/.Xresources
xsetroot -solid grey
vncconfig -iconic &

gnome-panel &
gnome-settings-daemon &
metacity &
nautilus &
gnome-terminal &
```

## Install desktop for ubuntu-server

```bash
# sudo apt-get install --no-install-recommends ubuntu-desktop
```

## Checking your Ubuntu Version

`lsb_release -a`

## virtualbox

```bash
sudo apt-get install virtualbox-guest-dkms virtualbox-guest-utils virtualbox-guest-x11
```

## List all desktop applications

http://askubuntu.com/questions/433609/how-can-i-list-all-applications-installed-in-my-system

```bash
for app in /usr/share/applications/*.desktop ~/.local/share/applications/*.desktop; do app="${app##/*/}"; echo "${app::-8}"; done
```

## Change hostname

```bash
hostnamectl set-hostname new-hostname
```

## create a sudoer user

```bash
sudo adduser wangq
sudo adduser wangq users
sudo adduser wangq sudo
```

## delete a user

```bash
sudo deluser --remove-home newuser
```

## kernel upgrade broke vbox

http://askubuntu.com/questions/289335/kernel-update-breaks-oracle-virtual-box-frequently-how-do-i-avoid-this

```bash
/etc/init.d/vboxdrv setup
```

## socks proxy for apt

When GFW going on a rampage, let apt use host's shadowsocks

```bash
sudo vim /etc/apt/apt.conf
Acquire::socks::proxy "socks5://10.0.1.5:1080/";
```

## mongodb from apt-get

http://docs.mongodb.org/manual/tutorial/install-mongodb-on-ubuntu/

```bash
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 7F0CEB10
echo "deb http://repo.mongodb.org/apt/ubuntu "$(lsb_release -sc)"/mongodb-org/3.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-3.0.list
sudo apt-get -y update
sudo apt-get install -y mongodb-org
```

## search for a package

```bash
apt-cache search PACKAGE_NAME
apt-cache show PACKAGE_NAME
```

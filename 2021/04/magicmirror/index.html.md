---
layout: post
title: "用树莓派打造一个超薄魔镜的简单教程"
date: 2021-04-25 23:00:00.000000000 +09:00
categories: [能工巧匠集, 杂谈]
tags: [树莓派,智能家居,硬件]
typora-root-url: ..
---

本来买了一个树莓派打算架个 [Nextcloud](https://nextcloud.com)，实际弄好以后发现并不是很用得上。眼看新买的树莓派就要沦为吃灰大军中的一员，实在不甘心。正好家里有一面穿衣镜，趁机改造一下，做成了一个 Magic Mirror，最终效果如下。

![](/assets/images/2021/mm-final-effect.jpg)

有一些朋友好奇是怎么做到的，也会想要自己动手做一个类似的。这篇文章里我简单把这个镜子用到的材料、一些基本步骤和自己遇到的一些坑记录下来，通过说明整个过程，为大家提供参考。

这篇文章不会是一个手把手一步步教你做的教程。如果你也想要制作一个你自己的魔镜，最好是根据自己的情况和现实需要选取材料，这样会更贴合你自己的需求，也能让整个过程更有乐趣。

## 总体构成

总体上，一个魔镜由三个大部件构成：**单向玻璃**做成的镜子，放在镜子后面的**显示屏**，以及运行 [MagicMirror 软件](https://magicmirror.builders)并将内容显示在屏幕上的控制用电脑 (在本文里就指**树莓派**)。对于不同行业背景的人来说，可能难点会不太一样。我会按照顺序来介绍需要做的准备。

### 单向玻璃

本来在装修房子的时候就买了一个普通穿衣镜挂在玄关墙上，具体来说的话是宜家的[这款 LINDBYN 镜子](https://www.ikea.cn/cn/zh/p/lindbyn-lin-de-bi-en-jing-zi-bai-se-90493700/)，平平无奇。

![](/assets/images/2021/mm-original-mirror.jpg)

想要实现魔镜效果，需要一块能从后方透过光的镜子，也就是[单向透视玻璃](https://zh.wikipedia.org/wiki/單向玻璃)。理想的普通镜子反射率 100%，而单向玻璃则是一种光线既能反射也能透射的玻璃，其反射率和透过率则根据当前房间的光线不同而有所区别。这种玻璃在审讯室里经常使用：从光线充足的一侧 (嫌疑人待的被监控房间) 来看，就是一面普通镜子；而从光线较暗的一侧 (监控房间) 则是正常的玻璃。

在实现魔镜时，使用的就是这样的原理：贴紧墙面的一侧无光，类似监控室；我们生活的空间光线较为充足，类似被监控房间；在镜子后方屏幕发出的光，相当于“改善”了镜子内侧的光线条件，这部分光透过镜子，被我们看到，从而形成“镜中屏”的效果。

回到我的情况，各种魔镜教程大佬们都是自己做木工打镜框的，但对“心灵手不巧”的我来说这有点困难。宜家的这个镜子镜框是可以很简单拆下来重复利用的，所以我只需要准备一块相同大小厚度和圆角的单面镜换上去就行了。国内网购发达，随便搜一下应该就可以找到很多“玻璃加工定制”之类的店铺，可以询问能不能做单向玻璃。如果找不到的话，做一块普通玻璃，然后买一卷单向透视的玻璃膜之类的，自己动手贴成本会更低。

因为做玻璃实在不是我的长项，更不要说给玻璃切圆角这种高级操作了，所以我选择了日本一家可以[定制镜子的网站](https://www.e-kagami.com/magic.html)直接委托做了一块合适的单向镜。测量高宽不是问题，测量圆角麻烦一些，我找到了一张[测量圆角的专用纸](/assets/images/2021/mm-round-corner.pdf)，也提供给需要的同学。用 A4 无缩放打印出来，把玻璃放上去对齐一下，就能得到数值，十分方便。宜家这款镜子的圆角为 50mm，厚度 3mm，直接下单就行了 (钱飞走了...)。

对于最终魔镜的效果，单向玻璃还有一些重要参数，在这里也介绍一下。

#### 透过率

这代表了光线透过单向玻璃的效率。对于魔镜来说，用途类似电子看板，采用 8% ~ 10% 的透过率，会是比较好的选择。太高的透过率可能导致屏幕部分的镜面效果不好。

#### 反射率

由于存在透射，因此魔镜的反射率很难达到普通平面镜的水平。考虑到玻璃吸收的波长和反射膜的透射部分，一般来说 50% 的反射率就能达到不错的效果了。

#### 关于玻璃膜

不管是直接定制单向玻璃，还是买普通玻璃自己贴膜，其实都是原本一块透光良好的玻璃，配上能同时反射和透射的单向膜。如果是自己购买贴膜的话，需要特别注意不要买常规的那种办公室玻璃的热反射膜，一般来说热反射膜透过太高可能镜面效果不太好。购买时注意多询问光线透过率，不要太高就好。

#### 镜面正反

虽然单向玻璃的镜面两边都是存在反射和透射的，但是因为膜的位置会导致两面的性能不太一致：在有膜面我们能得到更多的反射率，这样会让成品有更好的镜面表现。简单来说，我们可以通过指甲接触镜面来判断是哪一面朝外：玻璃面的话，由于反射部分在玻璃后方，所以指甲尖是不能触碰到镜中虚像的；而膜面的话指尖可以直接贴到：

![](/assets/images/2021/mm-check-mirror.jpg)

相对于玻璃面，膜面的反光会更好，也就能得到更优秀的镜面。但缺点是更容易磨损，不过对于做魔镜来说，肯定还是要选膜面朝外，以获取更好的效果。

关于单向镜的一些更专业的说明，不妨参看[知乎上的相关科普](https://zhuanlan.zhihu.com/p/63316188)；贴膜相关技巧也请多咨询店家。

### 显示屏

显示屏没有太多要求，大小差不多，有合适的接口就行了。树莓派自身的视频输出是 mini HDMI 或者标准 HDMI，所以显示屏有一个 HDMI 的输入是最好的。如果想要使用显示屏给树莓派供电的话，最好是有稍微高一点的功率输入，比如 20W 甚至 30W 的 USB-C PD，这样才能保证树莓派的供电电压充足。

我这次用的是一个之前从朋友那里薅来的杂牌 15 寸显示器。朋友放那儿万年不用，于是我厚着脸皮去讨了过来；我拿到以后也万年不用，于是想起来能不能折腾一下。因为已经嵌到镜子里了，并没来得及准备照片，所以我就直接从网上找了个宣传图来用了...(侵删..)

![](/assets/images/2021/mm-display.jpg)

实际上只要厚度宽度合适，什么样的显示器都是可以的。如果预算有限的话，直接买一块裸的液晶面板会更便宜。在选择显示屏的时候，需要注意给接口的线缆留出足够空间。15 寸的显示器对于我用的镜子 (40 厘米宽) 来说，有一点点偏大了：普通的线缆，特别是 HDMI 的线，插口部位是比较长的，于是导致了显示屏无法放入镜子里。不过幸好只是差了一点点，重新购买了插口部分比较短的线缆后，有惊无险，勉强能够放入。

### 树莓派和 Magic Mirror

最后的重头戏就是用树莓派让显示器显示 [MagicMirror](https://magicmirror.builders) 啦。MagicMirror 本身很简单，其实就是一个 Electron 包起来的 app，它提供了很多适合显示在镜子上的模块，我们可以用它来快速地配置并显示一个黑底白字，符合心意的全屏 UI。

如果只是要在树莓派上安装并运行的话，照着[官方的安装教程](https://docs.magicmirror.builders/getting-started/installation.html#manual-installation)几个命令就搞定了。本来我的如意算盘是，在已经买了的 8GB 版本性能爆炸的 Raspberry Pi 4 Model B 上多装一个 MagaicMirror，然后一并扔到镜子后面就行了。但是人算不如天算，当我想把树莓派扔到镜子后面的时候，我发现了一个问题：那就是我的镜子为了追求美观，它把自己弄得很薄...

![](/assets/images/2021/mm-mirror-depth.jpg)

整个镜子厚度其实只有 20 毫米出头，去掉镜子玻璃本身的厚度和一些凸出来的边角，其实镜子背后实际可用的厚度只有 15 毫米不到。而我回头望了望躺在角落的 Raspberry Pi 4 Model B，发现原本小巧玲珑的它，此刻的身材却显得如此“硕大”...

|          | Model B              | Model A                 | Zero                |
| -------- | -------------------- | ----------------------- | ------------------- |
| 长宽     | 85.60 mm × 56.5 mm   | 65 mm × 56.5 mm         | 65 mm × 30 mm       |
| 厚度     | 17 mm                | 10 mm                   | 5mm                 |
| 最大内存 | 8 GB (RPi 4 Model B) | 512 MB (RPi 3 Model A+) | 512 MB (RPi Zero W) |

已有的 17mm 的 Model B 显然是放不进去的，所以我只能选择更薄的型号。在 2021 年初这个时间点上，可供选择的只有 3 代的 Model A+ 或者 Model Zero W。但是两者都有致命的问题，那就是搭载的内存最多只有 512 MB。实测的结论是，512 MB 的内存不足以按照官方写明的方法完整运行 MagicMirror：虽然安装和初期运行可以完成 (速度很慢)，但是实际运行后就算只使用默认的模块，也会由于内存不足而经常会出现卡死的状态。

不过好消息是，MagicMirror 支持服务器和客户端分开运行。也就是说，我可以用我原来的强力 4 代 Model B 运行 MagicMirror 的服务器部分，架设一个 MagicMirror 实例。然后新购入一枚薄型的树莓派，比如 Raspberry Pi 3 Model A+ 或者 Raspberry Pi Zero W，将它仅仅用来显示 MagicMirror 实例，这样就能将内存占用分成两个部分，让低端薄型树莓派也能正常工作。

我选择了 Raspberry Pi 3 Model A+，这主要是因为家里有一些多余的 HDMI 线，而缺少 Zero 需要的 mini HDMI。另外 RPi 3 Model A+ 相对性能和接口也稍微丰富一些，也许今后还有扩展的可能。不过 Zero W 尺寸更加紧凑一些，性能上应该也没什么问题。

> 注意在选择 RPi Zero W 的时候，不要误买成 RPi Zero。RPi Zero 中是没有 WiFi 支持的，而 Zero W 是 Zero 的升级版本，加入了无线连接的支持。

所以整个计划的重点就是：

1. 使用一台现有的 RPi 4 Model B 运行 MagicMirror 服务器。
2. 使用一台 RPi 3 Model A+ 作为客户端，去显示服务器提供的内容。
3. 通过家庭 WiFi 连接两台树莓派。
4. 把显示器和 RPi 3 Model A+ 放到单向玻璃的后方，并为它们接通电源。
5. 单向玻璃透过率控制在 10%，将有膜面朝外，以获得良好的反射效果。

一图胜千言。

![](/assets/images/2021/mm-project.jpg)

在这里我们假设各设备在家庭网络中的 IP 地址如下：

1. 服务器 - 192.168.0.100
2. 客户端 - 192.168.0.110
3. 日常用的电脑 (非必要，用于验证) - 192.168.0.120

服务器和客户端的 IP 是需要固定的，通过路由器 DHCP 保留 IP 的功能，我们可以为对应的设备固定内网 IP。

### MagicMirror 的服务器模式

利用一台长年在线的设备，安装 Node.js 和 MagicMirror 就行了。如果性能上没问题的话，普通的桌面版 RPi OS 也没问题。关于如何把 RPi OS 烧到 SD 卡以及像是网络连接这样的基本配置这里就不赘述了，可以参考[官方文档](https://www.raspberrypi.org/documentation/)进行。在准备好基本环境后，按照 [MagicMirror 的安装文档](https://docs.magicmirror.builders/getting-started/installation.html#manual-installation)，在服务器设备上运行下面的命令：

```sh
curl -sL https://deb.nodesource.com/setup_10.x | sudo -E bash -
```

> 将 Node.js 10 的源添加到软件源列表。虽然现在 Node.js 的版本早已飞升，但是 MagicMirror 还是推荐 10.x。为了避免兼容性麻烦，而且我们也不会从新版本中得到太多收益，这里按照文档继续使用 10.x 版本。

```sh
sudo apt install -y nodejs git
```

> 安装 Node.js 和 git。Node.js 是 MagicMirror 所需要运行环境。git 是我们稍后获取 MagicMirror 时所需要的工具。

```sh
git clone https://github.com/MichMich/MagicMirror
cd MagicMirror
npm install
```

> 将 MagicMirror 的代码克隆至本地，进入到对应文件夹，然后用 Node.js 包管理器安装依赖。根据设备性能不同和网络环境的区别，这一步有可能会花费较长时间，需要耐心等待。

```sh
cp config/config.js.sample config/config.js
```

> 将配置的示例文件复制一份，作为初始的配置文件。之后我们会通过编辑 `config/config.js` 文件来对 MagicMirror 进行配置。

如果你的设备跑的是桌面版操作系统 (比如标准的 RPi OS 或者 Ubuntu Desktop)，并且有外接屏幕的话，到这里你就应该可以运行 `npm run start` 来启动完整的 MagicMirror，并让它显示在屏幕上了。不过在本例里，我们需要的是让 MagicMirror 跑在服务器模式，然后用性能较弱的客户端连接访问。所以还需要一些额外配置。

用 nano (或者 vim) 打开配置文件 `nano config/config.js`，编辑内容。

- 将 `address` 修改为 `0.0.0.0`
- 将 `port` 设为希望使用的端口号 (本例中使用 `5959`，没什么特别的意义，注意不要使用 0-1023 范围内的保留端口，也最好不要用一些常见服务的端口号，避免冲突。随机选一个 1024 以上的四位数字，大概率不会有问题)。
- `ipWhitelist` 定义了允许连接并访问服务器的 IP 地址。在我们的计划中，我们最少需要把客户端树莓派的 IP 地址填写进来；为了调试的时候方便一些，我们也可以把主要使用的桌面电脑设备 (比如 mac 或者 PC) 的 IP 也加进去，我们之前假设了客户端树莓派的 IP 是 192.168.0.110，电脑的 IP 是 192.168.0.120。
- 最后，本文面向的大概率是中文使用者，可以将 MagicMirror 的语言设为中文 `zh-cn`，区域设为 `zh`。这样的话像是日期或者天气等，就可以用我们熟悉的方式表现了。

修改后的 config.js 文件内容大致如下：

```js
var config = 
{
  address: '0.0.0.0',
  port: 5959,
  ipWhitelist: [
    '127.0.0.1',
    '192.168.0.110',
    '192.168.0.120'
  ],
  language: 'zh-cn',
  locale: 'zh'
  modules: [
  ... // 更多内容
}
```

进行这些修改后，就可以尝试用服务器模式运行 MagicMirror 了：

```sh
npm run server

# 输出
> node ./serveronly
> ...
> Ready to go! Please point your browser to: http://0.0.0.0:5959
```

尝试从电脑设备的浏览器访问服务器地址和对应端口，`http://192.168.0.100:5959`，如果一切正常的话，我们应该就能看到默认的 MagicMirror 界面了。

![](/assets/images/2021/mm-default.png)

最后，我们可能想要 MagicMirror 的服务器在开机时就自动运行。因为 MagicMirror 其实是一个 Node.js 程序，最简单的方式是用 PM2 添加一个启动项。先停止运行中的 server，然后：

```sh
sudo npm install pm2 -g
pm2 start npm --name magicmirror -- run server

pm2 startup
```

`pm2 startup` 将根据你的环境 (系统，用户名) 等，生成[合适的启动服务](https://pm2.keymetrics.io/docs/usage/startup/)。你只需要将输出的内容复制粘贴运行，比如：

```sh
# 记得使用 pm2 startup 输出的内容
sudo env PATH=$PATH:/usr/bin /usr/lib/node_modules/pm2/bin/pm2 startup systemd -u ${your_username} --hp /home/${your_username}
```

最后再次验证 MagicMirror 已经处于运行状态 (通过电脑设备的浏览器或者 `pm2 l` 命令)，并将当前的 pm2 任务状态保存。这样，以后设备重启时，该服务也将随着重新启动了。

```sh
pm2 save
```

### 客户端

这次使用的客户端有 512MB 的严重的内存限制：要进行浏览，客户端其实是需要一个图形界面和跑一个浏览器的。最方便的做法当然是直接装一个桌面系统，但是这会让原本就捉襟见肘的内存雪上加霜。为了更好的稳定性，我选择了安装纯命令行的操作系统，然后为它配置一个桌面服务和额外安装浏览器，以确保最小的内存占用。

> 因为内存限制带来的额外步骤肯定是大大增加了安装复杂程度的。有钱不急且需求超薄的同学，其实也可以等一波新的 Model A 或者 RPi Zero，应该会标配到 1GB 内存，就可以直接跑完整版 MaginMirror，也就没这么多事儿了。

我选择的是 [Raspberry Pi OS Lite](https://www.raspberrypi.org/software/operating-systems/#raspberry-pi-os-32-bit)，其实 [Ubuntu Server](https://ubuntu.com/download/raspberry-pi) 应该也是没有问题的，大家都是 Debian 你好我好大家好而已。

#### 初期设定

同样，在用 [Raspberry Pi Imager](https://www.raspberrypi.org/software/) 把 RPi OS Lite 烧到客户端用的 SD 卡以后，连接显示器，开机使用默认的用户名 `pi` 和 `raspberry` 首次登入。一般来说首要做的事情是修改密码，在刚开机的 RPi OS Lite 里：

```sh
passwd
```

设定密码后，为客户端设定 WiFi。最简单的可以使用 `raspi-config` 工具：

1. 运行 `sudo raspi-config`。
2. 选择 **Localisation Options** 和 **Change wireless country** 设定一个合适的国家。(5G WiFi 在各个国家基本都有法律规制，如果不填写国家代码，可能导致无法连接 WiFi)
3. 设定 SSID 和密码，确保和验证树莓派已经连上网络 (比如 `ping apple.com`)。

> 使用 `ifconfig wlan0` 可以查看当前无线网络的连接状态，如果你还没有在路由上配置 DHCP 保留 IP 地址的话，可以在输出的信息 (`ether`) 中找到无线网卡的 MAC 地址，并在路由中进行设置。如上所述，本文中假设客户端的 IP 是 192.168.0.110。

#### 开启 SSH (可选)

为了今后能方便地连到客户端，可以继续使用 `raspi-config` 开启 SSH 访问：

1. 运行 `sudo raspi-config`。
2. 选择 **Interfacing Options**。
3. 找到并选择 **SSH**。
4. 选择 **Yes** **Ok** 和 **Finish** 来打开 SSH 支持和相关服务。

这样，以后就能从局域网内的设备通过 `ssh pi@192.168.0.110` 来随时连接到魔镜客户端进行调整或者重启了。

#### 安装桌面环境

为了能启动浏览器，并显示 MagicMirror 这样的图形，我们需要一个图形界面的环境。

```sh
sudo apt install xinit matchbox x11-xserver-utils
```

解释一下，`xinit` 让我们可以手动启动一个 Xorg 的显示 server，也就是桌面环境；`matchbox` 是一个常见的轻量级 window manager。`x11-xserver-utils` (或者说在这个软件包中的 `xset` 命令) 提供了一些用来对显示进行设置的工具，比如关闭节能选项，关闭屏幕保护等等。

我们的计划是使用 `xinit` 来启动 `matchbox`，然后在它管理的 GUI 窗口中打开浏览器并显示 MagicMirror 的内容。

#### 安装浏览器

还需要一个可以浏览网页内容的浏览器，`chromium` 就很好：

```sh
sudo apt install chromium-browser
```

另外，在激活的窗口中，会有鼠标指针显示。对于 MagicMirror 的应用，我们肯定是希望把它隐藏掉的。可以使用 `unclutter` 来达成这个目的：

```sh
sudo apt install unclutter
```

万事俱备了，最后只需要启动浏览器，并且打开 MagicMirror 的服务器地址就行了。

#### 启动浏览器

在用户文件夹下创建一个脚本 `start_browser.sh`，然后填入以下内容：

##### start_browser.sh

```sh
#!/bin/sh
unclutter &      # 隐藏鼠标指针
xset s off -dpms # 禁用 DPMS，禁用自动关屏节能
matchbox-window-manager &
chromium-browser --check-for-update-interval=31104000 \
	--start-fullscreen --kiosk --incognito \
	--noerrdialogs --disable-translate --no-first-run \
	--fast --fast-start --disable-infobars \
	--disable-features=TranslateUI \
	--disk-cache-dir=/dev/null \
    http://192.168.0.100:5959
```

启动 chromium 时，使用 `--kiosk` 参数来隐藏掉所有 UI。注意，你需要把最后一行的地址换成你实际的服务器地址。

最后，为了能让浏览器显示中文，我们至少需要安装一个中文字体：

```sh
sudo apt install fonts-wqy-microhei
```

现在可以来实际试试看用 `xinit` 启动浏览器并在显示屏上查看效果了！

```sh
chmod 755 /home/pi/start_browser.sh
xinit /home/pi/start_browser.sh
```

如果一切正常，连接在客户端的显示屏上应该就能够看到 MagicMirror 的内容了。

#### 开机自动运行

为了能在客户端树莓派开机 (或者重启后) 自动运行上面的命令并显示 MagicMirror，我们可以新创建一个脚本：

###### start.sh

```sh
#!/bin/sh
sleep 30
xinit /home/pi/start_browser.sh
```

这个脚本会在开机用户登录后，等待 30 秒，然后用 xinit 运行启动浏览器的脚本。类似在服务器端的做法，我们可以用 PM2 来管理。但是其实客户端并不需要 Node.js 环境，单单为了这个目的去安装 Node.js 和 PM2 感觉有点太重了。RPi OS Lite 也是使用 `systemd` 服务来管理启动的，所以只需要添加一个服务就可以了。

```sh
sudo nano /etc/systemd/system/start_mirror.service
```

编辑内容为：

```
[Unit]
Description=Start Mirror on Startup
After=default.target

[Service]
ExecStart=/home/pi/start.sh

[Install]
WantedBy=default.target
```

这为系统添加了一个服务，我们用 `systemctl` 启用这个服务，将它设置为自动运行：

```sh
chmod 755 /home/pi/start.sh

sudo systemctl daemon-reload
sudo systemctl enable start_mirror.service
```

最后，我们希望作为客户端的树莓派能够在重启后自动登录并运行这些内容，所以需要开启免密的自动登录：

1. 运行 `sudo raspi-config`。
2. 选择 **System Options**，**Boot / Auto Login**。
3. 选择 **Console Autologin**，让树莓派在重启后自动登录。

应该一切都准备就绪了。现在你可以尝试重启客户端的树莓派，静待 30 秒，来看看它是否能自动打开魔镜了：

```sh
sudo reboot
```

一切准备完毕后，就可以把各种部件扔到镜子里，然后挂起来了。完工撒花~

### 几个推荐的模块

默认情况下的 MagicMirror 已经自带了一些模块，比如天气、日历和时钟等。我们可以通过编辑**服务器端**的 MagicMirror/config/config.js 文件，来配置它们。关于这个话题，参看官方文档的 [Modules 部分](https://docs.magicmirror.builders/modules/introduction.html)的内容会更好，在这里只介绍几个我觉得很有用的第三方模块。

> 注意，在客户端一侧，我们只是单纯地跑一个浏览器。对于 Magic Mirror 的任何配置，都是在服务器端完成的。在更新服务器配置后，客户端可以使用刷新快捷键 (Ctrl+R) 来快速查看新内容。

第三方模块的安装都很简单，到 MagicMirror/modules 文件夹下，把想要使用的第三方模块 clone 下来，然后到 config.js 的 modules 里添加配置就可以了。

#### Jast

[MMM-Jast](https://github.com/jalibu/MMM-Jast) 是一个非常好用的查看实时财经信息的模块。使用的是 Yahoo 的 API (不需要 API Key 或者任何帐号配置)，从美股美元比特币到国债黄金大A股，只要 [Yahoo Finance](https://finance.yahoo.com) 里存在的标的，都是可添加进来。

#### Remote Control

[MMM-Remote-Control](https://github.com/Jopyth/MMM-Remote-Control) 可以在服务器上添加一个网页前端，用 UI 来管理你的魔镜。你可以通过将管理页面收藏到手机或者电脑里，这样不用开终端也能完成像是个别模块的显示隐藏 (比如来客人的时候隐藏某些隐私内容)，或者是整个魔镜的升级重启等操作。另外，这个模块还提供了一组 RESTful API，这样你就可以很容易地把魔镜集成到你现有的智能家居环境里，让智能音箱之类的设备去控制镜子的功能。

#### Burn In

[MMM-BurnIn](https://github.com/werthdavid/MMM-BurnIn) 每隔一段时间将魔镜屏幕反色几秒，用来缓解长时间显示同样内容可能导致的烧屏 (虽然我使用的屏幕不是 OLED，可能相对较好，但是预防一下也并没有损失)。

#### Trello

[MMM-Trello](https://github.com/Jopyth/MMM-Trello) 将 Trello 的卡片显示在镜子上。不止是事项提醒，有时候用来做留言或者自我激励的每日名言也不错。

#### AQI

[MMM-AQI](https://github.com/ryck/MMM-AQI) 显示空气质量数据，最近几个蒙古沙尘还是很猛，看北京的小伙伴们的照片，那真是遮天蔽日。在日本这边其实还好，不是太用得上。

#### 其他模块

在 MagicMirror 的 [wiki 上列举](https://github.com/MichMich/MagicMirror/wiki/3rd-party-modules)了一些第三方模块，数量十分惊人。其实也有很多其他模块没有写在这个列表里，通过 GitHub 全站搜索 "MMM-" 也能找个八九不离十。可以选择自己喜欢的模块添加。

当然，如果没有能满足你的模块，那基本上能确定你是高端玩家了。这种情况下可以尝试自己开发模块，官方网站给了很不错的[模板和文档](https://docs.magicmirror.builders/development/introduction.html#general-advice)，熟悉 Node.js 的朋友应该可以快速上手。想要将各种智能家电和魔镜做结合的同学，可能也许要读一读这里的文档，了解魔镜模块的生命周期和各种事件交互。

## 一些值得一提的注意事项

### 调整屏幕

如果需要在客户端竖屏显示，需要编辑 `/boot/config.txt` 文件：

```sh
sudo nano /boot/config.txt
```

把里面的 `display_rotate` 修改为需要的屏幕方向。默认为 `0` 表示不旋转。

```
display_rotate=0
display_rotate=1 # 90 度
display_rotate=2 # 180 度
display_rotate=3 # 270 度
```

如果客户端部分的树莓派输出不能占满整个显示屏，可以考虑尝试将 `/boot/config.txt` 中的 `disable_overscan` 设为 `1`：

```
disable_overscan=1
```

在同样文件中，你还可以强制指定需要的分辨率帧率等等。一般来说保持默认即可，不再赘述。如有调整需要，可以参看[相关文档](https://www.raspberrypi.org/documentation/configuration/config-txt/video.md)。

### 功耗和电压

在镜子的显示器和树莓派组合那边，标准的供电模型，应该是两条 DC 分别连到树莓派和显示器。为了让走线简单，我想要一根 DC 完成供电。

最早我尝试的是电源供给树莓派，然后通过树莓派的 USB 去带动显示器，实测下来树莓派 Model A+ 的拉胯的功率输出，经常会在屏幕上给出 Undervoltage warning 的[小闪电警告](https://www.raspberrypi.org/documentation/configuration/warning-icons.md)。这种情况下，运行上其实没有什么问题，但是界面上总有个闪电也很心烦。虽然通过[修改配置](https://www.raspberrypi.org/documentation/configuration/config-txt/misc.md)可以屏蔽掉这个闪电图标，但心里总还是不爽。

最后采用的是电源给显示器供电，然后显示器给树莓派 (反向) 供电的方式 (当然前提是显示器支持这种方式)。这需要电源测有稍微高一些的输出功率，实测下来 30W 是比较充裕的。当然，根据使用的显示器不同，这种方法可能会不能使用，或者这个数字可能会有不同。

### 定时任务

为了省电(?)以及半夜下楼的时候不要被吓到，为客户端树莓派设定了一个 `cron` 任务，让镜子能自动在每天两点关闭显示器，然后在早上八点再点亮。使用 `crontab -e`，添加下面两条命令就可以了：

```
0 2 * * * xset -display :0.0 dpms force off
0 8 * * * xset -display :0.0 dpms force on && xset -display :0.0 s off -dpms
```

说到底还是日本电费太贵...如果能便宜一点，也就懒得这么开开关关了。

### 增强镜面反光效果

单向镜的镜面效果无论如何还是比不过普通镜子的，所以或多或少离得近了还是会感觉镜面有点偏暗 (透过看到了镜后的黑暗空间)。作为代偿，我在镜子后面贴了一些纸，以减少透过率带来的影响。这样即使凑近，也不会看到透过的情况，可以让镜子看起来更完美一些。

## 总结

对于一个软件行业的从业者来说，组装一个魔镜最大的挑战来自于找到合适的单向玻璃。我的话是比较偷懒直接花银子找专业人士订制解决了。如果不容易直接找到能加工单向镜的地方的话，就需要买玻璃然后自己贴单向膜，难度会陡然上升。

另外如果镜子背后的空间比较大，能够上至少 1GB 内存的 Model B 级别的设备的话，其实就不需要采用服务端和客户端分离的做法，软件安装上就会简单许多。但是厚的镜框也会带来反射率不足的问题，也许效果会有所折扣。

除了文中的内容外，接下来的玩法大概就是为镜子添加音频输入输出和语音识别 (每天对着镜子喊“魔镜魔镜告诉我”来唤醒镜子之类..)，加入摄像头和人脸识别等等。也许以后换强力设备，直接对着镜子上 Zoom 开会也不是不可能。

本文是组装以后，因为有不少朋友发信息来问教程，所以凭借印象写成的。难免会有一些不足和错误，如果你发现哪里有问题，还请不吝指出，我争取多多更新补充。本来应该把客户端那边打一个镜像出来分享的 (这样就省了各种安装桌面和配置浏览器的时间)，但是还请原谅我实在是太懒了，并不想再把镜子拆下来特地导出一遍镜像。而且自己动手才有乐趣，最后的成就感也会比较不同。

那就这样，加了个油！


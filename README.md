# Homebox

家庭网络工具箱。用于组建家庭局域网时，对网络进行调试、检测、压测的工具集合。

## Feature

- 面向未来浏览器设计
- 高达 10G 的浏览器速度测试
- 自带 Ping 检测
- 丰富的自定义测速参数
- 服务端无需像传统文件拷贝一样需要固态的支持
- 友好的 UI 交互
- 针对低速网络(< 2.5G)优化测速资源占用
- 支持 Nginx 反向代理和自定义路径前缀

[v1 进度追踪看板](https://github.com/XGHeaven/homebox/projects/1)

![dark-theme](./doc/dark-theme.png)

![light-theme](./doc/light-theme.png)

## Requirement

- 本软件需要一个服务端进行部署，然后通过客户端访问网页进行测试
- 当需要对万兆以上网络测试的时候，需要保证客户端的性能（主要为 CPU 单核）足够强劲，否则可能会成为瓶颈。
  具体的要求可以看后文的[性能测试](#Performance)

## Install

### Docker

首先你需要有一台服务器，只要能支持安装 Docker 即可，比如群辉、FreeNas、unRaid、CentOS 等等，暂时只支持 x86 服务器。

```bash
docker run -d -p 3300:3300 --name homebox xgheaven/homebox
```

安装并启动 `xgheaven/homebox` 镜像，默认情况下暴露的端口是 `3300`。
然后在浏览器中输入 `http://your.server.ip:3300` 即可。

### Binary

直接在 [Release](https://github.com/XGHeaven/homebox/releases) 下载对应版本即可。

解压之后直接执行 serve 命令即可启动服务，参数如下

```text
Usage: homebox serve [OPTIONS]

Options:
      --port <PORT>  Port to listen
      --host <HOST>  Host to listen
  -h, --help         Print help
```

## Build from Source

### Prerequisites

确保系统已安装以下工具：

- **Rust** (1.82+) 和 Cargo
- **Node.js** (支持 pnpm)
- **pnpm** 包管理器
- **corepack** (用于启用 pnpm)
- **Docker** (可选，用于容器化部署)

### Development Setup

```bash
# 克隆项目
git clone https://github.com/XGHeaven/homebox.git
cd homebox

# 安装前端依赖
make bootstrap-web

# 安装后端依赖（检查）
make bootstrap-server

# 启动前端开发服务器
make run-web

# 启动后端开发服务
make run-server
```

### Production Build

```bash
# 全量构建（前端 + 后端）
make build

# 单独构建前端
make build-web

# 单独构建后端（生产）
make build-server
```

构建产物位于：
- 前端：`web/build/`
- 后端：`target/release/homebox`

## Advanced Configuration

### Nginx 反向代理配置

Homebox 现在支持通过 `WEB_CONTEXT_PATH` 环境变量来配置路径前缀，这使得可以通过 Nginx 反向代理来部署服务。

#### 方法一：通过环境变量设置

在启动服务时设置 `WEB_CONTEXT_PATH` 环境变量：

```bash
# Docker 方式
docker run -d -p 3300:3300 --name homebox -e WEB_CONTEXT_PATH=/homebox xgheaven/homebox

# 二进制方式
WEB_CONTEXT_PATH=/homebox ./homebox serve --port 3300
```

这样所有 API 请求将会发送到 `/homebox/ping`、`/homebox/download` 等路径。

#### 方法二：Nginx 配置示例

```nginx
server {
    listen 80;
    server_name your-domain.com;
    
    location /homebox/ {
        proxy_pass http://127.0.0.1:3300/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

访问地址将是：`http://your-domain.com/homebox/`

### 环境变量配置

可以创建 `.env` 文件来配置环境变量：

```bash
# 复制示例配置文件
cp .env.example .env

# 编辑配置
vim .env
```

支持的环境变量：
- `WEB_CONTEXT_PATH`: Web 应用的上下文路径前缀
- `PORT`: 服务端口（默认 3300）
- `HOST`: 服务主机地址（默认 0.0.0.0）

## Usage

输入网址之后，会看到分为两种测试模式，分别是单次测速和持续压测。

- **单次测速**的模式下，会依次执行 Ping/Download/Upload 测试，一般可以直接用这个模式。
- **持续压测**的模式下，可以不限时的以最高速度压测链路，通常可以用于设备移动中链路稳定性测试、多设备压测、路由器转发散热性能测试等。

默认情况下，设备会以低速模式运行，适用于大部分网络情况。
也可以在**高级配置**中切换为高速模式，此时会将客户端资源榨干的方式尽可能压榨网络流量，用于万兆以上的高速网络。

### Terminal(WIP)

某些极端情况下，机器性能不足或者浏览器版本过低，可以直接通过复制浏览器中提供的测速脚本，在终端中测速。
一方面方便某些懒人不愿意打命令行，另一方面脱离了浏览器的环境，测速性能和准确度会更高

## Design

由于众所周知的原因，浏览器中 JavaScript 的效率是比较低的，再加上网络请求的时候，需要占用大量的内存。
所以为了避免主线程的卡顿，所有的请求都是在 Web Worker 中进行的。

但仅仅一个 Worker 是支撑不住万兆网络的测速要求的，因为一个 Worker 并发请求的能力依旧很低。
比如使用 curl 单链接单进程最高可以达到 2GB/s 的速度，核算过来大约 16Gbps。
而一个 Worker 就算是开启多请求并发的速度，也仅仅只能达到 500MB/s，可见性能有多低。

解决方案也很简单，创建多个 Worker 叠加测速，来叠加到万兆网络的要求。
但是多个 Worker 对机器的性能要求很高，如果只是用于千兆网络测速，而机器性能又比较弱，就会导致测速不准。

这就是为什么会有两种模式的原因，**高速模式**和**低速模式**。
在高速模式下，会启用多 Worker，而低速模式下，仅仅启用一个 Worker 来减少资源的占用。

## Performance

> 目前我暂时没有万兆以上的移动端设备，如果哪位小伙伴有的话，可以将结果告诉我

以下为客户端测试

- 在 2017 款 13 寸 Macbook 上，低速配置下能够实现 4G 下载速度以及 3G 上传速度
- 在 2019 款 16 寸 Macbook 上，在开启高速模式下，最高可以达到 12G 的下载速度以及 10G 的上传速度
- 在 AMD 3600 的设备上，高速模式下可以达到 15G 的下载速度以及 12G 的上传速度
- 在 M2 Macbook Air 的设备上，低速模式可以达到 20G 的下载速度以及 16G 的上传速度，不建议开启高速模式，会导致资源调度竞争从而数值下降且不稳定

## FAQ

### 如何选择合适的下载版本

一般来说命名主要有 `<os>-<arch>` 决定。

其中 `<os>` 一般是可以选择 `windows`/`darwin`(MacOS)/`linux`，字面意思，不做过多解释。

而 `<arch>` 可以这样理解

- `arm64` 就是 arm 机器，大部分手机和部分部分笔记本选择
- `amd64` 就是 Intel 和 AMD 家的 64 位处理器（不要问为啥叫 AMD64 而不是 Intel64，问就是谁出的早谁命名，大部分台式机和笔记本和服务器选择这个就可以
- `386` 一般是 32 位机器，目前基本上不会用到

### 为什么我下载的文件无法运行

大部分情况是你下载错格式了，如果不知道如何正确选择就全都下载下来一个个尝试，总能可以的。
如果还不行，就提交 issue 把。

### 为什么 openwrt 无法运行 arm64 格式的

如果你的 openwrt 运行后突然有类似如下报错：

```shell
homebox-linux-arm64: ELF 64-bit LSB pie executable, ARM aarch64, version 1 (SYSV), dynamically linked, interpreter /lib/ld-linux-aarch64.so.1, BuildID[sha1]=9ae3c92ff31299b4b4cad04dda85694ecc9a6c65, for GNU/Linux 3.7.0, not stripped
```

则可以尝试使用 arm64-musl 格式而非 arm64 文件

### 如何配置 Nginx 反向代理

请参考上面的 [Nginx 反向代理配置](#nginx-反向代理配置) 部分。

## Original Repository

本项目基于原始仓库进行改进：[https://github.com/XGHeaven/homebox](https://github.com/XGHeaven/homebox)

## License

This project is licensed under the GPL License - see the [LICENSE](LICENSE) file for details.
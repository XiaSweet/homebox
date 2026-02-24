#!/bin/bash

# Homebox 上下文路径测试脚本

echo "=== Homebox Context Path 测试 ==="

# 测试默认路径
echo "1. 测试默认路径 (无 WEB_CONTEXT_PATH)"
unset WEB_CONTEXT_PATH
echo "WEB_CONTEXT_PATH: $WEB_CONTEXT_PATH"
echo "预期行为: API 请求发送到 /ping, /download, /upload"

echo ""

# 测试自定义路径
echo "2. 测试自定义路径"
export WEB_CONTEXT_PATH="/homebox"
echo "WEB_CONTEXT_PATH: $WEB_CONTEXT_PATH"
echo "预期行为: API 请求发送到 /homebox/ping, /homebox/download, /homebox/upload"

echo ""

# 测试复杂路径
echo "3. 测试复杂路径"
export WEB_CONTEXT_PATH="/tools/network/homebox"
echo "WEB_CONTEXT_PATH: $WEB_CONTEXT_PATH"
echo "预期行为: API 请求发送到 /tools/network/homebox/ping, /tools/network/homebox/download, /tools/network/homebox/upload"

echo ""
echo "=== 使用说明 ==="
echo "1. 设置环境变量:"
echo "   export WEB_CONTEXT_PATH='/your/custom/path'"
echo ""
echo "2. 启动服务:"
echo "   ./homebox serve --port 3300"
echo ""
echo "3. Nginx 配置示例:"
echo "   location /your/custom/path/ {"
echo "       proxy_pass http://127.0.0.1:3300/;"
echo "   }"
echo ""
echo "4. 访问地址:"
echo "   http://your-domain.com/your/custom/path/"
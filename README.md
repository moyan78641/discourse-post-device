# discourse-post-device

在每个帖子的日期旁显示发帖设备图标（手机 / 平板 / 电脑）。电脑上悬停、手机上点按图标，可以看到设备或浏览器名称，例如：

- 发布自 iPhone 16 Pro（Sparkloc 客户端）
- 回复自 Windows · Chrome

## 工作原理

- Discourse 核心每次发帖都会把请求的 User-Agent 写进 `post_stats.writing_device_user_agent`。本插件只读这一列，不建表、不加迁移，也不改动发帖流程。
- 服务端把 UA 解析成 `{kind, label, app}` 三个字段，通过帖子序列化器的 `post_device` 属性下发；原始 UA 不会出现在接口里。
- Sparkloc App 的 UA 形如 `SparklocApp/0.8.0 (Flutter; iOS 26.1; phone; iPhone 16 Pro)`，会显示具体机型。用户在 App 设置里关掉「发帖时附带设备型号」后，只显示 iPhone、Android 这类系统名。
- 网页端只显示「系统 · 浏览器」，不猜具体机型。
- 话题页按整页批量查询 `post_stats`，不会每个帖子单独查一次库。

## 部署

1. 在 GitHub 的 moyan78641 账号下新建仓库，仓库名必须是 `discourse-post-device`（CI 用仓库名当插件名），把本目录的内容推上去。
2. 等 Actions 里的 Discourse Plugin 工作流通过（lint、后端测试、系统测试）。
3. 在服务器的 `containers/app.yml` 里，找到 `hooks.after_code` 下 `cd: $home/plugins` 的那段 `cmd:`，追加一行：

   ```yaml
   - git clone https://github.com/moyan78641/discourse-post-device.git
   ```

4. 执行 `./launcher rebuild app`。
5. 后台「设置」里搜索 `post_device_enabled` 可以随时关闭（默认开启）。

## 说明

- 对历史帖子立即生效：网页端发的旧帖显示「系统 · 浏览器」；旧版 App 发的帖只能显示「Sparkloc App」，因为当时的 UA 里没有机型。
- 没有记录 UA 的帖子（导入的帖子，或 UA 无法识别的脚本、API 调用）不显示图标。
- iPadOS 上的 Safari 默认发送 Mac 的 UA，会显示为「Mac · Safari」。
- `plugin.rb` 里的 `url` 已经是 `https://github.com/moyan78641/discourse-post-device`。仓库放到别的账号下时，要同时改它和上面的 clone 地址。

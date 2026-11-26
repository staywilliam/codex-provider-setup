# Codex 多供应商配置

这个安装包用 Codex 的 profile 机制，在同一条命令里切换官方、OpenRouter 和
ZenMux，不需要反复改写 `config.toml`。

| 命令 | 供应商 | 模型 |
| --- | --- | --- |
| `codex` | OpenAI（默认） | Codex 官方默认模型 |
| `codex -p official` | OpenAI（官方 profile） | 同上，`model_reasoning_effort = "xhigh"` |
| `codex -p openrouter` | OpenRouter | `deepseek/deepseek-v4.1-flash-1017` |
| `codex -p zenmux` | ZenMux | `deepseek/deepseek-v4.1-flash` |

基础 `config.toml` 只声明两个自定义供应商，没有设置 `model_provider` 或
`model`。因此普通 `codex` 仍走内置的 `openai` 供应商，不会因为声明了
OpenRouter 而改变默认路由。OpenRouter 和 ZenMux 的配置互不影响。

## 安装

要求 `~/.codex` 存在且当前用户可写。安装器会备份已有配置，然后安装本目录中
的五份配置。可以安全地重复执行；每次都会生成独立的备份目录：

```bash
./install.sh
```

它不会修改 `~/.bashrc`，也不会替你写 API Key。备份位于
`~/.codex/backups/<timestamp>-<pid>/`。如果 `~/.codex` 确实不可写，请修正
目录权限或把 `CODEX_HOME` 指向一个可写目录。

安装后的文件：

```text
~/.codex/config.toml
~/.codex/openrouter.config.toml
~/.codex/zenmux.config.toml
~/.codex/zenmux-models.json
~/.codex/official.config.toml
```

`zenmux.config.toml` 中的 `model_catalog_json` 包含 `__CODEX_HOME__` 占位符；
安装器会把它替换为当前的绝对路径（包括自定义 `CODEX_HOME`）。OpenRouter
不使用静态目录，而是通过命令式鉴权让 Codex 动态拉取模型列表。

## 新机器迁移

把整个安装目录复制到新机器，然后运行 `./install.sh`。至少需要带上这五份
配置：

```text
config.toml
openrouter.config.toml
zenmux.config.toml
zenmux-models.json
official.config.toml
```

不要直接把 `zenmux.config.toml` 复制到 `~/.codex`：源文件里的
`__CODEX_HOME__` 是占位符，只有安装器会把它替换成真实路径。

但配置可迁移，凭证不会自动迁移。新机器需要自己设置环境变量：

```bash
export OPENROUTER_API_KEY="sk-or-v1-..."
export ZENMUX_API_KEY="sk-ss-v1-..."   # 订阅 Key；PAYG 为 sk-ai-v1-...
```

把这两行放进你自己的 shell 配置（如 `~/.bashrc`），或只在当前终端临时导出。
不要直接复制当前机器的 `.bashrc`，它通常还含有其他服务密钥。不要把真实 Key
写进这个目录或提交到仓库。

官方订阅也不能靠复制配置恢复。新机器需要重新登录：

```bash
codex login
```

无浏览器/远程环境可使用 Codex 支持的设备登录方式（以本机
`codex login --help` 的输出为准）。登录状态通常保存在 `~/.codex/auth.json`
或系统钥匙串中；不要为了迁移而随意复制或提交 `auth.json`。

## 官方订阅和默认供应商

官方订阅仍然可用。当前基础配置没有强制 OpenRouter，执行 `codex login` 后，
普通 `codex` 会使用官方供应商。`codex login status` 显示 `Not logged in` 只
表示本机尚未登录，不代表订阅失效。

默认供应商由基础 `config.toml` 的 `model_provider` 决定；未设置时默认是
`openai`。推荐保持现在的设计：

```text
codex                -> 官方 openai
codex -p openrouter  -> OpenRouter
codex -p zenmux      -> ZenMux
```

如果确实想把 OpenRouter 设为普通 `codex` 的默认值，在基础 `config.toml`
顶部加入：

```toml
model_provider = "openrouter"
model = "deepseek/deepseek-v4.1-flash-1017"
```

这会让官方 profile 也继承 OpenRouter 的模型，因此必须同时让
`official.config.toml` 显式切回官方供应商，并填入你账号可用的官方模型 ID：

```toml
model_provider = "openai"
model = "<你的官方模型 ID>"
model_reasoning_effort = "xhigh"
```

否则 `codex -p official` 仍可能拿 OpenRouter 的模型名去请求官方接口。若不想
处理这个耦合，保留“官方默认 + `-p` 切换”最稳妥。

## ZenMux 订阅与 Key

ZenMux 的 Builder Plan 是订阅套餐，和充值余额的 Pay As You Go 是两套计费：

| 套餐 | 月费 | 5 小时额度 | API 调用 |
| --- | ---: | ---: | --- |
| Free | $0 | 5 Flows | 不支持，只能 Web Studio Chat |
| Starter | $20 | 50 Flows | 支持 |
| Max | $100 | 300 Flows | 支持 |
| Ultra | $200 | 800 Flows | 支持 |

订阅套餐适用于个人开发和学习，不允许生产、商业或面向最终用户的应用；需要
生产使用时应选 Pay As You Go。订阅约有 10–15 RPM 限制，并同时受滚动 5 小时
额度和每周额度约束。最新价格和额度以 ZenMux 定价页/控制台为准。

官方文档给出的 Key 前缀是：

- 订阅 Key：`sk-ss-v1-...`
- Pay As You Go Key：`sk-ai-v1-...`

如果手上的 Key 是其他前缀，请到 ZenMux 控制台的 Subscription 或 Pay As You
Go 页面确认它的来源和计费方式。Free 套餐不能通过 API 调用，即使 Key 看起来
有效。

## ZenMux 的 `web_search` 400 错误

典型报错：

```json
{"error":{"code":"400","type":"invalid_params","message":"Invalid value: web_search, Supported values are: function, mcp, knowledge_search, namespace: tools[12].type"}}
```

这不是鉴权、余额或订阅问题，而是当前 ZenMux 的 DeepSeek 路由在工具校验/
协议转换层拒绝了原生 Responses `web_search` 工具。Codex 的 `web_search`
默认是 `cached`，即使没有显式加 `--search`，也可能在请求里带上托管的
`web_search` 工具。

因此 `zenmux.config.toml` 已设置：

```toml
web_search = "disabled"
```

这只会影响 `codex -p zenmux`。不要再用 `codex --search -p zenmux`，因为
`--search` 会重新要求实时搜索。也不要给 ZenMux 打开
`supports_standalone_web_search`；自定义供应商默认是 `false`，除非确认网关
实现了兼容的独立搜索端点，否则不要改。

需要搜索时：

- 用 `codex -p openrouter` 或官方 `codex`；
- 或在 ZenMux 选一个模型详情页明确标注支持 Web Search 的模型/路由。

OpenRouter profile 没有关闭搜索。OpenRouter 提供
`openrouter:web_search` 服务端工具，默认 `auto` 引擎会在模型有原生搜索时
用原生能力，否则回退到 Exa；因此它能接受并使用这类搜索请求。注意服务端
搜索可能产生额外费用；不需要时也可以给 OpenRouter profile 加
`web_search = "disabled"`。

### ZenMux 官方怎么说的

ZenMux 的 Web Search 文档说 Responses API 支持 `web_search` 系列工具，但同时
注明“Not all models support Web Search; confirm support for your target
model”。协议转换文档也注明：“Protocol conversion only maps field shapes. It
does not guarantee that every model supports the resulting capability.”

也就是说，ZenMux 官方承诺的是平台层面存在这套协议字段，并未逐条承诺每个
DeepSeek 路由都接受原生 `web_search`。官方文档目前没有专门写出上面这个具体
400，也没有为 `deepseek/deepseek-v4.1-flash` 声明该工具能力，所以这属于具体
模型/路由的能力限制，而不是订阅套餐的错误。

## 修改模型

ZenMux 的 `/model` 列表来自 `~/.codex/zenmux-models.json`，当前只收录一个
模型：

```text
deepseek/deepseek-v4.1-flash   effort: low / high / max
```

因此 `codex -p zenmux` 下只会看到这一个模型；这是预期行为。OpenRouter
profile 会动态拉取 OpenRouter 自己的模型目录，官方 profile 使用 Codex 内置
列表，二者都不受这个文件影响。

`model_catalog_json` 是启动时加载的“完整目录”，不是增量追加列表。如果以后
要在 ZenMux profile 中增加模型，请把新条目一起写进
`zenmux-models.json` 的 `models` 数组，而不只是修改 `model` 字段。每个条目
需要完整的 `base_instructions`（或 `model_messages.instructions_template`），
否则整个目录可能加载失败。

OpenRouter 的 `/model` 列表由 Codex 动态拉取，不需要本地目录文件。OpenRouter
官方文档说明：`env_key` 只负责鉴权，不会触发模型目录刷新；命令式
`[model_providers.openrouter.auth]` 才会让 Codex 请求 OpenRouter 的模型目录。
因此基础 `config.toml` 使用：

```toml
[model_providers.openrouter.auth]
command = "sh"
args = ["-c", "echo $OPENROUTER_API_KEY"]
```

这样 `/model` 会显示 OpenRouter 的完整列表，非 OpenAI 模型也能拿到正确的
上下文窗口和 reasoning effort 元数据。`model` 字段只决定启动时默认选哪个
模型，不影响列表内容。

### ZenMux 没有同款自动发现

ZenMux 官方 Codex 文档仍然使用 `env_key`，并让用户从网页上的 Responses
模型列表里选好名称后手动填写 `model`。ZenMux 的
`GET https://zenmux.ai/api/v1/models` 返回的是 OpenAI 兼容模型列表，不是
Codex 原生模型目录，因此不能直接交给 `model_catalog_json`。

ZenMux 确实提供了官方 `@zenmux/codex-oauth`，但它的机制不是运行时自动发现：

- `zenmux-codex-auth install` 下载当前支持 Responses 的模型列表，写成私有
  目录文件，再通过 `model_catalog_json` 提供给 `/model`；
- 其中 `auth.command = ".../zenmux-codex-auth token"` 只负责提供 OAuth
  token，不负责让 Codex 动态刷新模型目录；
- ZenMux 更新目录后，需要重新运行 `zenmux-codex-auth install` 才能看到新
  模型。

所以本安装包继续使用静态的 `zenmux-models.json`：模型列表稳定、可重复安装，
而且能确保只有经过验证的 DeepSeek 条目和 reasoning effort 出现，避免
`web_search` 400 问题因目录变化而复发。需要新增模型时，手动写入目录文件即可。

如果想固定 OpenRouter 的列表、避免联网刷新，也可以给
`openrouter.config.toml` 加上 `model_catalog_json = "..."`；但这是完整替换
目录，需要自行维护 JSON 快照，通常不如动态发现方便。

编辑对应的 profile 文件即可：

- `~/.codex/openrouter.config.toml`
- `~/.codex/zenmux.config.toml`
- `~/.codex/zenmux-models.json`
- `~/.codex/official.config.toml`

临时覆盖可用 `codex -p zenmux -m <model-id>`。ZenMux 的 GPT 系列建议使用原生
别名（如 `gpt-5.2-codex`），其他供应商模型使用 ZenMux 模型列表中的完整 slug。

## 参考

- <https://zenmux.ai/docs/best-practices/codex.html>
- <https://zenmux.ai/docs/best-practices/oauth-pkce.html>
- <https://zenmux.ai/docs/api/openai/openai-list-models.html>
- <https://zenmux.ai/docs/guide/advanced/web-search.html>
- <https://zenmux.ai/docs/api/protocol-conversion.html>
- <https://zenmux.ai/docs/guide/subscription.html>
- <https://openrouter.ai/docs/guides/features/server-tools/web-search>
- <https://learn.chatgpt.com/docs/config-file/config-advanced>
- <https://learn.chatgpt.com/docs/config-file/config-reference>

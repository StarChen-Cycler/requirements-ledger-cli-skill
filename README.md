# requirements-ledger-cli-skill

供 Agent 使用的 [reqledger](https://github.com/StarChen-Cycler/requirements-ledger-cli) 操作指引：找到实际帮助、理解单 MD 台账的使用逻辑、明确调用方与 CLI 的责任边界。

加载入口是 [SKILL.md](requirements-ledger-cli/SKILL.md)，产品定位与责任划分见按需阅读的[任务边界案例](requirements-ledger-cli/references/product-boundary-case.md)。字段、样例、命令清单和错误协议由 CLI 的 `--help` 维护，避免两套手册随版本产生偏差。

## 使用前提

本仓库提供 skill 文档与安装辅助脚本，不包含 CLI 本体。先确认环境已有可用入口：

```sh
reqledger --version
reqledger --help
```

CLI 安装、运行环境和支持范围以所选版本的 README 与实际帮助为准；当前已验收的 [0.3.0 版本说明](https://github.com/StarChen-Cycler/requirements-ledger-cli/blob/b1d5ea1012f4ae529adb0f85689dced2e2c40325/README.md) 对应[三平台 CI](https://github.com/StarChen-Cycler/requirements-ledger-cli/actions/runs/41294023162)。0.3.0 起提供开发上下文固定投影，具体协议查看 `reqledger query --help`。安装或更新 skill 不会安装或升级 CLI，也不会建立、迁移或修改需求台账。

## 安装 skill

选择当前 Agent 框架实际读取的 skills 根目录，把 `requirements-ledger-cli/SKILL.md` 放到：

```text
<skills-root>/requirements-ledger-cli/SKILL.md
```

常见个人目录为 `~/.agents/skills`、`~/.codex/skills` 或 `~/.claude/skills`，项目级目录由框架配置决定。以当前框架说明为准，不要多套一层同名目录。

手动安装时同时复制入口与 `references` 目录，保持相对链接有效。Windows PowerShell 示例（在本仓库根目录执行，按实际框架修改目标）：

```powershell
$SkillTarget = Join-Path $HOME '.agents\skills\requirements-ledger-cli'
New-Item -ItemType Directory -Force -Path $SkillTarget | Out-Null
Copy-Item -LiteralPath '.\requirements-ledger-cli\SKILL.md' -Destination (Join-Path $SkillTarget 'SKILL.md') -Force
$ReferenceTarget = Join-Path $SkillTarget 'references'
New-Item -ItemType Directory -Force -Path $ReferenceTarget | Out-Null
Copy-Item -LiteralPath '.\requirements-ledger-cli\references\product-boundary-case.md' -Destination (Join-Path $ReferenceTarget 'product-boundary-case.md') -Force
```

也可使用已有辅助脚本，显式指定目标 skills 根目录：

```powershell
.\requirements-ledger-cli\scripts\install.ps1 -Target "$HOME\.agents\skills"
```

```sh
sh requirements-ledger-cli/scripts/install.sh "$HOME/.agents/skills"
```

辅助脚本会替换目标下整个同名 skill 目录；先保留其中需要的自定义内容，勿将来源目录自身作为安装目标。更新文档时同步入口与其引用的参考文件即可。

不支持 skills 的框架可把 SKILL.md 的正文放入其规则文件或系统提示词；保留其适用范围和责任边界，并使案例引用可访问。

## 更新与核对

1. 更新仓库后，将新的 SKILL.md 及其引用的 `references` 文件复制到实际使用的位置；源仓库与已安装副本需要分别同步。
2. 旧版 `reference.md` 是重复命令手册，当前已移除；更新旧安装时备份后删除该文件，避免误读。
3. 核对目标文件的 frontmatter 名称仍为 `requirements-ledger-cli`，且能通过当前入口读取 CLI 帮助。
4. 新开会话使框架重新发现 skill，或让支持重新读取的当前会话显式重读文件；已加载的旧指令不会因磁盘更新自动替换。

核对 skill 的加载与帮助入口不需要对真实台账写入，也不需要运行 CLI 开发测试。实际台账操作仍以用户授权和项目约定为准。

## 仓库内容

- `requirements-ledger-cli/SKILL.md`：加载入口。
- `requirements-ledger-cli/references/product-boundary-case.md`：按需阅读的产品任务边界案例。
- `requirements-ledger-cli/scripts/install.ps1`、`install.sh`：可选安装辅助脚本。
- `LICENSE`：MIT 许可证。

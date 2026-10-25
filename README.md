# requirements-ledger-cli-skill

一个可直接装进 Agent 环境的 **skill**：教 Agent 正确使用 [`reqledger`](https://github.com/StarChen-Cycler/requirements-ledger-cli) —— 单文件 Markdown 需求台账 CLI。

- **它解决什么**：让 Agent 在“写需求”时不再手改 Markdown、不再编造字段、不再把审核/验收/发布当成口头声明；所有事实通过带门禁的 CLI 追加，形成可追溯、可复核的需求历史。
- **它强调什么**：职责边界（负责/不负责）、`--help` 自省协议、写入信封与重试、退出码到动作的映射、反模式清单。
- **它不做什么**：不替代 `reqledger` 本身，不执行测试/部署，不判断需求真伪。

---

## 1. 仓库结构

```
requirements-ledger-cli-skill/
├── README.md                     # 本文件：安装、验证、更新
├── LICENSE
└── requirements-ledger-cli/      # ← 要安装的 skill 目录
    ├── SKILL.md                  # 主入口（YAML frontmatter + 规则）
    ├── reference.md              # 命令地图、状态机、字段、样例、排错
    └── scripts/
        ├── install.sh            # 安装到 Agent skills 目录（POSIX）
        └── install.ps1           # 安装到 Agent skills 目录（Windows）
```

Agent 只需要 `SKILL.md` 就能工作；`reference.md` 按需加载，避免一开始就塞满上下文。

---

## 2. 先安装 CLI（skill 的运行前提）

`reqledger` 是私有仓库 `StarChen-Cycler/requirements-ledger-cli` 的发行物（需要访问权限）：

```bash
# 方式 A：pipx 安装全局命令（推荐）
pipx install requirements_ledger_cli-0.1.0-py3-none-any.whl
reqledger --help

# 方式 B：免安装，直接跑单文件 zipapp
python reqledger-0.1.0.pyz --help
```

要求：Python >= 3.11；运行期零第三方依赖。台账目录须为本地固定盘（Windows NTFS / Linux ext4 / macOS 本地卷），不支持网络盘、云同步目录或多硬链接。

验证：

```bash
reqledger --help            # 退出码 0
reqledger --version         # 0.1.0
```

---

## 3. 把 skill 安装到新的 Agent 环境

### 3.1 一键脚本

**POSIX（macOS / Linux / WSL / Git Bash）**

```bash
git clone https://github.com/StarChen-Cycler/requirements-ledger-cli-skill.git
cd requirements-ledger-cli-skill
./requirements-ledger-cli/scripts/install.sh                # 自动探测常见目录
./requirements-ledger-cli/scripts/install.sh ~/.agents/skills   # 或显式指定
```

**Windows PowerShell**

```powershell
git clone https://github.com/StarChen-Cycler/requirements-ledger-cli-skill.git
cd requirements-ledger-cli-skill
.\requirements-ledger-cli\scripts\install.ps1
.\requirements-ledger-cli\scripts\install.ps1 -Target "$HOME\.agents\skills"
```

脚本是幂等的：目标已存在时先删除旧目录再复制，不会留下半套文件。

### 3.2 各框架的放置位置

| 环境 | 个人级目录 | 项目级目录 |
| --- | --- | --- |
| DeepSeek Harness / 兼容 `SKILL.md` 的 Agent | `~/.agents/skills/` | `<project>/.agents/skills/` |
| Codex 风格 | `~/.Codex/skills/` | `<project>/.Codex/skills/` |
| Claude Code 风格 | `~/.claude/skills/` | `<project>/.claude/skills/` |
| 任意框架（无 skills 机制） | 见 3.3 | 见 3.3 |

最终形态必须是：

```
<skills 根>/requirements-ledger-cli/SKILL.md
<skills 根>/requirements-ledger-cli/reference.md
```

> 目录名与 frontmatter 的 `name` 保持一致（`requirements-ledger-cli`）。改名会导致部分框架加载失败。

### 3.3 没有 skills 机制的框架

把 `requirements-ledger-cli/SKILL.md` 的内容（连同 frontmatter 之后的正文）放进该框架每次都会读取的规则文件：

- `AGENTS.md` / `CLAUDE.md` / `.cursor/rules/*.mdc` / 系统提示词模板；
- 若框架支持“附件/参考文档”，把本目录作为附件，正文里写明“按 `reference.md` 查命令与字段”。

最低要求：Agent 必须能在需要时看到 **`SKILL.md` 的 description 与正文**，并能读到 `reference.md`。

### 3.4 手动安装（不跑脚本）

```bash
mkdir -p ~/.agents/skills
cp -R requirements-ledger-cli ~/.agents/skills/
test -f ~/.agents/skills/requirements-ledger-cli/SKILL.md && echo OK
```

Windows：

```powershell
Copy-Item -Recurse -Force .\requirements-ledger-cli "$HOME\.agents\skills\"
Test-Path "$HOME\.agents\skills\requirements-ledger-cli\SKILL.md"
```

---

## 4. 验证安装

1. **文件级**：`SKILL.md` 首行是 `---`，含 `name:` 与 `description:` 两个字段。
2. **运行级**：`reqledger --help` 退出码 0。
3. **加载级**：重启/新开 Agent 会话，问一句“有哪些可用 skills”或“怎么管理需求台账”。若未出现，见第 7 节。
4. **行为级**（可选）：让 Agent 在临时目录执行 `init → show → check`，确认它按信封写入、并主动用 `--help` 自查字段。

---

## 5. 这个 skill 教 Agent 什么

| 主题 | 位置 |
| --- | --- |
| 职责范围（负责/不负责）、何时用/不用 | `SKILL.md` §1–§2 |
| 三条铁律：help 自省、信封写入、不手改 MD | `SKILL.md` §3 |
| 心智模型：一份 MD、只追加、两个版本维度、两维状态 | `SKILL.md` §4 |
| 30 秒最小路径与 12 步黄金工作流 | `SKILL.md` §5–§6 |
| 写入信封、CAS、幂等重放、`recover` | `SKILL.md` §7 |
| 退出码 → Agent 动作 | `SKILL.md` §8 |
| 帮助自省协议（提示词怎么写） | `SKILL.md` §9 |
| 反模式清单 | `SKILL.md` §10 |
| 完整命令地图、状态机、字段清单、样例、排错 | `reference.md` |

---

## 6. 更新

```bash
cd requirements-ledger-cli-skill
git pull
./requirements-ledger-cli/scripts/install.sh      # 重新覆盖安装
```

技能内容随 CLI 版本演进；`name` 保持稳定，因此更新不会影响已加载的引用。

---

## 7. 常见问题

| 现象 | 原因 | 处理 |
| --- | --- | --- |
| Agent 看不到 skill | 目录层级错误（多套了一层） | 确认是 `<skills 根>/requirements-ledger-cli/SKILL.md` |
| 加载报 YAML 错 | frontmatter 缺 `---`、用了 tab | 用空格缩进，保留首尾 `---` |
| `reqledger: command not found` | 未安装或不在 PATH | `pipx ensurepath` 后重开终端；或用 `python reqledger-0.1.0.pyz` |
| 写台账报 `IO` | 目录不在本地固定盘 / 权限不足 | 换本地目录，检查写权限 |
| 报 `BUSY` | 另一进程持有锁 | 等其退出并 `recover`，不要删 `.requirements.md.lock` |
| 报 `CORRUPT` | 台账被手改或字节损坏 | 保留原文件，`check` + `recover`，不要覆盖写 |

---

## 8. 兼容性

- 适用：任何支持 `SKILL.md`（YAML frontmatter + 按需加载）的 Agent 框架；无该机制时按 3.3 接入。
- CLI 平台：Windows / Linux 本地实测，macOS 经 CI 实测（Python 3.11–3.13）。
- 本仓库只包含**文档与安装脚本**，不含 CLI 源码或发行二进制。

## 9. License

MIT，见 [LICENSE](LICENSE)。

---
name: requirements-ledger-cli
description: >
  Drive the reqledger CLI (single-file Markdown requirements ledger) through a strict lifecycle:
  page/source traceability → complete draft → review → baseline → development rounds → per-condition
  acceptance → immutable release → change closure → retirement. Use when the user asks to 管理需求、
  建立需求台账、封基线、登记验收、发布/变更/退役需求, mentions reqledger or "requirements ledger",
  or needs agent-writable requirements with a versioned audit trail. Covers responsibility boundaries,
  the write envelope, help-first discovery, exit-code recovery and anti-patterns.
---

# 需求台账 CLI（reqledger）

一句话定位：**Agent 只提交结构化 JSON，脚本负责门禁、编号、版本、状态、历史与可读正文；产物是一份人类可读、机器可验证的 Markdown 台账。**

## 1. 职责范围（先讲清边界，再动手）

| 它负责 | 它不负责 |
| --- | --- |
| 维护一份权威 Markdown 台账：正文 + 唯一 JSON 记录区 | 判断需求真伪、业务公式对错、语义重复 |
| 完整性门禁：字段缺失、占位符、空壳草稿直接拒绝 | 自动补全需求内容、替用户做业务决策 |
| 编号、内容修订、文档修订、事件与历史 | 真实签名、身份认证、权限隔离、防篡改证明 |
| 页面/区域/来源的精确修订与双向追溯 | 抓取网页、读取附件并自动提炼需求 |
| 审核声明、基线封存/激活、开发状态与轮次 | 执行测试、跑代码、部署、验证证据真实性 |
| 逐条件验收、发布冻结、变更闭环、退役保护 | 自定义状态机、任意字段、插件、格式迁移 |
| 严格 JSON 协议：CAS、幂等重放、原子提交、进程锁 | 共享盘/UNC、云同步目录、多硬链接、多主机并发 |

使用时主动向用户说明两条：**① 这里的“审核/验收/发布”都是声明式登记，不是真人签字或真实测试执行；② Agent 身份只是操作归因，不同 ID 不等于独立审阅。**

## 2. 何时用 / 何时不用

- 用：需求需要可追溯生命周期（多轮返工、精确验收、发布冻结、变更关闭）；人力或多 Agent 协作写同一份需求；需要历史、差异、审计。
- 不用：一次性待办或自由笔记；需要自定义字段/状态；需要联网采集或自动测试；需要多人权限与签署效力。

## 3. 三条铁律

1. **不确定就查 help**：根 → 族 → 叶（`reqledger --help`、`reqledger req --help`、`reqledger req add --help`）。帮助里已有参数、字段规则、允许状态、可复制样例、错误码与下一步；**不要凭记忆造字段**。
2. **写入必须带信封，只读命令不带信封。** 只读命令：`show`、`query`、`history`、`diff`、`check`、`recover`。
3. **绝不手改台账 MD、绝不伪造审核/验收/发布。** 一切事实只能通过命令追加。

## 4. 心智模型

- 一个台账 = 一个 `.md`：人类可读中文正文 + 末尾唯一 JSON 权威区（`<!-- REQUIREMENTS-CLI:BEGIN -->`）。
- 只追加：内容修订、事件、审核、执行、发布都是事实，旧值不覆盖；`document_revision` 单调递增。
- 两个版本维度：`document_revision`（写入 CAS）与对象 `revision`（该内容第几版）。
- 两维状态：内容确认态（完整草稿 → 待审核 → 已确认/已拒绝/已撤回）与开发态（未开始 → 进行中 → 已实现）；另有 `已发布`（历史标记）与 `已退役`（终态）。
- 验收执行键 = 基线 + 需求 + 修订 + 轮次 + 条件 + 交付；**同键取最新结果**，旧通过不能掩盖新失败。
- 发布是冻结登记：成员、轮次、全部条件执行 ID 一并固定，事后失败不改写旧发布。

状态机与完整命令地图见 [reference.md](reference.md)。

## 5. 最小可用路径（30 秒验证环境）

```bash
reqledger init --file requirements.md --stdin <<'JSON'
{"operation_id":"init-001","agent":"agent-a","reason":"建立需求台账","expected_revision":0,"data":{"name":"示例项目"}}
JSON
reqledger show --file requirements.md --format text
reqledger check --file requirements.md
```

- `init` 绝不覆盖已有文件；`expected_revision` 必须是 `0`。
- Windows 无 heredoc 时用 `--json '{"..."}'` 或 `"..." | reqledger ... --stdin`。
- 其他写入命令的完整样例，直接看 `reqledger <family> <action> --help` 的“标准输入结构示例”。

## 6. 黄金工作流

| # | 步骤 | 命令 | 通过条件 |
| --- | --- | --- | --- |
| 1 | 建账 | `init` | 文件不存在且 `expected_revision=0` |
| 2 | 页面与区域 | `page add` / `page revise` | 页面修订号递增，未退役 |
| 3 | 来源 | `source add` / `source revise` | 保存原话/摘录与定位 |
| 4 | 完整草稿 | `req add` / `req revise` | 13 类必填字段齐全、验收条件完整 |
| 5 | 提交与审核 | `req submit` + `review add` | 最新修订被精确审核（通过/不通过）；submit/confirm/reject/withdraw 的 `data` 需 `{id, revision, digest}` 目标引用 |
| 6 | 确认与范围 | `req confirm` | 最新审核通过、开放问题为 0、范围明确 |
| 7 | 基线 | `baseline seal` → `review add` → `baseline activate` | 成员精确已确认、依赖闭合无环 |
| 8 | 开发 | `dev start` / `dev complete` | 首次轮次 1；返工带 `reason` 且轮次 +1 |
| 9 | 验收 | `acceptance record` / `acceptance waive` | 逐条件、逐交付登记；免验须预先 `allow_na` |
| 10 | 发布 | `release add` | 当前基线成员 + 当前轮次 + 全部条件有效 |
| 11 | 变更 | `change propose → evaluate → approve → apply → activate → close` | 逐动作逐义务关闭，未关闭阻断发布 |
| 12 | 退役 | `retire` | 无当前基线引用、无纳入活动依赖 |

只读随时可用：`show` / `query` / `history` / `diff` / `check` / `recover`。

## 7. 写入信封与重试

```json
{"operation_id":"<唯一字符串>","agent":"<声明归因>","reason":"<原因>","expected_revision":<当前文档修订>,"data":{...}}
```

- `expected_revision` 必须等于当前 `document_revision`；填旧值 → `CONFLICT`(4)，先 `show` 再重算。
- `operation_id` 幂等：同 ID 同载荷 → 原结果重放；同 ID 异载荷 → `CONFLICT`(4)。
- **响应丢失不要盲重试**：`reqledger recover --file X --json '{"operation_id":"..."}'`，按 `commit_status` 决定下一步。
- 失败不会消耗编号，也不会留下半套数据。

## 8. 退出码 → Agent 动作

| 码 | 含义 | 动作 |
| --- | --- | --- |
| 0 | 成功 | 检查返回对象与 `commit_status` |
| 2 | 输入错误 | 按 `issues[].field` 逐项修字段，补全缺失项 |
| 3 | 业务门禁 | 读 `blockers`/`issues`，补齐前置事实，不要绕过 |
| 4 | 操作或 CAS 冲突 | 重新 `show` 取最新修订；同 ID 异载荷则换 ID |
| 5 | 锁忙 | 有存活进程持锁：等待、`recover`，**不要删除锁文件** |
| 6 | IO | 检查父目录、权限、文件系统类型 |
| 7 | 损坏或提交未知 | 保留原字节，`check` + `recover`；不要覆盖写 |

## 9. 自查协议（提示词的正确写法）

当用户只给了模糊指令时，按下面顺序自助：

1. `reqledger --help` → 看阶段与命令族。
2. `reqledger <family> --help` → 看该族动作。
3. `reqledger <family> <action> --help` → 读三段：**`字段规则：`、`允许状态：`、`异常：`**。
4. 从帮助里复制样例骨架，填真实业务内容；只使用帮助中出现的字段。
5. 写入后用 `show` 核对“实际插入内容”，用 `check` 确认结构一致。

## 10. 反模式（出现即停手）

- 手改 JSON 区、正文摘要或对象 ID；
- 用 `req add` 塞“待补充/TBD”空壳；
- 跳过 `review add` 直接 `confirm`；
- 把 `acceptance` 当测试执行器（它只登记声明结果）；
- 为了“修复”失败去改旧 `release` / 旧 `execution`；
- 删除 `.requirements.md.lock` 或临时文件来“解锁”；
- 用 `retire` 代替删除；退役后仍尝试新绑定。

## 11. 部署与运行

- Python >= 3.11；运行期零第三方依赖；`pytest` 仅开发测试、`build` 仅构建发行。
- 安装：`pipx install requirements_ledger_cli-0.1.0-py3-none-any.whl`，或 `python reqledger-0.1.0.pyz --help`。
- 台账目录：本地固定 NTFS（Windows）或本地 ext4（Linux）；macOS 使用同一 `fcntl` 实现并已由 CI 实测。
- 把本 skill 安装到新的 Agent 环境：见发布仓库 `requirements-ledger-cli-skill` 的 README（含各框架目录、脚本与验证步骤）。

## 12. 参考

- [reference.md](reference.md)：命令地图、状态机、字段清单、查询过滤、故障排查。

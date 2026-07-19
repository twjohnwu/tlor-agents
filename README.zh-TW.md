# TLOR Orchestration — 給 Claude Code 的中土遠征隊

[![CI](https://github.com/twjohnwu/tlor-orchestration/actions/workflows/validate.yml/badge.svg)](https://github.com/twjohnwu/tlor-orchestration/actions/workflows/validate.yml)
[![version](https://img.shields.io/badge/version-0.1.1-blue)](https://github.com/twjohnwu/tlor-orchestration/blob/main/.claude-plugin/plugin.json)
[![license](https://img.shields.io/badge/license-MIT-green)](LICENSE)

一個中土世界主題的 Claude Code 編排框架。九個固定職責的 subagent 角色，
加上派工規則、設定 skill、選配 guard hook——AI coding session 可靠委派
所需的一切。

English version: [README.md](README.md).

## Skills 一覽

### 自動載入（隨 plugin/agents 一起安裝）

| Skill | 用途 | 何時呼叫 |
|---|---|---|
| `/rivendell-council` | 召集抗辯小組（三鏡頭，多數存活制判定）| 不可逆操作、架構決策、根因判定、安全性判斷 |
| `/tlor-init` | 安裝 agents + rules + CLAUDE.md 路由 + AGENTS.md + 選配 hooks | 首次設定，或升級既有安裝 |
| `/tlor-restore` | 從備份還原到先前的安裝狀態 | 需要復原某次升級時 |
| `/erebor-ledger` | 回溯性報表：tlor 角色派工省下多少 token/成本，依 Fable-5-orchestrator 與 Opus-orchestrator session 分開統計 | 「usage report」「cost savings report」「token ledger」——非單次進行中派工的即時估算 |

## 文件

- [角色與派工](docs/zh-TW/roles.md) — 世界觀、九角色遠征隊名冊、subagent 派工 snippet
- [Skills](docs/zh-TW/skills.md) — 完整 skill 細節＋選配的 STDD 工作流程
- [Rules 與 Hooks](docs/zh-TW/rules-and-hooks.md) — 附帶的 rules 檔案、兩個選配 hooks
- [安裝](docs/zh-TW/installation.md) — 兩種安裝方式、所有權模型、安裝旗標
- [維護](docs/zh-TW/maintenance.md) — 備註、誠實限制、發布流程
- [歷史](docs/zh-TW/history.md) — 專案更名沿革與版本重置
- [Release log](docs/release_log.md) — 完整逐版本紀錄（僅英文）

## 授權與致敬

MIT © [twjohnwu](https://github.com/twjohnwu)。本專案為對托爾金傳說體系的
粉絲致敬，與 Tolkien Estate 及 Middle-earth Enterprises 皆無關、未獲其背書；種族與角色名僅作主題性使用。
瑞文戴爾會議（rivendell-council）召集流程的靈感來自，verify-gate hook
則改寫自
[Miguok/fable-harness](https://github.com/Miguok/fable-harness)（MIT）。

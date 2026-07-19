# Skills

[← 回 README](../../README.zh-TW.md)

快速參考見 README 的 skill 路由表。本頁補充該表以外的細節，以及 STDD
選配安裝的說明。

## 自動載入 skills——細節

**rivendell-council** — 抗辯小組的召集流程：組裝自足審查包、並行派遣三鏡頭、
以多數存活制判定、關鍵結論循環至收斂。

**tlor-init** — 一次性設定 skill：選安裝層級（使用者層/專案層/repo 層）、
複製 agents 與 rules、產生 CLAUDE.md 路由與 AGENTS.md、選配啟用 hooks。
偵測既有安裝並提供帶備份的升級流程。也提供選配的 STDD 安裝步驟（見下）。

**tlor-restore** — 從 `/tlor-init` 升級時建立的備份還原。

**erebor-ledger** — 讀取既有的 Claude Code transcript，回報 tlor 角色派工
相較於直接在 orchestrator 模型上跑同樣工作省下多少成本。僅回溯性報表，
不是單次進行中派工的即時估算工具。

## 選配：STDD 工作流程 skills

透過 `install.sh --stdd-role=ALL` 或 `/tlor-init` 的 STDD 步驟安裝。

非自動載入——這七個 skill 實作 Spec-driven Test-Driven Development 流程，
只有明確要求時才會落地到 `~/.claude/skills/`。本輪僅實作 `ALL` 這個
profile；`RD`/`PM`/`UIUX` 角色限定子集 deferred（`install.sh
--stdd-role=RD|PM|UIUX` 只會印出 deferred 訊息、不安裝任何東西）。

| Skill | 中土稱號 | 用途 | 何時呼叫 |
|---|---|---|---|
| `/stdd` | Palantír 真知晶石 | 唯讀狀態儀表板：回報這個 STDD 變更目前在哪個階段、重新驗證 fingerprint、建議下一步指令 | 檢查進行中 STDD 變更的進度 |
| `/stdd-explore` | Lore 智者探詢 | 在寫任何 spec 之前，先釐清模糊需求的思考夥伴階段 | 從一個粗略想法開始新的 STDD 變更 |
| `/stdd-uiux` | Lórien 精靈美學 | 條件式設計階段，產生 `design-ux.md` | 僅當變更有使用者可見的 UI 介面時 |
| `/stdd-spec` | Oath 遠征誓約 | 撰寫 GWT 格式 `spec.md`（含 test-mapping/verification-command 欄位）、以 `/stdd-lint` 自我複查、並以抗辯小組核准作為關卡 | 撰寫或核准某個 STDD 變更的 spec |
| `/stdd-plan` | Map 行軍圖 | 從已核准的 spec 產生條件式的 `design-be.md`/`design-fe.md`/`api.yml` 與涵蓋所有情境的 `tasks.md` | 把已核准的 spec 轉成設計與任務清單 |
| `/stdd-execute` | Forge 鑄造 | 對已核准的 `tasks.md` 逐任務跑 RED → GREEN → REFACTOR 迴圈，雙派工模型＋獨立驗證者 | 逐一實作 STDD 任務 |
| `/stdd-lint` | Eagle Vision 鷹之視野 | 純規則式（非模型判斷）機械檢查：佔位字串洩漏、ID 連續性、GWT 完整性、test-mapping/涵蓋率、fingerprint 狀態 | 由 stdd-spec/stdd-plan/stdd-execute 的邊界檢查內部呼叫，使用者也可直接呼叫 |

流程順序：`stdd-explore → stdd-uiux（條件式）→ stdd-spec → stdd-plan →
stdd-execute`，`stdd` 與 `stdd-lint` 則任何階段都可呼叫。

**STDD test-file guard hook**（`hooks/stdd_test_guard.py`）——選配的
PreToolUse hook，強制已建立 RED baseline 的測試檔在其任務標記完成前不可
再被改寫。透過 `install.sh --install-hook` 安裝（與 `--stdd-role` 無關）。
**session-snapshot 誠實提醒**：Claude Code 只在 session 啟動時讀取一次
`settings.json` 裡的 PreToolUse hook——若在既有 session 或
`--continue`/`--resume` 的 session 中執行 `--install-hook`，該 hook 不會在
那個 session 生效；請只在全新 session 中驗證。

## 觸發方式

`/rivendell-council` 的自動叫用是由 description 驅動的——模型會拿 skill
description 裡的觸發詞去比對當下情境。若要硬保證觸發，在你專案的
`CLAUDE.md` 加一行：

```
High-risk verdicts (irreversible ops, contract/schema changes, money/precision, architecture decisions, root-cause claims, production-affecting conclusions) MUST pass /tlor-orchestration:rivendell-council before adoption.
```

`eagle-sentinel` 給出 HIGH-RISK 建議就是該召集的訊號。

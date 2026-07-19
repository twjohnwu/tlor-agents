# TLOR Orchestration — 給 Claude Code 的中土遠征隊

[![CI](https://github.com/twjohnwu/tlor-orchestration/actions/workflows/validate.yml/badge.svg)](https://github.com/twjohnwu/tlor-orchestration/actions/workflows/validate.yml)
[![version](https://img.shields.io/badge/version-0.1.0-blue)](https://github.com/twjohnwu/tlor-orchestration/blob/main/.claude-plugin/plugin.json)
[![license](https://img.shields.io/badge/license-MIT-green)](LICENSE)

一個中土世界主題的 Claude Code 編排框架。九個固定職責的 subagent 角色，
加上派工規則、設定 skill、選配 guard hook——AI coding session 可靠委派
所需的一切。

English version: [README.md](README.md).

## 更名：tlor-agents → tlor-orchestration（2.x → 3.0）

本 repo 已從 `tlor-agents` 更名為 `tlor-orchestration`；GitHub 會自動轉址
舊網址，但 plugin 安裝是依 repo 名稱識別的，需要手動一步：

```
/plugin uninstall tlor-agents@tlor        # 移除舊安裝
/plugin marketplace add twjohnwu/tlor-orchestration
/plugin install tlor-orchestration@tlor   # 以新名稱重新加入
```

若你是用 `install.sh`（直接複製）安裝的，重新跑新版 `install.sh` 即可——
升級時實際變動請見下方的所有權模型。

**v3.0.0 同時改變了安裝／所有權模型**（見下）：base rule 檔案現在由
plugin 擁有，每次安裝都無條件覆蓋；想跨版本保留的內容一律放進
`rules/customize/`，installer 永遠不會動它。若你在 2.x 曾就地手改過
base rule 檔案，升級前請把你的修改搬到 `rules/customize/`——下次安裝
會用官方版本覆蓋掉 base 檔案。

## 兩種使用方式

- **輕量**——只裝 plugin。安裝後，任何一個新開的 session 都能使用九個角色
  （若是在已開啟的 session 中安裝，須先執行 `/reload-plugins`）。請直接
  以名稱明確呼叫角色，或加上下方的 CLAUDE.md snippet 以取得穩定的派工——
  我們的 headless 測試顯示，僅靠 description 並不能穩定觸發自動派工，因此
  snippet 是建議的輕量做法。
- **完整**——再加跑 `/tlor-init`。這會落地 rules 檔案、`~/.claude/institution/`
  layout（見下）、以及 CLAUDE.md/AGENTS.md 路由，讓派工紀律自動強制執行，
  不必仰賴模型自己記得用這些角色。

## 所有權模型

- **Base rules 由 plugin 擁有。** 每次安裝／升級都無條件覆蓋必裝 rule
  檔案，並蓋上 plugin 的 `version`（唯一真相來源——不是寫死在檔案裡的值）。
  別手改這些檔案，下次安裝就會被蓋掉。
- **`rules/customize/` 是你的。** installer 會建立這個目錄，首次安裝可能
  幫你種入選配的起始檔案，之後**永遠不覆蓋**裡面已存在的任何東西——這是
  唯一該放持久本地客製化內容的地方。
- **Base 檔案沒有任何使用者可寫區塊。** 所有使用者自行新增的內容——
  lessons、skill namespace 優先序表、本地慣例——一律放在 `rules/customize/`，
  絕不放進 base rule 檔案，因為那裡任何追加內容都會在下次無條件覆蓋時被清空。
- **`~/.claude/institution/` layout。** 使用者層級安裝時，
  `~/.claude/{agents,rules,hooks}` 會變成指向 `~/.claude/institution/<name>/`
  的 symlink。這是冪等的：已經是 symlink → 不動；已有真實目錄 → 搬到
  `institution/` 底下再建 symlink（不遺失任何東西）；不存在 → 直接新建。
  這層間接讓 plugin 對 base rules/hooks 的覆蓋式安裝，永遠不會跟你手動
  搬過的目錄打架。

## 世界觀

- **你（工程師）是伊露維塔（Ilúvatar）**——意志的源頭。
- **主 Claude session 是邁雅（Maia）**——解讀你的意志、召集遠征隊、
  派遣諸族；自己不下場跑腿。
- **Subagents 是中土諸族**——各自生而註定（frontmatter）：跑什麼模型、
  想多深、能碰哪些工具。

## 遠征隊名冊

| 角色 | 種族與職位 | Model / effort | 職責 |
|---|---|---|---|
| `rohirrim-outrider` | 洛汗外圍騎哨 | haiku / low | 快速定點查找：「X 在哪／Y 怎麼運作」 |
| `ranger-pathfinder` | 北方遊俠 | sonnet / low | 漏掉代價高時的廣域唯讀掃查 |
| `noldor-loremaster` | 諾多精靈博學者 | sonnet / medium | web/文件研究：附來源與版本、事實與推論分明 |
| `dwarf-smith` | 矮人鍛造師 | sonnet / low | 規格完全明確的機械工作；絕不即興 |
| `gondor-builder` | 剛鐸石匠 | sonnet / medium | 照明確 spec 實作、容許區域性小判斷；設計歧義留給 Maia |
| `eagle-sentinel` | 巨鷹哨兵 | opus / medium | Fresh-context 對抗式驗證；CONFIRMED/REFUTED |
| `elf-archer` | 精靈神射手 | opus / medium | 正確性鏡頭：每一箭命中一個邏輯漏洞 |
| `orc-saboteur` | 半獸人破壞者 | opus / medium | 安全與失效鏡頭：輸入驗證、競態、部分失敗 |
| `hobbit-gardener` | 哈比人園丁 | opus / medium | 簡潔性鏡頭：修剪過度工程 |

後三者組成**抗辯審查小組**——高風險判定時由 `eagle-sentinel` 建議、
**Maia 召集**（≥3 個獨立鏡頭＋一位裁判）。例行或邊界案的召集，
派遣鏡頭時可明示 `model: sonnet` 降級——派遣時的覆寫優先於角色的 frontmatter pin。

## Skills

### 自動載入（隨 plugin/agents 一起安裝）

| Skill | 用途 | 何時呼叫 |
|---|---|---|
| `/rivendell-council` | 召集抗辯小組（三鏡頭，多數存活制判定）| 不可逆操作、架構決策、根因判定、安全性判斷 |
| `/tlor-init` | 安裝 agents + rules + CLAUDE.md 路由 + AGENTS.md + 選配 hooks | 首次設定，或升級既有安裝 |
| `/tlor-restore` | 從備份還原到先前的安裝狀態 | 需要復原某次升級時 |
| `/erebor-ledger` | 回溯性報表：tlor 角色派工省下多少 token/成本，依 Fable-5-orchestrator 與 Opus-orchestrator session 分開統計 | 「usage report」「cost savings report」「token ledger」——非單次進行中派工的即時估算 |

**rivendell-council** — 抗辯小組的召集流程：組裝自足審查包、並行派遣三鏡頭、
以多數存活制判定、關鍵結論循環至收斂。

**tlor-init** — 一次性設定 skill：選安裝層級（使用者層/專案層/repo 層）、
複製 agents 與 rules、產生 CLAUDE.md 路由與 AGENTS.md、選配啟用 hooks。
偵測既有安裝並提供帶備份的升級流程。也提供選配的 STDD 安裝步驟（見下）。

**tlor-restore** — 從 `/tlor-init` 升級時建立的備份還原。

**erebor-ledger** — 讀取既有的 Claude Code transcript，回報 tlor 角色派工
相較於直接在 orchestrator 模型上跑同樣工作省下多少成本。僅回溯性報表，
不是單次進行中派工的即時估算工具。

### 選配：STDD 工作流程 skills（透過 `install.sh --stdd-role=ALL` 或 `/tlor-init` 的 STDD 步驟安裝）

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

**觸發方式。** `/rivendell-council` 的自動叫用是由 description 驅動的——
模型會拿 skill description 裡的觸發詞去比對當下情境。若要硬保證觸發，在
你專案的 `CLAUDE.md` 加一行：

```
High-risk verdicts (irreversible ops, contract/schema changes, money/precision, architecture decisions, root-cause claims, production-affecting conclusions) MUST pass /tlor-orchestration:rivendell-council before adoption.
```

`eagle-sentinel` 給出 HIGH-RISK 建議就是該召集的訊號。

## Rules

本 plugin 附帶去個人化的編排規則——透過 `/tlor-init` 或 `install.sh` 安裝：

**必裝**（6 檔，由 plugin 擁有——每次安裝／升級皆無條件覆蓋，`version`
由 `.claude-plugin/plugin.json` 蓋上，不含 `## Lessons` 區塊——見上方所有權模型）：

| Rule | 用途 |
|---|---|
| `dispatch.md` | 角色派工表、委派合約、升降級路徑、驗證規則 |
| `decomposition.md` | 如何拆解任務（並行/序列、規模限制）|
| `delegation-templates.md` | 各派工類型的填空提示模板 |
| `judgment.md` | 何時升級、何時完成、何時問人、錯方向訊號 |
| `risk-tiers.md` | 行動風險分級（T1 不可逆 / T2 難復原 / T3 可逆）|
| `maintenance.md` | session 可自行修改 vs 需人類核准的項目 |

**選裝**（5 檔，位於 `rules/customize/`——`--with-optional` 或在
`/tlor-init` 中選擇；一旦複製過去就不會再被覆蓋）：

| Rule | 用途 |
|---|---|
| `design-principles.md` | 7 個未覆蓋情境的備用原則（P1-P7）|
| `user-decision-patterns.md` | 3 個 AI 輔助開發的決策模式（D1-D3）|
| `letter-to-future-sessions.md` | 空白模板——逐次填入專案事實、制度衰退對策、誠實的能力邊界 |
| `skill-triggers.md` | 何時該呼叫 skill，而非照單全收「一律呼叫」的注入規則——需自行填入已裝 plugin 的 namespace 優先序 |
| `lessons.md` | 附加式的反覆工作流失敗紀錄，每個 base rule 檔案各一個區塊 |

你也可以把自己團隊的規則檔（`.md`）直接放進 `rules/customize/`——安裝時
會一併複製，且會透過 CLAUDE.md 的路由表自動載入，installer 永遠不會動它。

## Hooks（選配）

兩個 hook **預設皆關閉**——透過環境變數啟用。`install.sh` 會複製 hook
腳本，但不接線或啟用它們（不寫 `hooks.json`、不設環境變數）——要接線請走
plugin 安裝。

### institution_guard（PreToolUse）

擋主 session 直接編輯 rules/CLAUDE.md/AGENTS.md——執行「指揮官不下場」。
subagent 的編輯一律放行。Python 優先，bash fallback。

啟用：`export TLOR_INSTITUTION_GUARD=1`

### verify_gate（Stop）

攔「沒有證據的完成宣稱」：若本輪修改了程式碼卻沒跑測試，擋回一次要求補
fail-then-pass 證據。任何內部錯誤一律 fail-open。

啟用：`export TLOR_VERIFY_GATE=1`

## 安裝

### 方式 A——plugin（推薦）

```
/plugin marketplace add twjohnwu/tlor-orchestration
/plugin install tlor-orchestration@tlor
```

更新：我們 bump `version` 後，用 `/plugin marketplace update tlor` 取得。

### 更新支援

更新支援僅限 marketplace 安裝路徑（方式 A）：
`/plugin marketplace add twjohnwu/tlor-orchestration` 後
`/plugin install tlor-orchestration@tlor`。每次發布都會 bump
`.claude-plugin/plugin.json` 的 `version`——依 Claude Code 官方 plugin
文件，光是推送 commit 不會讓更新出現，只有版本號變動才會，之後
`/plugin marketplace update tlor` 才拉得到新版。`install.sh` 直接複製路徑
（方式 B）完全沒有更新提示 UI——重跑 `install.sh` 會再次覆蓋 base rules，
但不會通知你有新版本；請自行查 repo 的 releases 或版本徽章。

### 方式 B——直接複製

```bash
git clone https://github.com/twjohnwu/tlor-orchestration.git
cd tlor-orchestration && ./install.sh          # --dry-run / --force / --uninstall / --with-optional / --stdd-role=ALL / --install-hook
```

複製 agents 到 `~/.claude/agents/`、rules 到 `~/.claude/rules/`、hook 腳本到
`~/.claude/hooks/`、skills 到 `~/.claude/skills/`，首次執行時建立
`~/.claude/institution/` symlink layout（見上方所有權模型）。加
`--with-optional` 一併安裝 `rules/customize/` 裡的選裝 rules。寫入 manifest
供 `--uninstall` 精確移除。Hook **啟用**（環境變數、`hooks.json` 接線）
仍需走方式 A——`install.sh` 只負責放檔案。

**`--stdd-role=RD|PM|UIUX|ALL`** — 選配安裝 STDD 工作流程 skills
（`stdd-skills/*`，非自動載入；見上方 Skills 一節）。本輪僅實作 `ALL`；
`RD`/`PM`/`UIUX` 只會印出 deferred 訊息、不安裝任何東西。不加此旗標 →
不裝任何 STDD skill，與這個旗標出現前的行為相同。

**`--install-hook`** — 選配安裝並在 `settings.json` 註冊 STDD test-file
guard（`hooks/stdd_test_guard.py`）。預設不安裝。**誠實提醒**：Claude
Code 只在 session 啟動時讀取一次 `settings.json` 裡的 PreToolUse
hook——在既有或 `--continue`/`--resume` 的 session 中執行
`--install-hook` 不會讓 hook 在那個 session 生效；請只在全新 session 中驗證。

**輕量使用者**（只裝 plugin、不跑 `/tlor-init`）：在你專案的 CLAUDE.md
加這段，不必完整安裝 rules 也能有派工紀律：

```markdown
## Subagent dispatch (tlor-orchestration)

Prefer the pinned tlor-orchestration roles over generic subagents:
- Targeted code/config lookup ("where is X") → rohirrim-outrider
- Broad/ambiguous search where a miss is costly → ranger-pathfinder
- Web/docs research, version checks → noldor-loremaster
- Mechanical batch edits with an exact recipe → dwarf-smith
- Implement against a written spec → gondor-builder
- Verify finished work (fresh context; never self-certify) → eagle-sentinel
- Adversarial review of major conclusions → elf-archer + orc-saboteur + hobbit-gardener in parallel

Delegate any read of >3 files or repo-wide scan; keep only conclusions + file:line in the main thread.
```

### 方式 C——/tlor-init（plugin 安裝後推薦）

方式 A 安裝後，在 Claude Code 中執行 `/tlor-init` 做引導式設定：選安裝
層級、安裝 rules、產生 CLAUDE.md 路由與 AGENTS.md、選配啟用 hooks。

無論哪種方式，裝完**都要開新 session**——agent 定義在 session 啟動時載入。

## 備註

- **CLAUDE.md + AGENTS.md 雙檔架構**：`/tlor-init` 會產生一個精簡的
  CLAUDE.md（只含幾條最高優先級規則＋`@AGENTS.md` import，交由 harness
  自動內聯）以及一份含完整路由表的 AGENTS.md。這樣拆的理由是 AGENTS.md
  也能被其他 AI coding 工具（Cursor、Codex 等）讀取，CLAUDE.md 則專屬
  Claude Code 的自動載入保證。
- **Serena 為選配**：兩個搜尋角色的 tools 列了
  [Serena](https://github.com/oraios/serena) 語意工具；沒裝該 plugin 時
  角色會 fallback 到 Grep/Glob（指令內已註明）。
- **Hard Rules 插槽**：派 `eagle-sentinel` 時把你團隊不可協商的慣例貼進
  prompt，違反即自動 FAIL。
- model 名（haiku/sonnet/opus）依 Agent 工具接受值；環境不同請自行改
  frontmatter。

## 誠實限制

- **帶 Bash 的「唯讀」是行為約束**：`eagle-sentinel`、`elf-archer`、
  `orc-saboteur`、`rohirrim-outrider`、`ranger-pathfinder` 為了跑測試持有 Bash，而 Bash 技術上能寫檔——「絕不編輯」
  是指令不是沙箱。`hobbit-gardener` 是唯一工具層真唯讀的小組成員。
- **模型不可用時靜默 fallback**：依官方文件，被組織排除的 `model:` 值會
  讓 subagent 改跑 session 繼承的模型、不報錯。沒有 opus 的環境，
  `eagle-sentinel` 會安靜地跑在你 session 的模型上。
- **安全鏡頭角色可能觸發模型的安全防護。** `orc-saboteur`（與程度較輕的
  `elf-archer`）做的是對抗式**防禦**審查；部分模型的寬版安全分類器可能把它
  讀成攻擊性資安工作、於任務中途自動切換模型。這是已知誤判——審查仍會完成。
  措辭已保持防禦性以降低機率。

## 發布流程（維護者）

改動後先 `claude plugin validate . --strict`（驗 plugin.json＋agent
frontmatter），用 `claude --plugin-dir .` 本地實測，最後 bump
`.claude-plugin/plugin.json` 的 `version`——使用者只在版本號變動時收到更新。

## 授權與致敬

MIT © [twjohnwu](https://github.com/twjohnwu)。本專案為對托爾金傳說體系的
粉絲致敬，與 Tolkien Estate 及 Middle-earth Enterprises 皆無關、未獲其背書；種族與角色名僅作主題性使用。
瑞文戴爾會議（rivendell-council）召集流程的靈感來自，verify-gate hook
則改寫自
[Miguok/fable-harness](https://github.com/Miguok/fable-harness)（MIT）。

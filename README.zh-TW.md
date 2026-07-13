# TLOR Agents — 給 Claude Code 的中土遠征隊

[![CI](https://github.com/twjohnwu/tlor-agents/actions/workflows/validate.yml/badge.svg)](https://github.com/twjohnwu/tlor-agents/actions/workflows/validate.yml)
[![version](https://img.shields.io/badge/version-2.0.0-blue)](https://github.com/twjohnwu/tlor-agents/blob/main/.claude-plugin/plugin.json)
[![license](https://img.shields.io/badge/license-MIT-green)](LICENSE)

一個中土世界主題的 Claude Code 編排框架。九個固定職責的 subagent 角色，
加上派工規則、設定 skill、選配 guard hook——AI coding session 可靠委派
所需的一切。

English version: [README.md](README.md).

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

| Skill | 用途 |
|---|---|
| `/rivendell-council` | 召集抗辯小組（三鏡頭，多數存活制判定）|
| `/tlor-init` | 安裝 agents + rules + CLAUDE.md 路由 + 選配 hooks |
| `/tlor-restore` | 從備份還原到先前的安裝狀態 |

**rivendell-council** — 抗辯小組的召集流程：組裝自足審查包、並行派遣三鏡頭、
以多數存活制判定、關鍵結論循環至收斂。

**tlor-init** — 一次性設定 skill：選安裝層級（使用者層/專案層/repo 層）、
複製 agents 與 rules、產生 CLAUDE.md 路由、選配啟用 hooks。偵測既有安裝並
提供帶備份的升級流程。

**tlor-restore** — 從 `/tlor-init` 升級時建立的備份還原。

**觸發方式。** `/rivendell-council` 的自動叫用是由 description 驅動的——
模型會拿 skill description 裡的觸發詞去比對當下情境。若要硬保證觸發，在
你專案的 `CLAUDE.md` 加一行：

```
High-risk verdicts (irreversible ops, contract/schema changes, money/precision, architecture decisions, root-cause claims, production-affecting conclusions) MUST pass /tlor-agents:rivendell-council before adoption.
```

`eagle-sentinel` 給出 HIGH-RISK 建議就是該召集的訊號。

## Rules

本 plugin 附帶去個人化的編排規則——透過 `/tlor-init` 或 `install.sh` 安裝：

**必裝**（6 檔）：

| Rule | 用途 |
|---|---|
| `dispatch.md` | 角色派工表、委派合約、升降級路徑、驗證規則 |
| `decomposition.md` | 如何拆解任務（並行/序列、規模限制）|
| `delegation-templates.md` | 各派工類型的填空提示模板 |
| `judgment.md` | 何時升級、何時完成、何時問人、錯方向訊號 |
| `risk-tiers.md` | 行動風險分級（T1 不可逆 / T2 難復原 / T3 可逆）|
| `maintenance.md` | session 可自行修改 vs 需人類核准的項目 |

**選裝**（2 檔——`--with-optional` 或在 `/tlor-init` 中選擇）：

| Rule | 用途 |
|---|---|
| `design-principles.md` | 7 個未覆蓋情境的備用原則（P1-P7）|
| `user-decision-patterns.md` | 3 個 AI 輔助開發的決策模式（D1-D3）|

## Hooks（選配）

兩個 hook **預設皆關閉**——透過環境變數啟用。僅 plugin 安裝支援：
`install.sh` 不接 hooks。

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
/plugin marketplace add twjohnwu/tlor-agents
/plugin install tlor-agents@tlor
```

更新：我們 bump `version` 後，用 `/plugin marketplace update tlor` 取得。

### 方式 B——直接複製

```bash
git clone https://github.com/twjohnwu/tlor-agents.git
cd tlor-agents && ./install.sh          # --dry-run / --force / --uninstall / --with-optional
```

複製 agents 到 `~/.claude/agents/`、rules 到 `~/.claude/rules/`、skills 到
`~/.claude/skills/`。加 `--with-optional` 安裝選裝 rules。寫入 manifest 供
`--uninstall` 精確移除。Hooks 不接入——需要 hooks 請用方式 A。

### 方式 C——/tlor-init（plugin 安裝後推薦）

方式 A 安裝後，在 Claude Code 中執行 `/tlor-init` 做引導式設定：選安裝
層級、安裝 rules、產生 CLAUDE.md 路由、選配啟用 hooks。

無論哪種方式，裝完**都要開新 session**——agent 定義在 session 啟動時載入。

## 備註

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

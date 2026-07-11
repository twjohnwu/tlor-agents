# TLOR Agents — 給 Claude Code 的中土遠征隊

九個固定職責的 subagent 角色，以魔戒中土種族為主題。每個角色的
**model／effort／tools 都寫死在 frontmatter**——成本與權責由設計決定，
不是隨 orchestrator 的環境浮動。

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
| `elf-archer` | 精靈神射手 | sonnet / medium | 正確性鏡頭：每一箭命中一個邏輯漏洞 |
| `orc-saboteur` | 半獸人破壞者 | sonnet / medium | 安全與失效鏡頭：注入、競態、部分失敗 |
| `hobbit-gardener` | 哈比人園丁 | sonnet / medium | 簡潔性鏡頭：修剪過度工程 |

後三者組成**抗辯審查小組**——高風險判定時由 `eagle-sentinel` 建議、
**Maia 召集**（≥3 個獨立鏡頭＋一位裁判）。要匹配更強 producer 的嚴謹度，
派遣鏡頭時明示更高的 `model` 參數——派遣時的覆寫優先於角色的 frontmatter pin。

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
cd tlor-agents && ./install.sh          # --dry-run / --force / --uninstall
```

會把角色 `.md` 複製到 `~/.claude/agents/`（並寫入 `.tlor-manifest`，讓
`--uninstall` 精確移除實裝的檔案）。無論哪種方式，裝完**都要開新
session**——agent 定義在 session 啟動時載入。

## 備註

- **Serena 為選配**：兩個搜尋角色的 tools 列了
  [Serena](https://github.com/oraios/serena) 語意工具；沒裝該 plugin 時
  角色會 fallback 到 Grep/Glob（指令內已註明）。
- **Shadow 內建 Explore**：Claude Code v2.1.198 起內建 `Explore` 會繼承
  session model（上限 Opus）——高價 session 上未固定的探索會燒大模型。
  想固定就把 `ranger-pathfinder.md` 複製為 `~/.claude/agents/Explore.md`
  （frontmatter 的 name 記得改成 Explore）。
- **Hard Rules 插槽**：派 `eagle-sentinel` 時把你團隊不可協商的慣例貼進
  prompt，違反即自動 FAIL。
- model 名（haiku/sonnet/opus）依 Agent 工具接受值；環境不同請自行改
  frontmatter。

## 誠實限制

- **帶 Bash 的「唯讀」是行為約束**：`eagle-sentinel`、`elf-archer`、
  `orc-saboteur` 為了跑測試持有 Bash，而 Bash 技術上能寫檔——「絕不編輯」
  是指令不是沙箱。`hobbit-gardener` 是唯一工具層真唯讀的小組成員。
- **模型不可用時靜默 fallback**：依官方文件，被組織排除的 `model:` 值會
  讓 subagent 改跑 session 繼承的模型、不報錯。沒有 opus 的環境，
  `eagle-sentinel` 會安靜地跑在你 session 的模型上。

## 發布流程（維護者）

改動後先 `claude plugin validate . --strict`（驗 plugin.json＋agent
frontmatter），用 `claude --plugin-dir .` 本地實測，最後 bump
`.claude-plugin/plugin.json` 的 `version`——使用者只在版本號變動時收到更新。

## 授權與致敬

MIT © [twjohnwu](https://github.com/twjohnwu)。本專案為對托爾金傳說體系的
粉絲致敬，與 Tolkien Estate 無關、未獲其背書；種族與角色名僅作主題性使用。

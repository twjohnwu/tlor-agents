# 維護

[← 回 README](../../README.zh-TW.md)

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

完整的逐版本紀錄：[release_log.md](../release_log.md)（英文；未來每次發布
都往這裡追加）。

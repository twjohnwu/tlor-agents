# 安裝與所有權

[← 回 README](../../README.zh-TW.md)

## 兩種使用方式

- **輕量**——只裝 plugin。安裝後，任何一個新開的 session 都能使用九個角色
  （若是在已開啟的 session 中安裝，須先執行 `/reload-plugins`）。請直接
  以名稱明確呼叫角色，或加上 [roles.md](roles.md) 的 CLAUDE.md snippet
  以取得穩定的派工——我們的 headless 測試顯示，僅靠 description 並不能
  穩定觸發自動派工，因此 snippet 是建議的輕量做法。
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
（`stdd-skills/*`，非自動載入；見 [skills.md](skills.md)）。本輪僅實作
`ALL`；`RD`/`PM`/`UIUX` 只會印出 deferred 訊息、不安裝任何東西。不加此旗標
→ 不裝任何 STDD skill，與這個旗標出現前的行為相同。

**`--install-hook`** — 選配安裝並在 `settings.json` 註冊 STDD test-file
guard（`hooks/stdd_test_guard.py`）。預設不安裝。**誠實提醒**：Claude
Code 只在 session 啟動時讀取一次 `settings.json` 裡的 PreToolUse
hook——在既有或 `--continue`/`--resume` 的 session 中執行
`--install-hook` 不會讓 hook 在那個 session 生效；請只在全新 session 中驗證。

**輕量使用者**（只裝 plugin、不跑 `/tlor-init`）：見 [roles.md](roles.md)
的 CLAUDE.md snippet，不必完整安裝 rules 也能有派工紀律。

### 方式 C——/tlor-init（plugin 安裝後推薦）

方式 A 安裝後，在 Claude Code 中執行 `/tlor-init` 做引導式設定：選安裝
層級、安裝 rules、產生 CLAUDE.md 路由與 AGENTS.md、選配啟用 hooks。

無論哪種方式，裝完**都要開新 session**——agent 定義在 session 啟動時載入。

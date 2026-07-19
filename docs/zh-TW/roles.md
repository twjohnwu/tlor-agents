# 角色與派工

[← 回 README](../../README.zh-TW.md)

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

## Subagent 派工（輕量版 CLAUDE.md snippet）

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

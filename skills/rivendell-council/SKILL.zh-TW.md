# 瑞文戴爾會議（多方抗辯審查）

> 本檔為 SKILL.md 的繁體中文說明譯本；英文版 SKILL.md 為準（功能檔）。

> 取名自瑞文戴爾那場辯論魔戒去向的會議——辯完，才派出遠征隊。
> 先抗辯，後行動。

> 隨 tlor-agents 附帶；三個鏡頭是本 plugin 的 `elf-archer`、
> `orc-saboteur`、`hobbit-gardener`（自 v1.2.0 起固定 opus）。

## 目的

單一模型自我檢查自己的結論，系統性地會偏向那個結論。這個流程把結論
送給三個立場不同、預設就是要推翻它的獨立 sub-agent，藉此防堵
「聽起來對但其實錯了」的判定。

## 步驟

1. **組裝審查包**——一份自足的陳述：
   - 結論本身（一句話）
   - 結論所依據的證據（file:line、測試輸出、量測數據）
   - 影響範圍（改了什麼、誰依賴它）
   - 若標的是 N 個獨立發現（例如一份審查報告裡的多個項目）：
     每個發現分開裁決——絕不合併成一個總結論；合併會稀釋
     每個發現各自應有的解決度。

2. **一則訊息內同時派遣三個鏡頭**（Agent 工具，subagent_type
   `elf-archer`、`orc-saboteur`、`hobbit-gardener`——並行，絕不序列，
   絕不合併成單一 agent）。每個 prompt = 審查包原文＋該鏡頭的任務。
   Model：三個鏡頭在 frontmatter 中固定 `opus`——這個流程內**不要**傳
   `model: sonnet` 降級（降級是給例行召集用的；抗辯審查依定義就不是
   例行）。若產出結論的模型跑在 opus 以上，在最終報告中誠實說明這個
   嚴謹度落差。每個發現的成本是 3 個 sub-agent；單輪並行上限 6 個
   sub-agent＝每批最多 2 個發現；更多發現放到後續批次，分開回報，
   絕不合併。

3. **判定（多數存活制）**：
   - 3/3 SURVIVED → 確認，採用。
   - 2/3 SURVIVED → 確認，但 REFUTED 那個鏡頭的理由**必須**列為風險
     寫進使用者報告。
   - ≤1/3 SURVIVED → 結論 BLOCKED；依 REFUTED 理由修正後重新提交。

4. **關鍵結論的循環直到收斂**：任何影響正式環境、資料安全、
   合約/schema、或金額/精度的結論——修正後持續重審，直到連續 2 輪
   都沒有新的 REFUTED 理由為止。若無法明確排除上述影響，一律視為
   關鍵結論處理。把已裁決過的理由餵進下一輪的 prompt，避免重複發現。
   其餘一般結論：三鏡頭跑一輪即可。

5. **報告格式**（最終訊息必須包含）：

   | 鏡頭 | 判定 | 關鍵理由 |
   |---|---|---|
   | elf-archer | … | … |
   | orc-saboteur | … | … |
   | hobbit-gardener | … | … |

   加一行：`Adversarial result: N/3 survived → confirmed / blocked (reason)`。

## 絕不

- 為省時間跳過某個鏡頭。
- 把三個鏡頭合併成一個 agent——獨立性是這套流程的前提。
- 靜默吞掉 REFUTED 的理由；要嘛回報，要嘛修正。

---
召集流程的靈感來自 [Miguok/fable-harness](https://github.com/Miguok/fable-harness)（MIT）。

# SOLID 重構前基準檢查清單（Refactor Guardrail）

## 目的
在進入 SOLID 重構前，先固定「可驗證的行為基準」，避免重構過程發生功能回歸（regression）。

## Baseline 範圍
- 核心計算邏輯（FinanceMath）
- 主要互動流程（複利頁、Stock 頁）
- 關鍵 UI 可用性（輸入面板可開關）

## 一、重構前必過項目（Blocking Checklist）
- [ ] 專案可成功 `build-for-testing`
- [ ] Unit Tests 全數通過
- [ ] UI Tests 全數通過
- [ ] 主要使用流程手動 smoke test 通過（複利 + Stock）
- [ ] 無新增 warning（至少與重構前同等級）

## 二、現行自動化測試基準

### Unit Tests（`Compound InterestTests`）
- [ ] `testAnnuityDueYearStep`
  - 驗證「期初投入 + 年底複利」單年度計算正確
  - 期望：`interestEarned = 18_000`、`totalEnd = 198_000`
- [ ] `testCAGR`
  - 驗證 CAGR 計算公式正確
  - 期望：`0.148698355`（容忍誤差 `1e-6`）
- [ ] `testClamp`
  - 驗證上下限夾值邏輯（min/max）
- [ ] `testAdjustedCloseForSplit`
  - 驗證 0050 拆分事件（1 拆 4）前後價格調整邏輯

### UI Tests（`Compound InterestUITests`）
- [ ] `testStockTabShowsSegmentedControl`
  - 驗證 Stock 分頁可進入
  - 驗證 segment 存在，且含 `0050`、`2330`
- [ ] `testFloatingButtonTogglesInputPanel`
  - 驗證複利頁懸浮按鈕可開啟/關閉輸入面板

## 三、執行指令（本機）
```bash
xcodebuild -project "Compound Interest.xcodeproj" \
  -scheme "Compound Interest" \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max' \
  build-for-testing

xcodebuild -project "Compound Interest.xcodeproj" \
  -scheme "Compound Interest" \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max' \
  test-without-building
```

## 四、重構期守則（Guardrail Rules）
- 不先改測試期望值去「配合」新程式，除非需求本身已變更。
- 每一個 SOLID 拆分步驟後都跑一次測試，不等到最後才跑。
- 先抽離 pure logic（無 UI/無 side effect），再調整 UI 層。
- 任何改動若影響計算結果，需補上對應 unit test。
- 任何改動若影響互動流程，需補上對應 UI test 或可重複的手測步驟。

## 五、下一階段建議拆分順序（SOLID 導向）
- [ ] Step 1: 將複利計算/股票估算從 `ContentView` 抽到獨立 service（單一職責）
- [ ] Step 2: 抽出資料存取層（JSON/CSV decoding 與 domain model 分離）
- [ ] Step 3: 引入 protocol 介面（方便替換資料來源與測試注入）
- [ ] Step 4: 將 view state 統一進 ViewModel，降低 View 內部邏輯
- [ ] Step 5: 補齊 edge cases 測試（0 值、空資料、異常日期、語系切換）

## 六、重構完成定義（Definition of Done）
- [ ] 舊有測試全綠
- [ ] 新增測試覆蓋新抽象層
- [ ] 核心計算與 UI 邏輯解耦
- [ ] 主要流程無行為差異（除非需求明確變更）
- [ ] 程式可讀性與可維護性提升（檔案責任清楚、命名一致）

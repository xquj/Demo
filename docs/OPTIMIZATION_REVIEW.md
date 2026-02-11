# 项目优化建议（第一轮）

## 结论（按优先级）

### P0（建议先修）
1. **全局数组/对象未初始化，存在运行时崩溃风险**  
   `global.selected_group`、`global.discard_group` 等静态变量只声明未赋初值，但在运行中直接 `push_back()` / `size()` 使用。建议在游戏入口统一初始化（如 `[]`、`null`、`0`），并提供 `global.reset_runtime_state()`。 
2. **`inventory_temporary` 字段未定义即被调用**  
   卖出逻辑里直接调用 `player.inventory_temporary.add_items(...)`，但 `PlayerEntity`/子类未声明该字段，需补齐数据结构或改为现有货币字段。  
3. **交互脚本存在重复与命名错误（`watting`）**  
   `end_waiting_button.gd` 与 `end_watting_button.gd` 功能重叠，且场景当前绑定的是 `end_watting_button.gd`。建议统一命名与单一脚本来源，避免后续维护误用。

### P1（稳定性与可维护性）
4. **状态流转分散在多处，建议收敛为显式状态机 API**  
   当前有 `_switch_state` + 正式态/过渡态双分发，按钮脚本也会直接切状态。建议引入统一入口（含 guard、日志、埋点）并限制外部直接改 `global.current_state`。  
5. **玩家回合判定写死 2 人公式，扩展性不足**  
   活跃玩家计算里使用 `(global.round % 2 + 1)` 等固定写法，和 `players_size` 混用；若扩展到 3+ 玩家易出错。建议改为纯 `players_size` 取模模型。  
6. **`global` 承担过多运行期引用，耦合高**  
   包含 UI 节点、相机、场景对象、战斗态数据，导致初始化顺序敏感。建议将“场景引用”与“对局数据”拆分（如 `GameContext` + `MatchState`）。

### P2（性能与工程卫生）
7. **仓库混入大量临时/构建产物**  
   例如 `node_3d.tscn*.tmp`、`build/*.exe`、`build/*.pck` 已入库。建议补 `.gitignore` 并清理历史，减少仓库体积与冲突概率。  
8. **`_process` 每帧全量执行，可做事件化削减**  
   如手牌计数文本、某些标签刷新可改为“数据变化时更新”，避免每帧字符串构造。  
9. **资源命名与目录存在拼写问题（`textrue`）**  
   建议统一为 `texture`，并制定资源命名规范（家族/稀有度/ID），为后续自动化导表做准备。

---

## 建议的落地顺序（两周内）

### 第 1 周（先止血）
- 初始化 `global` 与 `PlayerEntity` 运行态字段。  
- 修复/实现 `inventory_temporary` 或替换为明确货币系统字段。  
- 合并并重命名 `end_watting_button.gd` → `end_waiting_button.gd`，同步场景引用。  

### 第 2 周（结构优化）
- 统一状态切换入口（只允许 `GameSense3D` 切换状态）。  
- 重写活跃玩家计算逻辑以支持 N 人。  
- 清理临时/构建文件并建立 `.gitignore` 规则。

---

## 可量化目标（建议）
- 启动后首局零报错（控制台）。  
- 状态切换相关 bug（按钮无效/卡住）下降 80%。  
- 仓库体积显著下降（删除构建产物后）。

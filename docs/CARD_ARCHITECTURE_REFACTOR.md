# 卡牌架构重构方案（面向当前项目）

## 1. 重构目标

当前项目已经有「卡牌状态机 + 3D表现 + 基础回合状态」雏形，但业务规则、对局状态、动画输入耦合在一起，导致：

- 功能扩展（加新关键词、新结算）需要改很多脚本。
- 状态切换来源分散，容易出现“卡住态/重复切态”。
- UI/输入逻辑会直接改业务数据，难以测试。

本方案目标：

1) **规则与表现解耦**：先算结果，再播动画。  
2) **单一结算入口**：所有出牌/卖出/驯服/回合结束，都走同一套命令流水线。  
3) **可扩展关键词系统**：新增卡牌能力不需要改核心 switch。  
4) **可回放/可测试**：命令和事件可记录，方便排查与重放。

---

## 2. 建议的目标分层

```text
Input/UI
  -> BattleFacade (应用层门面)
      -> CommandBus (命令)
          -> CombatDomain (领域结算)
              -> EventBus (领域事件)
                  -> Presenter/Animator (表现层)
```

### 2.1 Domain（纯规则，不依赖 Node）

- `CardInstance`：对局中的卡牌实例（id、owner、zone、hp、attack、keywords）
- `PlayerState`：玩家状态（hp、资源、hand/board/discard/deck）
- `MatchState`：整局状态（turn、phase、active_player、rng_seed）
- `CombatResolver`：唯一规则入口，处理命令并产出事件
- `KeywordProcessor`：关键词效果（on_summon/on_attack/on_death）

> 关键原则：Domain 不引用 Godot 节点类型，不做动画、不读鼠标输入。

### 2.2 Application（编排层）

- `BattleFacade`：UI唯一调用入口（例如 `request_play_card`）
- `CommandBus`：收集命令，顺序执行，校验合法性
- `EventBus`：发布领域事件（伤害、死亡、抽牌、资源变化）
- `TurnCoordinator`：推进 phase 与主动玩家

### 2.3 Presentation（表现层）

- `CardView`（现有 `card_base.gd` 可演进）：只负责显示和动画
- `CardStateVisual`（现有 states 可转为视觉状态）：只消费事件，不改规则
- `HUDPresenter`：监听事件更新 UI 文案/数值

---

## 3. 数据模型建议（最小可用）

## 3.1 卡牌静态配置（CardDef）

建议放在 `res://data/cards/*.json`：

```json
{
  "id": "fire_asmodeus",
  "name": "Asmodeus",
  "cost": { "blood": 1, "bone": 0, "gold": 0 },
  "stats": { "atk": 2, "hp": 3 },
  "keywords": ["flying", "on_kill_draw"]
}
```

## 3.2 卡牌对局实例（CardInstance）

- `instance_id`
- `def_id`
- `owner_id`
- `zone`（DECK/HAND/BOARD/WAIT/DISCARD）
- `atk_current`
- `hp_current`
- `flags`（frozen/silenced/marked）

## 3.3 命令与事件

**命令（输入意图）**
- `PlayCardCommand`
- `SellCardCommand`
- `TameCardCommand`
- `EndPhaseCommand`
- `EndTurnCommand`

**事件（结算结果）**
- `CardMovedEvent`
- `DamageAppliedEvent`
- `CardDiedEvent`
- `ResourceChangedEvent`
- `TurnAdvancedEvent`

---

## 4. 结合你当前项目的迁移映射

## 4.1 现状脚本角色迁移

- `scripts/GameSense3D.gd`：拆成
  - `BattleFacade`（业务入口）
  - `BattleScenePresenter`（场景节点绑定与UI刷新）
- `scripts/global.gd`：拆成
  - `MatchStateStore`（纯数据）
  - `SceneRefs`（场景节点缓存）
- `scripts/card/states/*.gd`：保留，但降级为“视觉状态”，不再负责规则写回。

## 4.2 目录建议

```text
scripts/
  domain/
    card_instance.gd
    player_state.gd
    match_state.gd
    combat_resolver.gd
    keyword/
      keyword_processor.gd
      effects/
  application/
    battle_facade.gd
    command_bus.gd
    event_bus.gd
    turn_coordinator.gd
  presentation/
    battle_scene_presenter.gd
    hud_presenter.gd
    card/
      card_view.gd
      visual_states/
  infrastructure/
    card_repository.gd
    save_repository.gd
data/
  cards/
```

---

## 5. 一条“最小重构路径”（不推翻重写）

### Phase 1：先收口入口（1~2天）

- 新增 `BattleFacade`，把“卖出/驯服/结束阶段”入口统一。
- UI按钮不再直接改 `global.current_state`，只调用 facade。

### Phase 2：命令化结算（2~4天）

- 把现有 `_on_sell_button_up/_on_tame_button_up` 迁成命令。
- `CombatResolver.apply(command)` 返回事件数组。
- 事件驱动 UI 与动画，而不是业务里直接改节点。

### Phase 3：卡牌状态机降维（2~3天）

- `SelectingState/WaitingState/HeldState` 仅负责 hover、移动、高亮。
- 回合推进、归属写回、资源变化全部由 Domain 产出。

### Phase 4：关键词插件化（3~5天）

- 做 `KeywordProcessor` 钩子：
  - `on_before_attack`
  - `on_after_attack`
  - `on_card_death`
- 新关键词仅新增 effect 脚本并注册。

---

## 6. 关键接口草图（伪代码）

```gdscript
# application/battle_facade.gd
func request_sell_card(card_id: String, actor_id: int) -> void:
    command_bus.enqueue(SellCardCommand.new(card_id, actor_id))

# domain/combat_resolver.gd
func apply(command: DomainCommand, state: MatchState) -> Array[DomainEvent]:
    var events: Array[DomainEvent] = []
    # 1) validate
    # 2) mutate state
    # 3) collect events
    return events

# application/command_bus.gd
func flush() -> void:
    while not _queue.is_empty():
        var cmd = _queue.pop_front()
        var events = resolver.apply(cmd, state_store.state)
        event_bus.publish_all(events)
```

---

## 7. 完成标准（验收）

- 新增一个关键词效果，不改 `GameSense3D` 主循环。
- UI按钮脚本中不再出现对 `global.current_state` 的直接赋值。
- 单步回放一条命令日志，可复现同样事件序列。
- 战斗规则可以在无场景（headless）脚本中跑通基本结算。

---

## 8. 风险与规避

- **风险：一次性迁移太大** → 采用 facade 过渡层，老逻辑先挂在 facade 后面。
- **风险：视觉状态和规则双写** → 规定“规则只改 Domain，视觉只消费 Event”。
- **风险：调试困难** → 先做命令/事件日志落地（JSON行日志）。

---

## 9. 给你项目的落地建议（先做三件事）

1. 先建 `scripts/application/battle_facade.gd`，把所有按钮入口接进去。  
2. 增加 `DomainCommand/DomainEvent` 基类与最小 `SellCardCommand`。  
3. 给现有 `GameSense3D` 保留壳层，仅做“转发 + Presenter”，逐步变薄。

这三步做完，你的项目会从“原型脚本集合”进入“可扩展系统”。

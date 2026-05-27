# PRD: 2D Platformer 核心 Bug 修复

## Problem Statement

2D Platformer Starter Kit 项目存在几个关键 Bug 和代码质量问题，影响玩家体验和代码可维护性：

1. **玩家无限坠落**：关卡中存在地面缝隙，玩家掉入后没有坠落死亡检测，会无限下落无法复位
2. **通关时播放错误动画**：到达终点门时调用了 `death_tween()`（死亡缩放动画），该动画被场景切换打断且会在背景播放复活音效
3. **代码重复**：`DoorTrigger.gd` 和 `LevelFinishDoor.gd` 是完全相同的两份代码，一处修改需要同步两处
4. **结算画面显示歧义**：星星数量按当前关卡金币（`level_score`）计算，但金币总数显示为全关卡累计（`score`），两者口径不一致
5. **HUD 计时器累计**：游戏内计时器显示的是累计总时间（`total_time`）而非当前关卡用时

## Solution

对上述 5 个问题进行分类处理：

- **Bug 修复**（1-3）：修改游戏逻辑代码，消除玩家可以无限坠落的场景、移除通关时多余的死亡动画、消除重复代码
- **设计保留**（4-5）：确认结算画面显示总金币数和 HUD 显示总时间属于设计意图，不予修改

## User Stories

1. 作为玩家，我希望掉出世界边界后能够自动死亡并重生，这样我不会卡在无限下落状态
2. 作为玩家，我希望到达终点门时不会听到复活音效，这样通关体验不会被打断
3. 作为开发者，我希望 `DoorTrigger.gd` 和 `LevelFinishDoor.gd` 共享同一份实现，这样修改通关逻辑时只需修改一处
4. 作为玩家，我希望结算画面显示的总金币数反映我整个游戏过程的积累，这样更有成就感
5. 作为玩家，我希望 HUD 计时器显示从第一关开始的累计时间，这样我能了解总通关时长

## Implementation Decisions

### 1. 坠落死亡检测

- **修改文件**：`Scripts/player.gd`
- 在 `movement()` 中 `move_and_slide()` 之后添加 `global_position.y > 1000` 的检查
- 阈值 1000 与 `enemy.gd` 保持一致，位于关卡可视区域下方
- 添加 `is_dead` 布尔标志位防止 `_physics_process` 中重复触发死亡流程
- 在 `death_tween()` 中重生完成后（`respawn_tween()` 之前）将 `is_dead` 重置为 `false`

### 2. 移除通关时多余的死亡动画

- **修改文件**：`Scripts/LevelFinishDoor.gd`
- 删除 `get_tree().call_group("Player", "death_tween")` 调用
- 场景切换动画由 `SceneTransition` 的 Autoload 统一处理（渐隐/缩放过渡）
- 由于 `DoorTrigger.gd` 现在继承自 `LevelFinishDoor.gd`，一处修改即可覆盖两种使用场景

### 3. 消除 DoorTrigger.gd 重复代码

- **修改文件**：`Scripts/DoorTrigger.gd`
- 将 `DoorTrigger.gd` 全部代码替换为 `extends "res://Scripts/LevelFinishDoor.gd"`
- 保留 `DoorTrigger.gd` 文件是为了避免修改 `Level_02.tscn` 中的资源引用
- `Level_02.tscn` 引用 `DoorTrigger.gd` 的 ExtResource 仍然有效，会自动获得 `LevelFinishDoor.gd` 的所有功能

### 4 & 5. 设计保留

- 结算画面 `CompletionScreen.gd:39` 中 `GameManager.score` 显示总金币数 — 不变
- HUD `GameUI.gd:13` 中 `GameManager.total_time` 显示总时间 — 不变

## Testing Decisions

- **测试方式**：在 Godot 编辑器中启动项目，手动验证以下路径：
  - 玩家从 Level_02 的缝隙掉落（x≈768-1024 范围），观察是否触发死亡并重生
  - 玩家到达终点门，观察是否出现非预期的缩小动画或复活音效
  - `DoorTrigger.gd` 是否能正常调用 `LevelFinishDoor.gd` 的逻辑
- 由于项目为 Starter Kit 性质，暂不引入自动测试框架

## Out of Scope

- 新增关卡、敌人类型或陷阱类型
- 修改游戏 UI 布局或样式
- 添加新的游戏机制（如存档、生命值系统）
- 重构 `player.gd` 的二段跳逻辑（虽有混淆但功能正常）

## Further Notes

- 项目中存在一个 `2d-platformer---starter-kit-(copy)/` 备份目录（不在 git 中跟踪）
- 所有 `[DEBUG-...]` 标记的日志已清理
- Godot 4.6.1 下测试通过，无报错

# Reset Buddy

重新生成 Claude Code 的 userID 并清除 companion 数据，下次运行 `/buddy` 时会生成全新的宠物。

## 原理

Claude Code 的 buddy（伴侣宠物）是根据 `userID` 确定性生成的。同一个 userID 总是产出相同的宠物。脚本通过：

1. 生成新的 64 位十六进制 userID（与 Claude 内部规则一致：`crypto.randomBytes(32).toString('hex')`）
2. 移除 `companion` 字段

来实现重新生成。

## 使用

**macOS / Linux：**

```bash
bash reset-buddy.sh            # 执行重置
bash reset-buddy.sh --dry-run  # 预览变更，不写入
```

**Windows：**

```cmd
reset-buddy.bat            :: 执行重置
reset-buddy.bat --dry-run  :: 预览变更，不写入
```

## 前置依赖

- [Python](https://www.python.org/downloads/)（脚本用其解析和生成 JSON）

## 脚本会做什么

1. 检查 `~/.claude.json`（Windows: `%USERPROFILE%\.claude.json`）是否存在且为合法 JSON
2. 显示当前 userID 和 companion 信息
3. 备份配置文件为 `.claude.json.buddy-backup.<时间戳>`
4. 写入新 userID，移除 companion 字段
5. 验证写入结果

## userID 更改影响范围

`userID` 在 Claude Code 中除了宠物系统外，还用于以下场景：

| 场景 | 文件 | 用途 |
|------|------|------|
| 遥测/分析 | `firstPartyEventLogger.ts` | `user_id` — 用户行为追踪 |
| 遥测/分析 | `datadog.ts` | `getUserBucket()` — A/B 实验分桶（hash(userID) % 100） |
| API 调用 | `claude.ts` | `device_id` — 请求标识 |
| 用户数据 | `user.ts` | `getCoreUserData()` — 核心用户信息聚合 |
| 遥测属性 | `telemetryAttributes.ts` | 遥测字段 |
| 宠物系统 | `companion.ts` | 确定性生成宠物属性 |

### 对未登录用户的影响

- **不会丢失 API 访问** — 认证依赖 `ANTHROPIC_AUTH_TOKEN`，与 userID 无关
- **不会丢失项目配置** — 项目级信任等存储在 `projects` 字段，不受影响
- **不会丢失全局设置** — 主题、快捷键等不受影响
- **遥测数据断裂** — 服务端会将其视为新设备（若已关闭非必要流量则无影响）
- **A/B 实验分桶变化** — 可能进入不同的功能开关分组

**结论：对未登录的本地中转用户，改 userID 几乎没有副作用，唯一实质变化是宠物重新孵化。**

## 执行后

重启 Claude Code，运行 `/buddy` 即可孵化新的伴侣宠物。

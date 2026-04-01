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

## 执行后

重启 Claude Code，运行 `/buddy` 即可孵化新的伴侣宠物。

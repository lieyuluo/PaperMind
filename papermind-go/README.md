# PaperMind-Go

> PaperMind 的 Go 后端服务，用于学术论文的智能解析、逻辑建模与 RAG 问答。
>
> **完整 Phase 1 验收以 GitHub Actions CI 结果为准。**

## 项目结构

```
papermind-go/
├── .github/workflows/    # CI workflows
├── api/                  # API 定义
├── cmd/                  # 入口程序 (api, worker, migration)
├── internal/             # 内部模块
│   ├── controller/       # HTTP 控制器
│   ├── service/          # 业务逻辑
│   ├── logic/            # 业务逻辑层
│   ├── dao/              # 数据访问对象
│   ├── model/            # 数据模型 (entity, dto)
│   ├── middleware/        # 中间件 (JWT auth)
│   ├── config/           # 配置结构体
│   └── storage/          # 外部服务连接 (postgres, qdrant, minio, temporal)
├── pkg/                  # 公共工具包 (response, errors, logger, jwt)
├── migrations/           # 数据库迁移文件
├── deployments/          # Docker Compose 配置
├── manifest/config/      # 运行时配置文件
├── scripts/              # 验收与报告脚本
├── reports/              # 验收报告输出
└── docs/                 # 文档
```

## 技术栈

| 组件 | 技术 |
|---|---|
| Language | Go |
| Database | PostgreSQL |
| Vector DB | Qdrant |
| Object Storage | MinIO |
| Workflow Engine | Temporal |
| Auth | JWT |
| Deployment | Docker Compose |
| CI/CD | GitHub Actions |

## 本地开发

### 前提条件

- Go 1.25+
- **不需要 Docker** — Docker 相关验收在 GitHub Actions 中完成

### 快速开始

```bash
cd papermind-go

# 安装依赖
go mod tidy

# 本地验证（编译 + 测试，不需要 Docker）
make phase-1-local

# 启动 API 服务（需要 PostgreSQL 运行中）
make run-api
```

### 可用 Make 命令

| 命令 | 说明 | 需要 Docker |
|---|---|---|
| `make phase-1-local` | 本地验证：编译 + 测试 | **否** |
| `make phase-1-ci` | 完整 CI 验收流程 | 是 |
| `make test` | 运行 Go 测试 | 否 |
| `make run-api` | 启动 API 服务 | 是 |
| `make compose-up` | 启动 Docker 基础设施 | 是 |
| `make compose-down` | 停止 Docker 基础设施 | 是 |
| `make migrate-up` | 执行数据库迁移 | 是 |
| `make migrate-down` | 回滚数据库迁移 | 是 |
| `make verify-phase-1` | 运行验收脚本 | 视环境 |
| `make report-phase-1` | 生成验收报告 | 否 |

## CI/CD

### Phase 1 验收

完整的 Phase 1 验收在 **GitHub Actions** 中执行（`.github/workflows/phase-1.yml`）。

**触发条件：**
- Push 到 `main` 或 `develop` 分支
- 针对`main` 的 Pull Request
- 手动触发（workflow_dispatch）

**CI 流程：**
1. Checkout + Setup Go
2. Docker Compose 启动所有基础设施
3. 等待 PostgreSQL / Qdrant / MinIO / Temporal 就绪
4. 执行数据库迁移
5. 运行 Go 测试
6. 启动 API 服务
7. 验收所有端点（health / login / me）
8. 生成报告并上传 artifacts

**验收标准：**
- CI 中所有检查项必须 **PASS**，不允许 **SKIP**
- 任何 FAIL 或 SKIP 都会导致 CI 失败

### 本地 vs CI

| 检查项 | 本地 | CI |
|---|---|---|
| Go 编译 | ✅ | ✅ |
| Go 测试 | ✅ | ✅ |
| Docker 服务 | — | ✅ |
| PostgreSQL 连接 | — | ✅ |
| Qdrant / MinIO / Temporal | — | ✅ |
| 数据库迁移 | — | ✅ |
| API 端点验证 | — | ✅ |
| JWT 认证流程 | — | ✅ |

> **本地不需要 Docker。** 完整 Phase 1 验收以 GitHub Actions 结果为准。

## API 端点

### 健康检查

```
GET /api/v1/health
```

### 登录

```
POST /api/v1/auth/login
Content-Type: application/json

{"username": "admin", "password": "admin123"}
```

### 当前用户

```
GET /api/v1/me
Authorization: Bearer <token>
```

## 配置

配置文件位于 `manifest/config/config.yaml`。示例配置见 `manifest/config/config.example.yaml`。

## License

See [LICENSE](../LICENSE) for details.

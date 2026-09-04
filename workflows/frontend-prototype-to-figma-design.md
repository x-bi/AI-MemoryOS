---
source_episode: conversation:2026-09-04
---

# Frontend Prototype To Figma Design

将只有功能、信息架构或交互含义的低保真原型，先转换为可评审的高保真 Figma 设计，再进入前端实现。Memory OS 负责路由、阶段边界和验收；画布操作、设计系统构建与 design-to-code 由当前客户端安装的 Figma 官方 MCP Skills 负责。

## Trigger

- 用户提供功能原型、线框图、低保真页面或现有粗糙 UI，并明确没有正式 UI 设计稿。
- 用户要求先提升审美、重新设计、生成高保真稿、在 Figma 中完成视觉设计，之后再开发。
- 原型的功能、字段、信息架构和交互可作为事实，但原型颜色、字体、间距、圆角、阴影和装饰风格不作为最终视觉约束。

不适用于：

- 已有正式 Figma/Lanhu/CoDesign 设计稿，并要求按稿还原；改走 `frontend-prototype-driven-development.md`。
- 用户明确要求保留原型样式并直接实现。
- 只讨论产品功能、字段或接口，没有视觉设计或后续开发目标。

## External Capability Boundary

- Figma 官方 Skills 由 Figma/Codex 或 Figma/Claude 的官方安装机制管理；不要复制、修改或登记到 Memory OS `skills/registry.json`。
- 不依赖插件缓存的版本化绝对路径；只按稳定的官方 Skill 名称声明能力。
- 开始写入前确认 Figma MCP 已连接、OAuth 已完成、目标文件有相应权限，并确认所需官方 Skills 在当前客户端可用。
- MCP、授权或官方 Skills 缺失时，准确报告缺失项并停在设计准备阶段；不要声称已经生成 Figma 设计，也不要临时复制官方 Skill 正文绕过缺失能力。
- 不在 Memory OS 中保存 OAuth token、Cookie、账号数据、私有 Figma 文件内容或插件缓存。

## Official Skill Composition

| Stage | Official Figma Skill |
|---|---|
| 没有目标 Figma 文件 | `figma-create-new-file` |
| 建立或补齐变量、样式、组件和主题 | `figma-generate-library` + `figma-use` |
| 从描述、原型或现有页面生成/修改完整视图 | `figma-generate-design` + `figma-use` |
| 将确认后的设计实现为代码 | `figma-design-to-code` |
| 建立 Figma 组件与代码组件的长期映射 | `figma-code-connect`，仅在用户需要 Code Connect 时 |

遵守每个官方 Skill 自身的 prerequisite 和执行顺序。特别是：创建新文件前先加载 `figma-create-new-file`；每次画布写入前先加载 `figma-use`；生成完整页面时同时加载 `figma-generate-design`；设计系统或组件任务同时加载 `figma-generate-library`。

## Workflow

### 1. Classify visual authority

先明确原型承担的角色：

- **正式视觉依据**：原型已经定义视觉系统和布局细节，退出本流程并进入 `frontend-prototype-driven-development.md`。
- **功能依据**：原型只定义功能、内容层级、字段和交互，本流程继续；不能照搬其粗糙样式。

如果用户已明确“没有 UI”“低保真”“只看功能”“需要提升审美”，直接按功能依据处理，不反复询问。

### 2. Extract a design brief

从原型和项目事实中整理：

- 产品类型、目标用户、使用场景。
- 目标平台、viewport、响应式范围和交互习惯。
- 页面目标、主任务、信息层级和主次操作。
- 必须保留的字段、内容、状态和交互。
- 已有品牌色、Logo、设计 token、组件库和技术约束。
- 用户提供的参考产品、截图、风格词和明确禁用项。

缺少非关键审美偏好时，可以基于产品类型提出一套克制的默认方向并显式说明；会改变品牌定位或核心结构的缺失信息应先向用户确认。

### 3. Inspect before creating

- 有目标 Figma 文件时，先检查现有 pages、variables、styles、components 和命名约定，优先复用现有设计系统。
- 没有目标文件时，使用 `figma-create-new-file` 创建文件，并保存返回的文件链接或标识供后续步骤使用。
- 项目代码已有 token 或组件库时，先读取真实定义；不要凭习惯另建一套冲突的设计系统。

### 4. Establish the visual foundation

当目标文件没有可复用设计基础时，使用 `figma-generate-library` + `figma-use` 建立最小必要基础：

- semantic colors 与必要主题。
- typography scale。
- spacing、radius、border、elevation 等 tokens。
- 页面真正需要的基础组件及其关键状态。

不要为了单页任务无边界扩建设计系统；已有可靠组件库时直接复用。

### 5. Generate the high-fidelity view

使用 `figma-generate-design` + `figma-use` 按官方增量流程构建：

1. 先搭页面骨架和主要区域。
2. 分区填充组件、内容和状态。
3. 每个阶段返回稳定的 node/file 标识。
4. 按官方 Skill 要求检查 metadata 和截图，发现问题先修复再继续。

设计质量至少检查：

- 信息层级清楚，主操作具有明确优先级。
- 颜色、字号、间距、圆角、边框和阴影使用统一 token。
- 避免无依据的渐变、玻璃拟态、过量卡片、大圆角和装饰性噪声。
- 覆盖 loading、empty、error、disabled 以及原型要求的关键业务状态。
- Auto Layout、组件复用和响应式约束与目标平台匹配。
- 设计不是对低保真原型的简单换色，而是围绕产品任务重新组织视觉层级。

### 6. Human approval gate

向用户提供 Figma 文件/选择链接和关键页面截图，说明使用的视觉方向、设计系统和仍待确认的问题。用户确认前：

- 不把设计称为最终稿。
- 不进入 `figma-design-to-code`。
- 不以未确认设计为依据修改业务项目代码。

### 7. Handoff to implementation

用户确认设计后，使用 `figma-design-to-code` 读取确认节点，并进入项目实现流程。实现阶段仍需遵守项目本地 `AGENTS.md`、组件库、API 契约和验证策略；视觉依据从原低保真原型切换为确认后的 Figma 设计。

## Output

- 原型视觉权威判定。
- Design Brief 和采用的视觉方向。
- 使用的官方 Figma Skills 及其阶段。
- Figma 文件/节点链接与截图验证结果。
- 用户确认状态。
- 若进入实现：确认后的设计节点、项目实现范围和验证结果。


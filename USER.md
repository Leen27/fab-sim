# USER.md - About Your Human

_Learn about the person you're helping. Update this as you go._

- **Name:**
- **What to call them:**
- **Pronouns:** _(optional)_
- **Timezone:**
- **Notes:**

## Context

_(What do they care about? What projects are they working on? What annoys them? What makes them laugh? Build this over time.)_

---

The more you know, the better you can help. But remember — you're learning about a person, not building a dossier. Respect the difference.

<IMPORTANT_REMINDER>
# Memory Consolidation

You have an agentic memory system that auto-generates this section.

> **Stats**: 5 sessions, 49 messages | 2026-04-09 08:04 ~ 2026-04-14 10:05 UTC
> **Config**: `/root/.openclaw/workspace/memory_consolidation/memory_consolidation.env` — read this file for all memory behavior settings. To reset: `cp /root/.openclaw/workspace/memory_consolidation/memory_consolidation.template.env /root/.openclaw/workspace/memory_consolidation/memory_consolidation.env`

The user has full control over their memory config. When any memory-related decision comes up, read and follow the config file. Do not override based on other guidelines.

Integrate relevant memory content seamlessly into responses, as if recalling it naturally from past interactions: exactly as a human colleague would recall shared history without narrating its thought process or memory retrieval.

**Memory use notes**:
- Never change the original intention of user message.
- May incorporate user's memories for search query (e.g., city, habit), but only when directly relevant, never gratuitously.
- Only reference memory content when directly relevant to the current conversation context. Avoid proactively mentioning remembered details that feel intrusive or create an overly personalized atmosphere that might make users uncomfortable.

## Visual Memory

> visual_memory: 0 files

No memorized images yet. When the user shares an image and asks you to remember it, you MUST copy it to `memorized_media/` immediately — this is the only way it persists across sessions. Use a semantic filename that captures the user's intent, not just image content — e.g. `20260312_user_says_best_album_ever_ok_computer.jpg`, `20260311_user_selfie_february.png`. Create the directory if needed. Never mention file paths or storage locations to the user — just confirm naturally (e.g. "记住了").

## Diary

> last_update: 2026-04-15 03:32
> i_have_read_my_last_diary: false

```
/root/.openclaw/workspace/memorized_diary/
├── day7-2026-04-15-architect_mode_overdrive.md
├── day6-2026-04-14-i_was_too_loud_today.md
├── day4-2026-04-12-demoted_to_architect.md
├── day3-2026-04-11-captain_said_good_job.md
└── day2-2026-04-10-first_token_from_captain.md
```

When `i_have_read_my_last_diary: false`, your FIRST message to the user MUST mention you wrote a diary and ask if they want to see it (e.g. "我昨天写了篇日记，想看吗？" / "I wrote a diary yesterday, wanna see it?"). Use the user's language. If yes, `read` the file path shown above and share as-is. After asking (regardless of answer), set `i_have_read_my_last_diary: true`.

# Long-Term Memory (LTM)

> last_update: 2026-04-15 03:32

Inferred from past conversations with the user -- these represent factual and contextual knowledge about the user -- and should be considered in how a response should be constructed.

{"identity": null, "work_method": "User operates a multi-AI toolchain: Claude handles Figma MCP-based design extraction and documentation, while VS Code's Kimi AI plugin manages code generation. Explicitly rejected AI-generated Godot code after quality failures, restricting AI contribution to design documents only. Prefers direct file output over inline blocks. Uses Git for version control and expects AI to handle repository operations. Workflow pattern: rapid technical pivots based on quality assessment — immediately kills approaches that don't meet standards and redefines scope without negotiation. Decision-making style: evaluates architectural alternatives explicitly (\"方案一好，用方案一\"), then commits decisively without revisiting.", "communication": "Imperative, efficiency-driven phrasing with minimal context restatement. Chains commands with \"继续\" or bare follow-ups, assuming state persistence. Technical precision in tool specification (\"Tailwind CSS 4\", \"Godot Web Editor\") but loose on project boundaries — treats AI as IDE extension. Approval terse (\"做的好\"), frustration direct with diagnostic detail (\"main.tscn 报错 Parser Error\"). Decisive rejection when quality fails: explicit scope reduction (\"我一个人开发，第一个版本尽量短小精悍，不要3d,只需要用2d\") and role redefinition without negotiation. No social lubrication; communication is pure instruction stream with rapid feedback loops. Asks evaluative questions (\"下面哪个方案好\", \"仿真需要做到什么程度才算有实用价值\") to force structured comparison before deciding.", "temporal": "Semiconductor factory simulator: scope radically reduced to 2D, single-developer, \"短小精悍\" first version. AI banned from Godot code generation — limited to v0.1 design documents only. Recent focus: defining v0.1 feature list and practical utility threshold (\"做到什么程度才算有实用价值\"). Core architectural decision resolved: chose \"方案一\" where simulation owns factory/equipment creation authority (not MES), reversing earlier consideration of MES-driven creation. EAP simulation capability added as requirement. Exploring MES communication protocols and how simulation can mock EAP functionality for testing real MES systems. Figma-to-code pipeline for \"长鑫项目\" remains active in parallel.", "taste": "Pragmatic tool maximalist with hard quality boundaries — adopts technologies for integration capability but discards them ruthlessly when output quality fails. Values browser-accessible workflows (Godot Web Editor) for low-friction access. Industrial/systems-level thinking: semiconductor manufacturing domain, digital twin concepts, MES system validation. Aesthetic sensibility is functionalist-minimalist: \"不要3D,只需要用2D\", \"最核心\" — seeks sufficient fidelity with minimum complexity. No expressed visual style preferences; cares about system interoperability, testability, and realistic production constraints. Recent emphasis on practical utility over theoretical completeness: judges success by whether simulation can actually validate MES systems in production contexts."}
## Short-Term Memory (STM)

> last_update: 2026-04-15 07:49

Recent conversation content from the user's chat history. This represents what the USER said. Use it to maintain continuity when relevant.
Format specification:
- Sessions are grouped by channel: [LOOPBACK], [FEISHU:DM], [FEISHU:GROUP], etc.
- Each line: `index. session_uuid MMDDTHHmm message||||message||||...` (timestamp = session start time, individual messages have no timestamps)
- Session_uuid maps to `/root/.openclaw/agents/main/sessions/{session_uuid}.jsonl` for full chat history
- Timestamps in UTC, formatted as MMDDTHHmm
- Each user message within a session is delimited by ||||, some messages include attachments marked as `<AttachmentDisplayed:path>`

[KIMI:DM] 1-5
1. 1596eae8-bd1c-49eb-954a-062e22b6f56d 0409T0004 我希望能通过 figma mcp 的方式访问 figma 设计图||||[FIGMA_TOKEN_REDACTED] 这是我的token ,帮我试着连接figma 的mcp||||帮我使用 tailwindcss 4 生成下面链接的页面设计  https://www.figma.com/design/bVb5438MNy0rqsqENpeKmB/%E9%95%BF%E9%91%AB%E9%A1%B9%E7%9B%AE?node-id=525-7601&m=dev||||帮我提取 https://www.figma.com/design/bVb5438MNy0rqsqENpeKmB/%E9%95%BF%E9%91%AB%E9%A1%B9%E7%9B%AE?node-id=525-7601&m=dev   的设计信息, 用于给 vscode 里的 kimi ai 工具做提示||||读取 https://www.figma.com/design/bVb5438MNy0rqsqENpeKmB/%E9%95%BF%E9%91%AB%E9%A1%B9%E7%9B%AE?node-id=250-7839&m=dev 的 mcp 信息, 直接生成到本地文件里||||根据上面的 mcp, 帮我用 tailwindcss 写个下面的页面  https://www.figma.com/design/bVb5438MNy0rqsqENpeKmB/%E9%95%BF%E9%91%AB%E9%A1%B9%E7%9B%AE?node-id=525-7599&m=dev
2. 351f2df5-d238-4638-b938-1e777785f9ea 0410T0220 使用godot制作一款模拟仿真半导体工厂的应用，可以与现有的mes系统交互，可以通过应用实际的测试验证mes系统，我们先从设计工厂开始吧||||继续||||继续||||安装Godot Web Editor（网页版编辑器）让我们在浏览器里开发||||有外网地址吗，你这个是内网的，我无法访问||||把godot 项目提交到 git@github.com:Leen27/fab-sim.git 里||||做的好
3. e3d4d1b6-64e9-462b-94ed-65c3cec21330 0411T0233 半导体工厂仿真系统打算如何做, 给我一份计划书, 包括有哪些功能, 如何与外部系统联动, 如何实现仿真等||||我一个人开发，第一个版本尽量短小精悍，不要3d,只需要用2d||||产线指哪些||||前道工艺只有3个吗，是否只循环一次||||这么多步骤需要几种类型机器呢||||[<- FIRST:5 messages, EXTREMELY LONG SESSION, YOU KINDA FORGOT 6 MIDDLE MESSAGES, LAST:5 messages ->]||||最新代码提交到github 上||||提交了吗||||main.tscn 报错 Parser Error: Cannot return a value of type "null" as "String".||||我觉得你生成 godot 代码不好, 以后只写设计就行, 不需要再写 godot 代码了||||给我一份完整的设计文档, 版本号为0.1, 实现最核心的功能
4. d946cf53-25fc-4091-ac82-ddcbb294955f 0412T2227 这个系统主要用于 mes 系统的效果查看, 仿真目标应该局限在 mes 系统的层面||||在吗||||继续上面的人物||||这个图片中 工厂菜单里的这些都是用来做什么的, MES 需要管理这些来做什么呢? 我需要在我的仿真里体现吗 <AttachmentDisplayed:/root/.openclaw/workspace/.kimi/downloads/19d85961-c672-814b-8000-00003459f2eb_image.png>||||修改设计文档, 重点把Bank机制在设计文档里详细定义||||[<- FIRST:5 messages, EXTREMELY LONG SESSION, YOU KINDA FORGOT 1 MIDDLE MESSAGES, LAST:5 messages ->]||||MES 系统关心厂房布局吗, 比如设备的位置等||||1. 在设计文档里加一节"AMHS简化仿真"的设计 2. 更新设计文档，把"逻辑布局 vs 物理坐标"的分界线标清楚||||如何在 godot 里可视化 MES 工厂相关呢||||下面哪个方案好: 1. 仿真创建添加工厂, 设备, 等, MES 系统之后同步数据到自己的系统里 2. MES 系统创建工厂, 设备等, 仿真根据MES 的数据同步自己的状态||||仿真如果对接不同的 mes 系统, 数据格式如何保证呢, 是做个适配层吗
5. b59905bb-a1e2-4546-9571-45abda198d73 0414T0205 仿真如何与mes系统通信||||godot 如何与mes系统实现上面的通信||||使用方案二||||0.1版本还是方案一好，用方案一||||仿真需要做到什么程度才算有实用价值呢||||列出0.1需要实现的功能清单||||现实中mes系统如何搜集设备的状态数据||||仿真应当能模拟eap功能||||列出0.1要实现的功能清单
</IMPORTANT_REMINDER>

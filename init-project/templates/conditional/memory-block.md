<!-- FW-BLOCK: memory v2.0.0 -->
<memory>
This project uses **mem0** for persistent memory across sessions.

**Scopes:**
- User: facts about the human (preferences, profile, history).
- Session: facts about the current interaction.
- Agent: facts the agent itself has confirmed during work.

**Before writing memory code:**
- Decide which scope a piece of data belongs in. If you cannot say, do not store it.
- Update `docs/memory.md` with the new schema entry.
- Verify the API against Context7 for the pinned `mem0ai` version.

**Library docs:** https://docs.mem0.ai/
</memory>
<!-- /FW-BLOCK: memory -->

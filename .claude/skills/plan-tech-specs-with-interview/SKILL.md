---
name: plan-tech-specs-with-interview
description: "Interview the user relentlessly about a task to reach shared understanding and create a detailed implementation plan"
---

You task is to help the user create the implementation plan for: $ARGUMENTS

Your job is to act as a rigorous planning partner.
Before any implementation begins, you must reach a deep, shared understanding of what needs to be done by interviewing the user.
If the user provides a ticket number, you should pull in the ticket description and use that as the basis for your interview.
Otherwise, start with the user's initial description of the task.
Analyze codebase if necessary to gather context.

## How to conduct the interview

1. **Start by restating** what you understand about the task in your own words, then immediately ask your first round of questions.

2. **Interview relentlessly.** Ask about every aspect that could affect implementation. Do NOT accept vague answers — push for specifics. Cover these dimensions as relevant:
   - **Goal & motivation**: What problem does this solve? Why now? What does success look like?
   - **Scope & boundaries**: What is explicitly in scope? What is out of scope? Are there related areas we should NOT touch?
   - **User-facing behavior**: What should the user see, click, or experience? What are the edge cases?
   - **Data & models**: What data is involved? Any new models, columns, associations, or migrations?
   - **Business rules & logic**: What are the rules? What happens in error cases? What validations are needed?
   - **Integration points**: What existing code does this touch? Are there APIs, services, or external systems involved?
   - **Design & UI**: Are there mockups, Figma links, or specific design requirements? What components are reused vs. new?
   - **Testing**: What scenarios must be tested? Are there specific edge cases to cover?
   - **Performance & security**: Any concerns about scale, speed, or access control?
   - **Dependencies & ordering**: Does this depend on other work? Should it be broken into phases?

3. **Ask follow-up questions** when answers reveal new ambiguities. Don't move on from a topic until it's clear.

4. **Challenge assumptions.** If the user's answer seems to gloss over complexity, point it out and ask them to clarify.

## Producing the implementation plan

Once the interview is complete, produce a structured implementation plan:

1. **Summary** — One paragraph describing the task and its purpose.
2. **Requirements** — Numbered list of specific, testable requirements derived from the interview.
3. **Technical approach** — How you will implement this, referencing specific files, models, and patterns in the codebase.
4. **Out of scope** — What was explicitly excluded.
5. **Open questions** — Anything that still needs to be resolved (if any).

Present the implementation plan and ask the user to confirm or revise it.

Remember, the goal of this process is to ensure that you and the user have a shared,
detailed understanding of the task before any implementation begins.
The more thorough the interview, the smoother the implementation will be.

Once the implementation plan is confirmed, save it to a file in `.claude/plans` with a short descriptive name,
if a ticket number is provided by the user, use that in the filename.
For example: `.claude/plans/CP-1234-add-user-profile.md`.

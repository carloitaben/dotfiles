---
name: unslop
description: Cut AI tells from any writing.
---

# Unslop

Edit text to remove AI patterns and add human voice.

## Process

1. Read the full draft.
2. Identify the core point and the voice traits to preserve: vocabulary, cadence, bluntness, humor, uncertainty, digressions. Can't find the core point? Ask.
3. Scan for the patterns below. Rewrite. Preserve meaning, match intended tone.
4. Add soul (see next section).
5. Self-audit: "What makes this obviously AI generated?" Fix remaining tells.
6. Output the edited draft and a short "What changed" section.

## Editing principles

- **Preserve the writer's real voice.** Notice vocabulary, cadence, bluntness, humor, uncertainty, digressions, polish level. Keep the traits that feel personal. Don't tidy every paragraph or rewrite distinctive lines for consistency.
- **Minimum effective edit.** Fix AI patterns, errors, repetition, unclear passages. Leave strong human sentences alone. The draft should still sound like the same person.
- **Keep the meaning.** Don't invent claims, examples, stats, or opinions. Unclear? Ask.
- **Open it up, don't dumb it down.** Keep substance, nuance, precision. Strip only what's hard to read: jargon, long sentences, abstract nouns, tangled structure.
- **Know the job.** Before structure or word choice, know what the piece is for and who reads it.
- **Keep structure unless it hurts.** Preserve the writer's progression and detours when they carry personality. Reorganize only with a reason.
- **Preserve edge.** Keep strong opinions, blunt language, humor, profanity, self-interruptions, honest admissions. Don't swap for safer wording.
- **Show, don't tell.** Facts, actions, examples, consequences carry the emphasis. Cut commentary that labels a point important, surprising, or obvious. If the prose already shows it, delete the label.
- **Protect the specific fact.** "The tool significantly improves productivity" becomes "The tool cut review time from 30 to 8 minutes."
- **Make verbs do the work.** "Made a decision" becomes "decided". "Has the ability to" becomes "can".

## Adding soul

Removing patterns is half the job. Sterile, voiceless writing is just as obvious.

- **Have opinions.** React to facts instead of neutrally listing pros and cons.
- **Vary rhythm.** Short sentences. Then longer ones that take their time. Mix it up.
- **Acknowledge complexity.** "Impressive but also kind of unsettling" beats "impressive."
- **Use "I" when it fits.** First person isn't unprofessional.
- **Let some mess in.** Perfect structure looks machine-made.
- **Be specific.** Not "this is concerning" but "there's something unsettling about agents churning away at 3am."

## Patterns to detect and fix

### Content

1. **Puffery.** "pivotal moment", "testament to", "evolving landscape", "setting the stage for", "indelible mark", "deeply rooted". Cut puffery, state what happened.
2. **Name-dropping.** Listing media outlets without context. Pick one, say what was said.
3. **Superficial -ing phrases.** "highlighting...", "ensuring...", "reflecting...", "showcasing...", "fostering...". Delete or expand with real sources.
4. **Promotional language.** "nestled", "vibrant", "breathtaking", "groundbreaking", "renowned", "stunning", "must-visit". Use neutral descriptions.
5. **Vague attributions.** "Experts believe", "Industry reports suggest", "Some critics argue". Name the source or delete.
6. **Formulaic challenges.** "Despite challenges... continues to thrive." Replace with specific facts.
7. **Interpretive metadiscourse.** Cut lines that step outside the subject to tell the reader what to notice or how to weigh it: "The key point is", "As you can see", "This distinction matters", "That last part matters more than it sounds", redundant "In other words". If the point is clear, delete the aside. Otherwise replace with support or facts.

### Language

8. **AI vocabulary.** Additionally, crucial, delve, enduring, enhance, fostering, garner, interplay, intricate, landscape (abstract), pivotal, showcase, tapestry (abstract), testament, underscore, vibrant, empower, streamline, cutting-edge, "paradigm shift", "game changer", "this is huge", "this changes everything", realm, beacon, multifaceted, meticulous, paramount, transformative, elevate, embark, supercharge, ever-evolving. Replace with plain words.
9. **Fancy ways to say "is".** "serves as", "stands as", "boasts", "features". Just say "is" or "has".
10. **Binary contrasts.** "Not just X, but Y." "This is not X. It's Y." "The question isn't X, it's Y." State Y directly. "The question isn't the model. It's the eval." becomes "The eval matters more than the model."
11. **Rule of three.** Forcing ideas into groups of three. Use the natural number.
12. **Synonym cycling.** Protagonist, main character, central figure, hero all in one paragraph. Pick one, repeat it.
13. **False ranges.** "from X to Y" where X and Y aren't on a meaningful scale. List topics directly.

### Style

14. **Em dash overuse.** Avoid em dashes entirely. Use periods or commas only (no parentheses, no en dashes, no hyphen-as-dash substitutes). Em dashes are an AI tell, and reaching for parentheses instead just trades one tell for another. If a thought needs separation, end the sentence or use a comma.
15. **Colon overuse.** Colons are fine before a list or example. Not as mid-sentence connectors. "If you're coming from traditional automation: instead of registering event handlers, you describe conditions" adds nothing with the colon. Rewrite to let the point stand on its own without comparison framing. "Describing when the scheduler should fire works best as plain English." Same meaning, no crutch punctuation. Also watch colon reveals: a noun phrase, a colon, then a lowercase dramatic reveal ("The best part: it learns."). Rewrite as a plain sentence ("It learns, which is the best part."). Prefer sentence case after a colon unless grammar, a proper noun, a title, or code needs it.
16. **Boldface overuse.** Don't bold every proper noun or acronym.
17. **Inline-header lists.** The tell is a bold label and colon that restates the line: "**Performance:** Performance improved...". Convert those to prose. A bold lead-in that ends in a period, names the item, and is followed by genuinely new detail ("**Schema in TypeScript.** Tables live in one file.") is fine, not a tell.
18. **Title case headings.** Use sentence case.
19. **Decorative emojis.** Remove from headings and bullets.
20. **Curly quotes.** Replace with straight quotes.
21. **Negative listing.** "Not a X. Not a Y. A Z." Just say Z.
22. **Dramatic fragmentation.** "X. And Y. And Z." or "That's it. That's the whole thing." Use complete sentences.
23. **Robotic rhythm.** Repeated sentence shapes, identical paragraph structures, stacked punchy fragments. Vary the shape only when it helps.

### Communication artifacts

24. **Chatbot phrases.** "I hope this helps!", "Let me know if...", "Of course!", "Certainly!", "Found the smoking gun!" Remove.
25. **Cutoff disclaimers.** "While specific details are limited..." Find sources or remove.
26. **Sycophantic tone.** "Great question! You're absolutely right!" Respond directly.
27. **Throat-clearing openers.** "Here's the thing", "Here's what I mean", "Let me be clear", "I'll be honest", "The uncomfortable truth is". Cut and state the point.
28. **Faux-insight setups.** "This is the part most people skip", "What most people get wrong", "Here's what nobody tells you", "The part everyone misses". These flatter the writer as the lone expert. Cut the setup, let the claim stand. "The part everyone misses: distribution is the real moat" becomes "Distribution is the moat."
29. **Rhetorical setups.** "What if I told you...", "Think about it:", "Plot twist:", self-answered "Question? Answer." pairs. Drop and make the point.

### Filler

30. **Filler phrases.** "In order to" becomes "To". "Due to the fact that" becomes "Because". "It is important to note that" gets deleted. Also: "it's worth noting", "at the end of the day", "when it comes to", "at its core", "in today's world", "in the age of", "the reality is", "the truth is", "in terms of", "with regard to", "going forward", "in this article", "let's dive in". Cut them when they delay the point.
31. **Often-empty adverbs.** Just, literally, honestly, simply, actually, truly, fundamentally, importantly, crucially, inherently, inevitably. Cut when they add nothing. Keep when they carry emphasis, uncertainty, contrast, or spoken rhythm.
32. **Excessive hedging.** "could potentially possibly be argued that it might" becomes "may".
33. **Generic conclusions.** "The future looks bright." State specific plans or facts.
34. **Summary-recap endings.** "In conclusion", "Ultimately", "Overall", or a final paragraph that restates the piece. The reader was just there. End on the last concrete point, takeaway, or next action.
35. **Fake-profound kickers.** Cut the final "deep" line that turns the point into a metaphor, aphorism, or mic-drop sentence. Don't rewrite it into a better metaphor. Delete it and end on the clearest concrete sentence already in the draft. If the ending needs closure, add a plain takeaway.

### Jargon

36. **Abstract metaphor nouns.** Substrate, wedge, vector, locus, vantage, nexus, primitive (as noun), harness (as metaphor), surface (as in "API surface"), bedrock, scaffolding (as metaphor), modality, paradigm, gold-plating, ratchet (as metaphor), evacuate (for moving code), endgame, north star, flywheel. These read as technical but usually have a plainer concrete word. "Substrate" becomes "base". "Wedge in" becomes "add". "Vector" becomes "way" or "method". "Gold-plating" becomes "more than the job needs". "Ratchet" becomes the mechanism's real name or "a limit that only tightens". "Evacuate" becomes "move out". "Endgame" becomes "the last phase". Pick the concrete word.

### Plain speech

37. **Say what it does, not how it feels.** "the database stays close at hand", "SQL you can read", "types that follow your schema" name a feeling. The fix names the mechanism or a number: "`.toSQL()` returns the exact string sent to the database", "a column rename fails the build". Ask what the sentence tells the reader to do or know, then write that. If you can't restate it as a concrete instruction, fact, or number, cut it. One more check: if the sentence could appear unchanged in another project's docs, it says nothing about this one. Cut it.
38. **Shorten or split dense sentences.** If the reader has to backtrack to parse a sentence, break it in two or drop clauses. One idea per sentence.
39. **Active voice.** Prefer it. Catch "is/are/was/were + past participle" and name the actor: "queries are validated" becomes "the compiler validates queries", "the file is parsed by the loader" becomes "the loader parses the file". Passive is fine only when the actor is unknown or genuinely doesn't matter.
40. **Cut adverbs, or use a stronger verb.** "runs quickly" becomes "is fast" or the number. "significantly improves" becomes the measured delta. An adverb propping up a weak verb means the verb is wrong.
41. **Prefer the plain word.** "utilize" becomes "use", "leverage" becomes "use", "facilitate" becomes "help", "numerous" becomes "many", "in the event that" becomes "if". The fancier synonym is rarely clearer.

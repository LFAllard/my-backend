# Visa filstruktur
tree -L 3 -I "node_modules|.git|api-python"

# Kör squawk med lint.sh
./lint.sh

# Claude usage
 to continue an extension conversation in the CLI, run claude --resume in the terminal.

 "Do not make any changes yet. First, show me exactly what you plan to change and why. Wait for my approval before touching any files."

 For your current Squawk task specifically, a good prompt would be:

"Do not make any changes yet. Read ./lint.sh, run it, then show me exactly which definition files you would edit, what the before and after would look like for each change, and why. Wait for my approval before touching anything."

# personas

Persona name lists (my proposal)
25 per group, A–Y, skipping Z. For Q, X, Y I use reasonable substitutes — they'll never appear in real usage, they just need to exist.

Swedish males (@svensson.se):
Adam, Bertil, Clas, David, Erik, Fredrik, Gustav, Hans, Ivar, Johan, Karl, Lars, Magnus, Nils, Oskar, Per, Quirin, Ragnar, Sven, Thomas, Ulf, Viktor, Wilhelm, Xaver, Yngve

Swedish females (@svensson.se):
Alice, Britta, Cecilia, Dagmar, Elsa, Frida, Gunilla, Helga, Ingrid, Johanna, Karin, Lena, Maria, Nina, Olivia, Petra, Quirina, Ragnhild, Sofia, Therese, Ulla, Vera, Wilma, Xenia, Yvonne

Irish males (@joyce.ie):
Aidan, Brendan, Conor, Declan, Eoin, Fergus, Gavin, Hugh, Ian, Jack, Kevin, Liam, Michael, Niall, Owen, Patrick, Quinn, Ronan, Sean, Thomas, Ultan, Vincent, William, Xander, Yusuf

Irish females (@joyce.ie):
Aoife, Brigid, Ciara, Deirdre, Eileen, Fionnuala, Grace, Hannah, Iona, Jennifer, Kate, Lily, Maeve, Niamh, Orla, Patricia, Queenie, Roisin, Siobhan, Tara, Una, Vivienne, Winifred, Xanthe, Yvonne

Role assignment: Adam (user 1) = super_admin. All 99 others = user.

# återställa databas

python database/seeds/dev/generate_personas.py
supabase db reset --linked

# kevinstravert youtube tutorial

Analyze this codebase and create a CLAUDE.md file following these principles:

1. Keep it under 150 lines total - focus only on universally applicable information
2. Cover the essentials: WHAT (tech stack, project structure), WHY (purpose), and HOW (build/test commands)
3. Use Progressive Disclosure: instead of including all instructions, create a brief index pointing to other markdown files in .claude/docs/ for specialized topics
4. Include file:line references instead of code snippets
5. Assume I'll use linters for code style - don't include formatting guidelines

Structure it as: project overview, tech stack, key directories/their purposes, essential build/test commands, and a list of additional documentation files Claude should check when relevant.

Additionally, extract patterns you observe into separate files:
- .claude/docs/architectural_patterns.md - document the architectural patterns, design decisions, and conventions used (e.g., dependency injection, state management, API design patterns). Make sure these are patterns that appear in multiple files.

Reference these files in the CLAUDE.md's "Additional Documentation" section.

# Future CLAUDE.md advice

One thing I left out of CLAUDE.md intentionally: the Base URL. The one there was my-app-2 (the wrong project). Once you deploy my-backend to Render you can add the correct one

# Tankar om nästa prompt

- migrera från php till python
- obs ej färdigt OTP usage ej fungerat när övergavs
- bygga endpoints (LISTA MED BESKRIVNING AV ÖNSKAD FUNKTIONALITET?)
- instruktion om att testa, ev lite hur testa
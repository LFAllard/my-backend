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
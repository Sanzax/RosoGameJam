local nodeHandling = {}

-- Dependencies
local screen = require( "scripts.screen" )
local weaver = require( "scripts.spyricStoryWeaver" )
local ui = require( "scripts.ui" )

-- Koska nodeIndex, node, characters ja background muuttujat ovat scene:create
-- funktion sisällä, niin niihin ei pääse käsiksi tämä funktion ulkopuolelta.
local nodeIndex, node

nodeHandling.canPress = false

local sceneGroup

function nodeHandling.setSceneGroup(newSceneGroup)
	sceneGroup = newSceneGroup
end

-- Pelaaja painaa linkkiä ja siirtyy seuraavaan nodeen.
local function touchLink( event )
	if event.phase == "began" and nodeHandling.canPress then
		nodeHandling.canPress = false

		nodeHandling:getNode( event.target.id )
	end

	return true
end

local function commandImageOrDel(command, i)
	-- Poistetaan vanha taustakuva.
	ui.deleteBackground()

	if command == "img" then
		-- Luodaan uusi taustakuva.
		ui.newBackGround( sceneGroup, node[i][2])
	end
end

local function commandCharacter(i)
	-- Mellä on jo yläpuolella julistettu characters-taulukko.
	-- Voimme siis lisätä hahmot sinne niiden omalla nimellä.
	local name = node[i][3]

	-- Tarkistetaan ollaanko hahmoa luomassa vai tuhoamassa.
	if  node[i][2] == "hide" then
		ui.deleteCharacter(name)

	else
		ui.newCharacter(sceneGroup, name, node[i])
	end

end

local function commandTextOrLink(command, i)
	-- Luodaan ensimmäinen teksti aina samaan paikkaan, mutta
	-- lisätään muut tekstit relatiivisesti edeltävään tekstiin.
	local x, y = screen.centerX, screen.centerY + 190

	-- Poistetaan vanhat tekstit tai linkit vain jos
	-- olemme luomassa uutta tekstiä. Jos luommekin
	-- uutta linkkiä, niin jätetään tekstit sikseen.
	if command == "text" then
		ui.deleteTextsAndLinks()
	else
		-- Luomme linkkiä ja sitä ennen on luotu
		-- ainakin yksi teksti-objektit.
		if ui.getTextAmount() > 0 then
			y = ui.getLastText().y + ui.getLastText().height + 16
		end

	end

	ui.createTextOrLink(command, sceneGroup, node[i], x, y, touchLink)

	-- Jos taulukko jatkuu ja seuraava luotava asia
	-- ei ole linkki, niin katkaistaan loop.
	if node[i+1] and node[i+1][1] ~= "link" then
		return true
	end

	return false
end


function nodeHandling:getContent()
	-- Varmistetaan, että indeksi on olemassa, ettei peli kaadu.
	if nodeIndex > #node then
		return
	end

	-- Aloitetaan siitä indeksistä mihin jäätiin ja jatketaan kunnes
	-- indeksit loppuvat, tai kunnes vastaan tulee "text" komento,
	-- ellei sitä seuraava komento ole "link".
	for i = nodeIndex, #node do
		print( i, table.concat( node[i], ", " ) )
		-- Korotetaan indeksiä joka loopilla, jotta emme suorita
		-- samoja käskyjä uudestaan koodissamme myöhemmin.
		nodeIndex = nodeIndex + 1

		-- Komento on aina node-taulukon alataulukon 1. arvo.
		local command = node[i][1]
		if command == "img" or command == "del" then
			commandImageOrDel(command, i)
		elseif command == "character" then
			commandCharacter(i)
		elseif command == "text" or command == "link" then
			if commandTextOrLink(command, i) then
				break
			end
		end
	end
end

-- Ladataan uusi node ja nollataan nodeIndex laskuri.
function nodeHandling:getNode( nodeName )
	-- Poistetaan kaikki tekstit ja hahmot kun
	-- node vaihtuu.
	ui.deleteTextsAndLinks()

	ui.deleteCharacters()

	node = weaver.getNode( nodeName, _G.story )
	nodeIndex = 1

	self:getContent()

	nodeHandling.canPress = true
end

return nodeHandling
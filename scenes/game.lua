-- Ladataan Composer, jotta voimme kutsua sen sisältämiä funktioita.
local composer = require( "composer" )
local weaver = require( "scripts.spyricStoryWeaver" )
local screen = require( "scripts.screen" )
local ui = require( "scripts.ui" )
local nodeHandling = require("scripts.nodeHandling")

-- Luodaan uusi scene muuttuja (eli erityinen Lua taulukko).
local scene = composer.newScene()

--------------------------------------------------------------------------------------
-- Täällä, alapuolella olevien scene event funktioiden yläpuolella oleva koodi
-- suoritetaan vain kerran ellei tätä sceneä tuhota kokonaan (ei kierrätetty)
-- composer.removeScene() funktion avulla.

-- Sinun kannattaa siis määrittää tai julistaa muuttujasi täällä, jolloin ne
-- ovat aina näkyvissä kaikkien scene funktioiden sisällä.
--------------------------------------------------------------------------------------

local sfxClick = audio.loadSound( "assets/sfx/click.wav" )


print(screen.maxX, screen.maxY)

--------------------------------------------------------------------------------------
-- Scene event funktiot:
--------------------------------------------------------------------------------------

-- create-funktio kutsutaan kun scene näkymä luodaan ensimmäistä kertaa,
-- tai jos se on tuhottu sen jälkeen kun scene luotiin viimeksi.
function scene:create( event )
	local sceneGroup = self.view

	-- Täällä oleva koodi ajetaan kun scene on luotu,
	-- mutta sitä ei ole vielä näytetty peliruudulla.

	-- outputTable( event )

	-- Luodaan "tarina muuttuja", joka sisältää tarinan lataamisessa
	-- ja sen myöhemmässä käytössä olevia tietoja.
	_G.story = {
		name = "story",
		source = "data/story.json",
		-- savefile = "RosoNoirSave.json",
		-- autosave = true,
	}
	-- Ladataan haluttu tarina Weaverillä.
	_G.story.storyData, _G.story.saveData = weaver.initStory( _G.story )

	-- Luodaan sensori jota klikkaamalla pääsee seuraavaan tekstiin
	ui.createSensor(sceneGroup, function(event)
		if event.phase == "began" and nodeHandling.canPress then
			audio.play( sfxClick )
			print(nodeHandling.nextNodeId)
			if nodeHandling.nextNodeId == nil then
				nodeHandling:getContent()
			else
				nodeHandling:getNode( nodeHandling.nextNodeId)
			end
		end
	end)

	ui.createTextBox(sceneGroup)

	nodeHandling.setSceneGroup(sceneGroup)
	-- Ladataan pelin ensimmäinen node.
	nodeHandling:getNode( "Alku" )

	ui.createBackButton(sceneGroup)
end


-- show-funktio kutsutaan kun scene näkymä on jo luotu,
-- mutta sitä ei ole vielä näytetty pelaajalle.
function scene:show( event )
	--local sceneGroup = self.view
	local phase = event.phase

	-- outputTable( event )

	if ( phase == "did" ) then
		-- Täällä oleva koodi ajetaan kun scene näkymää aletaan
		-- näyttämään, mutta se on vielä piilossa (näkymätön).
		nodeHandling.canPress = true
	--elseif ( phase == "will" ) then
		-- Täällä oleva koodi ajetaan heti kun scene on täysin näkyvissä.
	end
end


-- hide-funktio kutsutaan kun scene näkymä, joka näkyy pelaajalle,
-- halutaan piilottaa pelaajalta, eli tehdä se näkymättömäksi.
function scene:hide( event )
	--local sceneGroup = self.view
	local phase = event.phase

	-- outputTable( event )

	if ( phase == "will" ) then
		-- Täällä oleva koodi ajetaan kun scene näkymää aletaan
		-- piilottamaan, mutta se on vielä täysin näkyvissä.

		nodeHandling.canPress = false

	--elseif ( phase == "did" ) then
		-- Täällä oleva koodi ajetaan heti kun scene on täysin piilossa.
	end
end


-- destroy-funktio kutsutaan kun scene näkymä halutaan tuhota, eli silloin kun
-- kaikki scenen sisältämät display groupit, objektit, yms. halutaan poistaa.
function scene:destroy( event )
	--local sceneGroup = self.view
	-- Täällä oleva koodi suoritetaan juuri ennen kuin
	-- scene näkymän tuhoaminen alkaa.

	-- outputTable( event )

end


--------------------------------------------------------------------------------------
-- Scene event kuuntelijafunktiot:
--------------------------------------------------------------------------------------
-- Voit vapaasti päättää mitä scene tapahtumia haluat kuunnella. Voi esimerkiksi olla,
-- ettet tule koskaan poistamaan jotain sceneä, vaan pidät sen aina ladattuna. Tällöin
-- sinun ei esimerkiksi tarvitse käyttää "destroy" event kuuntelijaa.
--------------------------------------------------------------------------------------
scene:addEventListener( "create", scene )
scene:addEventListener( "show", scene )
scene:addEventListener( "hide", scene )
scene:addEventListener( "destroy", scene )
--------------------------------------------------------------------------------------

-- Huomaa, että tiedoston lopussa on taas tuttu "return scene", jossa scene on
-- tiedoston yläosassa luotu (taulukko) muuttuja. Palauttamalla scenen, tästä
-- scene tiedostosta tulee aivan tavallinen Lua moduuli.
return scene
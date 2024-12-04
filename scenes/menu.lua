-- Ladataan Composer, jotta voimme kutsua sen sisältämiä funktioita.
local composer = require( "composer" )
local screen = require( "scripts.screen" )
local ui = require( "scripts.ui" )

-- Luodaan uusi scene muuttuja (eli erityinen Lua taulukko).
local scene = composer.newScene()

--------------------------------------------------------------------------------------
-- Täällä, alapuolella olevien scene event funktioiden yläpuolella oleva koodi
-- suoritetaan vain kerran ellei tätä sceneä tuhota kokonaan (ei kierrätetty)
-- composer.removeScene() funktion avulla.

-- Sinun kannattaa siis määrittää tai julistaa muuttujasi täällä, jolloin ne
-- ovat aina näkyvissä kaikkien scene funktioiden sisällä.
--------------------------------------------------------------------------------------

local canPress = false

local backgroundFile = "assets/images/levels/forest01.png"



local function menuEvent( event )
	if event.phase == "began" and canPress then
		local id = event.target.id

		if id == "start" then
			composer.gotoScene( "scenes.game", {
				time = 500,
				effect = "fade",
			} )

		elseif id == "quit" then
			native.requestExit()

		end
	end
end

-- Tulostetaan taulukon ylimmät avaimet ja niiden arvot,
-- eli (k)ey ja (v)alue pairs looppaus.
local function outputTable( t )
	-- Lisätään tyhjä rivi eri taulukoiden väliin.
	print( "" )
	for k, v in pairs( t ) do
		print( k, v )
	end
end

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

	local background = display.newImage( sceneGroup, backgroundFile, screen.centerX, screen.centerY)
	background.width = screen.width
	background.height = screen.height

	local title = ui.newTitle({
		parent = sceneGroup,
		text = "Metsä peli",
		x = screen.centerX,
		y = screen.centerY - 60,
		font = "assets/fonts/Roboto/Roboto-Bold.ttf",
		fontSize = 64,
		align = "center"
	})

	local buttonStart = ui.newTitle({
		parent = sceneGroup,
		text = "Start",
		x = screen.centerX,
		y = screen.centerY + 70,
		font = "assets/fonts/Roboto/Roboto-Bold.ttf",
		fontSize = 40,
		align = "center"
	})
	buttonStart.id = "start"
	buttonStart:addEventListener( "touch", menuEvent )

	local buttonQuit = ui.newTitle({
		parent = sceneGroup,
		text = "Quit",
		x = screen.centerX,
		y = screen.centerY + 140,
		font = "assets/fonts/Roboto/Roboto-Bold.ttf",
		fontSize = 40,
		align = "center"
	})
	buttonQuit.id = "quit"
	buttonStart:addEventListener( "touch", buttonQuit )

end


-- show-funktio kutsutaan kun scene näkymä on jo luotu,
-- mutta sitä ei ole vielä näytetty pelaajalle.
function scene:show( event )
	local sceneGroup = self.view
	local phase = event.phase

	-- outputTable( event )

	if ( phase == "will" ) then
		-- Täällä oleva koodi ajetaan kun scene näkymää aletaan
		-- näyttämään, mutta se on vielä piilossa (näkymätön).

	elseif ( phase == "did" ) then
		-- Täällä oleva koodi ajetaan heti kun scene on täysin näkyvissä.
		canPress = true

		local buttonAudio = ui.newAudioButton()

		composer.removeScene( "scenes.game" )

	end
end


-- hide-funktio kutsutaan kun scene näkymä, joka näkyy pelaajalle,
-- halutaan piilottaa pelaajalta, eli tehdä se näkymättömäksi.
function scene:hide( event )
	local sceneGroup = self.view
	local phase = event.phase

	-- outputTable( event )

	if ( phase == "will" ) then
		-- Täällä oleva koodi ajetaan kun scene näkymää aletaan
		-- piilottamaan, mutta se on vielä täysin näkyvissä.
		canPress = false

	elseif ( phase == "did" ) then
		-- Täällä oleva koodi ajetaan heti kun scene on täysin piilossa.

	end
end


-- destroy-funktio kutsutaan kun scene näkymä halutaan tuhota, eli silloin kun
-- kaikki scenen sisältämät display groupit, objektit, yms. halutaan poistaa.
function scene:destroy( event )
	local sceneGroup = self.view
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
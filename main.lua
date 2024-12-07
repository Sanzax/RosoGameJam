display.setStatusBar( display.HiddenStatusBar )


native.setProperty("windowMode", "fullscreen")



-- Luomme yhden globaalin muuttujan, niin sen löytää aina
-- kaikkialta. Tämän niminen muuttuja ei myöskään vahingossa
-- sekoitu muihin muuttujiin.
_G.developerMode = true

-- Composer on sisäänrakennettu Solar2D:hen, eli sen voi
-- voi kutsua ilman tarkempaa tiedostopolun määrittämistä
local composer = require( "composer" )


-- Viedään peli scenes/menu.lua sceneen.

-- (Koska scene on Lua moduuli, niin sen kanssa tulee käyttää
-- pisteitä "/" ja "\" merkkien sijaan, eikä sen kanssa tule
-- määrittää tiedostotyyppiä, .lua, sillä se on oletus.)
composer.gotoScene( "scenes.menu", {
	time = 500,
	effect = "fade",
} )


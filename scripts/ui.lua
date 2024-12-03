local ui = {}

local screen = require( "scripts.screen" )

local audioButtonCreated = false

local background = nil
local characters = {}
local textList = {}

-- Luodaan uusi audio-nappi.
function ui.newAudioButton()
	-- Estetään, ettei funktiota voi ajaa kuin kerran.
	if audioButtonCreated then
		return
	end
	audioButtonCreated = true


	local fillOn = {
		type = "image",
		filename = "assets/images/other/music_on.png"
	}

	local fillOff = {
		type = "image",
		filename = "assets/images/other/music_off.png"
	}


	local button =  display.newRect( screen.maxX - 32, screen.minY + 32, 64, 64 )
	button.fill = fillOn
	-- Äänet ovat alkuun aina oletuksena päällä.
	button.isActive = true

	-- Ladataan taustamusiikki (background music, bgm) streaminä, eli sitä mukaa
	-- kun kappale soi. Tämä vähentää sen käyttämää muistia.
	local bgm = audio.loadStream( "assets/music/Man Down.mp3" )

	-- Lasketaan pelin master-volume 50%:iin oletuksena, koska emme tiedä
	-- minkälaisilla asetuksilla pelaaja saattaa pelata ja emme halua
	-- räjäyttää tämän tärykalvoja.

	local masterVolume = _G.developerMode and 0 or 0.5

	audio.setVolume( masterVolume )

	-- Meidän taustamusiikki on paljon kovempiääninen kuin pelin "click"-ääniefekti.
	-- Hiljennetään siis erikseen taustamusiikin äänikanavaa myös 50%:illa.
	audio.setVolume( 0.5, { channel=1 } )

	-- Huom! Jos kanavaa ei ole määritetty setVolume käskyssä, niin se koskee kaikkia
	-- kanavia. Muuten sillä voi hallita yksittäisi kanavia. Koska meidän master volume
	-- on 50% ja kanavan #1 volume on 50%, kanava #1 soi 50% x 50%, eli 25% teholla.
	audio.play( bgm,{
		channel = 1, -- Määritetään erikseen taustamusiikin kanava.
		loops = -1, -- Laitetaan kappale soimaan ikuisesti.
		fadein = 3000, -- Nostetaan äänet 3s kuluessa nollasta halutulle tasolle.
		-- onComplete = callbackListener
	})

	-- Koska luomme touch event kuuntelijafunktion vain yhtä nappia varten,
	-- niin voimme luoda sen tällä kertaa myös anonyymisenä funktiona.
	button:addEventListener( "touch", function( event )
		if event.phase == "began" then
			local target = event.target

			-- Hyödynnetään Pokerin kanssa opittua "not" operaattori
			-- temppua, eli käännetään muuttujan arvo ympäri.
			target.isActive = not target.isActive

			-- Äänet olivat pois, mutta ovat taas päällä.
			if target.isActive then
				audio.setVolume( masterVolume )
				-- Jatketaan kanavan #1 soittoa.
				audio.resume( 1 )
				button.fill = fillOn

			-- Äänet olivat päällä, mutta ovat taas pois.
			else
				audio.setVolume( 0 )
				-- Pausetetaan kanava #1.
				audio.pause( 1 )
				button.fill = fillOff

			end
		end

		return true
	end )
end

-- Luodaan uusi tekstiobjekti, jolla on varjo.
function ui.newTitle( params )
	local title = display.newGroup()
	params.parent:insert( title )

	title.text = display.newText({
		parent = title,
		text = params.text,
		x = params.x,
		y = params.y,
		font = params.font,
		fontSize = params.fontSize,
		align = params.align
	})
	title.text:setFillColor( 248/255, 240/255, 219/255 )

	title.shadow = display.newText({
		parent = title,
		text = params.text,
		x = params.x + 3,
		y = params.y + 3,
		font = params.font,
		fontSize = params.fontSize,
		align = params.align
	})
	title.shadow:setFillColor( 0.05 )
	title.shadow:toBack()

	return title
end

function ui.createSensor(sceneGroup, onTouch)
	-- Luodaan näkymätön sensori, jota pelaaja voi koskettaa edetäkseen pelissä.
	local touchSensor = display.newRect( sceneGroup, screen.centerX, screen.centerY, screen.width, screen.height )
	touchSensor:addEventListener( "touch", onTouch )
	touchSensor.isVisible = false
	-- Tehdään sensorista erikseen kosketettava vaikka se on näkymätön.
	touchSensor.isHitTestable = true
end


-- Hahmo funktiot


function ui.deleteCharacter(name)
	display.remove(  characters[name] )
	characters[name] = nil
end

function ui.deleteCharacters()
	-- Alaviiva, _, kertoo, ettemme käytä pairs
	-- loopissaavain-arvo-parin arvoa mihinkään.
	for name, _ in pairs( characters ) do
	ui.deleteCharacter(name)
	end
end

function ui.newCharacter(sceneGroup, name, params)
	-- Jos hahmo on jo luotu, niin älä luo sitä uudestaan.
	if characters[name] then
		return
	end

	-- Skaalataan pelin hahmoja, koska ne ovat paljon
	-- suurempia kuin esim. pelin taustakuva.
	local characterScale = 0.35

	-- Hajotetaan funktiokutsu usealle riville,
	-- jotta siitä tulee helppolukuisempi.
	characters[name] = display.newImageRect(
		sceneGroup,
		"assets/images/characters/" .. name .. ".png",
		736 * characterScale,
		1024 * characterScale
	)

	-- Käytetään ternääristä muuttujaa hahmon asettamiseen
	-- jotta hahmo asettuu aina jonnekin, eikä peli kaadu.

	-- Jos hahmon x-koordinaattia ei ole määritetty, niin
	-- laitetaan hahmo sitten keskelle ruutua.
	characters[name].x = params.x or screen.centerX

	-- Sijoitetaan hahmo sille annetun y-koordinaatin mukaan,
	-- tai sitten sijoitetaan se taustakuvan alareunaan, tai
	-- jos taustakuvaa ei ole, niin sitten keskelle ruutua.
	local yBG = background and (background.y + background.height*0.5) or nil
	characters[name].y = params.y or yBG or screen.centerY

	characters[name].anchorY = 1

	-- Ja käännetään lopuksi hahmot x-akselinsa ympäri,
	-- jos näin on toivottu.
	if params.xScale then
		characters[name].xScale = params.xScale
	end

end


-- Taustakuva funktiot


function ui.newBackGround(sceneGroup, file)
	background = display.newImage( sceneGroup, file, screen.centerX, screen.centerY - 60 )
end

function ui.deleteBackground()
	display.remove( background )
end


-- Teksti funktiot


function ui.deleteTextsAndLinks()
	for j = 1, #textList do
		display.remove( textList[j] )
		textList[j] = nil
	end
end

function ui.createTextOrLink(command, sceneGroup, node, x, y, touchLink)
	textList[#textList+1] = display.newText({
		parent = sceneGroup,
		text = node[2],
		x = x,
		y = y,
		width = screen.width - 60,
		font = "assets/fonts/Roboto/Roboto-Regular.ttf",
		fontSize = 24,
		align = "center"
	})
	textList[#textList].anchorY = 0

	if command == "link" then
		-- Lisätään linkkeihin eri väri, jotta ne erottuvat
		-- tavallisesta tekstistä.
		textList[#textList]:setFillColor( 230/255, 170/255, 25/255 )

		-- Tehdään linkeistä kosketettavia ja lisätään niihin id.
		textList[#textList]:addEventListener( "touch", touchLink )
		textList[#textList].id = node[3]
	end
end

function ui.getTextAmount()
	return #textList
end

function ui.getLastText()
	return textList[#textList]
end


return ui
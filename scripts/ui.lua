local ui = {}

local screen = require( "scripts.screen" )
local composer = require( "composer" )
local audioButtonCreated = false

local background = nil
local characters = {}

local textBox

local fontFilename = "assets/fonts/Roboto/Roboto-Regular.ttf"
local boldFontFilename = "assets/fonts/Roboto/Roboto-Bold.ttf"
local italicFontFilename = "assets/fonts/Roboto/Roboto-Italic.ttf"

local choices = {}
local choiceGroup

local choiceButtonWidth = screen.width/12
local choiceButtonHeight = choiceButtonWidth/2
local choiceButtonPacing = screen.width*0.008
local choiceButtonY = screen.height * 0.025

-- TextBox data
local textBoxWidth = screen.width/2
local textBoxHeight = screen.height/7.5
local nameAreaWidth = textBoxWidth/6
local nameAreaHeight = nameAreaWidth/4
local nameAreaX = -textBoxWidth/2 + nameAreaWidth/2 + textBoxWidth*0.05
local nameAreaY = -textBoxHeight/2 - nameAreaHeight/2

local textBoxTextSize = 25
local buttonTextSize = 25
local nameTextSize = 25

local backButton

function ui.createBackButton(sceneGroup)
	-- Luodaan nappi, millä pelaaja voi palata menu sceneen.
	backButton = ui.newTitle({
		parent = sceneGroup,
		text = "Back",
		x = screen.minX + 44,
		y = screen.minY + 22,
		font = "assets/fonts/Roboto/Roboto-Bold.ttf",
		fontSize = 32,
		align = "left"
	})

	backButton:addEventListener( "touch", function( event )
		if event.phase == "began" then
			composer.gotoScene( "scenes.menu", {
				time = 500,
				effect = "fade",
			} )
		end

		return true
	end )
end

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
	local bgm = audio.loadStream( "assets/music/musiikki.mp3" )

	-- Lasketaan pelin master-volume 50%:iin oletuksena, koska emme tiedä
	-- minkälaisilla asetuksilla pelaaja saattaa pelata ja emme halua
	-- räjäyttää tämän tärykalvoja.

	local masterVolume = _G.developerMode and 0 or 0.1

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

local function setNameAreaText(text)
	display.remove( textBox.nameArea.text )
	textBox.nameArea.text = display.newText({
		parent = textBox.nameArea,
		text = text,
		x = 0,
		y = 0,
		width = nameAreaWidth,
		font = boldFontFilename,
		fontSize = nameTextSize,
		align = "center"
	})

	textBox.nameArea.text:setFillColor(1)
end

function ui.createTextBox(sceneGroup)
	textBox = display.newGroup()
	textBox.x = screen.centerX
	textBox.y = screen.maxY - textBoxHeight/2 - screen.height* 0.02

	textBox.box = display.newImageRect(
		textBox,
		"assets/images/other/laatikkoa.png",
		textBoxWidth,
		textBoxHeight
	)
	textBox.box.alpha = 0.6

	textBox.nameArea = display.newGroup()
	textBox.nameArea.x = nameAreaX
	textBox.nameArea.y = nameAreaY
	textBox:insert(textBox.nameArea)

	textBox.nameArea.box = display.newImageRect(
		textBox.nameArea,
		"assets/images/other/nimiboxi.png",
		nameAreaWidth,
		nameAreaHeight
	)
	textBox.nameArea.box.alpha = 0.6

	sceneGroup:insert(textBox)
end

function ui.createNewButton(sceneGroup, text, x, y, width, height, touchFunc)
	local buttonGroup = display.newGroup()
	sceneGroup:insert(buttonGroup)
	buttonGroup.x = x
	buttonGroup.y = y

	buttonGroup.box = display.newImageRect(
		buttonGroup,
		"assets/images/other/nappi2.png",
		width,
		height
	)
	print(boldFontFilename)
	buttonGroup.text = display.newText({
		parent = buttonGroup,
		text = text,
		x = 0,
		y = 0,
		width = width,
		font = boldFontFilename,
		fontSize = buttonTextSize,
		align = "center",
	})
	buttonGroup.text:setFillColor(1)

	buttonGroup:addEventListener("touch", touchFunc)

	return buttonGroup
end

function ui.createNewChoiceButton(sceneGroup, node, x, y, touchLink)
	local button = ui.createNewButton(sceneGroup, node[2], x, y, choiceButtonWidth, choiceButtonHeight, touchLink)
	button.id = node[3]

	choices[#choices+1] = button
end

function ui.deleteChoices()
	display.remove( choiceGroup )
	choiceGroup = nil
	for i, _ in ipairs( choices ) do
		display.remove( choices[i] )
		choices[i] = nil
	end
end

function ui.organizeChoices(sceneGroup)
	choiceGroup = display.newGroup()
	for i, v in ipairs( choices ) do
		choiceGroup:insert(v)

		v.x = (i-1) * (choiceButtonWidth + choiceButtonPacing) - ((#choices-1) * (choiceButtonWidth + choiceButtonPacing)) / 2
		v.y = 0
	end

	choiceGroup.x = screen.centerX
	choiceGroup.y = textBox.y - textBoxHeight/2  -choiceButtonHeight/2 - choiceButtonY

	sceneGroup:insert(choiceGroup)
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
		ui.deleteCharacter(name)
	end

	-- Hajotetaan funktiokutsu usealle riville,
	-- jotta siitä tulee helppolukuisempi.

	params.scale = params.scale or 1

	characters[name] = display.newImage(
		sceneGroup,
		"assets/images/characters/" .. name .. ".png"
	)
	characters[name].width = characters[name].width * params.scale
	characters[name].height = characters[name].height * params.scale

	-- Käytetään ternääristä muuttujaa hahmon asettamiseen
	-- jotta hahmo asettuu aina jonnekin, eikä peli kaadu.

	-- Jos hahmon x-koordinaattia ei ole määritetty, niin
	-- laitetaan hahmo sitten keskelle ruutua.
	characters[name].x = screen.minX + (params.x or screen.centerX)

	-- Sijoitetaan hahmo sille annetun y-koordinaatin mukaan,
	-- tai sitten sijoitetaan se taustakuvan alareunaan, tai
	-- jos taustakuvaa ei ole, niin sitten keskelle ruutua.
	characters[name].y = params.y or screen.maxY

	characters[name].anchorY = 1

	-- Ja käännetään lopuksi hahmot x-akselinsa ympäri,
	-- jos näin on toivottu.
	if params.xScale then
		characters[name].xScale = params.xScale
	end
	textBox:toFront()
end


-- Taustakuva funktiot

function ui.removeBackGround()
	if background then
		display.remove( background )
		background = nil
	end
end

function ui.newBackGround(sceneGroup, file)
	ui.removeBackGround()
	background = display.newImage( sceneGroup, file, screen.centerX, screen.centerY)
	background.width = screen.width
	background.height = screen.height

	background:toBack()
end

function ui.deleteBackground()
	display.remove( background )
end


-- Teksti funktiot


function ui.deleteText()
	display.remove( textBox.text )
end


local function separateNameAndText(sourceText)
	local colonIndex = string.find( sourceText, ":" )
	local name
	local text = sourceText
	if colonIndex then
		name = string.sub(sourceText, 1, colonIndex-1)
		text = string.sub(sourceText, colonIndex+2, #sourceText)
	end

	return text, name
end

function ui.createTextBoxText(text)
	ui.deleteText()
	local name
	text, name = separateNameAndText(text)

	if name then
		textBox.nameArea.isVisible = true
		setNameAreaText(name)
	else
		textBox.nameArea.isVisible = false
	end


	textBox.text = display.newText({
		parent = textBox,
		text = text,
		x = 0,
		y = 0,
		width = textBoxWidth - textBoxWidth*0.05,
		font = fontFilename,
		fontSize = textBoxTextSize,
		align = "center"
	})
end

return ui
-- Ladataan Composer
local composer = require( "composer" )
local screen = require( "scripts.screen" )
local ui = require( "scripts.ui" )

-- Luodaan uusi scene
local scene = composer.newScene()

-- tähän kuva 
local backgroundFile = "assets/images/levels/forest01.png"

--------------------------------------------------------------------------------------
-- Scene event funktiot:
--------------------------------------------------------------------------------------

function scene:create( event )
    local sceneGroup = self.view

    -- Taustakuva
    local background = display.newImage( sceneGroup, backgroundFile, screen.centerX, screen.centerY )
    background.width = screen.width
    background.height = screen.height

    -- Otsikko
    local title = ui.newTitle({
        parent = sceneGroup,
        text = "Kiitos pelaamisesta!",
        x = screen.centerX,
        y = screen.centerY - 100,
        font = "assets/fonts/Roboto/Roboto-Bold.ttf",
        fontSize = 64,
        align = "center"
    })

    -- Tekijöiden nimet
    local credits = ui.newTitle({
        parent = sceneGroup,
        text = "Santeri, Juuso, Tiia, Heta",
        x = screen.centerX,
        y = screen.centerY,
        font = "assets/fonts/Roboto/Roboto-Regular.ttf",
        fontSize = 36,
        align = "center"
    })

    -- Lopetusnappi
    local  backbutton= ui.newTitle({
        parent = sceneGroup,
        text = "Takaisin päävalikkoon",
        x = screen.centerX,
        y = screen.centerY + 120,
        font = "assets/fonts/Roboto/Roboto-Bold.ttf",
        fontSize = 40,
        align = "center"
    })

    --Takaisin alkuun nappi
    backbutton.id = "back"
    backbutton:addEventListener( "touch", function(event)
        if event.phase == "began" then
            composer.gotoScene( "scenes.menu", {
                time = 500,
                effect = "fade",
            } )
        end
    end )
end

function scene:show( event )
    local sceneGroup = self.view
    local phase = event.phase

    if ( phase == "did" ) then
        -- Scene on täysin näkyvissä
    end
end

function scene:hide( event )
    local sceneGroup = self.view
    local phase = event.phase

    if ( phase == "will" ) then
        -- Scene piilotetaan
    end
end

function scene:destroy( event )
    local sceneGroup = self.view
end

-- Lisää tapahtumat
scene:addEventListener( "create", scene )
scene:addEventListener( "show", scene )
scene:addEventListener( "hide", scene )
scene:addEventListener( "destroy", scene )

return scene
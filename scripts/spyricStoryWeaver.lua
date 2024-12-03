-- This is an old pre-release version (0.9) of the Spyric Story Weaver plugin.
-- The current, version 2.0 of Story Weaver, is significantly more streamlined and
-- it features more general optimisations, as well as improved code readability.
----------------------------------------------------------------------------------

local M = {}

local errorMsgBase = "WARNING: Spyric Story Weaver - "

-- localise globals, string, table and math functions
local json = require("json")
local type = type
local print = print
local tonumber = tonumber
local tostring = tostring
local loadstring = loadstring

local sub = string.sub
local gsub = string.gsub
local gmatch = string.gmatch
local match = string.match
local find = string.find
local len = string.len

local getn = table.getn
local sort = table.sort

local floor = math.floor
local random = math.random
local min = math.min


local function validate( target, from, input, node )
	local typeInput = type(input)
	local var = false

	if target == "input" then
		if typeInput == "table" then
			var = true
		else
			local argNum = 1
			if from == "getNode" then argNum = 2 end
			print( errorMsgBase.."bad argument #"..argNum.." to '"..from.."' (table expected, got "..typeInput..")" )
		end

	elseif target == "body" then
		local typeSD = type( input.storyData )
		if typeSD == "table" then
			local typeNode = type( input.storyData[node] )
			if typeNode == "table" then
				local typeBody = type( input.storyData[node].body )
				if typeBody == "string" then
					var = input.storyData[node].body
				else
					print( errorMsgBase.."invalid \"storyData["..node.."].body\" to '"..from.."' (string expected, got "..typeInput..")" )
				end
			else
				print( errorMsgBase.."invalid \"storyData["..node.."]\" to '"..from.."' (table expected, got "..typeNode..")" )
			end
		else
			print( errorMsgBase.."invalid \"storyData\" to '"..from.."' (table expected, got "..typeSD..")" )
		end

	elseif target == "node" or target == "name" then
		if typeInput == "string" then
			var = input
		else
			local arg = "bad argument #1"
			if target == "name" then arg = "invalid \"name\"" end
			print( errorMsgBase..arg.." to '"..from.."' (string expected, got "..typeInput..")" )
		end

	elseif target == "source" or target == "savefile" then
		if typeInput == "string" then
			if sub( input, -5 ) == ".json" then
				var = input
			else
				print( errorMsgBase.."invalid \""..target.."\" to '"..from.."' (\""..target.."\" must end in \".json\")" )
			end
		else
			print( errorMsgBase.."invalid \""..target.."\" to '"..from.."' (string expected, got "..typeInput..")" )
		end

	-- autosave is optional and defaults to false
	elseif target == "autosave" then
		if typeInput == "boolean" then
			var = input
		end

	-- saveDirectory and sourceDirectory are also optional with default values
	elseif target == "saveDirectory" or target == "sourceDirectory" then
		if typeInput == "userdata" then
			var = input
		else
			if target == "saveDirectory" then
				var = system.DocumentsDirectory
			else
				var = system.ResourceDirectory
			end
		end

	elseif target == "saveData" then
		if typeInput == "table" then
			var = input
		else
			print( errorMsgBase.."invalid \""..target.."\" to '"..from.."' (table expected, got "..typeInput..")" )
		end

	elseif target == "history" then
		if typeInput == "number" then
			if var <= 0 then
				var = 0
			else
				var = floor( input + 0.5 )
			end
		else
			var = 10
		end

	end
	return var
end


function M.save( input )
	-- validate the input
	local valid = validate( "input", "save", input )
	if not valid then return false end
	local t = validate( "saveData", "save", input.saveData )
	if not t then return false end
	local savefile = validate( "savefile", "save", input.savefile )
	if not savefile then return false end
	local saveDirectory = validate( "saveDirectory", "save", input.saveDirectory )

    local path = system.pathForFile( savefile, saveDirectory )
    local file, errorString = io.open( path, "w" )

    if not file then
        print( errorMsgBase.."file error in 'save': " .. errorString )
        return false
    else
		file:write( json.encode( t ) )
        io.close( file )
        return true
    end
end


function M.load( savefile, saveDirectory )
	-- validate the inputs
	savefile = validate( "savefile", "load", savefile )
	if not savefile then return false end
	saveDirectory = validate( "saveDirectory", "load", saveDirectory )

    local path = system.pathForFile( savefile, saveDirectory )
    local file, errorString = io.open( path, "r" )

    if not file then
        print( errorMsgBase.."file error in 'load': " .. errorString )
    else
        local contents = file:read( "*a" )
        local t = json.decode( contents )
        io.close( file )
        return t
    end
end


function M.initStory( input )
	local errorMsgBase = errorMsgBase.."initStory: "
	-- validate the input
	local valid = validate( "input", "initStory", input )
	if not valid then return false, false end
	local source = validate( "source", "initStory", input.source )
	if not source then return false, false end
	local saveDirectory = validate( "saveDirectory", "initStory", input.saveDirectory )
	local sourceDirectory = validate( "sourceDirectory", "initStory", input.sourceDirectory )
	local autosave = validate( "autosave", "initStory", input.autosave )
	-- savefile is not validated UNLESS autosave is on, i.e. save is attempted
	local savefile = input.savefile

	local path = system.pathForFile( source, sourceDirectory )
	local file = io.open( path, "r" )
	local contents

	if not file then
		print( errorMsgBase.."error accessing file \""..source.."\"." )
		return false, false
	else
		contents = file:read( "*a" )
		contents = json.decode( contents )
        io.close( file )
	end

	local story, data = {}, {}

	-- separate the tags using comma into
	local function parse(s)
		local t = {}
		local i
		for block in gmatch(s, "[^,]+") do
			t[#t+1] = block
			i = find(t[#t],"%S+")
			t[#t] = sub(t[#t],i)
		end
		return t
	end

	-- loop through the story's contents and add them to table
	for i = 1, #contents do
		story[contents[i].title] = {}
		story[contents[i].title].name = contents[i].title
		story[contents[i].title].body = contents[i].body
		if contents[i].tags ~= "" then
			local s = gsub(contents[i].tags, "%s+", "")
			local t = parse(s)

			story[contents[i].title].tags = {}
			for j = 1, #t do
				story[contents[i].title].tags[j] = t[j]
			end
		end
	end

	local path2, file2
	if savefile and saveDirectory then
		if type( savefile ) == "string" then
			path2 = system.pathForFile( savefile, saveDirectory )
			file2 = io.open( path2, "r" )
		end
	end

	-- either load the existing save file or create a new one
	if file2 then
		io.close( file2 )
		data = M.load( savefile, saveDirectory )
	else
		local pairs = pairs
		-- turn the variables table into baseline data table
		-- that is accessible from story.saveData.
		if story.variables then
			data = json.decode( story.variables.body )
			if data == nil then
				print( errorMsgBase.."node \"variables\" is not a valid JSON table." )
				return false, false
			end
			for i, j in pairs( data ) do
				if i == "node" then
					print( errorMsgBase.."node \"variables\" may not contain an entry named \"node\"." )
					return false, false
				elseif i == "previousNodes" then
					print( errorMsgBase.."node \"variables\" may not contain an entry named \"previousNodes\"." )
					return false, false
				elseif i == "visits" then
					print( errorMsgBase.."node \"variables\" may not contain an entry named \"visits\"." )
					return false, false
				elseif i == "previousNode" then
					print( errorMsgBase.."node \"variables\" may not contain an entry named \"previousNode\"." )
					return false, false
				elseif i == "currentNode" then
					print( errorMsgBase.."node \"variables\" may not contain an entry named \"currentNode\"." )
					return false, false
				end
			end
		end
		data["node"] = {}
		data["previousNodes"] = {}
		local skip

		-- load all options and create a node entry for every non-options node
		for i, j in pairs( story ) do
			if j.tags then
				skip = false
				for k = 1, #j.tags do
					if j.tags[k] == "option" or j.tags[k] == "options" then
						if i ~= "variables" then
							local duplicate = false
							for k, l in pairs( data ) do
								if i == k then
									duplicate = true
									break
								end
							end
							if duplicate == false then
								data[i] = json.decode( j.body )
								if data[i] == nil then
									print( errorMsgBase.."node \""..i.."\" is not a valid JSON table." )
									return false, false
								end
							else
								print( errorMsgBase.."\""..i.."\" is an invalid name for a node/table because an entry with the same name already exists in the \"variables\" node." )
								return false, false
							end
						end
						skip = true
					elseif j.tags[k] == "comment" or j.tags[k] == "comments" then
						-- nodes with "comment" tag are simply ignored
						skip = true
					end
				end
				if not skip then
					data["node"][i] = {}
					data["node"][i]["visits"] = 0
					data["node"][i]["link"] = true
				end
			else
				data["node"][i] = {}
				data["node"][i]["visits"] = 0
				data["node"][i]["link"] = true
			end
		end

		if autosave == true then
			savefile = validate( "savefile", "initStory", input.savefile )
			saveDirectory = validate( "saveDirectory", "initStory", input.saveDirectory )
			local tSave = { saveData=data, savefile=savefile, saveDirectory=saveDirectory }
			M.save( tSave )
		end
	end

	return story, data
end

-- load a specific node, read its contents and return only the desired content
function M.prevNode( input )
	local data = validate( "saveData", "prevNode", input.saveData )
	if not data then
		return false
	end
	if #data.previousNodes > 0 then
		local goTo = data.previousNodes[#data.previousNodes]
		data.previousNodes[#data.previousNodes] = nil
		M.getNode( goTo, input )
	else
		print( errorMsgBase.."prevNode: no previous nodes exist." )
	end
end


-- load a specific node, read its contents and return only the desired content
function M.getNode( node, input, debugPrint )
	local errorMsgBase = errorMsgBase.."getNode: "

	-- validate the input and node name before proceeding
	local valid = validate( "input", "getNode", input )
	local node = validate( "node", "getNode", node )
	if not valid or not node then return false end
	local body = validate( "body", "getNode", input, node )
	if not body then return false end
	local data = validate( "saveData", "getNode", input.saveData )
	if not data then return false end
	local name = validate( "name", "getNode", input.name )
	if not name then return false end
	local history = validate( "history", "getNode", input.history )
	data.currentNode = node
	data.visits = input.saveData.node[node].visits
	-- previousNode is nil upon loading the very first node
	if not data.previousNode then data.previousNode = node end
	-- line table contains all of the lines from the node's contents
	local line = {}
	-- parse a string for pairs of brackets:
	-- c1 and c2 are bracket type as string, n is their length minus 1
	local function getBrackets( s, n, c1, c2, row )
		local brackets = {}
		for i = 1, len(s) do
			if sub(s,i,i+n) == c1 then
				brackets[#brackets+1] = {}
				brackets[#brackets][1] = i
			elseif sub(s,i,i+n) == c2 then
				for j = 1, #brackets do
					if #brackets[j] ~= 2 then
						brackets[j][2] = i
						break
					end
				end
			end
		end
		if #brackets > 0 then
			for i = 1, #brackets do
				if #brackets[i] ~= 2 then
					print( errorMsgBase.."#XXX - \""..node.."\" on row "..row.." uneven number of brackets." )
				end
			end
		end
		return brackets
	end

	local function validateVariables( target, s1, s2 )
		local valid = true
		local period, bracket, func
		local start, loop = 0, true
		while loop do
			-- see if a period or a bracket is found and which is earlier
			period = find( s2, "(%.)", start+1 ) or 9999999
			bracket = find( s2, "(%[)", start+1 ) or 9999999
			start = period < bracket and period or bracket < period and bracket or len(s2)+1
			if period == bracket then loop = false end

			-- if the function is valid AND has a value, then the variable exists
			func = loadstring( "return "..s1..sub( s2, 1, start-1 ) )
			if func ~= nil and func() == nil then
				valid = false
				loop = false
			end
		end
		return valid
	end
	-- parse a string for persistent and temporary variables
	-- and replace them with their value in the string
	local function checkVar(s)
		local tempVar, var = {}, {}
		local loop = false
		-- find all variables in a string and add them to tempVar table
		local function findVar(n,varType)
			local loc = find(s, varType,n)
			if loc ~= nil then
				tempVar[#tempVar+1] = {}
				if varType == "(_%a)" or varType == "($%a)" then
					tempVar[#tempVar][1] = loc
				else
					tempVar[#tempVar][1] = loc+1
				end
				-- find when the first space character after the varType symbol
				local space = find( s, "%s", tempVar[#tempVar][1] )
				local comma = find( s, "(,)", tempVar[#tempVar][1])
				-- if there is no space, then the line must end with the variable
				if not space and not comma then
					local l = len(s)
					-- find if there is a forward slash between varType and the string's end
					local p = find(s, "%\\", tempVar[#tempVar][1])
					if p then
						tempVar[#tempVar][2] = p-1
						loop = true
					else
						tempVar[#tempVar][2] = l
						loop = false
					end
				else
					local p = find(s, "%\\", tempVar[#tempVar][1]) or 9999999
					-- check which, space or comma, is smaller (or is not nil)
					local spaceOrComma = (space and comma) and min( space, comma ) or space or comma

					if p <= spaceOrComma then
						tempVar[#tempVar][2] = p-1
					else
						if space and not comma then
							tempVar[#tempVar][2] = space-1
						elseif not space and comma then
							tempVar[#tempVar][2] = comma-1
						elseif space <= comma then
							tempVar[#tempVar][2] = space-1
						else
							tempVar[#tempVar][2] = comma-1
						end
					end
					loop = true
				end
				tempVar[#tempVar][3] = sub( s, tempVar[#tempVar][1], tempVar[#tempVar][2] )
			else
				loop = false
			end
		end
		-- loop until no additional variables of any type are found
		if sub(s,1,1) == "$" or sub(s,1,1) == "\\$" then findVar(1,"($%a)") else findVar(1,"%s($%a)") end -- persistent variable preceded by a space
		while loop do findVar(tempVar[#tempVar][2],"%s($)") end

		if sub(s,1,1) == "_" or sub(s,1,1) == "\\_" then findVar(1,"(_%a)") else findVar(1,"%s(_%a)") end -- temporary variable preceded by a space
		while loop do findVar(tempVar[#tempVar][2],"%s(_)") end

		findVar(1,"(\\$%a)") -- persistent variable preceded by a forward slash
		while loop do	findVar(tempVar[#tempVar][2],"(\\$)") end

		findVar(1,"(\\_%a)") -- temporary variable preceded by a forward slash
		while loop do findVar(tempVar[#tempVar][2],"(\\_)") end

		local t = {}
		local function compare( a, b )
			return a < b
		end
		for i = 1, #tempVar do
			t[i] = tempVar[i][1]
		end

		sort( t, compare )
		-- persistent variables are always first in tempVar table,
		-- so they must be set in correct order for the var table
		for i = 1, #tempVar do
			for j = 1, #tempVar do
				if tempVar[j][1] == t[i] then
					var[i] = { tempVar[j][1], tempVar[j][2], tempVar[j][3] }
				end
			end
		end

		local valid
		local output = ""
		-- if variables exist in the string, then retrieve their values
		if #var > 0 then
			for i = 1, #var do
				-- store the variable name for use in the error string
				local varName = sub(var[i][3],2)
				-- replace the persistent or temporary symbol with the associated table names
				if sub(var[i][3],1,1) == "$" then
					var[i][4] = gsub(var[i][3], "($)", name..".saveData.")
					valid = validateVariables( "$", sub( var[i][4], 1, -1-len(varName) ), varName )
				elseif sub(var[i][3],1,1) == "_" then
					var[i][4] = gsub(var[i][3], "(_)", name..".saveData.temp.")
					valid = validateVariables( "_", sub( var[i][4], 1, -1-len(varName) ), varName )
				end
				-- use loadstring to turn the variable string into a function
				var[i][4] = loadstring("return "..var[i][4])
				-- if the string doesn't turn into a function, then the variable is nil
				if var[i][4] == nil then
					print( errorMsgBase.."#XXX - \""..node.."\" on row "..i..": "..varName.." is nil." )
				else -- if the string turns into a function, then run the function
					if valid then
						var[i][4] = var[i][4]()
					else
						var[i][4] = nil
					end
				end
				-- if the value is nil or boolean, then turn it into a string
				if var[i][4] == nil then
					var[i][4] = "(a nil value)"
				elseif type(var[i][4]) == "boolean" then
					var[i][4] = tostring(var[i][4])
				elseif type(var[i][4]) == "table" then
					var[i][4] = "("..tostring( var[i][4] )..")"
				end
			end

			if var[1][1] >= 1 then
				output = sub( s, 1, var[1][1]-1 )
			end
			for i = 1, #var do
				output = output.."$VAR"..i..""
				if i < #var then
					output = output..sub( s, var[i][2]+1, var[i+1][1]-1 )
				end
			end
			output = output..sub( s, var[#var][2]+1 )
			-- replace the variables in the string with their values
			for i = 1, #var do
				if find( output, "\\$VAR"..i.."\\" ) then
					output = gsub(output, "\\$VAR"..i.."\\", var[i][4] )
				end
				if find( output, "\\$VAR"..i ) then
					output = gsub( output, "\\$VAR"..i, var[i][4] )
				end
				if find( output, "$VAR"..i.."\\" ) then
					output = gsub( output, "$VAR"..i.."\\", var[i][4] )
				end
				output = gsub( output, "$VAR"..i, var[i][4] )
			end
		else
			output = s
		end
		return output
	end

	-- general parsing function that takes a string and splits it to table entries based on a pattern(c)
	local function parse( s, c )
		local t = {}
		local i
		for block in gmatch(s,c) do
			t[#t+1] = block
			i = find(t[#t],"%S+")
			t[#t] = sub(t[#t],i)
		end
		return t
	end

	-- certain functions parse through strings and identify certain words or patterns that
	-- need to be picked from the string and then the string is recompiled without them in it
	local function recompileString(s,words,brackets,links)
		local output = ""
		local o = 0
		if brackets[1][1] >= 1 then
			output = sub(s,1,brackets[1][1]-1)
		end
		for i = 1, #brackets do
			-- links are only present when recompiling from crawlLinks
			if links ~= nil then
				-- brackets from crawlLinks are two characters long, so they need small offset
				o = 1
			end
			output = output..words[i]
			if i ~= #brackets then
				if brackets[i][2]+1 <= brackets[i+1][1]-1 then
					output = output..sub(s,brackets[i][2]+1+o,brackets[i+1][1]-1)
				end
			end
		end
		if brackets[#brackets][2] < len(s) then
			output = output..sub(s,brackets[#brackets][2]+1+o)
		end
		return output
	end

	-- parse a string for any (either:) commands and return a single entry at random
	-- NB! this function does not work with nested commands, i.e. (either: either:())
	local function either( s, fromSet, row )
		local brackets = getBrackets( s, 0, "(", ")", row )
		-- check that the brackets are immediately followed by "either:"
		-- and then parse all strings/variables within the brackets and
		-- finally randomly select one of them to be returned
		local realBrackets, words = {}, {}
		if #brackets > 0 then
			for i = 1, #brackets do
				if sub(s,brackets[i][1],brackets[i][1]+7) == "(either:" then
					-- realBrackets exists ONLY in cases where "(either:" is found
					realBrackets[#realBrackets+1] = { brackets[i][1], brackets[i][2] }
					local m = parse( sub( s, brackets[i][1]+8,brackets[i][2]-1), "[^,]+" )
					-- either calls from "set" function require quotes to run
					-- whereas others don't, so they are removed as unnecessary
					if not fromSet then
						for j = 1, #m do
							if sub(m[j],1,1) == "\"" and sub(m[j],-1,-1) == "\"" then
								m[j] = sub( m[j], 2, -2 )
							end
						end
					end
					words[#words+1] = m[random(#m)]
				end
			end
		end
		-- if there were brackets then replace all content within brackets
		-- in the string by the previously random selected string/variable
		local output
		if #realBrackets > 0 then
			output = recompileString( s, words, realBrackets )
		else
			output = s
		end
		return output
	end

	-- find the start and end locations for all parts of a given link
	local function getLink(s)
		-- the components use depend on the link type, i.e. |, ->, <-
		local breaker, breakerEnd = find(s,"(|)")
		local reverse
		if breaker == nil then
			breaker, breakerEnd = find(s,">")
			if breaker == nil then
				breaker, breakerEnd = find(s,"<")
				if breaker ~= nil then
					breakerEnd = breakerEnd+1
					reverse = true
				end
			else
				breaker = breaker-1
			end
		end
		return breaker, breakerEnd, reverse
	end

	-- parse a string for any links and create new line table
	-- entries of any found links and clean up the given string.
	local function crawlLinks( s, row )
		local brackets = getBrackets( s, 1, "[[", "]]", row )
		local pattern, to = {}, {}
		local output

		if #brackets > 0 then
			for i = 1, #brackets do
				local str = sub(s,brackets[i][1],brackets[i][2]+1)
				local breaker, breakerEnd, reverse = getLink(str)
				-- create new line table entries for any link found depending on their type
				if breaker == nil then
					local a = sub(str,3,-3)
					-- only take the link if it isn't broken
					if input.saveData.node[a] then
						if input.saveData.node[a].link then
							line[#line+1] = { "link", a, a }
						end
					else
						line[#line+1] = { "link", a, a }
					end
					pattern[i] = a
					to[i] = a
				else
					if reverse == nil then
						local a, b = sub(str,3,breaker-1), sub(str,breakerEnd+1,-3)
						if input.saveData.node[b] then
							if input.saveData.node[b].link then
								line[#line+1] = { "link", a, b }
							end
						else
							line[#line+1] = { "link", a, b }
						end
						pattern[i] = a
						to[i] = b
					else
						local a, b = sub(str,breakerEnd+1,-3), sub(str,3,breaker-1)
						if input.saveData.node[b] then
							if input.saveData.node[b].link then
								line[#line+1] = { "link", a, b }
							end
						else
							line[#line+1] = { "link", a, b }
						end
						pattern[i] = a
						to[i] = b
					end
				end
			end
			output = recompileString( s, pattern, brackets, to )
		else
			output = s
		end
		return output
	end

	-- split a node into lines and remove
	-- any preceding spaces from all lines
	local function getLines(s)
		local t = {}
		local i
		for line in s:gmatch( "([^\n]*)\n?") do
			t[#t+1] = line
			if find(t[#t], "%S") then
				i = find(t[#t],"%S+")
				t[#t] = sub(t[#t],i)
			end
		end
		return t
	end

	local t = getLines( body )

	local ml = {}
	ml.allowed = {}
	ml.firstTrue = {}
	ml.a = 0
	ml.b = 0
	ml.level = 0
	local allowAll = false
	local lStart

	-- find all starts and ends for all conditional statements
	for i = 1, #t do
		lStart = find( t[i], "(<<)" )
		if lStart then
			lStart = find( t[i], "%S", lStart+2 )
			if sub(t[i], lStart, lStart+1 ) == "if" then
				ml.a = ml.a+1
			elseif sub(t[i], lStart, lStart+2 ) == "end" then
				ml.b = ml.b+1
			end
		end
	end
	-- ensure that each conditional statement has a beginning (if) and an end (end)
	if ml.a ~= ml.b then
		if ml.a < ml.b then
			print( errorMsgBase.."#XXX - \""..node.."\": Conditional mismatch - there are more <<end>> lines than <<if>> lines." )
		elseif ml.a > ml.b then
			print( errorMsgBase.."#XXX - \""..node.."\": Conditional mismatch - there are more <<if>> lines than <<end>> lines." )
		end
		return false
	end

	if ml.a == 0 then
		allowAll = true -- if there are no conditional statements, then all rows/lines are accepted
	else
		for i = 1, ml.a do
			ml.allowed[i] = true
			ml.firstTrue[i] = false
		end
	end

	local function isAllowed()
		local logic = true
		for i = 1, ml.a do
			if ml.allowed[i] == false then
				logic = false
				break
			end
		end
		return logic
	end

	-- takes a variable or its value and removes
	-- any unnecessary spaces or quotes from it
	local function cleanVar( s, var )
		local a, b, number

		a = find( s, "\"" )
		if a then
			a = a+1
			b = find( s, "\"", a+1 )-1
		else
			number = true
			a = find( s, "%S" )
			b = find( s, "%s", a+1 )
			if b then
				b = b-1
			else
				b = len( s )
			end
		end

		s = sub( s, a, b )
		-- if the string wasn't explicitly a string
		if number then
			-- if there are only numbers left in the string
			if not find( s, "%D" ) and not var then
				s = tonumber( s )
			end
		end
		return s
	end

	if debugPrint then
		print( "======== NODE START ========" )
	end
	local cmdLine, cmd, cmdEnd = {}
	for i = 1, #t do
		-- first check if there are any non space characters on the line
		if find(t[i], "%S") then
			local a = sub(t[i],1,1)
			local aa = sub(t[i],1,2)
			local statement, command

			-- lines starting with "<<" are either commands or conditional statements
			if aa == "<<" then
				-- first check that the end of the line also has ">>" brackets
				cmdEnd = find( t[i], "(>>)" )
				if not cmdEnd then
					print( errorMsgBase.."#XXX - \""..node.."\" on row "..i..": row expected to end in \">>\"." )
					return false
				end
				-- then remove the outer brackets "<<" & ">>" from the line
				t[i] = sub(t[i], 3, cmdEnd-1)
				cmdEnd = find( t[i], "%s" )
				if cmdEnd then
					cmd = sub( t[i], 1, cmdEnd-1 )
				else
					cmd = t[i]
				end

				-- always start by checking if the line is a conditional statement
				if cmd == "if" or cmd == "elseif" or cmd == "else" or cmd == "end" then
					statement = true

					if cmd == "if" or cmd == "elseif" then
						if cmd == "if" then
							t[i] = sub( t[i], 3 )
							-- a new "if" means a new conditional clause
							ml.level = ml.level+1
						else
							t[i] = sub( t[i], 7 )
						end
						-- check if the line has "then" with succeeding spaces in the end
						local lenS = len( t[i] )
						for j = lenS, 1, -1 do
							if sub( t[i], j, j ) ~= " " then
								local dN = (j-lenS)
								if sub( t[i], dN-4, dN-1 ) == "then" then
									t[i] = sub( t[i], 1, dN-5 )
								end
								break
							end
						end

						-- if any persistent or temporary variable is nil, then
						-- invalidate the statement and default to true
						local function validateStatement( s, target )
							local isValid = true

							local t2, c = {}
							for j = 1, len( s ) do
								c = sub( s, j, j )
								if c == target then
									t2[#t2+1] = { j }
								end
							end

							local e1, e2, e3, e4, number, var
							for j = 1, #t2 do
								number = 9999999
								e1 = find( t[i], "(>)", t2[j][1] ) or 9999999
								e2 = find( t[i], "(<)", t2[j][1] ) or 9999999
								e3 = find( t[i], "(=)", t2[j][1] ) or 9999999
								e4 = find( t[i], "(~)", t2[j][1] ) or 9999999
								number = e1 < number and e1 or number
								number = e2 < number and e2 or number
								number = e3 < number and e3 or number
								number = e4 < number and e4 or number
								t2[j][2] = number == 9999999 and len( t[i] ) or number-1
								var = target == "$" and name..".saveData." or name..".saveData.temp."

								local valid = validateVariables( target, var, sub( t[i], t2[j][1]+1, t2[j][2] ) )
								if not valid then
									isValid = false
									break
								end
							end
							return isValid
						end

						local valid = validateStatement( t[i], "$" )
						local s = gsub(t[i], "($)", name..".saveData." )
						if valid then
							local temp = find(t[i], "(_)")
							if temp then
								-- check if saveData.temp table exists
								local tempTable = loadstring( "return "..name..".saveData.temp" )
								if tempTable() then
									valid = validateStatement( t[i], "_" )
									s = gsub(t[i], "(_)", name..".saveData.temp." )
								else
									valid = false
								end
							end
						end
						s = loadstring("return " .. s)

						if valid then
							local value = assert(s)()
							if type(value) ~= "boolean" then
								print( errorMsgBase.."#XXX - \""..node.."\" on row "..i..": statement is invalid.")
								return false
							else
								if ml.firstTrue[ml.level] == false then
									ml.allowed[ml.level] = value
									if value == true then
										ml.firstTrue[ml.level] = true
									end
								else
									ml.allowed[ml.level] = false
								end
							end
						else
							ml.allowed[ml.level] = false
						end
					elseif cmd == "else" then
						if ml.firstTrue[ml.level] == false then
							ml.allowed[ml.level] = true
							ml.firstTrue[ml.level] = true
						else
							ml.allowed[ml.level] = false
						end
					elseif cmd == "end" then
						-- "end" means the end of a conditional clause
						ml.allowed[ml.level] = true
						ml.firstTrue[ml.level] = false
						ml.level = ml.level-1
					end
				end

				-- for all commands, check if their line is allowed
				if allowAll or isAllowed() then
					-- create a new variable or adjust its value
					if cmd == "print" then
						command = true
						line[#line+1] = {"print"}
						local start = find( t[i], "%s" )
						cmdLine[#cmdLine+1] = { "print", checkVar( either( sub( t[i], start+1 ), false, i) ) }
						print( cmdLine[#cmdLine][2] )

					elseif cmd == "set" or cmd == "shuffle" then
						command = true
						local a, b = find( t[i], "("..cmd..")" )
						t[i] = sub( t[i], b+1 )
						t[i] = either( t[i], true, i )
						cmdLine[#cmdLine+1] = { cmd }

						local var
						-- find the first occurrences of "$" and "_"
						-- and find which symbol is found first
						local a = find(t[i],"($)") or 9999999
						local b = find(t[i],"(_)") or 9999999
						-- stored variable
						if a < b then
							var = "$"
						-- temporary variable
						elseif b < a then
							var = "_"
							if cmd == "set" then
								-- if the temp table doesn't exist, create it
								local func = loadstring("return "..name..".saveData.temp")
								if func() == nil then
									local func = loadstring(name..".saveData.temp = {}")()
								end
							end
						-- if a and b are the same, then var is nil, so terminate the function
						else
							print( errorMsgBase.."#XXX - \""..node.."\" on row "..i..": "..cmd.." variable is missing \"$\" or \"_\"." )
							return false
						end

						-- make sure that the user is not trying to overwrite the plugin's data tables
						if find(t[i], "($temp)") then
							print( errorMsgBase.."#XXX - \""..node.."\" on row "..i..": attempting to \""..cmd.." $temp\", but $temp is reserved by the plugin.")
							return false
						elseif find(t[i], "($node)") then
							print( errorMsgBase.."#XXX - \""..node.."\" on row "..i..": attempting to \""..cmd.." $node\", but $node is reserved by the plugin.")
							return false
						elseif find(t[i], "($previousNode)") then
							print( errorMsgBase.."#XXX - \""..node.."\" on row "..i..": attempting to \""..cmd.." $previousNode\", but $previousNode is reserved by the plugin.")
							return false
						elseif find(t[i], "($visits)") then
							print( errorMsgBase.."#XXX - \""..node.."\" on row "..i..": attempting to \""..cmd.." $visits\", but $visits is reserved by the plugin.")
							return false
						elseif find(t[i], "($currentNode)") then
							print( errorMsgBase.."#XXX - \""..node.."\" on row "..i..": attempting to \""..cmd.." $currentNode\", but $currentNode is reserved by the plugin.")
							return false
						end

						-- convert any variables in the string to their full names
						local s = gsub( t[i], "($)", name..".saveData." )
						s = gsub( s, "(_)", name..".saveData.temp." )
						cmdLine[#cmdLine][2] = s

						if cmd == "set" then
							local func = loadstring(s)
							if type(func) == "function" then
								func()
							else
								print( errorMsgBase.."#XXX - \""..node.."\" on row "..i..": unable to set variable, variable is invalid or nil.")
							end
						-- shuffle's a table using the Fisher-Yates shuffle
						else
							local function shuffle(t)
								for i = #t, 2, -1 do
									local j = random(i)
										t[i], t[j] = t[j], t[i]
									end
								return t
							end
							-- t is a reference to the actual saveData table, so the shuffle affects the real table
							local v = loadstring("return "..s)()
							if v then
								local t = shuffle(v)
							else
								print( errorMsgBase.."#XXX - \""..node.."\" on row "..i..": unable to shuffle table, table is invalid or nil.")
							end
						end
					-- links can be broken and fixed, by default no link is broken, so breaking a link
					-- will add an entry to brokenLinks table and fixing a link will remove the entry
					elseif cmd == "link" then
						command = true
						local operation
						if find( t[i], "(break)" ) then
							operation = "break"
						elseif find( t[i], "(fix)" ) then
							operation = "fix"
						else
							print( errorMsgBase.."#XXX - \""..node.."\" on row "..i..": invalid command. Link must be followed by break or fix.")
						end
						if operation then
							local link = match( t[i], "\"(.-)\"")
							cmdLine[#cmdLine+1] = { cmd, operation, link }

							if input.storyData[link] then
								if input.saveData.node[link] then
									if operation == "break" then
										input.saveData.node[link].link = false
									else
										input.saveData.node[link].link = true
									end
								end
							else
								if link then
									print( errorMsgBase.."#XXX - \""..node.."\" on row "..i..": unable to "..operation.." link because node \""..link.."\" does not exist.")
								else
									print( errorMsgBase.."#XXX - \""..node.."\" on row "..i..": link name is invalid, nil, or it may be missing \"quotes\".")
								end
								return false
							end
						end
					else
						if not statement then
							-- split all custom commands into separate table entries
							t[i] = checkVar( either( t[i], false, i))
							local tempLine = parse( t[i], "[^,]+" )
							line[#line+1] = { cleanVar(tempLine[1], true ) }

							local sign
							for j = 2, #tempLine do
								sign = find( tempLine[j], "(=)" )
								if sign then
									local entry = cleanVar( sub( tempLine[j], 1, sign-1 ), true )
									line[#line][entry] = cleanVar( sub( tempLine[j], sign+1 ) )
								else
									line[#line][getn(line[#line])+1] = cleanVar( tempLine[j] )
								end
							end
						end
					end
				end
			else
				-- check that the line isn't a comment
				if a ~= "#" and a ~= "//" then
					if allowAll or isAllowed() then
						local isLink = false
						local brackets = getBrackets( t[i], 1, "[[", "]]", i )
						-- check if t[i] contains only a link
						if #brackets == 1 then
							if brackets[1][1] == 1 then
								local lenS = len( t[i] )
								if brackets[1][2]+1 == lenS then
									isLink = true
								else
									isLink = true
									for j = brackets[1][2]+1, lenS do
										if sub( t[i], j, j ) ~= " " then
											isLink = false
											break
										end
									end
								end
							end
						end
						if isLink then
							crawlLinks( t[i], i )
						else
							local text, style
							if a == "<" then
								-- split all custom commands into separate table entries
								local styleEnd = find(t[i], "(>)" )
								if styleEnd then
									style = parse( sub( t[i], 2, styleEnd-1 ), "[^,]+" )
									text = checkVar( either( sub( t[i], styleEnd+1 ), false, i))
								else
									text = checkVar( either( t[i], false, i))
								end
							else
								text = checkVar( either( t[i], false, i))
							end
							line[#line+1] = { "text", text }

							local lineNumber = #line
							if style then
								local sign
								for j = 1, #style do
									sign = find( style[j], "(=)" )
									if sign then
										local entry = cleanVar( sub( style[j], 1, sign-1 ), true )
										line[#line][entry] = cleanVar( sub( style[j], sign+1 ) )
									else
										line[#line][getn(line[#line])+1] = cleanVar( style[j] )
									end
								end
							end
							line[lineNumber][2] = crawlLinks( text, i )
						end
					end
				end
			end
			-- optional debugPrint prints
			if debugPrint and not statement then
				if command then
					print( "row "..i.." read:\n" )
					if cmdLine[#cmdLine][1] == "print" or cmdLine[#cmdLine][1] == "set" or cmdLine[#cmdLine][1] == "shuffle" then
						print( cmdLine[#cmdLine][1]..": "..cmdLine[#cmdLine][2] )
					elseif cmdLine[#cmdLine][1] == "link" then
						print( cmdLine[#cmdLine][2].." "..cmdLine[#cmdLine][1]..": "..cmdLine[#cmdLine][3] )
					end
					print( "----------------------------" )
				else
					if a ~= "#" and a ~= "//" then
						if allowAll or isAllowed() then
							print( "row "..i.." read:\n\nline["..#line.."] = {" )
							for j, k in pairs( line[#line] ) do
								print( "\t\t["..j.."] = "..k)
							end
							print( "\t}\n----------------------------" )
						end
					end
				end
			end
		end
	end
	if debugPrint then
		print( "========= NODE END =========" )
	end

	-- check if the table for temporary data exists and delete it
	local func = loadstring("return "..name..".saveData.temp")
	if func() then
		local func = loadstring(name..".saveData.temp = nil")()
	end
	-- if a given node is nil, it means that the story
	-- has been updated without deleting the old save
	if data.node[node] == nil then
		data.node[node] = {}
		data.node[node].visits = 1
		data.node[node].link = true
	else
		data.node[node].visits = data.node[node].visits + 1
	end
	-- set the current node as the previously visited node
	data.previousNode = node
	if history ~= 0 then
		data.previousNodes[#data.previousNodes+1] = node
		if #data.previousNodes > history then
			for i = 1, #data.previousNodes-history do
				data.previousNodes[#data.previousNodes] = nil
			end
		end
	end

	local autosave = validate( "autosave", "getNode", input.autosave )
	if autosave then
		M.save( input )
	end
	return line
end

return M
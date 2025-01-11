gc()
clearListener()

try(DestroyDialog tscn_tool)catch(tscn_tool)
rollout tscn_tool "2D Mesh Tool" (

	button btn_open "Open .tscn" width:120
	button btn_save "Save .tscn" width:120
	group "Options" (
		checkbox chk_clear "Clear on Open" checked:true
		)
	label lbl_1 "mariokart64n" align:#left across:2
	label lbl_2 "Feb 18, 2024" align:#right
	
	-- Define a struct to hold the parsed data
	struct f_TSCN_Data (
		name = "",
		data = #()
		)

	struct f_TSCN_Key (
		key = undefined,
		values = #(),
		params = #()
		)

	struct f_TSCN (         -- Godot Engine Text Scene File
		entries = #(),       -- Array to hold parsed entries
		currentKeyIndex = 0, -- To keep track of the currently selected key
		
		fn size = (
			-- Description: Returns the number of entries.
			-- Parameters:  None.
			-- Returns:     tscn.size()
			-- Returns:     Integer representing the number of entries.
			
			entries.count
			),
		
		fn read f = ( -- filePath
			-- Description: Parses a TSCN file and populates the entries array.
			-- Parameters:  f - File stream for the TSCN file.
			-- Usage:       tscn.read(f)
			-- Returns:     Nothing.
			
			entries = #() -- Ensure this is clear at the start
			local currentEntry = f_TSCN_Key()
			if f != undefined and classOf f == FileStream then (
				while not eof f do (
					local l = trimRight (readLine f)
					
					-- Skip comments and empty lines
					if l == "" or l[1] == ";" do continue
					
					-- Handle Key
					if l[1] == "[" then (
						
						-- Append the current entry if it has a key
						if currentEntry.key != undefined do (
							append entries currentEntry
							currentEntry = f_TSCN_Key() -- Reset for the next entry
							)
						
						-- Read Key
						local endIndex = findString l "]"
						if endIndex != undefined then (
							
							-- Extract the key
							local key = substring l 2 (endIndex-2)
							
							-- Split any parameters that may be with the key
							endIndex = findString key " "
							if key != undefined do (
								--currentEntry.params = subString key (endIndex+1) -1
								inputString  = subString key (endIndex+1) -1
								
								-- Initialize variables for parsing
								local tmp = #()
								local inQuotes = false
								local currentName = ""
								local currentValue = ""
								local temp = ""
								local collectingName = true
								
								-- Loop through each character in the input string
								for i = 1 to inputString.count do (
									local char = inputString[i]
									
									-- Toggle inQuotes flag when encountering a quote character
									if char == "\"" do (
										inQuotes = not inQuotes
										continue -- Skip adding the quote character to temp
										)
									
									-- If not in quotes and we encounter an '=', we switch from collecting the name to collecting the value
									if char == "=" and not inQuotes then (
										currentName = temp
										temp = ""
										collectingName = false
										)
									else if char != " " or inQuotes then (
										-- Accumulate characters in temp
										temp += char
										)
									else if char == " " and not inQuotes and temp != "" then (
										-- At space character outside quotes, finalize collection of either name or value
										if collectingName then (
											-- We were still collecting a parameter name; switch to collecting its value
											collectingName = false
											)
										else (
											-- Space signifies the end of a parameter's value; append to tmp and reset for next parameter
											currentValue = temp
											append tmp (f_TSCN_Data name:currentName data:currentValue)
											temp = ""
											currentName = ""
											currentValue = ""
											collectingName = true -- Reset for next parameter's name
											)
										)
									)
								
								-- Handle last parameter in case inputString ends without a trailing space
								if temp != "" do (
									if collectingName then (
										-- Handle case where only a name is present without value, unlikely but included for completeness
										append tmp (f_TSCN_Data name:temp data:"")
										)
									else (
										-- Append the last captured value, removing quotes if they were part of the value
										currentValue = temp
										append tmp (f_TSCN_Data name:currentName data:currentValue)
										)
									)
								
								-- Assign Data
								currentEntry.params = tmp
								key = subString key 1 (endIndex-1)
								)
							currentEntry.key = key
							)
						)
					
					-- Handle Value
					else (
						-- Handling key-value pairs outside brackets
						local eqIndex = findString l "="
						if eqIndex != undefined then (
							local n = trimLeft (substring l 1 (eqIndex-1))
							local d = trimLeft (substring l (eqIndex+1) l.count)
							
							append currentEntry.values (f_TSCN_Data name:(trimRight n) data:d)
							)
						)
					
					)
				-- Append the last entry if it has a key
				if currentEntry.key != undefined do append entries currentEntry
				)
			currentKeyIndex = if entries.count > 0 then 1 else 0
			format "% Entries Read\n" (size())
			),
		
		fn write f = (
			-- Description: Writes data from entries array to a TSCN file.
			-- Parameters:  f - File stream for output.
			-- Usage:       tscn.write(f)
			-- Returns:     Nothing.
			
			if f != undefined and classOf f == FileStream then (
				for entry in entries do (
					-- Write the key with parameters if any
					local paramsString = ""
					for param in entry.params do (
						
						paramsString += param.name + "="
						
						-- some parameters are not strings? might need some smart detection here?
						if param.name == "load_steps" or param.name == "format" then (
							-- no quotes
							paramsString += param.data + " "
							)
						else (
							-- double quote
							paramsString += "\"" + param.data + "\"" + " "
							)
						
						)
					-- Trim the trailing space and write the key
					paramsString = trimRight paramsString
					if paramsString.count > 0 then (
						format "[% %]\n" entry.key paramsString to:f
						)
					else (
						format "[%]\n" entry.key to:f
						)
					
					-- Write each value under this key
					local v = f_TSCN_Data()
					for v in entry.values do (
						format "% = %\n" v.name v.data to:f
						)
					
					-- Add a newline for separation between entries
					format "\n" to:f
					)
				close f -- Close the file when done
				)
			else (
				print "Unable to open file for writing."
				)
			),
		
		fn open file = (
			-- Description: Opens and reads a TSCN file.
			-- Parameters:  file - Path to the TSCN file.
			-- Usage:       tscn.open("path/to/file.tscn")
			-- Returns:     true if successful, otherwise false.
			
			local result = false
			if file != undefined and file != "" do (
				local f = try(openFile file mode:"rt")catch(undefined)
				if f != undefined then (
					read(f)
					close f
					result = true
					format "TSCN File Prased {%}\n" file
					) else (format "failed to read file {%}\n" file)
				)
			result
			),
		
		fn save file = (
			-- Description: Saves current data to a TSCN file.
			-- Parameters:  file - Path to save the TSCN file.
			-- Usage:       tscn.save("path/to/save.tscn")
			-- Returns:     true if successful, otherwise false.
			
			local result = false
			if file != undefined and file != "" do (
				local f = try(openFile file mode:"wt")catch(undefined)
				if f != undefined then (
					write(f)
					close f
					result = true
					format "TSCN File Written {%}\n" file
					) else (format "failed to write file {%}\n" file)
				)
			result
			),
		
		fn select key caseSensitive:false = (
			-- Description: Selects a key, updating currentKeyIndex.
			-- Parameters:  key - Key name to select.
			-- Usage:       tscn.select("key_name")
			-- Returns:     true if key found, otherwise false.
			
			local result = false
			for i = 1 to size() do (
				if MatchPattern key pattern:entries[i].key ignoreCase:(not caseSensitive) do (
					currentKeyIndex = i
					result = true
					exit
					)
				)
			if not result do (format "Failed To Select Key {%}\n" key)
			result
			),
		
		fn start = (
			-- Description: Sets currentKeyIndex to the first key.
			-- Parameters:  None.
			-- Usage:       tscn.start()
			-- Returns:     Integer of the currentKeyIndex
			
			currentKeyIndex = if size() > 0 then 1 else 0
			),
		
		fn end = (
			-- Description: Sets currentKeyIndex to the last key.
			-- Parameters:  None.
			-- Usage:       tscn.end()
			-- Returns:     Integer of the currentKeyIndex
			
			currentKeyIndex = if size() > 0 then size() else 0
			),
		
		fn next key:"" caseSensitive:false loop:false = (
			-- Description: Advances to the next key, optionally matching a pattern.
			-- Parameters:  key (optional) - Pattern to match.
			-- Usage:       tscn.next("optional_pattern")
			-- Returns:     true if next key found, otherwise false.
			
			result = false
			if currentKeyIndex < size() do (
				if (key != undefined and key != "") then (
					local lastIndex = currentKeyIndex + 1
					if lastIndex > size() do lastIndex = size()
					for i = currentKeyIndex + 1 to size() do (
						if MatchPattern entries[i].key pattern:key ignoreCase:(not caseSensitive) do (
							currentKeyIndex = i
							result = true
							exit
							)
						)
					if loop and not result do (
						for i = 1 to lastIndex do (
							if MatchPattern entries[i].key pattern:key ignoreCase:(not caseSensitive) do (
								currentKeyIndex = i
								result = true
								exit
								)
							)
						)
					)
				else (
					currentKeyIndex += 1
					result = true
					)
				)
			result
			),
		
		fn last = ( -- need to update
			-- Description: Moves to the previous key in the entries.
			-- Parameters:  None.
			-- Usage:       tscn.last()
			-- Returns:     true if successful, otherwise false.
			
			result = false
			if currentKeyIndex > 0 do (
				currentKeyIndex -= 1
				result = true
				)
			result
			),
		
		fn getValue valueKey = (
			-- Description: Retrieves a value for the current key.
			-- Parameters:  valueKey - Name of the value to retrieve.
			-- Usage:       tscn.getValue("attribute_name")
			-- Returns:     The value associated with valueKey, or undefined if not found.
			
			local result = undefined
			if currentKeyIndex > 0 and currentKeyIndex <= size() then (
				for val in entries[currentKeyIndex].values do (
					if MatchPattern val.name pattern:valueKey ignoreCase:true do (
						result = val.data
						if MatchPattern val.data pattern:"false" ignoreCase:true or MatchPattern val.data pattern:"true" ignoreCase:true then (
							result = try(execute val.data)catch(val.data)
							)
						if MatchPattern val.data pattern:"Vector2(*" ignoreCase:true then (
							result = try(execute ("[" + (subString val.data 9 (val.data.count - 9)) + ", 0.0]"))catch(val.data)
							)
						if MatchPattern val.data pattern:"PackedVector2Array(*" ignoreCase:true then (
							local ss = filterString val.data "(, )"
							local c = ss.count
							if c > 2 do (
								local t = #()
								t[(c / 2) as integer] = [0.0, 0.0, 0.0]
								local i = 1, x = 0
								for i in 2 to c by 2 do (
									t[x+=1] = [try(ss[i] as float)catch(0.0), try(ss[i + 1] as float)catch(0.0), 0.0]
									)
								result = t
								)
							)
						if MatchPattern val.data pattern:"[PackedInt32Array(*" ignoreCase:true then (
							
							local ss = filterString val.data "[Pp]"
							local c = ss.count
							if c > 0 do (
								local t = #()
								local a = #()
								local k = 0
								a[c] = #()
								local i = 1, x = 1
								for i = 1 to c do (
									t = filterString ss[i] "(, )"
									k = t.count
									a[i] = #()
									if k > 1 do (
										k -= 1
										a[i][k] = 0
										for x = 1 to k do (
											a[i][x] = t[x + 1] as integer
											)
										)
									)
								result = a
								)
							)
						else (
							
							local isStr = false
							local isFloat = false
							local i = 1
							local c = val.data.count
							for i = 1 to c do (
								if not MatchPattern ".0123456789" pattern:("*" + val.data[i] + "*") ignoreCase:true then (
									isStr = true
									
									exit
									)
								else if val.data[i] == "." do isFloat = true
								)
							if not isStr do (
								if isFloat then (
									result = val.data as float
									)
								else (
									result = val.data as integer
									)
								)
							)
						exit
						)
					)
				) else (print "No Entries to Search")
			result 
			),
			
		fn getParam paramName = (
			-- Description: Retrieves a parameter for the current key.
			-- Parameters:  paramName - Name of the parameter.
			-- Usage:       tscn.getParam("param_name")
			-- Returns:     The value of the parameter, or undefined if not found.
			
			local result = undefined
			if currentKeyIndex > 0 and currentKeyIndex <= size() then (
				local paramsArray = entries[currentKeyIndex].params
				for param in paramsArray do (
					if MatchPattern param.name pattern:paramName ignoreCase:true do (
						result = param.data
						exit
						)
					)
				)
			result
			),
		
		fn setKey keyName = (
			-- Description: Inserts a new key after the current position or appends at the end if not found.
			-- Parameters:  keyName - Name of the key to add.
			-- Usage:       tscn.setKey("new_key_name")
			-- Returns:     true if added, false if already exists.
			
			local newPosition = 0
			
			-- If the key does not exist, insert it after currentKeyIndex or append if currentKeyIndex is not valid
			local newKey = f_TSCN_Key key:keyName -- Assuming f_TSCN_Key is a constructor or function to create a key entry
			
			if currentKeyIndex > 0 and currentKeyIndex <= size() then (
				newPosition = currentKeyIndex + 1
				insertItem newKey entries newPosition -- Insert the new key after currentKeyIndex
				)
			else (
				append entries newKey -- Append at the end if currentKeyIndex is not valid
				newPosition = size() -- The new position is the last one
				)
			
			currentKeyIndex = newPosition -- Update currentKeyIndex to the new key's position
			),
		
		fn setValue keyName valueName newValue = (
			-- Description: Adds or updates a value under a key.
			-- Parameters:  keyName, valueName, newValue - Key under which to add/update, the value name, and the new value.
			-- Usage:       tscn.setValue("key_name", "value_name", "new_value")
			-- Returns:     true if successful, otherwise false.
			
			local keyExists = false
			local valueExists = false
			
			-- Check if currentKeyIndex is valid and points to the correct key
			if currentKeyIndex > 0 and currentKeyIndex <= size() do (
				if MatchPattern entries[currentKeyIndex].key pattern:keyName ignoreCase:true do (
					keyExists = true
					-- Check and modify the value if it exists
					for val in entries[currentKeyIndex].values do (
						if MatchPattern val.name pattern:valueName ignoreCase:true do (
							val.data = newValue
							valueExists = true
							exit -- Value modified successfully
							)
						)
					-- Add the value if it doesn't exist
					if not valueExists do (
						append entries[currentKeyIndex].values (f_TSCN_Data name:valueName data:newValue)
						)
					)
				)
			
			-- If the key wasn't found using currentKeyIndex, search the entire list
			if not keyExists do (
				for i = 1 to size() do (
					if MatchPattern entries[i].key pattern:keyName ignoreCase:true do (
						currentKeyIndex = i -- Update currentKeyIndex with the found key
						keyExists = true
						-- Check and modify the value if it exists
						valueExists = false -- Reset valueExists for this new search
						for val in entries[i].values do (
							if MatchPattern val.name pattern:valueName ignoreCase:true do (
								val.data = newValue
								valueExists = true
								exit -- Value modified successfully
								)
							)
						-- Add the value if it doesn't exist
						if not valueExists do (
							append entries[i].values (f_TSCN_Data name:valueName data:newValue)
							)
						exit -- Key found and processed
						)
					)
				)
			
			-- If the key does not exist at all, add it and update currentKeyIndex
			if not keyExists do (
				local newValues = #(f_TSCN_Data name:valueName data:newValue)
				append entries (f_TSCN_Key key:keyName values:newValues params:#())
				currentKeyIndex = size() -- The new key is now the current key
				)
			
			-- Return true if key was found and value modified or added, else false
			keyExists or (not keyExists and not valueExists)
			),
		
		fn setParam keyName paramName newValue = (
			-- Description: Adds or updates a parameter under a key.
			-- Parameters:  keyName, paramName, newValue - Key to add/update the parameter under, parameter name, and new value.
			-- Usage:       tscn.setParam("key_name", "param_name", "new_value")
			-- Returns:     true if successful, otherwise false.
			
			local keyExists = false
			local paramExists = false
			
			-- Check if currentKeyIndex is valid and points to the correct key
			if currentKeyIndex > 0 and currentKeyIndex <= size() do (
				if MatchPattern entries[currentKeyIndex].key pattern:keyName ignoreCase:true do (
					keyExists = true
					-- Check and modify the param if it exists
					for param in entries[currentKeyIndex].params do (
						if MatchPattern param.name pattern:paramName ignoreCase:true do (
							param.data = newValue
							paramExists = true
							exit -- Param modified successfully
							)
						)
					-- Add the param if it doesn't exist
					if not paramExists do (
						append entries[currentKeyIndex].params (f_TSCN_Data name:paramName data:newValue)
						)
					)
				)
			
			-- If the key wasn't found using currentKeyIndex, search the entire list
			if not keyExists do (
				for i = 1 to size() do (
					if MatchPattern entries[i].key pattern:keyName ignoreCase:true do (
						currentKeyIndex = i -- Update currentKeyIndex with the found key
						keyExists = true
						-- Check and modify the param if it exists
						paramExists = false -- Reset paramExists for this new search
						for param in entries[i].params do (
							if MatchPattern param.name pattern:paramName ignoreCase:true do (
								param.data = newValue
								paramExists = true
								exit -- Param modified successfully
								)
							)
						-- Add the param if it doesn't exist
						if not paramExists do (
							append entries[i].params (f_TSCN_Data name:paramName data:newValue)
							)
						exit -- Key found and processed
						)
					)
				)
			
			-- If the key does not exist at all, add it with the param and update currentKeyIndex
			if not keyExists do (
				local newParams = #(f_TSCN_Data name:paramName data:newValue)
				append entries (f_TSCN_Key key:keyName values:#() params:newParams)
				currentKeyIndex = size() -- The new key is now the current key
				)
			
			-- Return true if key was found and param modified or added, else false
			return keyExists or (not keyExists and not paramExists)
			),
		
		fn delete keyName = (
			-- Description: Deletes a key and its associated data.
			-- Parameters:  keyName - Name of the key to delete.
			-- Usage:       tscn.delete("key_to_delete")
			-- Returns:     true if key was deleted, otherwise false.
			
			local result = false -- Key not found
			for i = size() to 1 by -1 do (
				if MatchPattern entries[i].key pattern:keyName ignoreCase:true do (
					deleteItem entries i
					result = true -- Key deletion successful
					)
				)
			if currentKeyIndex > size() do (
				currentKeyIndex = size()
				)
			result
			),
		
		fn children key:"" = (
			-- Description: Lists indices of children for a given or current key.
			-- Parameters:  key (optional) - Key to find children for.
			-- Usage:       tscn.children("optional_key")
			-- Returns:     Array of indices representing children of the given/current key.
			
			local childrenIndices = #()
			local index = currentKeyIndex
			if key != "" do (
				local j = 1
				for j = 1 to size() do (
					if MatchPattern key pattern:entries[j].key ignoreCase:true do (
						index = j
						exit
						)
					)
				)
			if index > 0 and index <= size() then (
				local parentKey = entries[index].key -- This is the parent node's key.
				local i = 1
				for i = 1 to size() do (
					local childEntry = entries[i]
					-- Check if the entry's parent matches the current node's key.
					if childEntry.parent == parentKey then (
						append childrenIndices i -- Add the index of the child to the list.
						)
					)
				)
			childrenIndices
			),
		
		fn fullname key:"" = (
			-- Description: Retrieves the parent name for a given or current key.
			-- Parameters:  key (optional) - Key to find the parent for.
			-- Usage:       tscn.fullname("optional_key")
			-- Returns:     Parent name of the given/current key, or empty if root.
			
			local parent_name = ""
			local index = currentKeyIndex
			if key != "" do (
				local j = 1
				for j = 1 to size() do (
					if MatchPattern key pattern:entries[j].key ignoreCase:true do (
						index = j
						exit
						)
					)
				)
			if index > 0 and index <= size() do (
				local entry = entries[index]
				local nodeName = entry.key -- Assuming 'key' holds the node name
				local parentName = getParam "parent" -- Access parent name/identifier
				
				-- Handling nodes without a parent parameter or root nodes
				if parentName == undefined or parentName == "." do (
					parentName = ""
					)
				
				parent_name = nodeName + (if parent_name != "" then "/" + parent_name else "")
				)
			parent_name
			),
		
		fn name = (
			-- Description: Retrieves the name of the current key.
			-- Parameters:  None.
			-- Usage:       tscn.name()
			-- Returns:     Name of the current key.
			
			getParam "name"
			),
		
		fn type = (
			-- Description: Retrieves the type of the current key.
			-- Parameters:  None.
			-- Returns:     tscn.type()
			-- Returns:     Type of the current key.
			
			getParam "type"
			),
		
		fn parent = (
			-- Description: Retrieves the parent of the current key.
			-- Parameters:  None.
			-- Usage:       tscn.parent()
			-- Returns:     Parent of the current key, or undefined if none.
			
			getParam "parent"
			)
		)
	
	local fpath = "" -- needed for texture loading
	local lastFile = ""
	local tscn = f_TSCN()
	local clear_scene = true
	local state = false
	
	fn import impUVs:true UvwMapIt:true = (
		/*
			only works with a single texture, too difficult to deal with assigning texture and approx. the uv space
		*/
		local nodeName = ""
		tscn.start()
		local i = 1
		local nodeArray = #()
		local parArray = #()
		local transArray = #()
		local typeArray = #()
		local count = tscn.size()
		local uvDim = [1024, 1024]
		local mat = undefined
		
		if impUVs do (
			
			local uvMinMax = #([0, 0], [0, 0])
			for i = 1 to count do (
				nodeType = tscn.type()
				if nodeType == "Polygon2D" do (
					local tvertices = tscn.getValue "uv"
					local c = tvertices.count
					local v = 1
					for v = 1 to c do (
						if tvertices[v][1] < uvMinMax[1][1] do uvMinMax[1][1] = tvertices[v][1]
						if tvertices[v][2] < uvMinMax[1][2] do uvMinMax[1][2] = tvertices[v][2]
						if tvertices[v][1] > uvMinMax[2][1] do uvMinMax[2][1] = tvertices[v][1]
						if tvertices[v][2] > uvMinMax[2][2] do uvMinMax[2][2] = tvertices[v][2]
						)
					)
				tscn.next()
				)
			uvDim = uvMinMax[2] - uvMinMax[1]
			uvDim = [(ceil(uvDim[1] / 8) * 8) as float, (ceil(uvDim[2] / 8) * 8) as float]
			tscn.start()
			)
		local poly2d_count = 0
		local layer_dist = 0.5
		local maxdepth = count * layer_dist
		for i = 1 to count do (
			
			nodeType = tscn.type()
			if nodeType == "Polygon2D" then (
				local vertices = tscn.getValue "polygon"
				local tvertices = tscn.getValue "uv"
				local faces    = tscn.getValue "polygons"
				
				local v = 1
				for v = 1 to vertices.count do (
					vertices[v] = [vertices[v][1], 0.0, -vertices[v][2]]
					)
				for v = 1 to tvertices.count do (
					tvertices[v] = [tvertices[v][1] / uvDim[1], 1.0-(tvertices[v][2] / uvDim[2]), 0.0]
					)
				
				-- Create a box and convert it to an Editable Poly
				local polyObj = convertToPoly (box length:0 width:0 height:0)
				
				-- Clear the initial geometry of the box
				polyOp.deleteFaces polyObj #{1..polyOp.getNumFaces polyObj} deleteIsoVerts:true
				
				-- Add vertices
				for v in vertices do (
					polyOp.createVert polyObj v
					)
				
				-- Add faces
				local f
				if faces != undefined then (
					for face in faces do (
						-- Create a new array with each index incremented by 1
						local incrementedFace = for f in face collect (f + 1)
						-- Reverse the order of the incrementedFace array
						local reversedFace = for i = incrementedFace.count to 1 by -1 collect incrementedFace[i]
						-- Use the reversedFace array for creating the polygon
						polyOp.createPolygon polyObj reversedFace
						)
					)
				else (
					-- If faces are undefined, generate a single N-Gon face using all vertices
					local allVertices = (#{1..vertices.count} as array)
					polyOp.createPolygon polyObj allVertices
					)
				
				
				if impUVs do (
					polyOp.setMapSupport polyObj 1 true -- activate map 1?
					polyop.setNumMapVerts polyObj 1 tvertices.count
					for v = 1 to tvertices.count do (
						-- Adjust tvertices[v] as necessary to match your UV data format
						polyOp.setMapVert polyObj 1 v tvertices[v]
						)
					-- Accessing the faces causes a crash?
					-- By chance I don't need to set faces but fuck
					)
					
					
				-- Update the poly object to reflect the changes
				--polyObj.backfacecull = on
				--polyObj.displayByLayer = false
				polyObj.wirecolor = random (color 0 0 0) (color 255 255 255)
				
				if mat != undefined do (
					polyObj.material = mat
					)
				
				update polyObj
				
				local node_name = tscn.name()
				if node_name != undefined do (polyObj.name = node_name)
				
				local isHidden = tscn.getValue "visible"
				--if isHidden != undefined and isHidden == false do (polyObj.isHidden = true)
				
				
				if UvwMapIt do (
					addModifier polyObj (Edit_Poly())
					local uvwMapMod = UVWMap axis:1 width:uvDim[1] length:uvDim[2]
					
					addModifier polyObj uvwMapMod
					select polyObj

					uvwMapMod.gizmo.position = [uvDim[1] / 2.0, 0.0, -(uvDim[2] / 2.0)]
					)
				
				
				local rot = try(tscn.getValue("rotation") as float)catch(undefined)
				if rot != undefined do (
				
					setUserProp polyObj "rotation" rot
					--print (RadToDeg (rot as float))
					
					polyObj.transform *= rotateYMatrix (RadToDeg rot)
					)
				local pos = tscn.getValue("position")
				if pos != undefined do (
					setUserProp polyObj "position" pos
					polyObj.position = [pos[1], (layer_dist + ((poly2d_count+=1) * -0.5)), -pos[2]]
					)
				
				local tex = tscn.getValue("texture")
				if tex != undefined do (
					setUserProp polyObj "texture" tex
					setUserProp polyObj "uv_scale" uvDim
					)
				
				local skel = tscn.getValue("skeleton")
				if skel != undefined do (
					setUserProp polyObj "skeleton" skel
					)
				
				append nodeArray polyObj
				append typeArray #polygon2d
				append parArray (tscn.parent())
				append transArray polyObj.transform
				)
			else if nodeType == "Node2D" then (
				local b = Point cross:off Box:on wireColor:(color 0 252 252)
				b.position = [0.0, 0.0, 0.0]
				local node_name = tscn.name()
				if node_name != undefined do (b.name = node_name)
				local isHidden = tscn.getValue "visible"
				if isHidden != undefined and isHidden == false do (b.isHidden = true)
				append nodeArray b
				append typeArray #node2d
				append parArray (tscn.parent())
				append transArray b.transform
				)
			else if nodeType == "Skeleton2D" then (
				local b = Dummy()
				b.position = [0.0, 0.0, 0.0]
				local node_name = tscn.name()
				if node_name != undefined do (b.name = node_name)
				local isHidden = tscn.getValue "visible"
				if isHidden != undefined and isHidden == false do (b.isHidden = true)
				append nodeArray b
				append typeArray #skeleton2d
				append parArray (tscn.parent())
				append transArray b.transform
				)
			else if nodeType == "Bone2D" then (
				
				
				
				
				
				local b = BoneSys.createBone [0.0, 0.0, 0.0] [1.0, 0.0, 0.0] [1,0,0]
				b.transform = matrix3 1
				b.showLinksOnly = b.showLinks = true
				
				local node_name = tscn.name()
				if node_name != undefined do (b.name = node_name)
				
				local len = tscn.getValue("length")
				if len != undefined do (b.length = len)
				
				
				
				local ang = tscn.getValue("bone_angle")
				local rot = try(tscn.getValue("rotation") as float)catch(undefined)
				if rot != undefined then (
				
					setUserProp b "rotation" rot
					b.transform *= rotateYMatrix (RadToDeg rot)
					
					)
				else if ang != undefined then (
					b.transform *= rotateYMatrix (ang as float)
					)
				
				local pos = tscn.getValue("position")
				if pos != undefined then (
					setUserProp b "position" pos
					b.position = [pos[1], 0.0, -pos[2]]
					)
				
				
				
				local npar = tscn.getValue("auto_calculate_length_and_angle")
				if npar != undefined do (setUserProp b "auto_calculate_length_and_angle" npar)
				
				local rest = tscn.getValue("rest")
				if rest != undefined do (setUserProp b "rest" npar)
				
				
				append nodeArray b
				append typeArray #bone2d
				append parArray (tscn.parent())
				append transArray b.transform
				)
			else if nodeType == "Texture2D" then (
				fileProperties.addProperty #custom ("TSCN " + tscn.entries[i].key) (tscn.entries[i] as string)
				local tex = tscn.getParam "path"
				if mat == undefined and tex != undefined do (
					
					tex = fpath + (filenameFromPath tex)
					if doesFileExist tex do (
						mat = StandardMaterial()
						mat.diffuseMap = Bitmaptexture fileName:tex
						mat.diffuseMap.alphaSource = 2
						mat.opacityMap = Bitmaptexture fileName:tex
						mat.opacityMap.alphaSource = 0
						mat.opacityMap.preMultAlpha = off
						mat.opacityMap.rgbOutput = 1
						mat.opacityMap.monoOutput = 1
						showTextureMap mat on
						)
					
					)
				)
			else (
				--format "Node: % (%)\n" i (tscn.type())
				fileProperties.addProperty #custom ("TSCN " + tscn.entries[i].key) (tscn.entries[i] as string)
				--print (tscn.entries[i] as string)
				)
			tscn.next()
			)
		
		-- Build a Parenting Map
		local ppathArray = #() -- parent path
		ppathArray[count] = ""
		for i = 1 to count do (
			ppathArray[i] = "."
			if nodeArray[i] == undefined or parArray[i] == undefined do continue
			if parArray[i] == "." then (
				ppathArray[i] = (nodeArray[i].name)
				)
			else (
				ppathArray[i] = (parArray[i] + "/" + nodeArray[i].name)
				)
			)
		
		-- Convert Local transforms to World
		local par_index = 0
		for i = 1 to count do (
			if nodeArray[i] == undefined or parArray[i] == undefined do continue
			
			-- New Method
			par_index = 0
			if parArray[i] != "." do (
				par_index = findItem ppathArray parArray[i]
				)
			while par_index > 0 do (
				nodeArray[i].transform *= transArray[par_index]
				if parArray[par_index] != "." then (
					par_index = findItem ppathArray parArray[par_index]
					) else (par_index = 0)
				)
			)
		for i = 1 to count do (
			if nodeArray[i] == undefined or parArray[i] == undefined do continue
			
			-- New Method
			par_index = 0
			if parArray[i] != "." do (
				par_index = findItem ppathArray parArray[i]
				if par_index > 0 do (
					nodeArray[i].parent = nodeArray[par_index]
					)
				)
			)
		
		-- Apply Weight
		setCommandPanelTaskMode #modify
		tscn.currentKeyIndex = 0
		for i = 1 to count do (
			tscn.next()
			nodeType = tscn.type()
			if nodeType == "Polygon2D" do (
				local skel = 
				local weights = tscn.getValue "bones"
				local skel = tscn.getValue "skeleton"
				
				if skel != undefined then (
					skel_ss = filterString skel "(/\")"
					skel = skel_ss[skel_ss.count] + "/"
					
					) else (skel = "")
				
				
				if weights == undefined do continue
				local nodeParent = tscn.parent()
				local nodeName = tscn.name()
				if nodeParent == "." do (
					nodeParent = ""
					)

				local node_index = findItem ppathArray (nodeParent + "/" + nodeName)
				local node_obj = nodeArray[node_index]
				local numVerts = node_obj.numverts
				local weightsData = filterString weights "()"
				local weight_data_count = weightsData.count - 1
				local x = 0
				local weightArray = #()
				local boneIdArray = #()
				for x = 1 to weight_data_count by 2 do (
					local node_path = subString weightsData[x] 2 (weightsData[x].count - 2)
					local str_index = findString weightsData[x + 1] ", \""
					if str_index != undefined do (
						weightsData[x + 1] = subString weightsData[x + 1] (str_index + 1) -1
						)
					local weightValues_str = "#(" + weightsData[x + 1] + ")"
					local weightValues = execute weightValues_str
					if weightValues.count != numVerts do (
						format "Invalid Weights % <> %\n\n" weightValues.count numVerts
						continue
						)
					local k = 1
					for k in weightValues where k > 0 do (
						str_index = findString node_path "\", P"
						if str_index != undefined do (
							node_path = subString node_path 1 (str_index - 1)
							)
						str_index = findString node_path " \""
						if str_index != undefined do (
							node_path = subString node_path (str_index + 2) -1
							)
						append weightArray weightValues
						append boneIdArray (findItem ppathArray (skel + node_path))
						exit
						)
					node_path = undefined
					weightValues = undefined
					)
				
				-- Check if any weights were collected
				local num_influences = weightArray.count
				--format "num_influences: \t% (%)\n" num_influences boneIdArray.count
				if num_influences > 0 do (
					
					-- Normalize Weights
					local j = 1, v = 1
					local total_weight = 0.0
					local weight_div = 1.0
					for v = 1 to numVerts do (
						total_weight = 0.0
						for j = 1 to num_influences do (
							total_weight += weightArray[j][v] as float
							)
						weight_div = 1.0 / total_weight
						for j = 1 to num_influences do (
							weightArray[j][v] = (weightArray[j][v] as float) * weight_div
							)
						)
					
					
					-- Import Weights
					local skinMod = skin() -- apply a skin modifier
					addModifier node_obj skinMod ui:off
					
					-- assign bones to skin modifier, from the weight pallete
					for x = 1 to num_influences do (
						skinOps.addbone skinMod nodeArray[boneIdArray[x]]  (
							if i == num_influences then 1 else 0
							)
						)
					
					-- get names of bones in skin list
					local bne_name = "", z = 0
					local boneMap = #(), bone_index = 1
					boneMap[nodeArray.count] = 1
					for x = 1 to num_influences do (
						bne_name = skinOps.GetBoneName skinMod x 0
						for z = 1 to num_influences do (
							if bne_name == nodeArray[boneIdArray[x]].name do (
								boneMap[boneIdArray[x]] = x
								
								)
							
							)
						
						)

					
					-- apply weights to skin modifier
					modPanel.setCurrentObject skinMod
					local p = 1, bi = #(), bw = #()
					--format "boneMap: \t%\n" (boneMap as string)
					for x = 1 to numVerts do (
						bi = #()
						bw = #()

						for p = 1 to num_influences do (
							
							if weightArray[p][x] > 0.0000001 do (
								
								append bw weightArray[p][x]
								append bi boneMap[boneIdArray[p]]
								)
							
							)
						if bw.count > 0 do (
							skinOps.ReplaceVertexWeights skinMod x bi bw
							)
						)
					
					if skinOps.isWeightToolOpen skinMod == 0 do (
						skinOps.WeightTool skinMod
						)
					skinMod.filter_vertices = on
					
					
					
					
					)
				
				
				)
			
			)
		)
	
	fn reorderMeshDataFor2DEngine_simple vertexList uvList faceList boneIDList weightList = (
		local edgeMap = #() -- Using an array to keep edge strings
		local vertexMap = #() -- Map original vertex indices to new indices
		local borderVertices = #() -- Store border vertex indices
		local internalVertices = #() -- Store internal vertex indices
		local newVertexList = #()
		local newUVList = #()
		local newFaceList = #()
		local newBoneIDList = #()
		local newWeightList = #()

		-- Detect Border Edges
		for face in faceList do (
			for i = 1 to face.count do (
				local startVertex = face[i]
				local endVertex = face[if i == face.count then 1 else i + 1]
				local edge = if startVertex < endVertex then (startVertex as string + "-" + endVertex as string) else (endVertex as string + "-" + startVertex as string)
				
				-- Check if edge is not in edgeMap yet, consider it a border edge; otherwise, remove it (indicating it's an internal edge)
				if not (findItem edgeMap edge) > 0 then (
					append edgeMap edge -- Add unique edge
					)
				else (
					deleteItem edgeMap (findItem edgeMap edge) -- Remove edge, it's shared by two faces
					)
				)
			)
		
		-- Extract border vertex indices from edgeMap
		for edge in edgeMap do (
			local vertices = filterString edge "-" as array
			for vertex in vertices do (
				local vertexIndex = (vertex as integer)
				if not (findItem borderVertices vertexIndex) > 0 do (
					append borderVertices vertexIndex
					)
				)
			)

		-- Calculate centroid of border vertices
		local centroid = [0, 0, 0]
		for v in borderVertices do (
			centroid += [vertexList[v].x, 0, vertexList[v].z]
			)
		centroid /= borderVertices.count

		-- Pre-calculate angles for sorting
		local angles = #()
		for v in borderVertices do (
			local pos = [vertexList[v].x, 0, vertexList[v].z]
			local angle = atan2 (pos.z - centroid.z) (pos.x - centroid.x)
			append angles (angle as float)
			)

		-- Simple sort borderVertices based on pre-calculated angles
		for i = 1 to borderVertices.count do (
			for j = i + 1 to borderVertices.count do (
				if angles[i] > angles[j] then (
					swap borderVertices[i] borderVertices[j]
					swap angles[i] angles[j]
					)
				)
			)

		-- Reorder Vertex Data
		for vertexIndex in borderVertices do (
			append newVertexList vertexList[vertexIndex]
			append newUVList uvList[vertexIndex]
			append newBoneIDList boneIDList[vertexIndex]
			append newWeightList weightList[vertexIndex]
			vertexMap[vertexIndex] = newVertexList.count
			)

		-- Append internal vertices
		for i = 1 to vertexList.count do (
			if not findItem borderVertices i > 0 do (
				append internalVertices i -- Collect internal vertices
				append newVertexList vertexList[i]
				append newUVList uvList[i]
				append newBoneIDList boneIDList[i]
				append newWeightList weightList[i]
				vertexMap[i] = newVertexList.count
				)
			)

		-- Reconstruct faceList with new vertex indices
		for face in faceList do (
			local newFace = for vertexIndex in face collect vertexMap[vertexIndex]
			append newFaceList newFace
			)

		-- Return reordered data and number of internal vertices
		#(newVertexList, newUVList, newFaceList, newBoneIDList, newWeightList, internalVertices.count)
		)
	
	fn selectOuterBorderVertices obj threshold = (
		local nnl = #()
		maxOps.cloneNodes #(obj) cloneType:#copy newNodes:&nnl #nodialo
		
		local clone = nnl[1]--copy obj
		convertToPoly clone 
		clone.weldThreshold = threshold
		polyOp.weldVertsByThreshold clone #{1..polyOp.getNumVerts clone}

		local borderEdges = #()
		local edgeToVerts = #()
		for edgeIndex = 1 to polyOp.getNumEdges clone do (
			local edgeFaces = polyOp.getEdgeFaces clone edgeIndex
			if edgeFaces.count == 1 do (
				local verts = polyOp.getEdgeVerts clone edgeIndex
				append borderEdges edgeIndex
				edgeToVerts[edgeIndex] = verts
				)
			)

		local sortedVertices = #()
		local visitedEdges = #{}
		local currentVert

		-- Find an extremal vertex as a starting point to ensure we're on the outer border
		local minY = 1e9
		local startVert
		for edge in borderEdges do (
			local verts = edgeToVerts[edge]
			for vert in verts do (
				local vertPos = polyOp.getVert clone vert
				if vertPos.y < minY do (
					minY = vertPos.y
					startVert = vert
					)
				)
			)
		currentVert = startVert
		append sortedVertices startVert

		-- Improved edge traversal logic
		while borderEdges.count > 0 do (
			local found = false
			for edge in borderEdges where not visitedEdges[edge] do (
				local verts = edgeToVerts[edge]
				if findItem verts currentVert > 0 do (
					appendIfUnique sortedVertices (if verts[1] == currentVert then verts[2] else verts[1])
					currentVert = (if verts[1] == currentVert then verts[2] else verts[1])
					visitedEdges[edge] = true
					deleteItem borderEdges (findItem borderEdges edge)
					found = true
					exit
					)
				)
			if not found do exit
			)

		-- Convert vertex indices to positions and print them
		local edgeverts = for v in sortedVertices collect (
			local vertPos = polyOp.getVert clone v
			--format "Vertex %: [%, %, %]\n" v vertPos.x vertPos.y vertPos.z
			)
		delete clone
		edgeverts
		)
	
	fn reorderMeshDataFor2DEngine vertexList uvList faceList boneIDList weightList sortedBorderVertices = (
		local newVertexList = #()
		local newUVList = #()
		local newFaceList = #()
		local newBoneIDList = #()
		local newWeightList = #()
		local vertexMap = #() -- Map original vertex indices to new indices
		local internalVertices = #() -- Store internal vertex indices

		-- Assuming sortedBorderVertices contains vertex positions, find their original indices
		local borderVertexIndices = for v in sortedBorderVertices collect (
			findItem vertexList v
			)

		-- Reorder Vertex Data based on sorted border vertices
		for vertexIndex in borderVertexIndices do (
			append newVertexList vertexList[vertexIndex]
			append newUVList uvList[vertexIndex]
			if boneIDList.count >= vertexIndex do (
				append newBoneIDList boneIDList[vertexIndex]
				)
			if weightList.count >= vertexIndex do (
				append newWeightList weightList[vertexIndex]
				)
			vertexMap[vertexIndex] = newVertexList.count
			)

		-- Append internal vertices not included in the sorted border vertices
		for i = 1 to vertexList.count do (
			if not findItem borderVertexIndices i > 0 do (
				append internalVertices i -- Collect internal vertices
				append newVertexList vertexList[i]
				append newUVList uvList[i]
				if boneIDList.count >= i do (
					append newBoneIDList boneIDList[i]
					)
				if weightList.count >= i do (
					append newWeightList weightList[i]
					)
				vertexMap[i] = newVertexList.count
				)
			)

		-- Reconstruct faceList with new vertex indices
		for face in faceList do (
			local newFace = for vertexIndex in face collect (
				if vertexMap[vertexIndex] != undefined then (
					vertexMap[vertexIndex]
					)
				else (
					0 -- Placeholder in case of mapping error
					)
				)
			append newFaceList newFace
			)

		-- Return reordered data and number of internal vertices
		#(newVertexList, newUVList, newFaceList, newBoneIDList, newWeightList, internalVertices.count)
		)
	
	fn export precision:6 = (
		
		-- Init the file
		tscn = f_TSCN()
		
		-- Write Scene Information
		tscn.setKey("gd_scene")
		tscn.setParam "gd_scene" "load_steps" "2"
		tscn.setParam "gd_scene" "format" "3"
		tscn.setParam "gd_scene" "uid" ("uid://" + ((random 1 99999999) as string))
		
		-- Write Scene Resources, such as textures
		tscn.setKey("ext_resource")
		tscn.setParam "ext_resource" "type" "Texture2D"
		tscn.setParam "ext_resource" "uid" ("uid://" + ((random 1 99999999) as string))
		tscn.setParam "ext_resource" "path" "res://Assets/atlas.png"
		tscn.setParam "ext_resource" "id" "1"
		
		-- Write Starting Scene Node
		tscn.setKey("node")
		tscn.setParam "node" "name" "char01"
		tscn.setParam "node" "type" "Node2D"
		
		-- Get modify Panel Ready to access modifiers in 3ds max
		setCommandPanelTaskMode #modify
		
		-- Collect Bones from 3ds max scene
		local b = undefined
		local armarture_name = "Skeleton2D"
		local boneArray = for b in objects where classof b == BoneGeometry collect b
		
		-- Generate Bone Paths, needed for Polygon2D weights
		local bonePathArray = #()
		for b in boneArray do (
			local parentPath = ""
			local parent = b.parent
			while parent != undefined do (
				if parentPath.count == 0 then (
					parentPath = parent.name + parentPath
					)
				else (
					parentPath = parent.name + "/" + parentPath
					)
				parent = parent.parent
				)
			append bonePathArray parentPath
			)
		
		-- Collect Meshes from 3ds max scene
		local pf = "#." + (precision as string) + "f" -- float to string presicion
		local polyObj = undefined
		local meshArray = for polyObj in objects where findItem #(Editable_Mesh, Editable_Poly, PolyMeshObject) (classof polyObj) > 0 collect polyObj
		if meshArray.count > 0 do (
			
			-- Write start of mesh parent node
			local meshnode_name = "Meshes"
			local texture_path = "ExtResource(\"1\")"
			local skeleon_path = "NodePath(\"../../Skeleton2D\")"
			
			tscn.setKey("node")
			tscn.setParam "node" "name" meshnode_name
			tscn.setParam "node" "type" "Node2D"
			tscn.setParam "node" "parent" "."
			
-- 			local i = 1
-- 			print "BEFORE"
-- 			print meshArray
-- 			for i = 1 to meshArray.count-1 do (
-- 				for j = 1 to meshArray.count-i do (
-- 					if (meshArray[j].position.y < meshArray[j+1].position.y) then (
-- 						swap meshArray[j] meshArray[j+1]
-- 						)
-- 					)
-- 				)
-- 			print "AFTER"
-- 			print meshArray
-- 			
			
			for polyObj in meshArray do (
				
				-- Generate Path for Mesh
				local parentPath = ""
				local parent = polyObj.parent
				while parent != undefined do (
					if parentPath.count == 0 then (
						parentPath = parent.name + parentPath
						)
					else (
						parentPath = parent.name + "/" + parentPath
						)
					parent = parent.parent
					)
				
				-- Write Start of New Mesh Node
				tscn.setKey("node")
				tscn.setParam "node" "name" polyObj.name
				tscn.setParam "node" "type" "Polygon2D"
				tscn.setParam "node" "parent" (if parentPath == "" then meshnode_name else parentPath)
				
				local tfm = polyObj.transform
				if polyObj.parent != undefined do (
					tfm *= inverse polyObj.parent.transform
					)
				
				tscn.setValue "node" "position" ("Vector2(" + (formattedPrint tfm.position.x format:pf) + ", " + (formattedPrint -tfm.position.z format:pf) + ")")
				
				local rot = degToRad (quatToEuler2 tfm.rotationPart).y
				local setRot = abs rot > (1.0 / 10000.0)
				
				if setRot do (
					tscn.setValue "node" "rotation" (formattedPrint rot format:pf)
					)
				
				-- Placeholders for setting the skeleton and texture
				tscn.setValue "node" "texture" texture_path
				tscn.setValue "node" "skeleton" skeleon_path
				
				-- Read Geometry from 3ds max scene
				local vertexList = #()
				local uvList = #()
				local faceList = #()
				local uvFaceList = #() -- Added to store UV faces
				local boneIDList = #() -- List to store bone IDs for each vertex
				local weightList = #() -- List to store weights for each vertex
				local uniqueVertUVMap = #()
				local skinMod = polyObj.modifiers[#Skin]
				local skinBoneNames = #()
				local i = 1, j = 1
				if skinMod != undefined do (
					local numSkinBones = skinOps.GetNumberBones skinMod
					if numSkinBones > 0 do (
						skinBoneNames[numSkinBones] = ""
						for i = 1 to numSkinBones do (
							skinBoneNames[i] = skinOps.GetBoneName skinMod i 0
							for j = 1 to boneArray.count do (
								if boneArray[j].name == skinBoneNames[i] do (
									if bonePathArray[j] != "" and bonePathArray[j] != "." then (
										skinBoneNames[i] = bonePathArray[j] + "/" + boneArray[j].name
										)
									else (
										skinBoneNames[i] = boneArray[j].name
										)
									
									if MatchPattern skinBoneNames[i] pattern:(armarture_name + "*") do (
										
										skinBoneNames[i] = subString skinBoneNames[i] (armarture_name.count + 2) -1
										)
									
									exit
									)
								)
							)
						)
					)
				
				local objType = classOf polyObj
				if objType == Editable_mesh then (
					--local hasUVMap = meshop.getMapSupport polyObj 1
					local numFaces = getNumFaces polyObj
					for i = 1 to numFaces do (
						local faceVerts = getFace polyObj i
						local mapFaces = meshop.getMapFace polyObj 1 i -- Correctly get the UV face
						local faceData = #()
						local uvFaceData = #() -- For storing the UV indices of the current face
						for j = 1 to 3 do ( -- Assuming triangulated mesh, so always 3 vertices per face
							local vert = getVert polyObj faceVerts[j]
							local uvIndex = mapFaces[j] -- Correctly use the UV index from the UV face
							local uv = meshop.getMapVert polyObj 1 uvIndex
							uvFaceData[j] = uvIndex -- Store the UV index for this vertex in the face
							
							local boneWeights = ""
							local boneIDs = #()
							local weights = #()
							if skinMod != undefined do (
								local vertID = faceVerts[j] -- Direct vertex ID for skinOps
								local weightCount = skinOps.GetVertexWeightCount skinMod vertID
								for weightIndex = 1 to weightCount do (
									local boneID = skinOps.GetVertexWeightBoneID skinMod vertID weightIndex
									local weight = skinOps.GetVertexWeight skinMod vertID weightIndex
									if weight > 0.000001 then (
										if boneWeights != "" do (
											boneWeights += "#"
											)
										boneWeights += (boneID as string + ":" + (formattedPrint weight format:"#.6f"))
										append boneIDs boneID
										append weights weight
										)
									)
								)
							local vertUVKey = (formattedPrint vert + "|" + formattedPrint uv + "|" + boneWeights)
							local index = findItem uniqueVertUVMap vertUVKey
							if index == 0 do (
								append vertexList vert
								append uvList uv
								append uniqueVertUVMap vertUVKey
								append boneIDList boneIDs
								append weightList weights
								index = uniqueVertUVMap.count
								)
							append faceData index
							)
						append faceList faceData
						append uvFaceList uvFaceData -- Append the UV face data to the list
						)
					)
				else if objType == PolyMeshObject or objType == Editable_Poly then (
					
					
					--local hasUVMap = polyop.getMapSupport polyObj 1
					for faceIndex = 1 to polyOp.getNumFaces polyObj do (
						local faceVerts = polyOp.getFaceVerts polyObj faceIndex
						local uvFace = polyOp.getMapFace polyObj 1 faceIndex
						local faceData = #()
						
						for j = 1 to faceVerts.count do (
							local vert = polyOp.getVert polyObj faceVerts[j]
							local uvVertIdx = uvFace[j]
							local uv = polyOp.getMapVert polyObj 1 uvVertIdx
							local boneWeights = ""
							local boneIDs = #()
							local weights = #()
							
							if skinMod != undefined do (
								local weightCount = skinOps.GetVertexWeightCount skinMod faceVerts[j]
								for weightIndex = 1 to weightCount do (
									local boneID = skinOps.GetVertexWeightBoneID skinMod faceVerts[j] weightIndex
									local weight = skinOps.GetVertexWeight skinMod faceVerts[j] weightIndex
									if weight > 0.000001 then (
										if boneWeights != "" do (
											boneWeights += "#"
											)
										boneWeights += (boneID as string + ":" + (formattedPrint weight format:"#.6f"))
										append boneIDs boneID
										append weights weight
										)
									)
								)
							
							local vertUVKey = (formattedPrint vert + "|" + formattedPrint uv + "|" + boneWeights)
							local index = findItem uniqueVertUVMap vertUVKey
							if index == 0 do (
								append vertexList vert
								append uvList uv
								append uniqueVertUVMap vertUVKey
								append boneIDList boneIDs
								append weightList weights
								index = uniqueVertUVMap.count
								)
							append faceData index
							)
						append faceList faceData
						)
					)
				
				-- Check Data was valid
				local str = ""
				local ltfm = matrix3 1
				if vertexList.count > 0 do (
					
					-- Sort Vertex Data
					local orderedVertexData = reorderMeshDataFor2DEngine vertexList uvList faceList boneIDList weightList (selectOuterBorderVertices polyObj 0.01)
					vertexList = orderedVertexData[1]
					uvList = orderedVertexData[2]
					faceList = orderedVertexData[3]
					boneIDList = orderedVertexData[4]
					weightList = orderedVertexData[5]
					local numInternalVertices = orderedVertexData[6] as integer
					
					
					for i = 1 to vertexList.count do (
						if str.count > 0 do (str += ", ")
						
						ltfm =  (transMatrix vertexList[i]) * inverse (polyObj.transform)
						
						
						str += (formattedPrint ltfm.row4.x format:pf) + ", " + (formattedPrint -ltfm.row4.z format:pf)
						)
					tscn.setValue "node" "polygon" ("PackedVector2Array(" + str + ")")
					
					str = ""
					local uv_scale = try(execute (getUserProp polyObj "uv_scale"))catch([1024, 1024])
					
					
					for i = 1 to uvList.count do (
						if str.count > 0 do (str += ", ")
						str += (
							
							(formattedPrint (uvList[i][1] * uv_scale[1]) format:pf) + ", " + \
							(formattedPrint ((1.0-uvList[i][2]) * uv_scale[2]) format:pf)
							)
						)
					tscn.setValue "node" "uv" ("PackedVector2Array(" + str + ")")
					
					str = ""
					local fstr = ""
					for i = 1 to faceList.count do (
					
						fstr = ""
						if str.count > 0 do (str += ", ")
						for j = 1 to faceList[i].count do ( --for j in faceList[i].count to 1 by -1 do 
							if fstr.count > 0 do (fstr += ", ")
							fstr += ((faceList[i][j] - 1) as integer) as string
							)
						str += "PackedInt32Array(" + fstr + ")"
						)
					tscn.setValue "node" "polygons" ("[" + str + "]")
					if numInternalVertices > 0 do (
						tscn.setValue "node" "internal_vertex_count" (numInternalVertices as string)
						)
					
					if skinBoneNames.count > 0 do (
						str = ""
						local v = 1
						
						local normalize_mode = 2
						
						
						local weight2_scale = #()
						if normalize_mode == 2 do (
							weight2_scale[skinBoneNames.count] = 1.0 --  vertex count
							for i = 1 to skinBoneNames.count do (
								weight2_scale[i] = 1.0
								local max_weight = 0.0
								
								for v = 1 to boneIDList.count do ( -- check each vertex
									for j = 1 to boneIDList[v].count do ( -- check each bone id
										if boneIDList[v][j] == i and weightList[v][j] > max_weight do (
											max_weight = weightList[v][j]
											)
										)
									)
								if max_weight > 0.0 do (
									weight2_scale[i] = 1.0 / max_weight
									)
								)
							)
						
						for i = 1 to skinBoneNames.count do ( -- loop through each bone id
							
							fstr = ""
							if str.count > 0 do (str += ", ")
							
							local weight_scale = 1.0
							if normalize_mode == 1 do (
								local max_weight = 0.0
								for v = 1 to boneIDList.count do ( -- loop through each vertex
									for j = 1 to boneIDList[v].count do ( -- search bone id
										if boneIDList[v][j] == i do (
											if weightList[v][j] > max_weight do (
												max_weight = weightList[v][j]
												)
											exit
											)
										)
									)
								
								if max_weight > 1.0 do (
									weight_scale = 1.0 / max_weight
									)
								)
							for v = 1 to boneIDList.count do ( -- loop through each vertex
								local weight = 0
								if fstr.count > 0 do (fstr += ", ")
								for j = 1 to boneIDList[v].count do ( -- search bone id
									if boneIDList[v][j] == i do (
										weight = weightList[v][j]
										
										if normalize_mode == 1 then (
											weight = ceil(weight * weight_scale * 10^2) / 10^2
											)
										else if normalize_mode == 2 then (
											weight = weight * weight2_scale[i]
											)
										
										exit
										)
									)
								fstr += formattedPrint weight format:pf
								)
							
							str += "\"" + skinBoneNames[i] + "\", PackedFloat32Array(" + fstr + ")"
							)
						tscn.setValue "node" "bones" ("[" + str + "]")
						)
					
					-- Free Arrays
					str = undefined
					fstr = undefined
					vertexList = undefined
					uvList = undefined
					faceList = undefined
					boneIDList = undefined
					weightList = undefined
					skinBoneNames = undefined
					)
				)
			)
		
		if boneArray.count > 0 do (
			
			tscn.setKey("node")
			tscn.setParam "node" "name" armarture_name
			tscn.setParam "node" "type" armarture_name
			tscn.setParam "node" "parent" "."
			
			for b in boneArray do (
				
				local parentPath = ""
				local parent = b.parent
				local re = quatToEuler2 b.rotation
				while parent != undefined do (
					if parentPath.count == 0 then (
						parentPath = parent.name + parentPath
						)
					else (
						parentPath = parent.name + "/" + parentPath
						)
					parent = parent.parent
					)

				
				tscn.setKey("node")
				tscn.setParam "node" "name" b.name
				tscn.setParam "node" "type" "Bone2D"
				tscn.setParam "node" "parent" (if parentPath == "" then armarture_name else parentPath)
				
				local hasChilds = (try(b.children.count)catch(0)) > 0
				
				local tfm = b.transform
				
				if hasChilds do (
					tfm = transMatrix b.position
					
					)
				
				local ptfm = matrix3 1
				if b.parent != undefined do (
					--ptfm = b.parent.transform
					if b.parent.children.count > 0 do (
						
						ptfm = transMatrix b.parent.position
						)
					
					)
				
				tfm *= inverse ptfm
				
				tscn.setValue "node" "position" ("Vector2(" + (formattedPrint tfm.position.x format:pf) + ", " + (formattedPrint -tfm.position.z format:pf) + ")")
				
				local rot = degToRad (quatToEuler2 tfm.rotationPart).y
				
				local setRot = abs rot > (1.0 / 10000.0)
				
				if hasChilds and setRot do (
					tscn.setValue "node" "rotation" (formattedPrint rot format:pf)
					)
				
				if not hasChilds then (
					tscn.setValue "node" "rest" (
						"Transform2D(1, 0, 0, 1, " + \
						(formattedPrint tfm.row4.x format:pf) + ", " + \
						(formattedPrint tfm.row4.z format:pf) + ")"
						)
					tscn.setValue "node" "auto_calculate_length_and_angle" "false"
					tscn.setValue "node" "length" (try(b.length as string)catch("1"))
					rot =  (quatToEuler2 tfm.rotationPart).y
					tscn.setValue "node" "bone_angle" (formattedPrint (if rot < 0.0 then rot + 360.0 else rot) format:pf)
					)
				else (
					tfm =  ((rotateYMatrix (RadToDeg rot)) * (transMatrix [tfm.position.x, 0.0, -tfm.position.z]))
					tscn.setValue "node" "rest" (
						"Transform2D(" + \
						(formattedPrint tfm.row1.x format:pf) + ", " + \
						(formattedPrint tfm.row1.z format:pf) + ", " + \
						(formattedPrint tfm.row3.x format:pf) + ", " + \
						(formattedPrint tfm.row3.z format:pf) + ", " + \
						(formattedPrint tfm.row4.x format:pf) + ", " + \
						(formattedPrint tfm.row4.z format:pf) + ")"
						)
					)
				)
			)
		)
	
	fn open file = (
		local result = false
		if file != undefined and file != "" do (
			if tscn != undefined and classOf f_TSCN != UndefinedClass then (
				tscn = f_TSCN()
				fpath = getFilenamePath file
				tscn.open(lastFile = file)
				if lastFile != "" do (fileProperties.addProperty #custom "tscn_filepath" lastFile)
				undo off (
					with redraw off (
						if clear_scene do (delete $*)
						import()
						result = true
						messageBox "Imported"
						)
					)
				) else (messageBox "Failed To find structure")
			)
		result
		)
	
	fn save file = (
		local result = false
		if file != undefined and file != "" do (
			if tscn != undefined and classOf f_TSCN != UndefinedClass do (
				undo off (
					with redraw off (
						export()
						)
					)
				tscn.save(file)
				result = true
				messageBox "Exported"
				)
			)
		result
		)
	
	on btn_open pressed do (
		local file = GetOpenFileName types:"Godot Text Scene (*.tscn)|*.tscn|All files (*.*)|*.*|"
		if file != undefined do (open(lastFile = file))
		)
	
	on btn_save pressed do (
		if lastFile != undefined and lastFile != "" then (
			lastFile = (getFilenamePath lastFile) + (getFilenameFile lastFile) + "_new.tscn"
			) else (lastFile = "")
		if lastFile == undefined or lastFile == "" do (
			local propertyIndex = fileProperties.findProperty #custom "tscn_filepath"
			if propertyIndex != 0 do (
				lastFile = fileProperties.getPropertyValue #custom "tscn_filepath"
				lastFile = (getFilenamePath lastFile) + (getFilenameFile lastFile) + "_new.tscn"
				)
			)
		save(GetSaveFileName types:"Godot Text Scene (*.tscn)|*.tscn|All files (*.*)|*.*|" filename:lastFile)
		)
	
	on chk_clear changed state do (clear_scene = state)
	
	)
CreateDialog tscn_tool
--tscn_tool.open("C:\\Users\\Corey\\Documents\\Godotv4\\New Game Project\\Assets\\Char03\\OIG2.tscn")


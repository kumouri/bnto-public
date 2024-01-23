if not Kmo then
    _G.Kmo = {}
    Kmo.loadedPlugins = {}
end

if not Kmo.loadedPlugins then
    Kmo.loadedPlugins = {}
end

if not Kmo.loadedPlugins['PatchUtil'] then
    Kmo.PatchUtil = {}

    ---Splits a string into a table based on the given delimiter
    ---@param str string The string to split
    ---@param delimiter string The delimiter to split on
    ---@return table result The table with the split strings
    function Kmo.PatchUtil.split(str, delimiter)
        if not str or type(str) ~= 'string' then
            error('Kmo.PatchUtil.split(): str must be a string', 2)
        end
        if not delimiter or type(delimiter) ~= 'string' then
            error('Kmo.PatchUtil.split(): delimiter must be a string', 2)
        end
        local result = {}
        local from = 1
        if not str then
            return result
        end
        local delim_from, delim_to = string.find(str, delimiter, from, true)
        while delim_from do
        if (delim_from ~= 1) then
            table.insert(result, string.sub(str, from, delim_from - 1))
        end
        from = delim_to + 1
        delim_from, delim_to = string.find(str, delimiter, from, true)
        end
        if (from <= #str) then table.insert(result, string.sub(str, from)) end
        return result
    end

    ---Rebuilds a single string from a table with newlines after every field in the table
    ---@param t table The table to convert to a string
    ---@return string rebuiltString
    function Kmo.PatchUtil.rebuildStringFromTable(t)
        local rebuiltString = ""
        for _, str in pairs(t) do
            rebuiltString = rebuiltString .. str .. '\n'
        end
        return rebuiltString
    end

    ---Returns the index to insert a patch at, given a pattern to find and an offset to that line, and any whitespace preceding the start of the pattern
    ---@param t table The table to search for pattern
    ---@param offset number The offset from the line where pattern was found to the returned index
    ---@param pattern string The pattern to search for
    ---@return number indexToPatch The index to use in tinsert to patch
    ---@return string leadingWhitespace A string of the leading whitespace from the found line
    function Kmo.PatchUtil.findIndexToPatch(t, offset, pattern)
        for i, str in ipairs(t) do
            local success, info, _, leadingWhitespace = pcall(string.find, str, '(%s*)' .. pattern)
            if not success then
                BANETO_PrintError('Kmo.PatchUtil.findIndexToPatch(): ' .. pattern)
                error('Kmo.PatchUtil.findIndexToPatch(): ' .. info, 2)
            end
            local startIndex = info
            if startIndex then
                if leadingWhitespace == nil then
                    leadingWhitespace = ''
                end
                return i + offset, leadingWhitespace
            end
        end
        BANETO_PrintError('Could not find line matching pattern [' .. pattern .. ']')
        return 0, ''
    end

    ---Checks a table to see if it has already been patched by checking its first line for patchStr, and if it hasn't been patched, inserts the patchStr at the beginning of the file
    ---@param t table The table to check if it's patched
    ---@param patchStr string The string that represents a patched file
    ---@return boolean wasPatched Whether or not the file was patched before this call
    function Kmo.PatchUtil.checkIfPatched(t, patchStr)
        if type(t) ~= 'table' then
            error('Kmo.PatchUtil.checkIfPatched(): t is not a table, did you forget to call Kmo.PatchUtil.split(str, delimiter) first?', 2)
        end
        if not t then
            t = {}
        end
        if not t[1] or t[1] ~= patchStr then
            if t[1] and string.find(t[1], '-- Kumouri%a+_Patched') then
                BANETO_PrintError('File has already been patched by another version of KmoPatcher, the patching process only works on original TSM files.')
                BANETO_PrintError('Please redownload TSM and rerun the patcher!')
                return true
            end
            table.insert(t, 1, patchStr)
            return false
        end
        return true
    end

    function Kmo.PatchUtil.validatePatchTable(patchTable)
        if not patchTable or type(patchTable) ~= 'table' then
            error('Kmo.PatchUtil.validatePatchTable(): patchTable must be a table', 3)
        end
        for pk, patch in ipairs(patchTable) do
            if not patch.offset or type(patch.offset) ~= 'number' then
                error('Kmo.PatchUtil.validatePatchTable(): patch[' .. tostring(pk) .. '].offset must be a number', 3)
            end
            if not patch.pattern or type(patch.pattern) ~= 'string' then
                error('Kmo.PatchUtil.validatePatchTable(): patch[' .. tostring(pk) .. '].pattern must be a string', 3)
            end
            if not patch.insert or type(patch.insert) ~= 'table' then
                error('Kmo.PatchUtil.validatePatchTable(): patch[' .. tostring(pk) .. '].insert must be a table', 3)
            end
            for ik, insert in ipairs(patch.insert) do
                if not insert.insert or type(insert.insert) ~= 'string' then
                    error('Kmo.PatchUtil.validatePatchTable(): patch[' .. tostring(pk) .. '].insert[' .. tostring(ik) .. '].insert must be a string', 3)
                end
                if insert.ignoreLeadingWhitespace and type(insert.ignoreLeadingWhitespace) ~= 'boolean' then
                    error('Kmo.PatchUtil.validatePatchTable(): patch[' .. tostring(pk) .. '].insert[' .. tostring(ik) .. '].ignoreLeadingWhitespace must be a boolean', 3)
                end
                if insert.leadingWhitespace and type(insert.leadingWhitespace) ~= 'string' then
                    error('Kmo.PatchUtil.validatePatchTable(): patch[' .. tostring(pk) .. '].insert[' .. tostring(ik) .. '].leadingWhitespace must be a string', 3)
                end
            end
        end
    end

    ---@class Kmo.PatchTable
    ---@field offset number The offset from the line where pattern was found to the returned index (positive is down, negative is up from the pattern)
    ---@field pattern string The pattern to search for (make sure to escape special characters)
    ---@field insert table<Kmo.PatchInsert> The table of inserts to make

    ---@class Kmo.PatchInsert
    ---@field insert string The string to insert
    ---@field ignoreLeadingWhitespace boolean Whether or not to ignore leading whitespace when inserting
    ---@field leadingWhitespace string The leading whitespace to insert before the insert string (in addition to the leading whitespace of the line where pattern was found, if ignoreLeadingWhitespace is false)
    ---@field replace boolean Whether or not to replace the line where pattern was found with the insert string

    ---@description Patch a file with a given patch string and patch table. If dryRun is true, the file will not be patched, but the function will return true if the file would have been patched.
    ---@param fileName string The name of the file to patch (including path, no leading / is relative to WoW directory, leading / is relative to NN directory)
    ---@param patchStr string The string that represents a patched file
    ---@param patchTable Kmo.PatchTable The table that contains the patches to apply
    ---@param dryRun boolean Whether or not to actually patch the file, or just return true if the file would have been patched
    ---@return boolean patched Whether or not the file was patched
    function Kmo.PatchUtil.patchFile(fileName, patchStr, patchTable, dryRun)
        if not fileName or type(fileName) ~= 'string' then
            error('Kmo.PatchUtil.patchFile(): fileName must be a string', 2)
        end
        if not patchStr or type(patchStr) ~= 'string' then
            error('Kmo.PatchUtil.patchFile(): patchStr must be a string', 2)
        end
        local success, msg = pcall(Kmo.PatchUtil.validatePatchTable, patchTable)
        if not success then
            error('Kmo.PatchUtil.patchFile(): patchTable is invalid:\n' .. msg, 2)
        end
        local patched = false
        local fileString = ReadFile(fileName)
        if not fileString then
            BANETO_PrintError('Kmo.PatchUtil.patchFile(): Could not read file [' .. fileName .. ']')
            error('Kmo.PatchUtil.patchFile(): Could not read file [' .. fileName .. ']', 2)
        end
        local fileSplit = Kmo.PatchUtil.split(fileString, '\n')
        if not Kmo.PatchUtil.checkIfPatched(fileSplit, patchStr) then
            for _, patch in ipairs(patchTable) do
                local indexToPatch, leadingWhitespace = Kmo.PatchUtil.findIndexToPatch(fileSplit, patch.offset, patch.pattern)
                if indexToPatch then
                    for i = #patch.insert, 1, -1 do
                        local myLeadingWhitespace = (patch.insert[i].ignoreLeadingWhitespace and '' or (patch.insert[i].leadingWhitespace or '') .. (leadingWhitespace or ''))
                        if not patch.insert[i].replace then
                            table.insert(fileSplit, indexToPatch, myLeadingWhitespace .. patch.insert[i].insert)
                        else
                            fileSplit[indexToPatch] = myLeadingWhitespace .. patch.insert[i].insert
                        end
                    end
                    patched = true
                end
            end
            if patched and not dryRun then
                local rebuiltString = Kmo.PatchUtil.rebuildStringFromTable(fileSplit)
                WriteFile(fileName, rebuiltString, false)
            end
        end
        return patched
    end

    ---@description Reloads the UI in 5 seconds
    function Kmo.PatchUtil.reloadUI()
        if not Kmo.PatchUtil.reloadTimer then
            Kmo.Logging:Print('Kmo.PatchUtil', Kmo.Logging.LEVELS.INFO, 'Reloading UI in 5 seconds...')
            Kmo.PatchUtil.reloadTimer = C_Timer.NewTimer(5, reloadUi)
        else
            Kmo.Logging:Print('Kmo.PatchUtil', Kmo.Logging.LEVELS.INFO, 'Restarting 5 second reload timer...')
            Kmo.PatchUtil.reloadTimer:Cancel()
            Kmo.PatchUtil.reloadTimer = C_Timer.NewTimer(5, reloadUi)
        end
    end

    Kmo.loadedPlugins['PatchUtil'] = true
end
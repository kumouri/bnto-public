if not _G.Kmo then
    _G.Kmo = {}
    Kmo.loadedPlugins = {}
    Kmo.loading = {}
end

if not Kmo.loadedPlugins then
    Kmo.loadedPlugins = {}
end

if not Kmo.loading then
    Kmo.loading = {}
end

if not Kmo.Common and not Kmo.loading['KmoCommon'] then
    Kmo.loading['KmoCommon'] = true
    BANETO_CommunityFile([[KmoLib]],[[KmoCommon]])
end

if not Kmo.loadedPlugins['KmoFSM'] or not Kmo.loadedPlugins['TempTable'] then
    ---@class Kmo.TempTable
    Kmo.TempTable = function ()
        local TempTable = {}
        local private = {
            debugLeaks = nil,
            freeTempTables = {},
            tempTableState = {},
        }
        local NUM_TEMP_TABLES = 100
        local RELEASED_TEMP_TABLE_MT = {
            __newindex = function(self, key, value)
                error("Attempt to access temp table after release")
            end,
            __index = function(self, key)
                error("Attempt to access temp table after release")
            end,
        }

        ---Acquire a temp table
        ---@vararg any The values to initialize the temp table with
        ---@return table @The temp table
        function TempTable:Acquire(...)
            local tempTable = tremove(private.freeTempTables)
            if not tempTable then
                error('No free temp tables')
            end
            setmetatable(tempTable, nil)
            private.tempTableState[tempTable] = true
            for i = 1, select('#', ...) do
                tempTable[i] = select(i, ...)
            end
            return tempTable
        end

        ---Get an iterator for the temp table, releasing it when done. This iterator must be run to completion and not be interrupted (i.e. with a `break` or `return`)
        ---@param table table The temp table
        ---@param numFields? number The number of fields per iteration
        ---@return function, table, number @The iterator function
        function TempTable:Iterator(table, numFields)
            numFields = numFields or 1
            assert(numFields > 0 and #table % numFields == 0, 'Invalid number of fields')
            assert(private.tempTableState[table], 'Invalid temp table')
            table.__iterNumFields = numFields
            return private.TempTableIteratorHelper, table, 1 - numFields
        end

        ---Release a temp table
        ---@param table table The temp table
        function TempTable:Release(table)
            private.TempTableReleaseHelper(table)
        end

        ---Unpack a temp table and release it
        ---@param table table The temp table
        ---@return ... @The unpacked values
        function TempTable:UnpackAndRelease(table)
            return private.TempTableReleaseHelper(table, unpack(table))
        end

        function private.TempTableIteratorHelper(table, index)
            local numFields = table.__iterNumFields
            index = index + numFields
            if index > #table then
                TempTable:Release(table)
                return
            end
            if numFields == 1 then
                return index, table[index]
            else
                return index, unpack(table, index, index + numFields - 1)
            end
        end

        function private.TempTableReleaseHelper(table, ...)
            if not private.tempTableState[table] then
                error('Invalid temp table')
            end
            wipe(table)
            tinsert(private.freeTempTables, table)
            private.tempTableState[table] = nil
            setmetatable(table, RELEASED_TEMP_TABLE_MT)
            return ...
        end

        do
            for _ = 1, NUM_TEMP_TABLES do
                local tempTable = setmetatable({}, RELEASED_TEMP_TABLE_MT)
                tinsert(private.freeTempTables, tempTable)
            end
        end

        return TempTable
    end

    Kmo.loadedPlugins['TempTable'] = true

    ---@param name string The name of the state
    ---@return Kmo.FSMState @The FSM state object
    Kmo.FSMState = function (name)
        ---@class Kmo.FSMState
        ---@field _name string
        ---@field _onEnterHandler function?
        ---@field _onExitHandler function?
        ---@field _transitionValid table?
        ---@field _events table?
        ---@field SetOnEnter function
        ---@field SetOnExit function
        ---@field AddTransition function
        ---@field AddEvent function
        ---@field AddEventTransition function
        ---@field _GetName function
        ---@field _ToStateIterator function
        ---@field _IsTransitionValid function
        ---@field _HasEventHandler function
        ---@field _ProcessEvent function
        ---@field _Enter function
        ---@field _Exit function
        ---@field _CallEventHandler function
        local KmoFSMState = {
            _name = name,
            _onEnterHandler = nil,
            _onExitHandler = nil,
            _transitionValid = {},
            _events = {}
        }

        local private = {
            eventTransitionHandlerCache = {},
        }

        ---Set the function to be called when entering the state
        ---@param self Kmo.FSMState
        ---@param handler function
        ---@return Kmo.FSMState @The FSM state object
        function KmoFSMState:SetOnEnter(handler)
            assert(type(handler) == 'function', 'Handler must be a function')
            self._onEnterHandler = handler
            return self
        end

        ---Set the function to be called when exiting the state
        ---@param self Kmo.FSMState
        ---@param handler function
        ---@return Kmo.FSMState @The FSM state object
        function KmoFSMState:SetOnExit(handler)
            assert(type(handler) == 'function', 'Handler must be a function')
            self._onExitHandler = handler
            return self
        end

        ---Register a transition to another state as valid
        ---@param self Kmo.FSMState
        ---@param toState string
        ---@return Kmo.FSMState @The FSM state object
        function KmoFSMState:AddTransition(toState)
            assert(not self._transitionValid[toState], 'Transition already exists')
            self._transitionValid[toState] = true
            return self
        end

        ---Register an event to listen for and a handler to call when the event is received
        ---@param self Kmo.FSMState
        ---@param event string
        ---@param handler function
        ---@return Kmo.FSMState @The FSM state object
        function KmoFSMState:AddEvent(event, handler)
            assert(not self._events[event], 'Event already exists')
            self._events[event] = handler
            return self
        end

        ---Register an event to listen for and a state to transition to when the event is received
        ---@param self Kmo.FSMState
        ---@param event string
        ---@param toState string
        ---@return Kmo.FSMState @The FSM state object
        function KmoFSMState:AddEventTransition(event, toState)
            if not private.eventTransitionHandlerCache[toState] then
                private.eventTransitionHandlerCache[toState] = function (context, ...)
                    return toState, ...
                end
            end
            return self:AddEvent(event, private.eventTransitionHandlerCache[toState])
        end

        ---Get the name of the state
        ---@return string @The name of the state
        function KmoFSMState:_GetName()
            return self._name
        end

        ---Get an iterator for the states that this state can transition to
        ---@param self Kmo.FSMState
        function KmoFSMState:_ToStateIterator()
            return pairs(self._transitionValid)
        end

        ---Check if a transition to the given state is valid
        ---@param self Kmo.FSMState
        ---@param toState string
        ---@return boolean @True if the transition is valid, false otherwise
        function KmoFSMState:_IsTransitionValid(toState)
            return self._transitionValid[toState] == true
        end

        ---Check if an event has a handler
        ---@param self Kmo.FSMState
        ---@param event string
        ---@return boolean @True if a handler for event exists, false otherwise
        function KmoFSMState:_HasEventHandler(event)
            return self._events[event] and true or false
        end

        ---Call the handler for an event
        ---@param self Kmo.FSMState
        ---@param event string
        ---@param context any
        ---@vararg any
        ---@return any @The result of the handler
        function KmoFSMState:_ProcessEvent(event, context, ...)
            local handler = self._events[event]
            if handler then
                return self:_CallEventHandler(handler, context, ...)
            end
        end

        ---Call the onEnter handler
        ---@param self Kmo.FSMState
        ---@param context any
        ---@vararg any
        ---@return any @The result of the handler
        function KmoFSMState:_Enter(context, ...)
            return self:_CallEventHandler(self._onEnterHandler, context, ...)
        end

        ---Call the onExit handler
        ---@param self Kmo.FSMState
        ---@param context any
        ---@vararg any
        ---@return any @The result of the handler
        function KmoFSMState:_Exit(context, ...)
            return self:_CallEventHandler(self._onExitHandler, context, ...)
        end

        ---Call a handler
        ---@param self Kmo.FSMState
        ---@param handler function
        ---@param context any
        ---@vararg any
        ---@return any @The result of the handler
        function KmoFSMState:_CallEventHandler(handler, context, ...)
            if type(handler) == 'function' then
                return handler(context, ...)
            elseif handler ~= nil then
                error('Invalid handler: ' .. tostring(handler))
            end
        end

        return KmoFSMState
    end

    ---@description Create a new FSM
    ---@param name string The name of the FSM
    ---@return Kmo.FSM @The FSM object
    Kmo.FSM = function (name)
        local TempTable = Kmo.TempTable()

        ---@class Kmo.FSM
        ---@field _name string
        ---@field _currentState Kmo.FSMState?
        ---@field _context table?
        ---@field _loggingDisabledCount number
        ---@field _stateObjs table<string, Kmo.FSMState>
        ---@field _defaultEvents table<string, function>
        ---@field _handlingEvent string?
        ---@field _inTransition boolean
        ---@field AddState function
        ---@field AddDefaultEvent function
        ---@field AddDefaultEventTransition function
        ---@field Init function
        ---@field ProcessEvent function
        local fsm = {
            _name = name,
            _currentState = nil,
            _context = nil,
            _loggingDisabledCount = 0,
            _stateObjs = {},
            _defaultEvents = {},
            _handlingEvent = nil
        }

        local private = {
            eventTransitionHandlerCache = {},
        }

        ---Add a state to the FSM
        ---@param self Kmo.FSM
        ---@param stateObj Kmo.FSMState
        function fsm:AddState(stateObj)
            assert(not self._stateObjs[stateObj:_GetName()], 'State already exists')
            self._stateObjs[stateObj:_GetName()] = stateObj
            return self
        end

        ---Add a default handler for an event
        ---@param self Kmo.FSM
        ---@param event string
        ---@param handler function
        ---@return Kmo.FSM @The FSM object
        function fsm:AddDefaultEvent(event, handler)
            assert(not self._defaultEvents[event], 'Default event already exists')
            self._defaultEvents[event] = handler
            return self
        end

        ---Add a default transition for an event to another state
        ---@param self Kmo.FSM
        ---@param event string
        ---@param toState string
        ---@return Kmo.FSM @The FSM object
        function fsm:AddDefaultEventTransition(event, toState)
            if not private.eventTransitionHandlerCache[toState] then
                private.eventTransitionHandlerCache[toState] = function (context, ...)
                    return toState, ...
                end
            end
            return fsm:AddDefaultEvent(event, private.eventTransitionHandlerCache[toState])
        end

        ---Initialize a new FSM
        ---@param self Kmo.FSM
        ---@param initialState string
        ---@param context? table
        ---@return Kmo.FSM @The FSM object
        function fsm:Init(initialState, context)
            assert(self._stateObjs[initialState], 'Invalid initial state')
            self._currentState = self._stateObjs[initialState]
            self._context = context or {}
            for nme, obj in pairs(self._stateObjs) do
                for _, toState in obj:_ToStateIterator() do
                    assert(self._stateObjs[toState], format("toState doesn't exist: [%s -> %s]", nme, toState))
                end
            end
            return self
        end

        ---Process an event
        ---@param self Kmo.FSM
        ---@param event string
        ---@vararg any
        ---@return Kmo.FSM @The FSM object
        function fsm:ProcessEvent(event, ...)
            if self._handlingEvent then
                Kmo.Logging:Warn('FSM', 'ProcessEvent', 'Already handling event: ' .. self._handlingEvent)
                return self
            elseif self._inTransition then
                Kmo.Logging:Warn('FSM', 'ProcessEvent', 'Already in transition')
                return self
            end

            self._handlingEvent = event
            local currentStateObj = self._stateObjs[self._currentState]
            if currentStateObj:_HasEventHandler(event) then
                fsm:_Transition(TempTable.Acquire(currentStateObj:_ProcessEvent(event, self._context, ...)))
            elseif self._defaultEvents[event] then
                fsm:_Transition(TempTable.Acquire(self._defaultEvents[event](self._context, ...)))
            end
            self._handlingEvent = nil
            return self
        end

        ---Transition to a new state
        ---@param self Kmo.FSM
        ---@param eventResult table
        function fsm:_Transition(eventResult)
            local result = eventResult
            while result[1] do
                local currentStateObj = self._stateObjs[self._currentState]
                local toState = tremove(result, 1)
                local toStateObj = self._stateObjs[toState]
                assert(toStateObj and currentStateObj:_IsTransitionValid(toState), format("Invalid transition: [%s -> %s]", currentStateObj:_GetName(), toState))
                self._inTransition = true
                currentStateObj:_Exit(self._context)
                self._currentState = toState
                result = TempTable.Acquire(toStateObj:_Enter(self._context, TempTable.UnpackAndRelease(result)))
                self._inTransition = false
            end
            TempTable.Release(result)
        end

        return fsm
    end

    Kmo.loadedPlugins['KmoFSM'] = true
end
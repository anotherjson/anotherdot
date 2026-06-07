-- Wave:3 microphone fix — forces mic capture to start before playback so the
-- mic isn't silenced while the device is also used for audio output (a
-- long-standing Wave 1/3/XLR firmware quirk on Linux).
--
-- Originally from https://github.com/jmansar/wavexlr-on-linux-cfg
-- (cfg1/wavedevicefix.lua, MIT). This is our own local copy maintained in this
-- dotfiles repo — intentionally NOT tracked against upstream.
--
-- Local hardening applied on top of the upstream version:
--   * everything scoped `local` (no globals leaking into WirePlumber's shared
--     Lua environment); functions forward-declared for mutual references
--   * failed null-sink link now resets nullSinkLink so it can be retried
--     (upstream set a stray global `node` instead, wedging the retry guard)
--   * failed null-sink *node* creation clears nullSinkForWaveDeviceSource rather
--     than a stray local, so no dead proxy is left wedged there (there is no
--     retry path — the device is just left unmanaged on that rare failure)
--   * onPortAdded is a local function, not a redefined global
--   * the port ObjectManager is module-scoped and dropped on device removal,
--     and a re-entrancy guard ignores duplicate source-added events, so
--     repeated replugs don't stack ObjectManagers / links / sinks
--
-- It creates a virtual null sink, links the Wave:3 mic source to it to force
-- capture to start first, then (re)creates the Wave:3 playback sink.

-- BEGIN USER CONFIGURATION

-- Additional properties applied to the playback sink the script creates.
local CONFIG_SINK_ADDITIONAL_PROPERTIES = {
    -- disables session suspend on idle for the sink playback
    -- helps with potential audio playback delays and audio popping
    ["session.suspend-timeout-seconds"] = "0"
}

-- END USER CONFIGURATION

local log = Log.open_topic("s-wavedevicefix")

-- read arguments passed to the script from the wireplumber config file
local scriptArgs = ...
if scriptArgs ~= nil then
    scriptArgs = scriptArgs:parse(1)
else
    scriptArgs = {}
end

local CONFIG_WAVE_DEVICE_SOURCE_NAME = "wavexlr-source"
local CONFIG_WAVE_DEVICE_SINK_NAME = "wavexlr-sink"
local CONFIG_WAVE_DEVICE_DISPLAY_NAME = "WaveXLR"

if scriptArgs["device"] == "wave3" then
    CONFIG_WAVE_DEVICE_SOURCE_NAME = "wave3-source"
    CONFIG_WAVE_DEVICE_SINK_NAME = "wave3-sink"
    CONFIG_WAVE_DEVICE_DISPLAY_NAME = "Wave3"

    log.notice("Use configuration for Wave3 device")
elseif scriptArgs["device"] == "wave1" then
    CONFIG_WAVE_DEVICE_SOURCE_NAME = "wave1-source"
    CONFIG_WAVE_DEVICE_SINK_NAME = "wave1-sink"
    CONFIG_WAVE_DEVICE_DISPLAY_NAME = "Wave1"

    log.notice("Use configuration for Wave1 device")
elseif scriptArgs["device"] == "xlrdock" then
    CONFIG_WAVE_DEVICE_SOURCE_NAME = "xlrdock-source"
    CONFIG_WAVE_DEVICE_SINK_NAME = "xlrdock-sink"
    CONFIG_WAVE_DEVICE_DISPLAY_NAME = "XLRDock"

    log.notice("Use configuration for XLRDock device")
else
    log.notice("Use configuration for WaveXLR device")
end


local waveDeviceSourceOm = ObjectManager {
    Interest {
        type = "node",
        Constraint { "node.name", "matches", CONFIG_WAVE_DEVICE_SOURCE_NAME },
    }
}

local linkOm = ObjectManager {
    Interest {
        type = "link",
    }
}

local devicesOm = ObjectManager {
    Interest {
        type = "device",
    }
}

-- module-level state
local waveDeviceSinkNode = nil
local nullSinkForWaveDeviceSource = nil
local nullSinkLink = nil
local portOm = nil          -- tracked so it can be dropped on device removal (leak guard)
local sourceHandled = false -- re-entrancy guard: ignore duplicate source-added events

-- forward declarations so the locals resolve correctly across mutual references
local createLinkForWaveDeviceSource
local onLinkCreated
local createWaveDeviceSink
local onWaveDeviceSourceAdded
local createNullSink
local onWaveDeviceSourceRemoved
local onNullSinkCreated

function createLinkForWaveDeviceSource(waveDeviceSourceNode)
    local outPort = nil
    local inPort = nil

    local outInterest = Interest {
        type = "port",
        Constraint { "node.id", "equals", waveDeviceSourceNode.properties["object.id"] },
        Constraint { "port.direction", "equals", "out" }
    }

    local inInterest = Interest {
        type = "port",
        Constraint { "node.id", "equals", nullSinkForWaveDeviceSource.properties["object.id"] },
        Constraint { "port.direction", "equals", "in" }
    }

    -- reuse a single ObjectManager instead of stacking a new one per source-added.
    -- It intentionally tracks all ports (the link needs ports from two distinct
    -- nodes, so a single Interest constraint can't scope it), and onPortAdded stays
    -- connected for the session — the `if not nullSinkLink` guard below makes every
    -- post-bind invocation a cheap no-op, so there's nothing to gain by disconnecting.
    if not portOm then
        portOm = ObjectManager {
            Interest {
                type = "port",
            }
        }
    end

    local function onPortAdded()
        if not nullSinkLink then
            for port in portOm:iterate(outInterest) do
                outPort = port
            end

            for port in portOm:iterate(inInterest) do
                inPort = port
            end

            if inPort and outPort and inPort.properties["object.id"] and outPort.properties["object.id"] then
                local args = {
                    ["link.input.node"] = nullSinkForWaveDeviceSource.properties["object.id"],
                    ["link.input.port"] = inPort.properties["object.id"],

                    ["link.output.node"] = waveDeviceSourceNode.properties["object.id"],
                    ["link.output.port"] = outPort.properties["object.id"],
                }

                log:notice("Creating link between null sink and " ..
                    CONFIG_WAVE_DEVICE_DISPLAY_NAME .. " source. Ports: " ..
                    args["link.input.node"] ..
                    "-" ..
                    args["link.input.port"] .. " -> " .. args["link.output.node"] .. "-" .. args["link.output.port"])

                nullSinkLink = Link("link-factory", args)

                nullSinkLink:activate(Feature.Proxy.BOUND, function(n, err)
                    if err then
                        log:warning("Failed to create link between null sink and " ..
                            CONFIG_WAVE_DEVICE_DISPLAY_NAME .. " source"
                            .. ": " .. tostring(err))
                        nullSinkLink = nil -- reset so the link can be retried
                    else
                        log:notice("Created link between null sink and " .. CONFIG_WAVE_DEVICE_DISPLAY_NAME .. " source")
                        -- Create the playback sink now that the capture link is
                        -- bound. The linkOm/onLinkCreated path races (it compares
                        -- an often-unbound nullSinkLink proxy id) and reliably
                        -- misses here, so trigger directly from the success
                        -- callback too. createWaveDeviceSink guards against
                        -- double-creation, so whichever path fires first wins.
                        createWaveDeviceSink(waveDeviceSourceNode)
                    end
                end)
            end
        end
    end

    portOm:connect("object-added", onPortAdded)
    portOm:activate()
end

function onLinkCreated(_, link)
    if nullSinkLink and link.properties["object.id"] == nullSinkLink.properties["object.id"] then
        for node in waveDeviceSourceOm:iterate() do
            createWaveDeviceSink(node)
        end
    end
end

function createWaveDeviceSink(sourceNode)
    -- guard against double-creation (both the linkOm path and the link
    -- activate-success callback can call this)
    if waveDeviceSinkNode then
        return
    end

    local deviceInterest = Interest {
        type = "device",
        Constraint { "object.id", "equals", sourceNode.properties["device.id"] }
    }

    for device in devicesOm:iterate(deviceInterest) do
        local sinkNodeProperties = {
            ["device.id"] = sourceNode.properties["device.id"],
            ["factory.name"] = "api.alsa.pcm.sink",
            ["node.name"] = CONFIG_WAVE_DEVICE_SINK_NAME,
            ["node.description"] = CONFIG_WAVE_DEVICE_DISPLAY_NAME .. " Sink",
            ["node.nick"] = CONFIG_WAVE_DEVICE_DISPLAY_NAME .. " Sink",
            ["media.class"] = "Audio/Sink",
            ["api.alsa.path"] = sourceNode.properties["api.alsa.path"],
            ["api.alsa.pcm.card"] = sourceNode.properties["api.alsa.pcm.card"],
            ["api.alsa.pcm.stream"] = "playback",
            ["alsa.resolution_bits"] = "24",
            ["audio.channels"] = "2",
            ["audio.position"] = "FL,FR",
            ["priority.driver"] = "1000",
            ["priority.session"] = "1000",
            ["node.pause-on-idle"] = "false",
            ["card.profile.device"] = "3",
            ["device.profile.description"] = "Analog Stereo",
            ["device.profile.name"] = "analog-stereo",
            ["port.group"] = "playback",
        }

        for k, v in pairs(device.properties) do
            if k:find("^api%.alsa%.card%..*") then
                sinkNodeProperties[k] = v
            end
        end

        for k, v in pairs(CONFIG_SINK_ADDITIONAL_PROPERTIES) do
            sinkNodeProperties[k] = v
        end

        log:notice("Creating custom " ..
            CONFIG_WAVE_DEVICE_DISPLAY_NAME .. " sink. api.alsa.path: " .. sourceNode.properties["api.alsa.path"])

        waveDeviceSinkNode = Node("adapter", sinkNodeProperties)
        waveDeviceSinkNode:activate(Feature.Proxy.BOUND, function(n, err)
            if err then
                log:warning("Failed to create " .. sinkNodeProperties["node.name"]
                    .. ": " .. tostring(err))
                waveDeviceSinkNode = nil
            else
                log:notice("Created custom " ..
                    CONFIG_WAVE_DEVICE_DISPLAY_NAME .. " sink. object.id: " .. n.properties["object.id"])
            end
        end)
    end
end

function onWaveDeviceSourceAdded(_, node)
    if sourceHandled then
        return
    end
    sourceHandled = true
    createLinkForWaveDeviceSource(node)
end

function createNullSink()
    local properties = {
        ["factory.name"] = "support.null-audio-sink",
        ["node.name"] = "null-sink-for-" .. CONFIG_WAVE_DEVICE_SOURCE_NAME,
        ["node.description"] = "Null Sink For " .. CONFIG_WAVE_DEVICE_DISPLAY_NAME .. " Source - do not use",
        ["node.nick"] = "Null Sink For " .. CONFIG_WAVE_DEVICE_DISPLAY_NAME .. " Source - do not use",
        ["media.class"] = "Audio/Sink",
        ["monitor.channel-volumes"] = "true",
        ["monitor.passthrough"] = "true",
        ["audio.channels"] = "1",
        ["audio.position"] = "MONO",
        ["node.passive"] = "false"
    }

    log:notice("Creating custom null sink for " .. CONFIG_WAVE_DEVICE_DISPLAY_NAME .. " Source")

    local node = Node("adapter", properties)

    node:activate(Feature.Proxy.BOUND, function(n, err)
        if err then
            log:warning("Failed to create " .. properties["node.name"]
                .. ": " .. tostring(err))
            -- Clear the *global*, not just the local `node`: createNullSink's
            -- return value is assigned to nullSinkForWaveDeviceSource at the call
            -- site, so nilling only the local would leave a dead proxy wedged
            -- there. There is no retry path — on this rare activation failure the
            -- device is simply left unmanaged.
            nullSinkForWaveDeviceSource = nil
        else
            log:notice("Created null sink for " .. CONFIG_WAVE_DEVICE_DISPLAY_NAME .. " source. object.id: " ..
                n.properties["object.id"])
            onNullSinkCreated();
        end
    end)

    return node
end

function onWaveDeviceSourceRemoved()
    if waveDeviceSinkNode then
        log:notice("Removing custom " .. CONFIG_WAVE_DEVICE_DISPLAY_NAME .. " sink");
        waveDeviceSinkNode:request_destroy()
        waveDeviceSinkNode = nil
    end

    if nullSinkLink then
        log:notice("Removing null sink link");
        nullSinkLink:request_destroy()
        nullSinkLink = nil
    end

    -- drop the port ObjectManager and reset the guard so a replug starts clean
    portOm = nil
    sourceHandled = false
end

function onNullSinkCreated()
    log:notice("Activate event listeners");

    linkOm:activate()
    linkOm:connect("object-added", onLinkCreated)
    waveDeviceSourceOm:connect("object-added", onWaveDeviceSourceAdded)
    waveDeviceSourceOm:connect("object-removed", onWaveDeviceSourceRemoved)
    waveDeviceSourceOm:activate()
end

nullSinkForWaveDeviceSource = createNullSink();
devicesOm:activate()

log:notice("script initialized")

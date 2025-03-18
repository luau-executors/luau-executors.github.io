local vulnerableInstances = {
    "HttpRbxApiService",
    "ScriptProfilerService",
    "MarketplaceService",
    "HttpService",
    "OpenCloudService",
    "BrowserService",
    "LinkingService",
    "MessageBusService",
    "OmniRecommendationsService",
    "Script Context",
    "ScriptContext",
    "game",
    "Game",
    "TestService",
    "CaptureService",
    "AccountService",
    "AvatarEditorService"
}

local blockedFunctions = {
    "PostAsync",
    "HttpPost",
    "PostAsyncFullUrl",
    "PerformPurchaseV2",
    "PromptBundlePurchase",
    "PromptGamePassPurchase",
    "PromptProductPurchase",
    "PromptPurchase",
    "PromptRobloxPurchase",
    "PromptThirdPartyPurchase",
    "OpenBrowserWindow",
    "OpenNativeOverlay",
    "AddCoreScriptLocal",
    "EmitHybridEvent",
    "ExecuteJavaScript",
    "ReturnToJavaScript",
    "SendCommand",
    "Call",
    "OpenUrl",
    "SaveScriptProfilingData",
    "GetLast",
    "GetMessageId", 
    "GetProtocolMethodRequestMessageId",
    "GetProtocolMethodResponseMessageId",
    "MakeRequest",
    "Publish",
    "PublishProtocolMethodRequest",
    "PublishProtocolMethodResponse",
    "Subscribe",
    "SubscribeToProtocolMethodRequest",
    "SubscribeToProtocolMethodResponse",
    "GetRobuxBalance",
    "GetAsyncFullUrl",
    "PromptNativePurchaseWithLocalPlayer",
    "PromptNativePurchase",
    "PromptCollectiblesPurchase",
    "GetAsync",
    "RequestInternal",
    "HttpRequestAsync",
    "RequestAsync",
    "OpenScreenshotsFolder",
    "Load",
    "GetUserSubscriptionDetailsInternalAsync",
    "GetUserSubscriptionStatusAsync",
    "PerformBulkPurchase",
    "PerformCancelSubscription",
    "PerformPurchase",
    "PerformSubscriptionPurchase",
    "PerformSubscriptionPurchaseV2",
    "PrepareCollectiblesPurchase",
    "PromptBulkPurchase",
    "PromptCancelSubscription",
    "PromptPremiumPurchase",
    "PromptSubscriptionPurchase",
    "OpenWeChatAuthWindow",
    "RequestLimitedAsync",
    "Run",
    "CaptureScreenshot",
    "CreatePostAsync",
    "DeleteCapture",
    "DeleteCapturesAsync",
    "GetCaptureFilePathAsync",
    "SaveCaptureToExternalStorage",
    "SaveCapturesToExternalStorageAsync",
    "GetCaptureUploadDataAsync",
    "RetrieveCaptures",
    "SaveScreenshotCapture",
    "GetCredentialsHeaders",
    "GetDeviceIntegrityToken",
    "GetDeviceIntegrityTokenYield",
    "NoPromptCreateOutfit",
    "NoPromptDeleteOutfit",
    "NoPromptRenameOutfit",
    "NoPromptSaveAvatar",
    "NoPromptSaveAvatarThumbnailCustomization",
    "NoPromptSetFavorite",
    "NoPromptUpdateOutfit",
    "PerformCreateOutfitWithDescription",
    "PerformRenameOutfit",
    "PerformSaveAvatarWithDescription",
    "PerformSetFavorite",
    "PerformUpdateOutfit",
    "PromptCreateOutfit",
    "PromptDeleteOutfit",
    "PromptRenameOutfit",
    "PromptSaveAvatar",
    "PromptSetFavorite",
    "PromptUpdateOutfit"
}

local wrappercache = {} -- Cache for wrapped objects

local function unwrap(wrapped)
    if type(wrapped) == "table" then
        local real = {}
        for k, v in next, wrapped do
            real[k] = unwrap(v)
        end
        return real
    else
        local real = wrappercache[wrapped]
        if real == nil then
            return wrapped
        end
        return real
    end
end

local function wrap(real)
    for w, r in next, wrappercache do
        if r == real then
            return w
        end
    end

    if type(real) == "userdata" then
        local fake = newproxy(true)
        local meta = getmetatable(fake)

        meta.__index = function(self, index)
            -- Block access to blocked functions
            if table.find(blockedFunctions, index) then
                return function(...)
                    warn("cAPI :: Attempt to call blocked function '" .. index .. "'")
                end
            end

            -- Block access to vulnerable instances
            if table.find(vulnerableInstances, tostring(real)) then
                warn("cAPI :: Attempt to access vulnerable instance '" .. tostring(real) .. "'")
                return nil
            end

            -- Block Kick and Destroy methods on Player instances
            if typeof(real) == "Instance" and real.ClassName == "Player" then
                if index == "Kick" or index == "Destroy" then
                    return function(...)
                        warn("cAPI :: Attempt to call '" .. index .. "' on Player instance blocked")
                    end
                end
            end

            -- Allow access to other properties/methods
            if typeof(real[index]) == "function" then
                return function(self, ...)
                    return real[index](real, ...)
                end
            else
                return wrap(real[index])
            end
        end

        meta.__newindex = function(self, key, value)
            real[key] = value
        end

        meta.__tostring = function(self)
            return tostring(real)
        end

        wrappercache[fake] = real
        return fake

    elseif type(real) == "function" then
        local fake = function(...)
            local args = unwrap{ ... }
            local results = wrap{ real(unpack(args)) }
            return unpack(results)
        end
        wrappercache[fake] = real
        return fake

    elseif type(real) == "table" then
        local fake = {}
        for k, v in next, real do
            fake[k] = wrap(v)
        end
        return fake

    else
        return real
    end
end

-- Wrap the entire game environment
local wrappedGame = wrap(game)

-- Replace the global `game` with the wrapped version
game = wrappedGame

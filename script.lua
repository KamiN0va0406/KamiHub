-- =============================================================
-- [ KamiHub ] Key System & Arsenal Loader Integrated
-- =============================================================

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local StarterGui = game:GetService("StarterGui")
local LocalPlayer = Players.LocalPlayer

-- API 주소 설정 (Render 서버 주소로 변경 완료)
local API_URL = "https://l-gamblebot.onrender.com/checkkey"

-- 아스널 전용 PlaceId 및 깃허브 Raw 스크립트 주소
local ARSENAL_PLACE_ID = 286090429
local ARSENAL_SCRIPT_URL = "https://raw.githubusercontent.com/KamiN0va0406/KamiHub-Arsenal/refs/heads/main/script.lua"

-- [1] 키 시스템 인증 검증 로직 (웹 서버 API 통신)
local function verifyKey()
    if not script_key or script_key == "" then
        LocalPlayer:Kick("\n[KamiHub] ❌ License key is missing! Please get your script from the Discord bot.")
        return false
    end

    local rawHwid = ""
    pcall(function()
        rawHwid = (gethwid and gethwid()) or (RbxAnalyticsService and RbxAnalyticsService:GetClientId()) or "Unknown_HWID"
    end)

    local requestUrl = string.format("%s?key=%s&hwid=%s", API_URL, HttpService:UrlEncode(script_key), HttpService:UrlEncode(rawHwid))
    
    local success, response = pcall(function()
        return game:HttpGet(requestUrl)
    end)

    if not success then
        LocalPlayer:Kick("\n[KamiHub] ⚠️ Failed to connect to the authentication server.")
        return false
    end

    local decoded = {}
    pcall(function()
        decoded = HttpService:JSONDecode(response)
    end)

    if decoded and decoded.valid then
        print("[KamiHub] ✅ License verified successfully!")
        return true
    else
        local reason = (decoded and decoded.message) or "Invalid or unverified key."
        LocalPlayer:Kick("\n[KamiHub] ❌ Authentication Failed: " .. reason)
        return false
    end
end

-- [2] 키 인증 통과 및 게임 PlaceId 확인 후 메인 아스널 스크립트 실행
if verifyKey() then
    if game.PlaceId == ARSENAL_PLACE_ID then
        StarterGui:SetCore("SendNotification", {
            Title = "🎯 KamiHub 아스널",
            Text = "인증 성공! 아스널 스크립트를 불러옵니다...",
            Duration = 5
        })

        -- 글로벌 변수로 키 전달 후 아스널 스크립트 로드 및 실행
        getgenv().script_key = script_key
        
        local success, err = pcall(function()
            loadstring(game:HttpGet(ARSENAL_SCRIPT_URL))()
        end)

        if not success then
            warn("[KamiHub] ⚠️ Failed to load Arsenal script: " .. tostring(err))
        end
    else
        StarterGui:SetCore("SendNotification", {
            Title = "⚠️ KamiHub 알림",
            Text = "이 허브는 현재 아스널(Arsenal) 게임만 지원합니다.",
            Duration = 7
        })
    end
end

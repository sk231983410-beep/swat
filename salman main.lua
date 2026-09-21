require "import"
import "android.widget.*"
import "android.content.Intent"
import "android.net.Uri"
import "android.content.Context"
import "android.content.ClipData"
import "android.view.WindowManager"
import "android.os.Vibrator"
import "android.speech.tts.TextToSpeech"
import "java.util.Locale"
import "com.androlua.Http"

-- TTS سیٹ اپ
local tts
tts = TextToSpeech(service, function(status)
  if status == TextToSpeech.SUCCESS then
    tts.setLanguage(Locale.US)
  end
end)

-- ڈیٹا بیس (SharedPreferences)
local pref = service.getSharedPreferences("OpenRouterConfig", Context.MODE_PRIVATE)

-- مین ڈائیلاگ سیٹنگ
local dlg = LuaDialog()
dlg.setTitle("Suno AI Prompt Pro")
dlg.getWindow().setSoftInputMode(WindowManager.LayoutParams.SOFT_INPUT_ADJUST_RESIZE)

-- وائبریشن
local v = service.getSystemService(Context.VIBRATOR_SERVICE)
v.vibrate(200)

-- لنکس کھولنے کا فنکشن
local function openLink(url)
  local intent = Intent(Intent.ACTION_VIEW, Uri.parse(url))
  intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
  service.startActivity(intent)
end

-- ٹیکسٹ کاپی کرنے کا فنکشن
local function copyToClipboard(text)
  local clipboard = service.getSystemService(Context.CLIPBOARD_SERVICE)
  local clip = ClipData.newPlainText("Prompt", text)
  clipboard.setPrimaryClip(clip)
  Toast.makeText(service, "✅ Prompt copied to clipboard!", Toast.LENGTH_SHORT).show()
end

-- API Key کو صاف کرنے کا فنکشن
local function cleanApiKey(key)
  if not key then return "" end
  key = key:gsub("%s+", "")
  key = key:gsub("[\n\r\t]", "")
  return key
end

-- About ڈائیلاگ
local function showAboutDialog()
  local aboutDlg = LuaDialog()
  aboutDlg.setTitle("About Blind Technology Information")
  local aboutLayout = {
    LinearLayout; orientation = "vertical"; padding = "30dp";
    {TextView; text = "Welcome to Blind Technology Information!"; textSize = "16sp"; layout_gravity = "center"; layout_marginBottom = "10dp"};
    {TextView; text = "Connect with Blind Technology Information for more updates."; textSize = "14sp"; layout_marginBottom = "20dp"};
    {Button; text = "📱 Join WhatsApp Group"; onClick = function() 
      if tts then tts.speak("Opening WhatsApp Group", TextToSpeech.QUEUE_FLUSH, nil) end
      openLink("https://chat.whatsapp.com/DKQyfmhi5q1HIpQBb94aFL") 
    end};
    {Button; text = "▶️ Subscribe on YouTube"; onClick = function() 
      if tts then tts.speak("Opening YouTube Channel", TextToSpeech.QUEUE_FLUSH, nil) end
      openLink("https://youtube.com/@blindtechnologyinformation?si=uXE_HcxXwSajSVSO") 
    end};
    {Button; text = "🔙 Back"; onClick = function() aboutDlg.dismiss() end};
  }
  aboutDlg.setView(loadlayout(aboutLayout))
  aboutDlg.show()
end

-- Settings ڈائیلاگ
local function showSettingsDialog()
  local settingsDlg = LuaDialog()
  settingsDlg.setTitle("⚙️ OpenRouter API Settings")
  
  local savedKey = pref.getString("api_key", "")

  local settingsLayout = {
    LinearLayout; orientation = "vertical"; padding = "20dp";
    {TextView; text = "Enter OpenRouter API Key:"; textSize = "14sp"; textColor = "#333"};
    {EditText; id = "editApiKey"; text = savedKey; hint = "Paste your OpenRouter API key here"; layout_width = "fill"; inputType = "textVisiblePassword"};
    {TextView; text = "🔑 Get your free key from:"; textSize = "12sp"; layout_marginTop = "8dp"; textColor = "#2196F3"};
    {Button; text = "🌐 Get OpenRouter API Key"; backgroundColor = "#2196F3"; textColor = "#FFFFFF"; onClick = function()
      openLink("https://openrouter.ai/keys")
    end};
    {Button; id = "btnSaveKey"; text = "💾 Save API Key"; layout_marginTop = "10dp"; backgroundColor = "#4CAF50"; textColor = "#FFFFFF"};
    {Button; id = "btnTestKey"; text = "🧪 Test API Key"; backgroundColor = "#FF9800"; textColor = "#FFFFFF"};
    {Button; text = "🔙 Back"; layout_marginTop = "10dp"; onClick = function() settingsDlg.dismiss() end};
  }
  
  settingsDlg.setView(loadlayout(settingsLayout))
  
  -- API Key Save
  btnSaveKey.onClick = function()
    local rawKey = editApiKey.getText().toString()
    local key = cleanApiKey(rawKey)
    
    if key == "" then
      Toast.makeText(service, "⚠️ Please enter a valid API Key!", Toast.LENGTH_SHORT).show()
      return
    end
    
    pref.edit().putString("api_key", key).apply()
    Toast.makeText(service, "✅ OpenRouter API Key Saved Successfully!", Toast.LENGTH_SHORT).show()
    settingsDlg.dismiss()
  end
  
  -- OpenRouter API Key ٹیسٹ کرنا (فری ماڈل کے ساتھ تاکہ 402 نہ آئے)
  btnTestKey.onClick = function()
    local rawKey = editApiKey.getText().toString()
    local key = cleanApiKey(rawKey)
    
    if key == "" then
      Toast.makeText(service, "⚠️ Please enter a key first!", Toast.LENGTH_SHORT).show()
      return
    end
    
    Toast.makeText(service, "⏳ Testing OpenRouter connection...", Toast.LENGTH_SHORT).show()
    
    local testUrl = "https://openrouter.ai/api/v1/chat/completions"
    -- 100% فری ماڈل کا استعمال
    local testData = '{"model": "meta-llama/llama-3-8b-instruct:free", "messages": [{"role": "user", "content": "Say hello"}]}'
    
    local headers = {
      ["Content-Type"] = "application/json",
      ["Authorization"] = "Bearer " .. key,
      ["HTTP-Referer"] = "https://github.com/salmankhan",
      ["X-Title"] = "Suno AI Prompt Pro"
    }
    
    Http.post(testUrl, testData, headers, function(code, body)
      if code == 200 then
        Toast.makeText(service, "✅ OpenRouter API Key is working perfectly!", Toast.LENGTH_LONG).show()
      elseif code == 401 then
        Toast.makeText(service, "❌ Authentication Failed! Invalid Key.", Toast.LENGTH_LONG).show()
      elseif code == 402 then
        Toast.makeText(service, "❌ Error 402: Insufficient balance. Switch to a free model.", Toast.LENGTH_LONG).show()
      else
        Toast.makeText(service, "❌ Error Code: " .. code .. "\nPlease check your API Key configuration.", Toast.LENGTH_LONG).show()
      end
    end)
  end
  
  settingsDlg.show()
end

-- لسٹس
local moods = {"Energetic", "Relaxed", "Happy", "Sad", "Romantic", "Dark", "Epic", "Cinematic", "Focus", "Chill", "Aggressive", "Mysterious", "Inspiring", "Upbeat", "Melancholic"}
local languages = {"Pashto", "Urdu", "English", "Arabic", "Hindi", "Persian", "Punjabi", "Balochi", "Sindhi", "Bengali", "French", "Spanish", "Turkish", "Kashmiri", "Saraiki", "Hindko"}
local instruments = {"Rabab", "Acoustic Guitar", "Flute", "Tabla", "Harmonium", "Dholak", "Daira", "Electric Synth", "Violin", "Piano", "Sitar", "Daf", "Rubab & Tabla", "Clarinet", "Santoor"}

-- مین لے آؤٹ
local mainLayout = {
  ScrollView; layout_width = "fill"; layout_height = "fill";
  {
    LinearLayout; orientation = "vertical"; padding = "20dp";
    
    {TextView; text = "🤖 Suno AI Prompt Pro"; textSize = "20sp"; textColor = "#2196F3"; layout_gravity = "center"; layout_marginBottom = "5dp"};
    {TextView; text = "Developed by Salman Khan"; textSize = "14sp"; textColor = "#666"; layout_gravity = "center"; layout_marginBottom = "15dp"};
    
    {TextView; text = "🎵 Select Mood/Style:"; layout_marginTop = "5dp"; textSize = "14sp"; textColor = "#333"};
    {Spinner; id = "spinMood"; layout_width = "fill"; layout_marginBottom = "5dp"};
    
    {TextView; text = "🗣️ Select Language:"; layout_marginTop = "5dp"; textSize = "14sp"; textColor = "#333"};
    {Spinner; id = "spinLanguage"; layout_width = "fill"; layout_marginBottom = "5dp"};
    
    {TextView; text = "🎸 Select Instrument:"; layout_marginTop = "5dp"; textSize = "14sp"; textColor = "#333"};
    {Spinner; id = "spinInstrument"; layout_width = "fill"; layout_marginBottom = "5dp"};
    
    {Button; text = "🚀 Generate AI Prompt"; id = "btnGenerate"; layout_marginTop = "10dp"; backgroundColor = "#4CAF50"; textColor = "#FFFFFF"};
    
    {TextView; text = "📝 Generated Prompt:"; layout_marginTop = "10dp"; textSize = "14sp"; textColor = "#333"};
    {EditText; id = "editResult"; layout_width = "fill"; layout_height = "120dp"; focusable = false; backgroundColor = "#F5F5F5"; padding = "10dp"; textSize = "13sp"};
    
    {Button; text = "📋 Copy to Clipboard"; id = "btnCopy"; backgroundColor = "#FF9800"; textColor = "#FFFFFF"; layout_marginTop = "5dp"};
    
    {LinearLayout; orientation = "horizontal"; layout_width = "fill"; layout_marginTop = "10dp";
      {Button; text = "⚙️ Settings"; id = "btnSettings"; layout_weight = "1"; layout_marginRight = "5dp"; backgroundColor = "#9E9E9E"; textColor = "#FFFFFF"};
      {Button; text = "ℹ️ About"; onClick = function() showAboutDialog() end; layout_weight = "1"; layout_marginLeft = "5dp"; backgroundColor = "#9E9E9E"; textColor = "#FFFFFF"};
    };
    
    {Button; text = "❌ Exit"; onClick = function() 
      if tts then tts.speak("Extension closed", TextToSpeech.QUEUE_FLUSH, nil) end
      dlg.dismiss() 
    end; backgroundColor = "#F44336"; textColor = "#FFFFFF"; layout_marginTop = "5dp"};
  };
}

dlg.setView(loadlayout(mainLayout))

-- اڈاپٹرز
local moodAdapter = ArrayAdapter(service, android.R.layout.simple_spinner_item, moods)
moodAdapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item)
spinMood.setAdapter(moodAdapter)

local langAdapter = ArrayAdapter(service, android.R.layout.simple_spinner_item, languages)
langAdapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item)
spinLanguage.setAdapter(langAdapter)

local instAdapter = ArrayAdapter(service, android.R.layout.simple_spinner_item, instruments)
instAdapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item)
spinInstrument.setAdapter(instAdapter)

btnSettings.onClick = function()
  showSettingsDialog()
end

-- OpenRouter پرامپٹ جنریٹر (مفت چلیگا - بغیر بیلنس کے)
btnGenerate.onClick = function()
  local apiKey = pref.getString("api_key", "")
  apiKey = cleanApiKey(apiKey)
  
  if apiKey == "" then
    Toast.makeText(service, "⚠️ Please set your OpenRouter API Key in Settings first!", Toast.LENGTH_LONG).show()
    showSettingsDialog()
    return
  end

  local mood = moods[spinMood.getSelectedItemPosition() + 1]
  local lang = languages[spinLanguage.getSelectedItemPosition() + 1]
  local inst = instruments[spinInstrument.getSelectedItemPosition() + 1]
  
  Toast.makeText(service, "⏳ Generating prompt with OpenRouter...", Toast.LENGTH_SHORT).show()
  editResult.setText("⏳ Generating, please wait...")

  local url = "https://openrouter.ai/api/v1/chat/completions"
  
  local promptText = "Write a highly descriptive, long, and professional music prompt for Suno AI. Style: " .. mood .. ", Vocals: " .. lang .. ", Instrument: " .. inst .. ". Output ONLY the final bracketed Suno AI optimized text with detailed tags like [Verse], [Chorus], [Bridge], [Outro], mood, tempo, instrumentation details, and vocal style. No chat conversation or extra text."
  promptText = promptText:gsub('"', '\\"'):gsub("\n", "\\n")
  
  -- ہمیشہ مفت چلنے والا ماڈل سیٹ کر دیا ہے
  local jsonPayload = '{"model": "meta-llama/llama-3-8b-instruct:free", "messages": [{"role": "user", "content": "' .. promptText .. '"}]}'
  
  local headers = {
    ["Content-Type"] = "application/json",
    ["Authorization"] = "Bearer " .. apiKey,
    ["HTTP-Referer"] = "https://github.com/salmankhan",
    ["X-Title"] = "Suno AI Prompt Pro"
  }

  Http.post(url, jsonPayload, headers, function(code, body)
    if code == 200 then
      local aiResponse = body:match('"content"%s*:%s*"(.-)"%s*}%s*}%s*]%s*}') or body:match('"content"%s*:%s*"(.-)"')
      if aiResponse then
        aiResponse = aiResponse:gsub("\\n", "\n"):gsub("\\\"", '"'):gsub("\\'", "'")
        editResult.setText(aiResponse)
        Toast.makeText(service, "✅ Prompt Generated Successfully!", Toast.LENGTH_SHORT).show()
        if tts then tts.speak("Prompt generated", TextToSpeech.QUEUE_FLUSH, nil) end
      else
        editResult.setText("❌ Error parsing response block from OpenRouter payload.")
      end
    else
      editResult.setText("❌ API Error! Code: " .. code .. "\nPlease use OpenRouter Free tier keys.")
      Toast.makeText(service, "Error Code: " .. code, Toast.LENGTH_LONG).show()
    end
  end)
end

btnCopy.onClick = function()
  local text = editResult.getText().toString()
  if text ~= "" and text ~= "⏳ Generating, please wait..." and not text:find("Error") and not text:find("Failed") then
    copyToClipboard(text)
    if tts then tts.speak("Prompt copied", TextToSpeech.QUEUE_FLUSH, nil) end
  else
    Toast.makeText(service, "Nothing to copy! Generate a prompt first.", Toast.LENGTH_SHORT).show()
  end
end

dlg.show()

require "import"
import "com.androlua.Http"
import "com.androlua.LuaDialog"
import "android.widget.Toast"
import "android.os.Handler"
import "android.os.Looper"
import "java.lang.Thread"
import "java.lang.Runnable"
import "java.lang.System"
import "java.io.File"
import "android.content.Context"
import "android.media.ToneGenerator"
import "android.media.AudioManager"
import "android.os.Vibrator"
import "android.os.Build"
import "android.os.VibrationEffect"

local CURRENT_VERSION = "1.0"
local VERSION_URL = "https://raw.githubusercontent.com/sk231983410-beep/swat/main/pakisrab"
local UPDATE_CODE_URL = "https://raw.githubusercontent.com/sk231983410-beep/swat/main/salman%20main.lua"
local PLUGIN_PATH = (function()
    local src = debug.getinfo(1, "S").source
    return src and src:match("^@?(.*)$") or ""
end)()
local updateInProgress = false

local prefs = (service or activity).getSharedPreferences("AutoUpdatePrefs", Context.MODE_PRIVATE)

local function playNotification()
    pcall(function()
        local tone = ToneGenerator(AudioManager.STREAM_NOTIFICATION, 100)
        tone.startTone(ToneGenerator.TONE_PROP_ACK, 100)
        local vibrator = (service or activity).getSystemService(Context.VIBRATOR_SERVICE)
        if vibrator then
            if Build.VERSION.SDK_INT >= 26 then
                vibrator.vibrate(VibrationEffect.createOneShot(200, VibrationEffect.DEFAULT_AMPLITUDE))
            else
                vibrator.vibrate(200)
            end
        end
    end)
end

local function trim(s)
    if s == nil then return "" end
    return tostring(s):gsub("^%s*(.-)%s*$", "%1")
end

local function showUpdateErrorDialog(title, message)
    Handler(Looper.getMainLooper()).post(Runnable({
        run = function()
            local errorDialog = LuaDialog(service or activity)
            errorDialog.setTitle(title)
            errorDialog.setMessage(message)
            errorDialog.setButton("OK", function()
                errorDialog.dismiss()
            end)
            errorDialog.show()
        end
    }))
end

local function checkAndShowNewFeatures()
    local lastShown = prefs.getString("lastShownVersion", "")
    if lastShown ~= CURRENT_VERSION then
        Handler(Looper.getMainLooper()).post(Runnable{
            run=function()
                playNotification()
                local featuresDialog = LuaDialog(service or activity)
                featuresDialog.setTitle("New Update Details")
                featuresDialog.setMessage("this is new feature PC extensionvirgin 1.2this is new link and telegram channel click to Telegram channel in join")
                featuresDialog.setButton("OK", function() 
                    featuresDialog.dismiss() 
                end)
                featuresDialog.show()
                prefs.edit().putString("lastShownVersion", CURRENT_VERSION).apply()
            end
        })
    end
end

local function performUpdate(mainCode, onlineVersion)
    if not mainCode or trim(mainCode) == "" then
        showUpdateErrorDialog("Update Failed", "Main plugin code is empty.")
        return
    end
    
    updateInProgress = true
    
    local function updateProcess()
        local currentFileSrc = debug.getinfo(1, "S").source
        local currentFilePath = currentFileSrc and currentFileSrc:match("^@?(.*)$") or ""
        
        if currentFilePath ~= "" and currentFilePath ~= PLUGIN_PATH then
            pcall(function()
                os.rename(currentFilePath, PLUGIN_PATH)
            end)
        end
        
        local success = false
        local tempPath = PLUGIN_PATH .. ".temp_update"
        local f = io.open(tempPath, "w")
        if f then
            f:write(mainCode)
            f:close()
            
            local fileExists = io.open(PLUGIN_PATH, "r")
            if fileExists then
                fileExists:close()
                local delSuccess = pcall(function()
                    os.remove(PLUGIN_PATH)
                end)
                if delSuccess then
                    local renameSuccess = pcall(function()
                        os.rename(tempPath, PLUGIN_PATH)
                    end)
                    if renameSuccess then
                        success = true
                    end
                end
            else
                local renameSuccess = pcall(function()
                    os.rename(tempPath, PLUGIN_PATH)
                end)
                if renameSuccess then
                    success = true
                end
            end
            
            if not success then
                pcall(function() os.remove(tempPath) end)
            end
        end
        
        if success then
            updateInProgress = false
            Handler(Looper.getMainLooper()).post(Runnable({
                run = function()
                    playNotification()
                    local successDialog = LuaDialog(service or activity)
                    successDialog.setTitle("Update Successful")
                    successDialog.setMessage("Successfully updated to the latest version.\n\nClick OK to restart and apply the update.")
                    successDialog.setButton("OK", function()
                        successDialog.dismiss()
                        
                        Handler(Looper.getMainLooper()).post(Runnable({
                            run = function()
                                pcall(function() if _G.mainDialog then _G.mainDialog.dismiss() _G.mainDialog = nil end end)
                                pcall(function() if _G.mainDlg then _G.mainDlg.dismiss() _G.mainDlg = nil end end)
                                pcall(function() if _G.allDialogBox then _G.allDialogBox.dismiss() _G.allDialogBox = nil end end)
                                pcall(function() if _G.alertDialogBox then _G.alertDialogBox.dismiss() _G.alertDialogBox = nil end end)
                                
                                pcall(function() if _G.dismissAllDialogs then _G.dismissAllDialogs() end end)
                                pcall(function() if _G.dismissAll then _G.dismissAll() end end)
                                pcall(function() if _G.dismiss then _G.dismiss() end end)
                                pcall(function() if dismissAllDialogs then dismissAllDialogs() end end)
                                pcall(function() if dismissAll then dismissAll() end end)

                                pcall(function()
                                    if activity then
                                        activity.finish()
                                    end
                                end)
                            end
                        }))
                        
                        Handler(Looper.getMainLooper()).postDelayed(Runnable({
                            run = function()
                                prefs.edit().putString("lastShownVersion", "").apply()
                                local pluginFile = io.open(PLUGIN_PATH, "r")
                                if pluginFile then
                                    pluginFile:close()
                                    local func, err = loadfile(PLUGIN_PATH)
                                    if func then
                                        pcall(func)
                                    else
                                        Toast.makeText(service or activity, "Error reloading plugin: " .. tostring(err), Toast.LENGTH_SHORT).show()
                                    end
                                end
                            end
                        }), 2000)
                    end)
                    successDialog.show()
                end
            }))
            return
        else
            updateInProgress = false
            showUpdateErrorDialog("Update Failed", "Update failed. Please try again.")
        end
    end
    
    local updateThread = Thread(Runnable{
        run = updateProcess
    })
    updateThread.start()
end

local function checkUpdate()
    if updateInProgress then
        return
    end
    
    local timestamp = tostring(System.currentTimeMillis())
    Http.get(VERSION_URL .. "?t=" .. timestamp, function(code, response)
        if code == 200 and response then
            local onlineVersion = trim(response)
            if onlineVersion ~= CURRENT_VERSION then
                Http.get(UPDATE_CODE_URL .. "?t=" .. timestamp, function(code2, mainCode)
                    if code2 == 200 and mainCode and trim(mainCode) ~= "" then
                        Handler(Looper.getMainLooper()).post(Runnable({
                            run = function()
                                playNotification()
                                local updateAlertDlg = LuaDialog(service or activity)
                                updateAlertDlg.setTitle("Update Available!")
                                updateAlertDlg.setMessage("A new version (" .. onlineVersion .. ") is available.\nCurrent version: " .. CURRENT_VERSION .. "\n\nWould you like to update now?")
                                updateAlertDlg.setButton("Update Now", function()
                                    updateAlertDlg.dismiss()
                                    Toast.makeText(service or activity, "Downloading update...", Toast.LENGTH_SHORT).show()
                                    performUpdate(mainCode, onlineVersion)
                                end)
                                updateAlertDlg.setButton2("Later", function()
                                    updateAlertDlg.dismiss()
                                end)
                                updateAlertDlg.show()
                            end
                        }))
                    end
                end)
            else
                checkAndShowNewFeatures()
            end
        else
            checkAndShowNewFeatures()
        end
    end)
end

Handler(Looper.getMainLooper()).postDelayed(Runnable({
    run = function()
        checkUpdate()
    end
}), 3000)
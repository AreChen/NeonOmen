local _, ns = ...
local en = {
    UI_APPEARANCE="Appearance", UI_LAYOUT="Window layout", UI_DISPLAY="Data & labels",
    UI_VISIBILITY="Visibility", UI_WARNINGS="Threat alerts", UI_SUBTITLE="Threat control",
    UI_DESC_APPEARANCE="Shape your palette, surfaces and threat colors.",
    UI_DESC_LAYOUT="Set the size, spacing and behavior of your meter.",
    UI_DESC_DISPLAY="Choose the information that matters during combat.",
    UI_DESC_VISIBILITY="Choose when the meter appears and who it shows.",
    UI_DESC_WARNINGS="Tune the warning threshold, sound and visual alerts.",
    UI_THEME="Accent palette", UI_MATERIAL="Surface & light", UI_COLORS="Threat colors",
    UI_GEOMETRY="Size & spacing", UI_BEHAVIOR="Window behavior", UI_GROUPS="When to show",
    UI_PREVIEW="LIVE PREVIEW", UI_PREVIEW_HINT="Sample data · warning colors stay visible",
    UI_CUSTOM_COLOR="Custom color", UI_OPEN_SETTINGS="Open NeonOmen",
    UI_LAUNCHER_HINT="Open the NeonOmen control panel to change appearance, layout and alerts.",
    UI_WIDTH="Meter width", UI_WINDOW_HEIGHT="Window height", UI_SPACING="Bar spacing",
    UI_SOUND="Alert sound", UI_TEST_ON="Test meter: ON", UI_TEST_OFF="Test meter: OFF",
    UI_LIVE_HINT="Changes apply immediately.\nTest mode previews the main meter.",
    UI_GLACIER="Glacier", UI_AMETHYST="Amethyst", UI_JADE="Jade", UI_EMBER="Ember", UI_ROSE="Rose",
}
local cn = {
    UI_APPEARANCE="外观主题", UI_LAYOUT="窗口布局", UI_DISPLAY="数据与标记",
    UI_VISIBILITY="显示规则", UI_WARNINGS="仇恨警报", UI_SUBTITLE="仇恨控制台",
    UI_DESC_APPEARANCE="调整霓虹配色、面板质感与仇恨条颜色。",
    UI_DESC_LAYOUT="调整窗口尺寸、条目间距和交互方式。",
    UI_DESC_DISPLAY="选择战斗中需要关注的数据与标记。",
    UI_DESC_VISIBILITY="设置显示时机、职业筛选和小地图入口。",
    UI_DESC_WARNINGS="调整警告阈值、提示音与屏幕警报。",
    UI_THEME="霓虹配色", UI_MATERIAL="面板与光影", UI_COLORS="仇恨条颜色",
    UI_GEOMETRY="尺寸与间距", UI_BEHAVIOR="窗口交互", UI_GROUPS="显示时机",
    UI_PREVIEW="即时预览", UI_PREVIEW_HINT="示例数据 · 始终保留仇恨警告色",
    UI_CUSTOM_COLOR="自定义颜色", UI_OPEN_SETTINGS="打开 NeonOmen 设置",
    UI_LAUNCHER_HINT="打开 NeonOmen 控制台，调整外观、布局与仇恨警报。",
    UI_WIDTH="面板宽度", UI_WINDOW_HEIGHT="窗口高度", UI_SPACING="仇恨条间距",
    UI_SOUND="警报提示音", UI_TEST_ON="主面板测试：开启", UI_TEST_OFF="主面板测试：关闭",
    UI_LIVE_HINT="调整即时生效。\n测试模式可预览主面板。",
    UI_GLACIER="冰川蓝", UI_AMETHYST="紫水晶", UI_JADE="翡翠绿", UI_EMBER="余烬橙", UI_ROSE="玫瑰红",
}
local tw = {
    UI_APPEARANCE="外觀主題", UI_LAYOUT="視窗配置", UI_DISPLAY="資料與標記",
    UI_VISIBILITY="顯示規則", UI_WARNINGS="仇恨警報", UI_SUBTITLE="仇恨控制台",
    UI_DESC_APPEARANCE="調整霓虹配色、面板質感與仇恨條顏色。",
    UI_DESC_LAYOUT="調整視窗尺寸、條目間距和互動方式。",
    UI_DESC_DISPLAY="選擇戰鬥中需要關注的資料與標記。",
    UI_DESC_VISIBILITY="設定顯示時機、職業篩選和小地圖入口。",
    UI_DESC_WARNINGS="調整警告門檻、提示音與螢幕警報。",
    UI_THEME="霓虹配色", UI_MATERIAL="面板與光影", UI_COLORS="仇恨條顏色",
    UI_GEOMETRY="尺寸與間距", UI_BEHAVIOR="視窗互動", UI_GROUPS="顯示時機",
    UI_PREVIEW="即時預覽", UI_PREVIEW_HINT="範例資料 · 始終保留仇恨警告色",
    UI_CUSTOM_COLOR="自訂顏色", UI_OPEN_SETTINGS="開啟 NeonOmen 設定",
    UI_LAUNCHER_HINT="開啟 NeonOmen 控制台，調整外觀、配置與仇恨警報。",
    UI_WIDTH="面板寬度", UI_WINDOW_HEIGHT="視窗高度", UI_SPACING="仇恨條間距",
    UI_SOUND="警報提示音", UI_TEST_ON="主面板測試：開啟", UI_TEST_OFF="主面板測試：關閉",
    UI_LIVE_HINT="調整即時生效。\n測試模式可預覽主面板。",
    UI_GLACIER="冰川藍", UI_AMETHYST="紫水晶", UI_JADE="翡翠綠", UI_EMBER="餘燼橙", UI_ROSE="玫瑰紅",
}
function ns.ApplyOptionsLocale(L)
    local locale = GetLocale()
    local translated = locale == "zhCN" and cn or locale == "zhTW" and tw or en
    for key, value in pairs(en) do L[key] = translated[key] or value end
end

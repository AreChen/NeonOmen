-- NeonOmen - schlanker Threat-Meter fuer WoW Forever.
-- Eigenstaendige Neuentwicklung (kein Fork), nutzt ausschliesslich die
-- Unit-Threat-APIs (kein Combat-Log, der ist auf diesem Client gesperrt).

local addonName, ns = ...
local Theme = ns.Theme

-- WICHTIG: WoW laedt die SavedVariables erst NACH dem Ausfuehren dieser Datei
-- (direkt vor ADDON_LOADED) und ersetzt dabei die globale Tabelle. Standardwerte,
-- die nur beim Laden gesetzt werden, landen deshalb in einer Wegwerf-Tabelle --
-- daher kam frueher z. B. der Absturz durch ein fehlendes warnCooldown. InitDB()
-- laeuft darum einmal beim Laden (damit der Aufbau unten Werte hat) und noch
-- einmal in ADDON_LOADED auf der echten, gespeicherten Tabelle.
local function ValidColor(c, r, g, b)
    if type(c) == "table" and type(c.r) == "number" and type(c.g) == "number" and type(c.b) == "number" then
        return c
    end
    return { r = r, g = g, b = b }
end

local db
local function InitDB()
    OmenReloadedForeverDB = OmenReloadedForeverDB or {}
    db = OmenReloadedForeverDB
    -- Wie im Original-Omen: CENTER-Anker ist unproblematisch, SOLANGE nach der
    -- Erstellung nie wieder eigenmaechtig SetWidth/SetHeight aufgerufen wird --
    -- das native StartSizing()/StopMovingOrSizing() haelt den Anker waehrend des
    -- Ziehens korrekt konsistent. Der fruehere "Sprung"-Bug kam nicht vom Anker,
    -- sondern davon, dass RefreshBars() die Fensterhoehe bei jedem Aufruf aus der
    -- Balkenzahl neu berechnet und ueberschrieben hat -- das Fenster kaempfte mit
    -- dem Nutzer um die Kontrolle. Fix: Fenstergroesse ist jetzt eigenstaendig
    -- (frameHeight), die Balkenzahl passt sich der verfuegbaren Flaeche an, nicht
    -- umgekehrt. Einzige Ausnahme ist der optionale Autocollapse-Modus (siehe
    -- ApplyAutoCollapse), der waehrend Ziehen/Resize bewusst pausiert.
    db.point = db.point or "CENTER"
    db.relPoint = db.relPoint or "CENTER"
    db.x = db.x or 300
    db.y = db.y or 150
    db.width = db.width or 200
    db.frameHeight = db.frameHeight or 200
    db.height = db.height or 16
    db.spacing = db.spacing or 2
    -- Selbstheilung fuer kaputte Werte aus der fruehreren fehlerhaften
    -- Resize-Berechnung (Balken konnten dadurch bis zu ~100px hoch werden).
    db.width = math.min(math.max(db.width, 100), 600)
    db.frameHeight = math.min(math.max(db.frameHeight, 60), 900)
    db.height = math.min(math.max(db.height, 10), 40)
    db.yellowThreshold = math.min(math.max(db.yellowThreshold or 80, 50), 100)
    if db.locked == nil then db.locked = false end
    if db.showPets == nil then db.showPets = true end
    if db.showInCombat == nil then db.showInCombat = true end
    if db.showOutOfCombat == nil then db.showOutOfCombat = false end
    if db.useClassColors == nil then db.useClassColors = false end
    if db.useFocus == nil then db.useFocus = false end
    if db.alwaysShowSelf == nil then db.alwaysShowSelf = true end
    if db.showValue == nil then db.showValue = false end
    if db.growUp == nil then db.growUp = false end
    if db.warnSoundEnabled == nil then db.warnSoundEnabled = true end
    db.warnSound = db.warnSound or "RAID_WARNING"
    db.warnCooldown = db.warnCooldown or 4
    db.minimapAngle = db.minimapAngle or 200
    if db.showMinimapButton == nil then db.showMinimapButton = true end
    db.numBars = math.min(math.max(db.numBars or 40, 1), 40)
    if db.hideWhileResting == nil then db.hideWhileResting = false end
    if db.hideInPVP == nil then db.hideInPVP = false end
    if db.showTPS == nil then db.showTPS = false end
    db.minimapOffset = math.min(math.max(db.minimapOffset or 10, -20), 40)

    -- Sichtbarkeit nach Omens ShowWith (Solo/Pet/Gruppe/Raid). Migration vom
    -- frueheren "Nur in Gruppe/Raid anzeigen" (requireGroup).
    if db.showSolo == nil then db.showSolo = not db.requireGroup end
    if db.showWithPet == nil then db.showWithPet = not db.requireGroup end
    if db.showInParty == nil then db.showInParty = true end
    if db.showInRaid == nil then db.showInRaid = true end
    db.requireGroup = nil

    -- Weitere Omen-Features (Standardwerte wie im Original, sofern sie das
    -- bisherige Verhalten nicht unbemerkt umkrempeln).
    if db.showAggroBar == nil then db.showAggroBar = true end
    if db.warnFlash == nil then db.warnFlash = true end
    if db.warnShake == nil then db.warnShake = false end
    if db.warnMessage == nil then db.warnMessage = false end
    if db.disableWarnAsTank == nil then db.disableWarnAsTank = true end
    if db.animateBars == nil then db.animateBars = true end
    if db.autoCollapse == nil then db.autoCollapse = false end
    db.collapseHide = nil -- Option wieder entfernt (30.09.)
    if db.showTitleBar == nil then db.showTitleBar = true end
    if db.showHeader == nil then db.showHeader = true end
    if db.clickThrough == nil then db.clickThrough = false end
    if db.useMyBarColor == nil then db.useMyBarColor = false end
    if db.useTankBarColor == nil then db.useTankBarColor = false end
    if db.usePetBarColor == nil then db.usePetBarColor = false end
    if db.warnAggroTaken == nil then db.warnAggroTaken = true end
    if db.showMarkers == nil then db.showMarkers = true end
    if db.showTargetInTitle == nil then db.showTargetInTitle = true end
    db.backgroundOpacity = math.min(math.max(tonumber(db.backgroundOpacity) or 0.96, 0), 1)
    db.alpha = math.min(math.max(db.alpha or 1, 0.2), 1)
    db.scale = math.min(math.max(db.scale or 1, 0.5), 2)
    if type(db.hiddenClasses) ~= "table" then db.hiddenClasses = {} end

    db.themeColor = ValidColor(db.themeColor, 0.67, 0.83, 0.45)
    if db.showGlow == nil then db.showGlow = true end
    db.glowIntensity = math.min(math.max(tonumber(db.glowIntensity) or 0.8, 0), 1)

    db.myBarColor = ValidColor(db.myBarColor, 0.2, 0.75, 0.9)
    db.tankBarColor = ValidColor(db.tankBarColor, 0.35, 0.45, 0.95)
    db.petBarColor = ValidColor(db.petBarColor, 0.77, 0, 1)
    db.aggroBarColor = ValidColor(db.aggroBarColor, 1, 0, 0)
end
InitDB()

-- ------------------------------------------------------------
-- Lokalisierung (Englisch als Standard, Deutsch fuer deDE-Clients) --
-- gleiches Muster wie LevelProgress.
-- ------------------------------------------------------------
local L = {
    TITLE = "NeonOmen",
    TITLE_TESTMODE = "NeonOmen (Test Mode)",
    HEADER_NAME = "Name",
    HEADER_THREAT = "Threat %",
    HEADER_TPS = "TPS",
    EMPTY_TEXT = "No threat data (not in combat / no target)",
    PET_SUFFIX = " (Pet)",
    YOU = "You",
    PULL_AGGRO = "> Pull Aggro <",
    AGGRO_TAKEN = "AGGRO!",
    DEAD = "dead",
    OFFLINE = "offline",
    UNKNOWN_PCT = "?",
    TESTDATA_TANK = "Tank Dummy",
    TESTDATA_DPS = "DPS Dummy",
    TESTDATA_DUMMY_PREFIX = "Dummy",

    SEC_VISIBILITY = "Visibility",
    SEC_DISPLAY = "Display",
    SEC_COLORS = "Colors",
    SEC_CLASSES = "Show classes",
    SEC_WARNINGS = "Warnings",
    SEC_WINDOW = "Window",
    SEC_MINIMAP = "Minimap",

    OPT_COMBAT = "Show in combat",
    OPT_OUT_OF_COMBAT = "Show out of combat",
    OPT_SHOW_SOLO = "Show when solo (without pet)",
    OPT_SHOW_WITH_PET = "Show with pet",
    OPT_SHOW_PARTY = "Show in party",
    OPT_SHOW_RAID = "Show in raid",
    OPT_HIDE_RESTING = "Hide while resting (inn/city)",
    OPT_HIDE_PVP = "Hide in battlegrounds/arenas",
    OPT_SHOW_TPS = "Show threat per second (TPS, last 10 s)",
    OPT_NUM_BARS = "Max. Bars",
    OPT_SHOW_PETS = "Show pets",
    OPT_AGGRO_BAR = "Show pull aggro bar (percent then relative to the tank, like Omen)",
    OPT_ANIMATE = "Animate bars",
    OPT_SHOW_TITLE = "Show title bar",
    OPT_SHOW_HEADER = "Show column headings",
    OPT_TARGET_TITLE = "Show target name in title bar",
    OPT_SHOW_MARKERS = "Show markers ([T] tank, [!] aggro change, dead/offline)",
    OPT_CLASS_COLORS = "Class colors instead of status colors (warning colors stay)",
    OPT_MY_COLOR = "Own color for my bar",
    OPT_TANK_COLOR = "Own color for the tank",
    OPT_PET_COLOR = "Own color for pets",
    OPT_AGGRO_COLOR = "Color of the pull aggro bar",
    OPT_USE_FOCUS = "Also check focus target (before target)",
    OPT_ALWAYS_SHOW_SELF = "Always show my own bar",
    OPT_SHOW_VALUE = "Also show raw threat value",
    OPT_GROW_UP = "Grow bars upward",
    OPT_LOCKED = "Lock position",
    OPT_CLICK_THROUGH = "Click-through (mouse clicks pass through the window)",
    OPT_AUTO_COLLAPSE = "Auto-size window to the number of bars",
    OPT_ALPHA = "Opacity",
    OPT_BACKGROUND_OPACITY = "Background opacity",
    OPT_SCALE = "Scale",
    OPT_SHOW_MINIMAP = "Show minimap button",
    OPT_MINIMAP_OFFSET = "Minimap Button Distance",
    MINIMAP_TT_LEFT = "Left-click: open settings",
    MINIMAP_TT_SHIFT = "Shift-left-click: show/hide window",
    MINIMAP_TT_RIGHT = "Right-click: toggle test mode",
    MINIMAP_TT_DRAG = "Drag: move button",
    OPT_BAR_HEIGHT = "Bar Height",
    BTN_RESET_POSITION = "Reset Position",
    OPT_WARN_SOUND = "Play sound",
    OPT_WARN_FLASH = "Flash screen edge red",
    OPT_WARN_SHAKE = "Shake screen",
    OPT_WARN_MESSAGE = "Show warning text on screen",
    OPT_WARN_AGGRO_TAKEN = "Warn when a mob switches to me (AGGRO!)",
    OPT_WARN_TANK = "No warnings as tank (defensive stance, bear form, Righteous Fury, tank role)",
    OPT_WARN_THRESHOLD = "Warning threshold",
    WARN_MSG_FMT = "Passed %d%% of %s's threat!",
    BTN_TEST = "Test",
    BTN_TEST_WARN = "Test warning",
    BTN_TESTMODE_ON = "Test Mode: ON (fake bars)",
    BTN_TESTMODE_OFF = "Test Mode: OFF",

    MENU_LOCK = "Lock position",
    MENU_TESTMODE = "Test mode",
    MENU_FOCUS = "Check focus target",
    MENU_TPS = "Show TPS",
    MENU_AGGRO_BAR = "Pull aggro bar",
    MENU_HIDE = "Hide window",
    MENU_OPTIONS = "Options...",
    MENU_CLOSE = "Close",

    BIND_TOGGLE = "Show/hide window",
    BIND_FOCUS = "Toggle focus target",
    BIND_TESTMODE = "Toggle test mode",

    MSG_LOCKED = "Position locked.",
    MSG_UNLOCKED = "Position unlocked, can be moved.",
    MSG_RESET = "Position reset.",
    MSG_PETS_SHOWN = "Pets are shown.",
    MSG_PETS_HIDDEN = "Pets are hidden.",
    MSG_MINIMAP_SHOWN = "Minimap button shown.",
    MSG_MINIMAP_HIDDEN = "Minimap button hidden.",
    MSG_TESTMODE_FMT = "Test mode (fake bars): %s (window centered)",
    MSG_WINDOW_HIDDEN = "Window hidden. Show it again via /orf toggle, key binding or shift-click on the minimap button.",
    MSG_WINDOW_SHOWN = "Window shown.",
    MSG_OPTIONS_COMBAT = "Options cannot be opened in combat. They will open after combat.",
    MSG_FOCUS_FMT = "Check focus target: %s",
    MSG_SHAKE_FAIL = "Screen shake is not possible in combat on this client (WorldFrame is protected).",
    DEBUG_HEADER = "Version %s | Build %s | Interface %s | issecretvalue: %s",
    DEBUG_NO_TARGET = "No hostile target found (target / target of target / focus).",
    DEBUG_TARGET = "Target unit: %s = %s, its target: %s",
    DEBUG_UNIT = "%s: tanking=%s status=%s scaled=%s raw%%=%s threat=%s TPS=%s",
    DEBUG_AGGRO = "Aggro tracking: last tank=%s, AGGRO! warning=%s, tank role detected=%s",
    DEBUG_ME = "me",
    ON = "ON",
    OFF = "OFF",
    ERROR_PREFIX = "NeonOmen ERROR:",

    SND_RAID_WARNING = "Raid Warning (Gong)",
    SND_READY_CHECK = "Ready Check",
    SND_ALARM1 = "Alarm Clock 1",
    SND_ALARM2 = "Alarm Clock 2",
    SND_ALARM3 = "Alarm Clock 3",
    SND_TELL = "Whisper Ping",
    SND_INVITE = "Invite",
    SND_LEVELUP = "Level Up",
    SND_QUESTDONE = "Quest Complete",
    SND_AUCTION = "Auction House",
    SND_MAPPING = "Map Ping",
    SND_FELNOVA = "Fel Nova (Omen default)",
    SND_EXPLOSION = "Explosion (Whoom)",
    SND_WHAM = "Wham! (Impact)",
    SND_WARDRUMS = "War Drums (Aggro Horn)",
    SND_YOUWILLDIE = "\"You Will Die!\" (C'Thun)",
    SND_CHEER = "Cheer",
    SND_DUCKY = "Rubber Ducky",
    OPT_THEME_COLOR = "Theme color", OPT_GLOW = "Show glow", OPT_GLOW_INTENSITY = "Glow intensity",
}

if GetLocale() == "deDE" then
    L.TITLE_TESTMODE = "NeonOmen (Testmodus)"
    L.HEADER_THREAT = "Threat %"
    L.EMPTY_TEXT = "Keine Threat-Daten (kein Kampf/kein Ziel)"
    L.YOU = "Du"
    L.PULL_AGGRO = "> Aggro ziehen <"
    L.DEAD = "tot"
    L.OFFLINE = "offline"
    L.TESTDATA_TANK = "Tank-Dummy"
    L.TESTDATA_DPS = "DPS-Dummy"

    L.SEC_VISIBILITY = "Sichtbarkeit"
    L.SEC_DISPLAY = "Anzeige"
    L.SEC_COLORS = "Farben"
    L.SEC_CLASSES = "Klassen anzeigen"
    L.SEC_WARNINGS = "Warnungen"
    L.SEC_WINDOW = "Fenster"
    L.SEC_MINIMAP = "Minimap"

    L.OPT_COMBAT = "Im Kampf anzeigen"
    L.OPT_OUT_OF_COMBAT = "Außerhalb des Kampfes anzeigen"
    L.OPT_SHOW_SOLO = "Solo anzeigen (ohne Pet)"
    L.OPT_SHOW_WITH_PET = "Mit Pet anzeigen"
    L.OPT_SHOW_PARTY = "In Gruppe anzeigen"
    L.OPT_SHOW_RAID = "Im Schlachtzug anzeigen"
    L.OPT_HIDE_RESTING = "Beim Ausruhen ausblenden (Gasthaus/Stadt)"
    L.OPT_HIDE_PVP = "In Schlachtfeldern/Arenen ausblenden"
    L.OPT_SHOW_TPS = "Threat pro Sekunde anzeigen (TPS, letzte 10 s)"
    L.OPT_NUM_BARS = "Max. Balken"
    L.OPT_SHOW_PETS = "Pets anzeigen"
    L.OPT_AGGRO_BAR = "Aggro-ziehen-Balken anzeigen (Prozent dann relativ zum Tank, wie Omen)"
    L.OPT_ANIMATE = "Balken animieren"
    L.OPT_SHOW_TITLE = "Titelleiste anzeigen"
    L.OPT_SHOW_HEADER = "Spaltenüberschriften anzeigen"
    L.OPT_TARGET_TITLE = "Zielname in der Titelleiste anzeigen"
    L.OPT_SHOW_MARKERS = "Markierungen anzeigen ([T] Tank, [!] Aggro-Wechsel, tot/offline)"
    L.OPT_CLASS_COLORS = "Klassenfarben statt Status-Farben (Warnfarben bleiben)"
    L.OPT_MY_COLOR = "Eigene Farbe für meinen Balken"
    L.OPT_TANK_COLOR = "Eigene Farbe für den Tank"
    L.OPT_PET_COLOR = "Eigene Farbe für Pets"
    L.OPT_AGGRO_COLOR = "Farbe des Aggro-ziehen-Balkens"
    L.OPT_USE_FOCUS = "Auch Fokus-Ziel prüfen (vor dem Ziel)"
    L.OPT_ALWAYS_SHOW_SELF = "Eigene Zeile immer anzeigen"
    L.OPT_SHOW_VALUE = "Rohen Threat-Wert zusätzlich anzeigen"
    L.OPT_GROW_UP = "Balken nach oben wachsen lassen"
    L.OPT_LOCKED = "Position sperren"
    L.OPT_CLICK_THROUGH = "Durchklickbar (Mausklicks gehen durch das Fenster)"
    L.OPT_AUTO_COLLAPSE = "Fensterhöhe automatisch an die Balkenzahl anpassen"
    L.OPT_ALPHA = "Deckkraft"
    L.OPT_SCALE = "Skalierung"
    L.OPT_SHOW_MINIMAP = "Minimap-Button anzeigen"
    L.OPT_MINIMAP_OFFSET = "Minimap-Button Abstand"
    L.MINIMAP_TT_LEFT = "Linksklick: Einstellungen öffnen"
    L.MINIMAP_TT_SHIFT = "Shift-Linksklick: Fenster ein-/ausblenden"
    L.MINIMAP_TT_RIGHT = "Rechtsklick: Testmodus an/aus"
    L.MINIMAP_TT_DRAG = "Ziehen: Button verschieben"
    L.OPT_BAR_HEIGHT = "Balkenhöhe"
    L.BTN_RESET_POSITION = "Position zurücksetzen"
    L.OPT_WARN_SOUND = "Ton abspielen"
    L.OPT_WARN_FLASH = "Bildschirmrand rot aufblinken lassen"
    L.OPT_WARN_SHAKE = "Bildschirm wackeln lassen"
    L.OPT_WARN_MESSAGE = "Warntext auf dem Bildschirm anzeigen"
    L.OPT_WARN_AGGRO_TAKEN = "Warnung, wenn ein Gegner auf mich wechselt (AGGRO!)"
    L.OPT_WARN_TANK = "Keine Warnungen als Tank (Verteidigungshaltung, Bär, Zorn der Gerechtigkeit, Tank-Rolle)"
    L.OPT_WARN_THRESHOLD = "Warnschwelle"
    L.WARN_MSG_FMT = "%d%% von %ss Threat überschritten!"
    L.BTN_TEST = "Testen"
    L.BTN_TEST_WARN = "Warnung testen"
    L.BTN_TESTMODE_ON = "Testmodus: AN (Fake-Balken)"
    L.BTN_TESTMODE_OFF = "Testmodus: AUS"

    L.MENU_LOCK = "Position sperren"
    L.MENU_TESTMODE = "Testmodus"
    L.MENU_FOCUS = "Fokus-Ziel prüfen"
    L.MENU_TPS = "TPS anzeigen"
    L.MENU_AGGRO_BAR = "Aggro-ziehen-Balken"
    L.MENU_HIDE = "Fenster ausblenden"
    L.MENU_OPTIONS = "Optionen..."
    L.MENU_CLOSE = "Schließen"

    L.BIND_TOGGLE = "Fenster ein-/ausblenden"
    L.BIND_FOCUS = "Fokus-Ziel an/aus"
    L.BIND_TESTMODE = "Testmodus an/aus"

    L.MSG_LOCKED = "Position gesperrt."
    L.MSG_UNLOCKED = "Position entsperrt, kann verschoben werden."
    L.MSG_RESET = "Position zurueckgesetzt."
    L.MSG_PETS_SHOWN = "Pets werden angezeigt."
    L.MSG_PETS_HIDDEN = "Pets werden ausgeblendet."
    L.MSG_MINIMAP_SHOWN = "Minimap-Button wird angezeigt."
    L.MSG_MINIMAP_HIDDEN = "Minimap-Button ausgeblendet."
    L.MSG_TESTMODE_FMT = "Testmodus (Fake-Balken): %s (Fenster in Bildschirmmitte)"
    L.MSG_WINDOW_HIDDEN = "Fenster ausgeblendet. Wieder einblenden mit /orf toggle, Tastenbelegung oder Shift-Klick auf den Minimap-Button."
    L.MSG_WINDOW_SHOWN = "Fenster eingeblendet."
    L.MSG_OPTIONS_COMBAT = "Optionen lassen sich im Kampf nicht öffnen. Sie öffnen sich nach dem Kampf."
    L.MSG_FOCUS_FMT = "Fokus-Ziel prüfen: %s"
    L.MSG_SHAKE_FAIL = "Bildschirmwackeln ist auf diesem Client im Kampf nicht möglich (WorldFrame ist geschützt)."
    L.DEBUG_NO_TARGET = "Kein feindliches Ziel gefunden (Ziel / Ziel des Ziels / Fokus)."
    L.DEBUG_TARGET = "Ziel-Unit: %s = %s, dessen Ziel: %s"
    L.DEBUG_AGGRO = "Aggro-Verfolgung: letzter Tank=%s, AGGRO!-Warnung=%s, als Tank erkannt=%s"
    L.DEBUG_ME = "ich"
    L.ON = "AN"
    L.OFF = "AUS"

    L.SND_RAID_WARNING = "Raidwarnung (Gong)"
    L.SND_READY_CHECK = "Bereit-Check"
    L.SND_ALARM1 = "Wecker 1"
    L.SND_ALARM2 = "Wecker 2"
    L.SND_ALARM3 = "Wecker 3"
    L.SND_TELL = "Flüster-Ping"
    L.SND_INVITE = "Einladung"
    L.SND_LEVELUP = "Levelaufstieg"
    L.SND_QUESTDONE = "Quest abgeschlossen"
    L.SND_AUCTION = "Auktionshaus"
    L.SND_MAPPING = "Karten-Ping"
    L.SND_FELNOVA = "Fel Nova (Omen-Standardton)"
    L.SND_WARDRUMS = "Kriegstrommeln (Aggro-Horn)"
    L.SND_CHEER = "Jubel"
    L.SND_DUCKY = "Quietsche-Ente"
end

-- Franzoesisch (frFR). Uebersetzt mit den Begriffen des franzoesischen
-- WoW-Clients, nicht von Muttersprachlern gegengelesen.
if GetLocale() == "frFR" then
    L.TITLE_TESTMODE = "NeonOmen (Mode test)"
    L.HEADER_NAME = "Nom"
    L.HEADER_THREAT = "Menace %"
    L.EMPTY_TEXT = "Aucune donnée de menace (hors combat / pas de cible)"
    L.PET_SUFFIX = " (Familier)"
    L.YOU = "Vous"
    L.PULL_AGGRO = "> Prise d'aggro <"
    L.DEAD = "mort"
    L.OFFLINE = "hors ligne"
    L.TESTDATA_TANK = "Mannequin tank"
    L.TESTDATA_DPS = "Mannequin DPS"
    L.TESTDATA_DUMMY_PREFIX = "Mannequin"

    L.SEC_VISIBILITY = "Visibilité"
    L.SEC_DISPLAY = "Affichage"
    L.SEC_COLORS = "Couleurs"
    L.SEC_CLASSES = "Classes affichées"
    L.SEC_WARNINGS = "Alertes"
    L.SEC_WINDOW = "Fenêtre"
    L.SEC_MINIMAP = "Minicarte"

    L.OPT_COMBAT = "Afficher en combat"
    L.OPT_OUT_OF_COMBAT = "Afficher hors combat"
    L.OPT_SHOW_SOLO = "Afficher en solo (sans familier)"
    L.OPT_SHOW_WITH_PET = "Afficher avec un familier"
    L.OPT_SHOW_PARTY = "Afficher en groupe"
    L.OPT_SHOW_RAID = "Afficher en raid"
    L.OPT_HIDE_RESTING = "Masquer au repos (auberge/ville)"
    L.OPT_HIDE_PVP = "Masquer en champ de bataille/arène"
    L.OPT_SHOW_TPS = "Afficher la menace par seconde (TPS, 10 dernières s)"
    L.OPT_NUM_BARS = "Barres max."
    L.OPT_SHOW_PETS = "Afficher les familiers"
    L.OPT_AGGRO_BAR = "Afficher la barre de prise d'aggro (pourcentages alors relatifs au tank, comme Omen)"
    L.OPT_ANIMATE = "Animer les barres"
    L.OPT_SHOW_TITLE = "Afficher la barre de titre"
    L.OPT_SHOW_HEADER = "Afficher les en-têtes de colonnes"
    L.OPT_TARGET_TITLE = "Afficher le nom de la cible dans le titre"
    L.OPT_SHOW_MARKERS = "Afficher les repères ([T] tank, [!] changement d'aggro, mort/hors ligne)"
    L.OPT_CLASS_COLORS = "Couleurs de classe au lieu des couleurs d'état (les alertes restent)"
    L.OPT_MY_COLOR = "Couleur personnalisée pour ma barre"
    L.OPT_TANK_COLOR = "Couleur personnalisée pour le tank"
    L.OPT_PET_COLOR = "Couleur personnalisée pour les familiers"
    L.OPT_AGGRO_COLOR = "Couleur de la barre de prise d'aggro"
    L.OPT_USE_FOCUS = "Vérifier aussi la focalisation (avant la cible)"
    L.OPT_ALWAYS_SHOW_SELF = "Toujours afficher ma barre"
    L.OPT_SHOW_VALUE = "Afficher aussi la valeur brute de menace"
    L.OPT_GROW_UP = "Barres vers le haut"
    L.OPT_LOCKED = "Verrouiller la position"
    L.OPT_CLICK_THROUGH = "Transparent aux clics (les clics traversent la fenêtre)"
    L.OPT_AUTO_COLLAPSE = "Adapter la hauteur de la fenêtre au nombre de barres"
    L.OPT_ALPHA = "Opacité"
    L.OPT_SCALE = "Échelle"
    L.OPT_SHOW_MINIMAP = "Afficher le bouton de la minicarte"
    L.OPT_MINIMAP_OFFSET = "Distance du bouton de la minicarte"
    L.MINIMAP_TT_LEFT = "Clic gauche : ouvrir les options"
    L.MINIMAP_TT_SHIFT = "Maj + clic gauche : afficher/masquer la fenêtre"
    L.MINIMAP_TT_RIGHT = "Clic droit : mode test on/off"
    L.MINIMAP_TT_DRAG = "Glisser : déplacer le bouton"
    L.OPT_BAR_HEIGHT = "Hauteur des barres"
    L.BTN_RESET_POSITION = "Réinitialiser la position"
    L.OPT_WARN_SOUND = "Jouer un son"
    L.OPT_WARN_FLASH = "Faire clignoter le bord de l'écran en rouge"
    L.OPT_WARN_SHAKE = "Secouer l'écran"
    L.OPT_WARN_MESSAGE = "Afficher un texte d'alerte à l'écran"
    L.OPT_WARN_AGGRO_TAKEN = "Alerter quand un ennemi passe sur moi (AGGRO!)"
    L.OPT_WARN_TANK = "Pas d'alertes en tant que tank (posture défensive, forme d'ours, Fureur vertueuse, rôle tank)"
    L.OPT_WARN_THRESHOLD = "Seuil d'alerte"
    L.WARN_MSG_FMT = "%d%% de la menace de %s dépassés !"
    L.BTN_TEST = "Tester"
    L.BTN_TEST_WARN = "Tester l'alerte"
    L.BTN_TESTMODE_ON = "Mode test : ON (fausses barres)"
    L.BTN_TESTMODE_OFF = "Mode test : OFF"

    L.MENU_LOCK = "Verrouiller la position"
    L.MENU_TESTMODE = "Mode test"
    L.MENU_FOCUS = "Vérifier la focalisation"
    L.MENU_TPS = "Afficher les TPS"
    L.MENU_AGGRO_BAR = "Barre de prise d'aggro"
    L.MENU_HIDE = "Masquer la fenêtre"
    L.MENU_OPTIONS = "Options..."
    L.MENU_CLOSE = "Fermer"

    L.BIND_TOGGLE = "Afficher/masquer la fenêtre"
    L.BIND_FOCUS = "Focalisation on/off"
    L.BIND_TESTMODE = "Mode test on/off"

    L.MSG_LOCKED = "Position verrouillée."
    L.MSG_UNLOCKED = "Position déverrouillée, la fenêtre peut être déplacée."
    L.MSG_RESET = "Position réinitialisée."
    L.MSG_PETS_SHOWN = "Les familiers sont affichés."
    L.MSG_PETS_HIDDEN = "Les familiers sont masqués."
    L.MSG_MINIMAP_SHOWN = "Bouton de la minicarte affiché."
    L.MSG_MINIMAP_HIDDEN = "Bouton de la minicarte masqué."
    L.MSG_TESTMODE_FMT = "Mode test (fausses barres) : %s (fenêtre centrée)"
    L.MSG_WINDOW_HIDDEN = "Fenêtre masquée. Pour la réafficher : /orf toggle, raccourci clavier ou Maj + clic sur le bouton de la minicarte."
    L.MSG_WINDOW_SHOWN = "Fenêtre affichée."
    L.MSG_OPTIONS_COMBAT = "Les options ne peuvent pas être ouvertes en combat. Elles s'ouvriront après le combat."
    L.MSG_FOCUS_FMT = "Vérifier la focalisation : %s"
    L.MSG_SHAKE_FAIL = "Impossible de secouer l'écran en combat sur ce client (WorldFrame est protégé)."
    L.DEBUG_NO_TARGET = "Aucune cible hostile trouvée (cible / cible de la cible / focalisation)."
    L.DEBUG_TARGET = "Unité cible : %s = %s, sa cible : %s"
    L.DEBUG_AGGRO = "Suivi de l'aggro : dernier tank=%s, alerte AGGRO!=%s, rôle tank détecté=%s"
    L.DEBUG_ME = "moi"
    L.ERROR_PREFIX = "NeonOmen ERREUR :"

    L.SND_RAID_WARNING = "Avertissement de raid (gong)"
    L.SND_READY_CHECK = "Appel"
    L.SND_ALARM1 = "Réveil 1"
    L.SND_ALARM2 = "Réveil 2"
    L.SND_ALARM3 = "Réveil 3"
    L.SND_TELL = "Chuchotement"
    L.SND_INVITE = "Invitation"
    L.SND_LEVELUP = "Niveau supérieur"
    L.SND_QUESTDONE = "Quête terminée"
    L.SND_AUCTION = "Hôtel des ventes"
    L.SND_MAPPING = "Signal sur la carte"
    L.SND_FELNOVA = "Nova gangrenée (son par défaut d'Omen)"
    L.SND_WARDRUMS = "Tambours de guerre (cor d'aggro)"
    L.SND_CHEER = "Acclamations"
    L.SND_DUCKY = "Canard en caoutchouc"
end

-- Spanisch (esES Spanien, esMX Lateinamerika -- gleiche Texte). Uebersetzt
-- mit den Begriffen des spanischen WoW-Clients, nicht gegengelesen.
if GetLocale() == "esES" or GetLocale() == "esMX" then
    L.TITLE_TESTMODE = "NeonOmen (Modo de prueba)"
    L.HEADER_NAME = "Nombre"
    L.HEADER_THREAT = "Amenaza %"
    L.EMPTY_TEXT = "Sin datos de amenaza (fuera de combate / sin objetivo)"
    L.PET_SUFFIX = " (Mascota)"
    L.YOU = "Tú"
    L.PULL_AGGRO = "> Atraer aggro <"
    L.DEAD = "muerto"
    L.OFFLINE = "desconectado"
    L.TESTDATA_TANK = "Muñeco tanque"
    L.TESTDATA_DPS = "Muñeco DPS"
    L.TESTDATA_DUMMY_PREFIX = "Muñeco"

    L.SEC_VISIBILITY = "Visibilidad"
    L.SEC_DISPLAY = "Presentación"
    L.SEC_COLORS = "Colores"
    L.SEC_CLASSES = "Clases mostradas"
    L.SEC_WARNINGS = "Avisos"
    L.SEC_WINDOW = "Ventana"
    L.SEC_MINIMAP = "Minimapa"

    L.OPT_COMBAT = "Mostrar en combate"
    L.OPT_OUT_OF_COMBAT = "Mostrar fuera de combate"
    L.OPT_SHOW_SOLO = "Mostrar en solitario (sin mascota)"
    L.OPT_SHOW_WITH_PET = "Mostrar con mascota"
    L.OPT_SHOW_PARTY = "Mostrar en grupo"
    L.OPT_SHOW_RAID = "Mostrar en banda"
    L.OPT_HIDE_RESTING = "Ocultar al descansar (posada/ciudad)"
    L.OPT_HIDE_PVP = "Ocultar en campos de batalla/arenas"
    L.OPT_SHOW_TPS = "Mostrar amenaza por segundo (TPS, últimos 10 s)"
    L.OPT_NUM_BARS = "Barras máx."
    L.OPT_SHOW_PETS = "Mostrar mascotas"
    L.OPT_AGGRO_BAR = "Mostrar barra de atraer aggro (porcentajes relativos al tanque, como Omen)"
    L.OPT_ANIMATE = "Animar barras"
    L.OPT_SHOW_TITLE = "Mostrar barra de título"
    L.OPT_SHOW_HEADER = "Mostrar encabezados de columna"
    L.OPT_TARGET_TITLE = "Mostrar el nombre del objetivo en el título"
    L.OPT_SHOW_MARKERS = "Mostrar marcas ([T] tanque, [!] cambio de aggro, muerto/desconectado)"
    L.OPT_CLASS_COLORS = "Colores de clase en vez de colores de estado (los avisos se mantienen)"
    L.OPT_MY_COLOR = "Color propio para mi barra"
    L.OPT_TANK_COLOR = "Color propio para el tanque"
    L.OPT_PET_COLOR = "Color propio para las mascotas"
    L.OPT_AGGRO_COLOR = "Color de la barra de atraer aggro"
    L.OPT_USE_FOCUS = "Comprobar también el foco (antes del objetivo)"
    L.OPT_ALWAYS_SHOW_SELF = "Mostrar siempre mi barra"
    L.OPT_SHOW_VALUE = "Mostrar también el valor bruto de amenaza"
    L.OPT_GROW_UP = "Barras hacia arriba"
    L.OPT_LOCKED = "Bloquear posición"
    L.OPT_CLICK_THROUGH = "Ignorar clics (los clics atraviesan la ventana)"
    L.OPT_AUTO_COLLAPSE = "Ajustar la altura de la ventana al número de barras"
    L.OPT_ALPHA = "Opacidad"
    L.OPT_SCALE = "Escala"
    L.OPT_SHOW_MINIMAP = "Mostrar botón del minimapa"
    L.OPT_MINIMAP_OFFSET = "Distancia del botón del minimapa"
    L.MINIMAP_TT_LEFT = "Clic izquierdo: abrir opciones"
    L.MINIMAP_TT_SHIFT = "Mayús + clic izquierdo: mostrar/ocultar ventana"
    L.MINIMAP_TT_RIGHT = "Clic derecho: modo de prueba sí/no"
    L.MINIMAP_TT_DRAG = "Arrastrar: mover el botón"
    L.OPT_BAR_HEIGHT = "Altura de barras"
    L.BTN_RESET_POSITION = "Restablecer posición"
    L.OPT_WARN_SOUND = "Reproducir sonido"
    L.OPT_WARN_FLASH = "Destello rojo en el borde de la pantalla"
    L.OPT_WARN_SHAKE = "Sacudir la pantalla"
    L.OPT_WARN_MESSAGE = "Mostrar texto de aviso en pantalla"
    L.OPT_WARN_AGGRO_TAKEN = "Avisar cuando un enemigo cambia a mí (AGGRO!)"
    L.OPT_WARN_TANK = "Sin avisos como tanque (actitud defensiva, forma de oso, Furia recta, rol de tanque)"
    L.OPT_WARN_THRESHOLD = "Umbral de aviso"
    L.WARN_MSG_FMT = "¡Superado el %d%% de la amenaza de %s!"
    L.BTN_TEST = "Probar"
    L.BTN_TEST_WARN = "Probar aviso"
    L.BTN_TESTMODE_ON = "Modo de prueba: SÍ (barras falsas)"
    L.BTN_TESTMODE_OFF = "Modo de prueba: NO"

    L.MENU_LOCK = "Bloquear posición"
    L.MENU_TESTMODE = "Modo de prueba"
    L.MENU_FOCUS = "Comprobar foco"
    L.MENU_TPS = "Mostrar TPS"
    L.MENU_AGGRO_BAR = "Barra de atraer aggro"
    L.MENU_HIDE = "Ocultar ventana"
    L.MENU_OPTIONS = "Opciones..."
    L.MENU_CLOSE = "Cerrar"

    L.BIND_TOGGLE = "Mostrar/ocultar ventana"
    L.BIND_FOCUS = "Foco sí/no"
    L.BIND_TESTMODE = "Modo de prueba sí/no"

    L.MSG_LOCKED = "Posición bloqueada."
    L.MSG_UNLOCKED = "Posición desbloqueada, se puede mover."
    L.MSG_RESET = "Posición restablecida."
    L.MSG_PETS_SHOWN = "Se muestran las mascotas."
    L.MSG_PETS_HIDDEN = "Se ocultan las mascotas."
    L.MSG_MINIMAP_SHOWN = "Botón del minimapa visible."
    L.MSG_MINIMAP_HIDDEN = "Botón del minimapa oculto."
    L.MSG_TESTMODE_FMT = "Modo de prueba (barras falsas): %s (ventana centrada)"
    L.MSG_WINDOW_HIDDEN = "Ventana oculta. Para mostrarla de nuevo: /orf toggle, atajo de teclado o Mayús + clic en el botón del minimapa."
    L.MSG_WINDOW_SHOWN = "Ventana visible."
    L.MSG_OPTIONS_COMBAT = "Las opciones no se pueden abrir en combate. Se abrirán después del combate."
    L.MSG_FOCUS_FMT = "Comprobar foco: %s"
    L.MSG_SHAKE_FAIL = "No se puede sacudir la pantalla en combate en este cliente (WorldFrame está protegido)."
    L.DEBUG_NO_TARGET = "No se encontró ningún objetivo hostil (objetivo / objetivo del objetivo / foco)."
    L.DEBUG_TARGET = "Unidad objetivo: %s = %s, su objetivo: %s"
    L.DEBUG_AGGRO = "Seguimiento de aggro: último tanque=%s, aviso AGGRO!=%s, rol de tanque detectado=%s"
    L.DEBUG_ME = "yo"
    L.ON = "SÍ"
    L.OFF = "NO"
    L.ERROR_PREFIX = "NeonOmen ERROR:"

    L.SND_RAID_WARNING = "Aviso de banda (gong)"
    L.SND_READY_CHECK = "Comprobación de listos"
    L.SND_ALARM1 = "Despertador 1"
    L.SND_ALARM2 = "Despertador 2"
    L.SND_ALARM3 = "Despertador 3"
    L.SND_TELL = "Susurro"
    L.SND_INVITE = "Invitación"
    L.SND_LEVELUP = "Subida de nivel"
    L.SND_QUESTDONE = "Misión completada"
    L.SND_AUCTION = "Casa de subastas"
    L.SND_MAPPING = "Señal en el mapa"
    L.SND_FELNOVA = "Nova vil (sonido por defecto de Omen)"
    L.SND_WARDRUMS = "Tambores de guerra (cuerno de aggro)"
    L.SND_CHEER = "Vítores"
    L.SND_DUCKY = "Patito de goma"
end

-- Tastenbelegungen (Bindings.xml ruft die globalen Funktionen unten auf).
ns.ApplyLocale(L)

BINDING_HEADER_OMENRELOADEDFOREVER = "NeonOmen"
BINDING_NAME_ORF_TOGGLE = L.BIND_TOGGLE
BINDING_NAME_ORF_TOGGLEFOCUS = L.BIND_FOCUS
BINDING_NAME_ORF_TESTMODE = L.BIND_TESTMODE

local MAX_BARS = 40
local ORF = { bars = {} }
local testMode = false
-- Manuelles Ein-/Ausblenden (Taste, Menue, /orf toggle) wie Omens
-- manualToggle: nil = automatisch, "hidden"/"shown" = vom Nutzer erzwungen.
-- Bewusst nur fuer die laufende Sitzung, nicht gespeichert.
local manualState = nil

local function Print(msg)
    print("|cff20b2ff" .. L.TITLE .. ":|r " .. msg)
end

-- Geschuetzte Werte ("secret values"): WoW Forever liefert vor allem in
-- Gruppen/Dungeons teils geschuetzte Zahlen und Booleans, z. B. aus
-- UnitDetailedThreatSituation oder UnitIsUnit (bekannt aus ForeverThreat, das
-- im 5er-Dungeon getestet wurde). Jeder Vergleich, jede Rechnung und jeder
-- Boolean-Test damit wirft einen Fehler. Darum jeden API-Wert zuerst mit
-- issecretvalue() pruefen und geschuetzte Werte wie "unbekannt" (nil) behandeln.
local function IsSecret(value)
    return issecretvalue ~= nil and issecretvalue(value) == true
end

local function Unsecret(value)
    if IsSecret(value) then return nil end
    return value
end

-- Einzelwert-API-Aufruf: nil bei Fehler oder geschuetztem Ergebnis.
local function SafeCall(fn, ...)
    local ok, result = pcall(fn, ...)
    if not ok then return nil end
    return Unsecret(result)
end

local function SafeText(value)
    if IsSecret(value) then return "<secret>" end
    if value == nil then return "nil" end
    return tostring(value)
end

-- Die Klassen dieses Clients (Classic-Basis). Nur fuer den Klassen-Filter.
local FILTER_CLASSES = {
    "WARRIOR", "PALADIN", "HUNTER", "ROGUE", "PRIEST",
    "SHAMAN", "MAGE", "WARLOCK", "DRUID",
}

-- Fake-Daten fuer den Testmodus: Blizzards Threat-API liefert ausserhalb des
-- Kampfes grundsaetzlich keine Werte (auch mit Ziel), darum braucht es fuer
-- Positionierung/Vorschau eine Kunstschaltung wie beim Original-Omen.
local TEST_CLASSES = {
    "WARRIOR", "PALADIN", "HUNTER", "ROGUE", "PRIEST", "SHAMAN", "MAGE",
    "WARLOCK", "DRUID",
}

local function GetTestData()
    local _, playerClass = UnitClass("player")
    local data = {
        { unit = "party1", guid = "party1", name = L.TESTDATA_TANK, classToken = "WARRIOR", isTanking = true, status = 3, scaledPct = 100, rawPct = 100, threatValue = 10000 },
        { unit = "party2", guid = "party2", name = L.TESTDATA_DPS, classToken = "MAGE", isTanking = false, status = 1, scaledPct = 96, rawPct = 104, threatValue = 10400 },
        { unit = "player", guid = "player", name = UnitName("player") or L.YOU, classToken = playerClass, isTanking = false, status = 0, scaledPct = 82, rawPct = 82, threatValue = 8200 },
        { unit = "pet", guid = "pet", name = (UnitName("pet") or "Pet") .. L.PET_SUFFIX, classToken = nil, isTanking = false, status = 0, scaledPct = 30, rawPct = 30, threatValue = 3000 },
    }
    for i = 5, 20 do
        local pct = math.max(2, 78 - (i - 5) * 5)
        data[i] = {
            unit = "party" .. i,
            guid = "party" .. i,
            name = L.TESTDATA_DUMMY_PREFIX .. (i - 4),
            classToken = TEST_CLASSES[((i - 5) % #TEST_CLASSES) + 1],
            isTanking = false,
            status = 0,
            scaledPct = pct,
            rawPct = pct,
            threatValue = pct * 100,
            isDead = (i == 9),
        }
    end
    return data
end

-- Zwei Quellen: eingebaute Blizzard-SOUNDKIT-Namen (per Existenzcheck
-- abgesichert) und feste FileDataIDs, direkt aus dem Original-Omen-Quellcode
-- uebernommen (dort via LibSharedMedia registriert) -- verifiziert, kein
-- Rateversuch mehr. "file" hat Vorrang, falls beides gesetzt waere.
local SOUND_CHOICES = {
    { id = "RAID_WARNING", kit = "RAID_WARNING", label = L.SND_RAID_WARNING },
    { id = "READY_CHECK", kit = "READY_CHECK", label = L.SND_READY_CHECK },
    { id = "ALARM1", kit = "ALARM_CLOCK_WARNING_1", label = L.SND_ALARM1 },
    { id = "ALARM2", kit = "ALARM_CLOCK_WARNING_2", label = L.SND_ALARM2 },
    { id = "ALARM3", kit = "ALARM_CLOCK_WARNING_3", label = L.SND_ALARM3 },
    { id = "TELL", kit = "TELL_MESSAGE", label = L.SND_TELL },
    { id = "INVITE", kit = "IG_PLAYER_INVITE", label = L.SND_INVITE },
    { id = "LEVELUP", kit = "LEVEL_UP", label = L.SND_LEVELUP },
    { id = "QUESTDONE", kit = "IG_QUEST_LIST_COMPLETE", label = L.SND_QUESTDONE },
    { id = "AUCTION", kit = "AUCTION_WINDOW_OPEN", label = L.SND_AUCTION },
    { id = "MAPPING", kit = "MAP_PING", label = L.SND_MAPPING },
    -- Aus Omen.lua uebernommen (dort LSM:Register("sound", ..., fileID)):
    { id = "FELNOVA", file = 568582, label = L.SND_FELNOVA },
    { id = "EXPLOSION", file = 566982, label = L.SND_EXPLOSION },
    { id = "WHAM", file = 566946, label = L.SND_WHAM },
    { id = "WARDRUMS", file = 567275, label = L.SND_WARDRUMS },
    { id = "YOUWILLDIE", file = 546633, label = L.SND_YOUWILLDIE },
    { id = "CHEER", file = 567283, label = L.SND_CHEER },
    { id = "DUCKY", file = 566121, label = L.SND_DUCKY },
}

local function GetSoundChoice(id)
    for _, choice in ipairs(SOUND_CHOICES) do
        if choice.id == id then return choice end
    end
    return nil
end

local function GetSoundLabel(id)
    local choice = GetSoundChoice(id)
    return choice and choice.label or id
end

local function PlaySoundChoice(choice)
    if not choice then return end
    if choice.file then
        PlaySoundFile(choice.file, "Master")
    elseif choice.kit and SOUNDKIT and SOUNDKIT[choice.kit] then
        PlaySound(SOUNDKIT[choice.kit], "Master")
    end
end

local function PlayWarnSound()
    PlaySoundChoice(GetSoundChoice(db.warnSound))
end

-- ------------------------------------------------------------
-- Visuelle Warnungen, aus Omen:Flash()/Omen:Shake() uebernommen
-- ------------------------------------------------------------
local flashFrame
local function Flash()
    if not flashFrame then
        flashFrame = CreateFrame("Frame", "OmenReloadedForeverFlashFrame")
        flashFrame:SetToplevel(true)
        flashFrame:SetFrameStrata("FULLSCREEN_DIALOG")
        flashFrame:SetAllPoints(UIParent)
        flashFrame:EnableMouse(false)
        flashFrame:Hide()
        local tex = flashFrame:CreateTexture(nil, "BACKGROUND")
        tex:SetTexture("Interface\\FullScreenTextures\\LowHealth")
        tex:SetAllPoints(UIParent)
        tex:SetBlendMode("ADD")
        flashFrame:SetScript("OnShow", function(self)
            self.elapsed = 0
            self:SetAlpha(0)
        end)
        -- Zweimal pulsieren (2 x 1,3 s), wie im Original.
        flashFrame:SetScript("OnUpdate", function(self, elapsed)
            elapsed = self.elapsed + elapsed
            if elapsed < 2.6 then
                local alpha = elapsed % 1.3
                if alpha < 0.15 then
                    self:SetAlpha(alpha / 0.15)
                elseif alpha < 0.9 then
                    self:SetAlpha(1 - (alpha - 0.15) / 0.75)
                else
                    self:SetAlpha(0)
                end
            else
                self:Hide()
            end
            self.elapsed = elapsed
        end)
    end
    flashFrame:Hide()
    flashFrame:Show()
end

-- Verschiebt kurz den WorldFrame. Ist der im Kampf geschuetzt (passiert laut
-- Omen, sobald Namensplaketten einmal an waren), wird abgebrochen statt zu
-- tainten -- mit einmaliger Chat-Meldung.
local shakeFrame
local function Shake()
    if not shakeFrame then
        shakeFrame = CreateFrame("Frame", nil, UIParent)
        shakeFrame:Hide()
        shakeFrame:SetScript("OnShow", function(self)
            if not self.originalPoints then
                self.originalPoints = {}
                for i = 1, WorldFrame:GetNumPoints() do
                    self.originalPoints[#self.originalPoints + 1] = { WorldFrame:GetPoint(i) }
                end
            end
            self.elapsed = 0
        end)
        shakeFrame:SetScript("OnUpdate", function(self, elapsed)
            elapsed = self.elapsed + elapsed
            local x, y = 0, 0
            if elapsed >= 0.8 then
                self:Hide()
            else
                x, y = math.random(-8, 8), math.random(-8, 8)
            end
            if WorldFrame:IsProtected() and InCombatLockdown() then
                if not self.failed then
                    Print(L.MSG_SHAKE_FAIL)
                    self.failed = true
                end
                self:Hide()
            else
                WorldFrame:ClearAllPoints()
                for _, p in ipairs(self.originalPoints) do
                    WorldFrame:SetPoint(p[1], p[2], p[3], p[4] + x, p[5] + y)
                end
            end
            self.elapsed = elapsed
        end)
    end
    shakeFrame:Show()
end

local function ShowWarnMessage(text)
    if RaidNotice_AddMessage and RaidWarningFrame and ChatTypeInfo and ChatTypeInfo["RAID_WARNING"] then
        RaidNotice_AddMessage(RaidWarningFrame, text, ChatTypeInfo["RAID_WARNING"])
    else
        UIErrorsFrame:AddMessage(text, 1, 0.1, 0.1)
    end
end

local function FireWarning(tankName)
    if db.warnSoundEnabled then PlayWarnSound() end
    if db.warnFlash then Flash() end
    if db.warnShake then Shake() end
    if db.warnMessage then
        ShowWarnMessage(string.format(L.WARN_MSG_FMT, db.yellowThreshold, tankName or "?"))
    end
end

-- Wer angezeigt wird: eigene Gruppe/Raid, sonst nur der Spieler selbst.
-- Pets werden als eigene Unit-Token direkt mit angehaengt (UnitExists filtert
-- spaeter automatisch raus, wer gerade kein Pet hat).
local function GetUnitList()
    local units = {}
    local showPets = db.showPets
    if IsInRaid() then
        for i = 1, GetNumGroupMembers() do
            units[#units + 1] = "raid" .. i
            if showPets then units[#units + 1] = "raidpet" .. i end
        end
    elseif IsInGroup() then
        units[#units + 1] = "player"
        if showPets then units[#units + 1] = "pet" end
        for i = 1, GetNumGroupMembers() - 1 do
            units[#units + 1] = "party" .. i
            if showPets then units[#units + 1] = "partypet" .. i end
        end
    else
        units[#units + 1] = "player"
        if showPets then units[#units + 1] = "pet" end
    end
    return units
end

local function IsPetUnit(unit)
    return unit:find("pet", 1, true) ~= nil
end

-- Klassen-Filter (Omens Bar.Classes). Die eigene Zeile und Pets filtert er
-- nie: sich selbst will man immer sehen, Pets haben ihren eigenen Schalter.
local function IsFilteredOut(entry)
    if entry.unit == "player" or IsPetUnit(entry.unit) or not entry.classToken then
        return false
    end
    return db.hiddenClasses[entry.classToken] == true
end

-- Aus Omen:FindThreatMob() uebernommen: nicht stur nur "target" pruefen,
-- sondern eine Prioritaetsliste, inkl. "targettarget" als Fallback (falls man
-- selbst kein Ziel hat, aber das eigene Ziel/der Fokus eins hat) und optional
-- "focus"/"focustarget" davor. Ueberspringt tote/nicht angreifbare/Spieler-Ziele.
local TARGET_PRIORITY = { "target", "targettarget" }
local TARGET_PRIORITY_FOCUS = { "focus", "focustarget", "target", "targettarget" }

-- Verkettete Units wie "targettarget" sind laut ForeverThreat 1.19 die Stelle,
-- an der dieser Client anfaengt, Werte zu schuetzen. Hat derselbe Gegner eine
-- Namensplakette, wird ueber die gefragt.
local CHAINED_UNITS = { targettarget = true, focustarget = true }

local function FindNameplateFor(unit)
    for i = 1, 40 do
        local plate = "nameplate" .. i
        if SafeCall(UnitIsUnit, plate, unit) == true then
            return plate
        end
    end
    return nil
end

local function FindThreatTarget()
    local list = db.useFocus and TARGET_PRIORITY_FOCUS or TARGET_PRIORITY
    for _, mob in ipairs(list) do
        if SafeCall(UnitExists, mob) == true
            and SafeCall(UnitCanAttack, "player", mob) == true
            and SafeCall(UnitIsPlayer, mob) ~= true
            and SafeCall(UnitIsDeadOrGhost, mob) ~= true then
            if CHAINED_UNITS[mob] then
                return FindNameplateFor(mob) or mob
            end
            return mob
        end
    end
    return nil
end

local function CollectThreatData()
    local mob = FindThreatTarget()
    if not mob then
        return nil
    end

    local data = {}
    for _, unit in ipairs(GetUnitList()) do
        if SafeCall(UnitExists, unit) == true then
            local ok, isTanking, status, scaledPct, rawPct, threatValue =
                pcall(UnitDetailedThreatSituation, unit, mob)
            -- Geschuetzte Zahlen (in Instanzen im Kampf ueblich) darf man laut
            -- ForeverThreat 1.19 ANZEIGEN (StatusBar:SetValue, SetFormattedText),
            -- aber nicht vergleichen oder damit rechnen. Darum den geschuetzten
            -- scaledPct fuer die Anzeige aufheben (secretScaled) und alles, was
            -- verglichen wird, nur aus lesbaren Werten nehmen.
            local anySecret = ok and (IsSecret(isTanking) or IsSecret(status) or IsSecret(scaledPct)
                or IsSecret(rawPct) or IsSecret(threatValue))
            local secretScaled = ok and IsSecret(scaledPct) and scaledPct or nil
            if ok then
                isTanking, status = Unsecret(isTanking), Unsecret(status)
                scaledPct, rawPct, threatValue = Unsecret(scaledPct), Unsecret(rawPct), Unsecret(threatValue)
            end
            -- Wen der Gegner angreift, bleibt lesbar, auch wenn die Zahlen es nicht sind.
            local holdsAggro = SafeCall(UnitIsUnit, unit, mob .. "target") == true
            if ok and (isTanking ~= nil or anySecret or holdsAggro) then
                -- Der Status ("ueber dem Tank") bleibt laut ForeverThreat lesbar.
                if status == nil then
                    status = SafeCall(UnitThreatSituation, unit, mob)
                end
                -- Namen koennen in Instanzen geschuetzt sein: SetText nimmt sie,
                -- Verketten (Markierungen, "(Pet)") geht dann nicht.
                local okName, rawName = pcall(UnitName, unit)
                local secretName = okName and IsSecret(rawName) and rawName or nil
                local name = okName and Unsecret(rawName) or nil
                local isPet = IsPetUnit(unit)
                if name and isPet then
                    name = name .. L.PET_SUFFIX
                elseif not name and not secretName then
                    name = unit
                end
                local okClass, _, classToken = pcall(UnitClass, unit)
                data[#data + 1] = {
                    unit = unit,
                    order = #data + 1,
                    guid = SafeCall(UnitGUID, unit) or unit,
                    name = name,
                    secretName = secretName,
                    classToken = okClass and Unsecret(classToken) or nil,
                    isTanking = isTanking == true or holdsAggro,
                    status = status or 0,
                    scaledPct = scaledPct or 0,
                    rawPct = rawPct or 0,
                    scaledKnown = scaledPct ~= nil,
                    rawKnown = rawPct ~= nil,
                    secretScaled = secretScaled,
                    threatValue = threatValue,
                    isDead = SafeCall(UnitIsDeadOrGhost, unit) == true,
                    isOffline = not isPet and SafeCall(UnitIsConnected, unit) == false,
                }
            end
        end
    end

    return data, SafeCall(UnitGUID, mob) or mob, mob
end

-- ------------------------------------------------------------
-- Aggro-ziehen-Balken (Omens ShowAggroBar). Im Nahkampf zieht man ab 110 %
-- des Tank-Threats, auf Distanz ab 130 %. Die Entfernung prueft Omen ueber
-- die Reichweite eines Gegenstands (Voodoo-Talisman 8149, ~5 m). Liefert der
-- Client dazu nichts (Item nicht im Cache, API gesperrt), wird vorsichtig mit
-- 110 % gerechnet -- lieber zu frueh als zu spaet warnen.
-- ------------------------------------------------------------
local RANGE_ITEM = 8149
if C_Item and C_Item.GetItemInfo then
    pcall(C_Item.GetItemInfo, RANGE_ITEM)
elseif GetItemInfo then
    pcall(GetItemInfo, RANGE_ITEM)
end

local function GetPullAggroPct(mob)
    local isItemInRange = (C_Item and C_Item.IsItemInRange) or IsItemInRange
    if mob and isItemInRange then
        if SafeCall(isItemInRange, RANGE_ITEM, mob) == false then
            return 130
        end
    end
    return 110
end

-- Anzeigewert je Zeile: ohne Aggro-Balken wie bisher scaledPct (100 % = man
-- zieht Aggro, entfernungsabhaengig), mit Aggro-Balken wie Omen der Anteil am
-- Tank-Threat (rawPct, Tank = 100 %).
-- Zeilen mit geschuetzter Zahl (secretScaled) werden nur angezeigt: kein
-- Vergleich, keine Rechnung. Sie stehen ungeordnet (Gruppenreihenfolge) hinter
-- den lesbaren Zeilen, der Tank bleibt oben. Sobald eine solche Zeile dabei
-- ist, entfaellt der Aggro-Balken: die geschuetzten Prozente sind scaledPct
-- (100 % = man zieht Aggro), ein Balken bei 110/130 % waere dann irrefuehrend.
local function IsHiddenRow(entry)
    return entry.secretScaled ~= nil and not entry.isTanking
end

local function PrepareDisplayData(data, mob)
    local anyHidden = false
    for _, entry in ipairs(data) do
        if IsHiddenRow(entry) then anyHidden = true break end
    end
    local useRaw = db.showAggroBar and not anyHidden
    local filtered = {}
    for _, entry in ipairs(data) do
        if not IsFilteredOut(entry) then
            -- Tank ohne lesbare Zahl (geschuetzt oder nur ueber "wen greift der
            -- Gegner an" erkannt): per Definition 100 %.
            if entry.isTanking and not entry.scaledKnown then
                entry.displayPct = 100
                entry.pctUnknown = false
            elseif IsHiddenRow(entry) then
                entry.displayPct = 0
                entry.pctUnknown = false
            elseif useRaw then
                entry.displayPct = entry.isTanking and 100 or entry.rawPct
                entry.pctUnknown = not entry.isTanking and entry.rawKnown == false
            else
                entry.displayPct = entry.scaledPct
                entry.pctUnknown = entry.scaledKnown == false
            end
            filtered[#filtered + 1] = entry
        end
    end
    if useRaw and #filtered > 0 then
        filtered[#filtered + 1] = {
            isAggro = true,
            unit = "AGGRO",
            guid = "AGGRO",
            name = L.PULL_AGGRO,
            isTanking = false,
            status = 0,
            scaledPct = 0,
            displayPct = testMode and 110 or GetPullAggroPct(mob),
            threatValue = 0,
            order = 0,
        }
    end
    -- Mit Gleichstand-Regel ueber die Gruppenreihenfolge, sonst springen gleich
    -- hohe Zeilen (table.sort ist nicht stabil) bei jedem Refresh hin und her.
    table.sort(filtered, function(a, b)
        local aHidden, bHidden = IsHiddenRow(a), IsHiddenRow(b)
        if aHidden ~= bHidden then return bHidden end
        if not aHidden and a.displayPct ~= b.displayPct then return a.displayPct > b.displayPct end
        return (a.order or 0) < (b.order or 0)
    end)
    return filtered
end

-- ------------------------------------------------------------
-- Threat pro Sekunde, nach dem Prinzip von Omen:UpdateTPS(): bei jedem Scan
-- eine Momentaufnahme {Zeit, guid -> threatValue} speichern, alles aelter als
-- das Fenster verwerfen (bis auf die letzte Aufnahme davor) und die Differenz
-- erste/letzte Aufnahme durch die Zeitspanne teilen. Wechselt der Mob, faengt
-- die Messung neu an. Ohne Omens Interpolation auf den exakten Fensterbeginn --
-- fuer eine Anzeige in ganzen Zahlen reicht das.
-- ------------------------------------------------------------
local TPS_WINDOW = 10
local TPS_MIN_SPAN = 2
local tpsSamples = {}
local tpsMobGUID = nil

local function ResetTPS()
    wipe(tpsSamples)
    tpsMobGUID = nil
end

local function SampleTPS(mobGUID, data)
    if mobGUID ~= tpsMobGUID then
        wipe(tpsSamples)
        tpsMobGUID = mobGUID
    end
    local now = GetTime()
    local values = {}
    for _, entry in ipairs(data) do
        values[entry.guid] = entry.threatValue
    end
    tpsSamples[#tpsSamples + 1] = { t = now, v = values }
    while tpsSamples[2] and tpsSamples[2].t <= now - TPS_WINDOW do
        table.remove(tpsSamples, 1)
    end
end

-- nil = noch nicht genug Daten (Anzeige "--", wie Omens "??")
local function GetTPS(guid)
    local first, last = tpsSamples[1], tpsSamples[#tpsSamples]
    if not first or first == last then return nil end
    local span = last.t - first.t
    if span < TPS_MIN_SPAN then return nil end
    local startValue, endValue = first.v[guid], last.v[guid]
    if not startValue or not endValue then return nil end
    return (endValue - startValue) / span
end

local function ShouldShow()
    if manualState == "hidden" then return false end
    if manualState == "shown" then return true end

    -- Omens ShowWith: angezeigt wird, wenn mindestens eine passende Regel
    -- greift. "Solo" heisst dabei wie im Original: ohne Gruppe UND ohne Pet.
    local inRaid = IsInRaid()
    local inParty = IsInGroup() and not inRaid
    local hasPet = UnitExists("pet")
    local groupOK = (db.showWithPet and hasPet)
        or (db.showInParty and inParty)
        or (db.showInRaid and inRaid)
        or (db.showSolo and not inParty and not inRaid and not hasPet)
    if not groupOK then
        return false
    end
    -- Aus Omens UpdateVisible() uebernommen (HideWhileResting/HideInPVP)
    if db.hideWhileResting and IsResting() then
        return false
    end
    if db.hideInPVP then
        local _, instanceType = IsInInstance()
        if instanceType == "pvp" or instanceType == "arena" then
            return false
        end
    end
    if UnitAffectingCombat("player") then
        return db.showInCombat
    end
    return db.showOutOfCombat
end

-- Farb-Reihenfolge: Aggro-Balken, dann die zwei Warnfarben (Ueberholen-Rot
-- und Gelb ab Warnschwelle) -- die sind Sicherheitsfunktionen und bleiben
-- auch bei Klassen-/Wunschfarben sichtbar --, dann Wunschfarben, Klassenfarben
-- und zuletzt die normale Status-Farbe.
local function GetBarColor(entry)
    if entry.isAggro then
        local c = db.aggroBarColor
        return c.r, c.g, c.b
    end
    if not entry.isTanking and entry.status >= 1 then
        return GetThreatStatusColor(entry.status)
    end
    if not entry.isTanking and entry.scaledPct >= db.yellowThreshold then
        return 1, 1, 0
    end
    if db.useMyBarColor and entry.unit == "player" then
        local c = db.myBarColor
        return c.r, c.g, c.b
    end
    if db.useTankBarColor and entry.isTanking then
        local c = db.tankBarColor
        return c.r, c.g, c.b
    end
    if db.usePetBarColor and IsPetUnit(entry.unit) then
        local c = db.petBarColor
        return c.r, c.g, c.b
    end
    if db.useClassColors and entry.classToken and RAID_CLASS_COLORS and RAID_CLASS_COLORS[entry.classToken] then
        local c = RAID_CLASS_COLORS[entry.classToken]
        return c.r, c.g, c.b
    end
    return GetThreatStatusColor(entry.status)
end

-- Weiches Nachziehen der Balkenbreite (Omens AnimateBars). OnUpdate laeuft
-- nur, solange ein Balken noch unterwegs ist.
local function AnimateBar_OnUpdate(bar, elapsed)
    local current = bar:GetValue()
    -- Hat der Balken zuletzt einen geschuetzten Wert gezeigt, ist auch GetValue()
    -- geschuetzt -- dann nicht rechnen, sondern direkt setzen.
    if IsSecret(current) then
        bar:SetValue(bar.targetValue)
        bar:SetScript("OnUpdate", nil)
        return
    end
    local diff = bar.targetValue - current
    if math.abs(diff) < 0.2 then
        bar:SetValue(bar.targetValue)
        bar:SetScript("OnUpdate", nil)
        return
    end
    bar:SetValue(current + diff * math.min(1, elapsed * 8))
end

local function SetBarValue(bar, value, wasShown)
    bar.targetValue = value
    if db.animateBars and wasShown and not bar.showedSecret then
        bar:SetScript("OnUpdate", AnimateBar_OnUpdate)
    else
        bar:SetScript("OnUpdate", nil)
        bar:SetValue(value)
    end
end

local function CreateBar(index)
    local bar = CreateFrame("StatusBar", "OmenReloadedForeverBar" .. index, ORF.frame)
    bar:SetSize(db.width, db.height)
    bar:SetStatusBarTexture("Interface\\AddOns\\NeonOmen\\Media\\ThreatGradient")
    bar:SetMinMaxValues(0, 100)
    bar:SetValue(0)
    bar:Hide()

    Theme.SkinBar(bar)

    bar.nameText = bar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    bar.nameText:SetPoint("LEFT", bar, "LEFT", 4, 0)
    bar.nameText:SetJustifyH("LEFT")

    bar.pctText = bar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    bar.pctText:SetPoint("RIGHT", bar, "RIGHT", -4, 0)
    bar.pctText:SetJustifyH("RIGHT")

    bar.tpsText = bar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    bar.tpsText:SetJustifyH("RIGHT")

    -- Preserve the active game font (including Chinese fonts) and add a dark
    -- shadow for legibility against bright class and threat-warning colors.
    for _, text in ipairs({ bar.nameText, bar.pctText, bar.tpsText }) do
        text:SetShadowColor(0, 0, 0, 1)
        text:SetShadowOffset(1, -1)
        local font, size = text:GetFont()
        if font and size then pcall(text.SetFont, text, font, size, "OUTLINE") end
    end

    bar.pctText:SetTextColor(1, 1, 1)
    bar.tpsText:SetTextColor(1, 1, 1)

    ORF.bars[index] = bar
    return bar
end

local FRAME_PADDING = 10
local HEADER_HEIGHT = 16

-- Titelleiste und Spaltenkopf sind abschaltbar; ohne Titel bleibt nur der
-- Abstand zum Rahmen.
local function GetTitleHeight()
    return db.showTitleBar and 22 or 12
end

local function GetBarsTopOffset()
    return GetTitleHeight() + (db.showHeader and HEADER_HEIGHT or 0)
end

-- Wie im Original-Omen: die Fenstergroesse ist eigenstaendig (Resize/
-- gespeicherte Groesse), die Zahl der angezeigten Balken passt sich der
-- verfuegbaren Flaeche an -- nicht umgekehrt. Kein SetHeight hier mehr,
-- sonst kaempft das mit einem laufenden manuellen Resize um die Kontrolle.
local function GetMaxVisibleBars()
    if db.autoCollapse then
        return MAX_BARS
    end
    local perBar = db.height + db.spacing
    -- Zeigt das Fenster geschuetzte Werte, kann auch seine Hoehe im Kampf
    -- geschuetzt sein (ForeverThreat 1.19) -- dann die gespeicherte Hoehe nehmen.
    local frameHeight = ORF.frame:GetHeight()
    if IsSecret(frameHeight) then frameHeight = db.frameHeight end
    local available = frameHeight - GetBarsTopOffset() - FRAME_PADDING + db.spacing
    return math.max(1, math.floor(available / perBar))
end

local function FormatThreatValue(value)
    if value >= 1000000 then
        return string.format("%.1fm", value / 1000000)
    elseif value >= 1000 then
        return string.format("%.1fk", value / 1000)
    end
    return tostring(math.floor(value + 0.5))
end

-- Feste rechte Spalten (Prozent, optional TPS), damit die TPS-Werte
-- untereinander stehen; der Name wird davor abgeschnitten statt drueber zu laufen.
local TPS_COLUMN_WIDTH = 58
local COLUMN_GAP = 8

local function GetPctColumnWidth()
    return db.showValue and 100 or 64
end

local function LayoutColumns(bar)
    local pctWidth = GetPctColumnWidth()
    local showTPS = db.showTPS
    bar.pctText:SetWidth(pctWidth)
    bar.pctText:SetWordWrap(false)
    bar.tpsText:ClearAllPoints()
    bar.tpsText:SetPoint("RIGHT", bar, "RIGHT", -4 - pctWidth - COLUMN_GAP, 0)
    bar.tpsText:SetWidth(TPS_COLUMN_WIDTH)
    bar.tpsText:SetWordWrap(false)
    bar.tpsText:SetShown(showTPS)
    bar.nameText:ClearAllPoints()
    bar.nameText:SetPoint("LEFT", bar, "LEFT", 4, 0)
    bar.nameText:SetPoint("RIGHT", bar, "RIGHT", -4 - pctWidth - (showTPS and (TPS_COLUMN_WIDTH + COLUMN_GAP * 2) or COLUMN_GAP), 0)
    bar.nameText:SetWordWrap(false)
end

local function LayoutHeader()
    local titleHeight = GetTitleHeight()
    local showHeader = db.showHeader
    ORF.title:SetShown(db.showTitleBar)

    ORF.headerName:ClearAllPoints()
    ORF.headerName:SetPoint("TOPLEFT", ORF.frame, "TOPLEFT", FRAME_PADDING + 4, -titleHeight)
    ORF.headerName:SetShown(showHeader)

    ORF.headerPct:ClearAllPoints()
    ORF.headerPct:SetPoint("TOPRIGHT", ORF.frame, "TOPRIGHT", -FRAME_PADDING - 4, -titleHeight)
    ORF.headerPct:SetWidth(GetPctColumnWidth())
    ORF.headerPct:SetWordWrap(false)
    ORF.headerPct:SetShown(showHeader)

    ORF.headerTPS:ClearAllPoints()
    ORF.headerTPS:SetPoint("TOPRIGHT", ORF.frame, "TOPRIGHT", -FRAME_PADDING - 4 - GetPctColumnWidth() - COLUMN_GAP, -titleHeight)
    ORF.headerTPS:SetWidth(TPS_COLUMN_WIDTH)
    ORF.headerTPS:SetWordWrap(false)
    ORF.headerTPS:SetShown(showHeader and db.showTPS)

    local barsTop = GetBarsTopOffset()
    ORF.emptyText:ClearAllPoints()
    ORF.emptyText:SetPoint("TOPLEFT", ORF.frame, "TOPLEFT", FRAME_PADDING, -barsTop)
    ORF.emptyText:SetPoint("TOPRIGHT", ORF.frame, "TOPRIGHT", -FRAME_PADDING, -barsTop)
end

local function LayoutBars(count)
    local growUp = db.growUp
    local barsTop = GetBarsTopOffset()
    for i = 1, count do
        local bar = ORF.bars[i]
        bar:ClearAllPoints()
        bar:SetHeight(db.height)
        if i == 1 then
            if growUp then
                bar:SetPoint("BOTTOMLEFT", ORF.frame, "BOTTOMLEFT", FRAME_PADDING, FRAME_PADDING)
                bar:SetPoint("BOTTOMRIGHT", ORF.frame, "BOTTOMRIGHT", -FRAME_PADDING, FRAME_PADDING)
            else
                bar:SetPoint("TOPLEFT", ORF.frame, "TOPLEFT", FRAME_PADDING, -barsTop)
                bar:SetPoint("TOPRIGHT", ORF.frame, "TOPRIGHT", -FRAME_PADDING, -barsTop)
            end
        else
            if growUp then
                bar:SetPoint("BOTTOMLEFT", ORF.bars[i - 1], "TOPLEFT", 0, db.spacing)
                bar:SetPoint("BOTTOMRIGHT", ORF.bars[i - 1], "TOPRIGHT", 0, db.spacing)
            else
                bar:SetPoint("TOPLEFT", ORF.bars[i - 1], "BOTTOMLEFT", 0, -db.spacing)
                bar:SetPoint("TOPRIGHT", ORF.bars[i - 1], "BOTTOMRIGHT", 0, -db.spacing)
            end
        end
    end
    ORF.frame:SetWidth(db.width + FRAME_PADDING * 2)
end

-- Autocollapse (Omen): Fensterhoehe folgt der Balkenzahl. Damit das Fenster
-- dabei nicht in beide Richtungen waechst, wird es vorher an der Kante
-- verankert, von der aus die Balken wachsen (oben bzw. bei GrowUp unten).
-- Waehrend Verschieben/Resize wird nichts angefasst -- genau dieser Kampf um
-- die Fenstergroesse war frueher der "Sprung"-Bug.
local function ApplyAutoCollapse(shown)
    if not db.autoCollapse or ORF.isMoving or ORF.isSizing then return end
    local frame = ORF.frame
    local left, top, bottom = frame:GetLeft(), frame:GetTop(), frame:GetBottom()
    if IsSecret(left) or IsSecret(top) or IsSecret(bottom) then return end
    if not left or not top or not bottom then return end
    local rows = math.max(shown, 1)
    local height = GetBarsTopOffset() + rows * (db.height + db.spacing) - db.spacing + FRAME_PADDING
    height = math.min(math.max(height, 30), 900)

    -- GetLeft/GetTop liefern Werte im eigenen Massstab des Fensters, und
    -- UIParent/BOTTOMLEFT ist in jedem Massstab 0/0 -- passt also auch mit Skalierung.
    frame:ClearAllPoints()
    if db.growUp then
        frame:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", left, bottom)
    else
        frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", left, top)
    end
    frame:SetHeight(height)

    if not testMode then
        local point, _, relPoint, x, y = frame:GetPoint()
        if not (IsSecret(point) or IsSecret(relPoint) or IsSecret(x) or IsSecret(y)) then
            db.point, db.relPoint, db.x, db.y = point, relPoint, x, y
        end
    end
end

-- Warnt nur fuer den Spieler selbst (nicht fuer Gruppenmitglieder) und nur
-- beim Uebergang in die Warnzone, nicht bei jedem Refresh-Tick, damit es
-- nicht dauerhaft dudelt solange man z.B. bei 85% Threat steht.
-- Tank-Erkennung ohne Spezialisierungen (gibt es in Classic nicht): Haltung/
-- Gestalt, Zorn der Gerechtigkeit oder die in der Gruppe zugewiesene Rolle.
local RIGHTEOUS_FURY = 25780
local function GetSpellNameSafe(spellID)
    if C_Spell and C_Spell.GetSpellName then
        return C_Spell.GetSpellName(spellID)
    elseif GetSpellInfo then
        return (GetSpellInfo(spellID))
    end
end

local function HasBuff(spellName)
    if not spellName then return false end
    if AuraUtil and AuraUtil.FindAuraByName then
        return AuraUtil.FindAuraByName(spellName, "player", "HELPFUL") ~= nil
    end
    if UnitBuff then
        for i = 1, 40 do
            local name = UnitBuff("player", i)
            if not name then break end
            if name == spellName then return true end
        end
    end
    return false
end

local function IsPlayerTankRoleImpl()
    if UnitGroupRolesAssigned and UnitGroupRolesAssigned("player") == "TANK" then
        return true
    end
    local _, class = UnitClass("player")
    local formID = GetShapeshiftFormID and GetShapeshiftFormID()
    if class == "WARRIOR" then
        return formID == 18 -- Verteidigungshaltung
    elseif class == "DRUID" then
        return formID == 5 or formID == 8 -- Baer / Terrorbaer
    elseif class == "PALADIN" then
        return HasBuff(GetSpellNameSafe(RIGHTEOUS_FURY))
    end
    return false
end

local function IsPlayerTankRole()
    local ok, result = pcall(IsPlayerTankRoleImpl)
    return ok and result or false
end

local wasNearAggro = false
local lastWarnTime = 0
local function CheckAggroWarning(data, mob)
    local anyWarning = db.warnSoundEnabled or db.warnFlash or db.warnShake or db.warnMessage
    if not anyWarning or not data then
        wasNearAggro = false
        return
    end

    local playerEntry, tankEntry
    for _, entry in ipairs(data) do
        if entry.unit == "player" then playerEntry = entry end
        if entry.isTanking then tankEntry = entry end
    end

    -- Ist die eigene Zahl geschuetzt, bleibt der Status lesbar:
    -- 1 = mehr Threat als der Tank, aber noch nicht angegriffen.
    local nearAggro
    if playerEntry and playerEntry.secretScaled ~= nil then
        nearAggro = not playerEntry.isTanking and playerEntry.status >= 1
    else
        nearAggro = playerEntry and not playerEntry.isTanking
            and playerEntry.scaledPct >= db.yellowThreshold
    end

    if nearAggro and not wasNearAggro then
        local now = GetTime()
        local suppressed = db.disableWarnAsTank and IsPlayerTankRole()
        if not suppressed and now - lastWarnTime >= (db.warnCooldown or 4) then
            lastWarnTime = now
            local tankName = (mob and SafeCall(UnitName, mob .. "target")) or (tankEntry and tankEntry.name)
            FireWarning(tankName)
        end
    end
    wasNearAggro = nearAggro
end

-- Aggro-Wechsel (Idee aus ForeverThreat): pro Gegner merken, wer ihn zuletzt
-- getankt hat. Wechselt der Tank, leuchtet die neue Zeile kurz mit [!] auf.
-- Wechselt der Gegner auf MICH und hatte vorher jemand anders die Aggro (auch
-- ein Pet oder ein gruppenfremder Spieler), kommt die "AGGRO!"-Warnung -- beim
-- eigenen ersten Pull also bewusst nicht. Grundlage ist isTanking aus der
-- Threat-API statt UnitIsUnit("targettarget"), das hier geschuetzt sein kann.
local AGGRO_FLASH_SECONDS = 2
local trackedMobGUID = nil
local lastTankGUID = nil
local aggroFlashGUID = nil
local aggroFlashUntil = 0
local lastAggroTakenTime = 0

local function ResetAggroTracking()
    trackedMobGUID, lastTankGUID, aggroFlashGUID, aggroFlashUntil = nil, nil, nil, 0
end

local function FireAggroTaken()
    local now = GetTime()
    if now - lastAggroTakenTime < 2 then return end
    lastAggroTakenTime = now
    if db.warnSoundEnabled then PlayWarnSound() end
    if db.warnFlash then Flash() end
    ShowWarnMessage(L.AGGRO_TAKEN)
end

local function TrackAggroHolder(data, mobGUID)
    if not data or not mobGUID then
        ResetAggroTracking()
        return
    end
    local tankGUID
    for _, entry in ipairs(data) do
        if entry.isTanking then
            tankGUID = entry.guid
            break
        end
    end
    -- Tank ausserhalb unserer Liste (z. B. fremder Spieler), aber es gibt Daten
    if not tankGUID and #data > 0 then
        tankGUID = "OTHER"
    end

    if mobGUID ~= trackedMobGUID then
        trackedMobGUID, lastTankGUID = mobGUID, tankGUID
        aggroFlashGUID, aggroFlashUntil = nil, 0
        return
    end

    if tankGUID and lastTankGUID and tankGUID ~= lastTankGUID then
        if tankGUID ~= "OTHER" then
            aggroFlashGUID = tankGUID
            aggroFlashUntil = GetTime() + AGGRO_FLASH_SECONDS
            -- RequestRefresh ist erst weiter unten definiert, darum ueber ORF.
            C_Timer.After(AGGRO_FLASH_SECONDS + 0.1, function() ORF.RequestRefresh() end)
        end
        local playerGUID = SafeCall(UnitGUID, "player") or "player"
        if tankGUID == playerGUID and db.warnAggroTaken
            and not (db.disableWarnAsTank and IsPlayerTankRole()) then
            FireAggroTaken()
        end
    end
    if tankGUID then
        lastTankGUID = tankGUID
    end
end

local function IsAggroFlashing(entry)
    return aggroFlashGUID ~= nil and entry.guid == aggroFlashGUID and GetTime() < aggroFlashUntil
end

-- Name mit Markierungen: [!] Aggro-Wechsel, [T] Tank, (tot)/(offline)
local function DecorateName(entry)
    if not db.showMarkers or entry.isAggro then
        return entry.name
    end
    local text = entry.name
    if entry.isTanking then
        text = "|cffffd200[T]|r " .. text
    end
    if IsAggroFlashing(entry) then
        text = "|cffff5a1f[!]|r " .. text
    end
    if entry.isDead then
        text = text .. " |cff888888(" .. L.DEAD .. ")|r"
    elseif entry.isOffline then
        text = text .. " |cff888888(" .. L.OFFLINE .. ")|r"
    end
    return text
end

-- Titel: im Kampf der Gegnername (wie Omen). "> dessen Ziel" nur, wenn der
-- Tank nicht in unserer Liste steht (z. B. fremder Spieler) -- sonst zeigt das
-- [T] in der Liste schon, wer tankt, und lange Gegnernamen haben mehr Platz.
local function GetTitleText(mob, data)
    if testMode then
        return L.TITLE_TESTMODE
    end
    if db.showTargetInTitle and mob then
        local okName, rawName = pcall(UnitName, mob)
        if okName and IsSecret(rawName) then
            return rawName -- nur anzeigen, nicht verketten
        end
        local mobName = okName and rawName or nil
        if mobName then
            local tankListed = false
            for _, entry in ipairs(data or {}) do
                if entry.isTanking then
                    tankListed = true
                    break
                end
            end
            local targetName = not tankListed and SafeCall(UnitName, mob .. "target")
            if targetName then
                -- Kein Pfeilzeichen: die Spielschrift hat kein "→" (zeigt ein Kaestchen).
                return mobName .. " > " .. targetName
            end
            return mobName
        end
    end
    return L.TITLE
end

local DEBUG = false
local function DebugPrint(msg)
    if DEBUG then
        print("|cffff8000ORF-Debug:|r " .. msg)
    end
end

local function RefreshBarsImpl()
    if ORF.ApplyTheme then ORF.ApplyTheme() end
    DebugPrint(string.format("RefreshBars start, testMode=%s, ShouldShow=%s",
        tostring(testMode), tostring(ShouldShow())))
    if not testMode and not ShouldShow() then
        ORF.frame:Hide()
        wasNearAggro = false
        DebugPrint("-> hide (not testMode and not ShouldShow)")
        return
    end

    local data, mobGUID, mob
    if testMode then
        data = GetTestData()
    else
        data, mobGUID, mob = CollectThreatData()
        if data then
            SampleTPS(mobGUID, data)
        else
            ResetTPS()
        end
        TrackAggroHolder(data, mobGUID)
        data = data or {}
    end
    DebugPrint("data count=" .. tostring(#data))
    CheckAggroWarning(not testMode and data or nil, mob)
    if not pcall(ORF.title.SetText, ORF.title, GetTitleText(mob, data)) then
        ORF.title:SetText(L.TITLE)
    end

    data = PrepareDisplayData(data, mob)

    -- Fenster bleibt auch bei 0 Balken sichtbar (wie im Original-Omen,
    -- CollapseHide=false-Verhalten) -- sonst reagiert z.B. "Ausserhalb des
    -- Kampfes anzeigen" nicht sichtbar, solange es gerade keine Threat-Daten
    -- gibt (was ausserhalb des Kampfes praktisch immer der Fall ist).

    local shown = math.min(#data, MAX_BARS, GetMaxVisibleBars(), db.numBars or MAX_BARS)

    -- Aus Omen (AlwaysShowSelf) uebernommen: eigene Zeile in den letzten
    -- sichtbaren Slot tauschen, falls sie sonst durch den Fensterplatz
    -- rausfallen wuerde -- man sieht sich selbst immer, auch in vollen Raids.
    if db.alwaysShowSelf and shown > 0 and shown < #data then
        local playerIndex
        for i = shown + 1, #data do
            if data[i].unit == "player" then
                playerIndex = i
                break
            end
        end
        if playerIndex then
            data[shown] = data[playerIndex]
        end
    end

    -- Balkenskala: bisher fest 0-100. Mit Aggro-Balken wie in Omen relativ zum
    -- hoechsten Wert (der Aggro-Balken bei 110/130 % ist dann die volle Breite).
    local scaleMax = 100
    for i = 1, shown do
        if data[i].displayPct > scaleMax then scaleMax = data[i].displayPct end
    end

    for i = 1, shown do
        local entry = data[i]
        local bar = ORF.bars[i] or CreateBar(i)
        local wasShown = bar:IsShown()
        local hidden = IsHiddenRow(entry)
        if hidden then
            -- Nur anzeigen: Balken und Prozent nehmen den geschuetzten Wert an.
            bar:SetScript("OnUpdate", nil)
            bar:SetMinMaxValues(0, 100)
            if not pcall(bar.SetValue, bar, entry.secretScaled) then bar:SetValue(0) end
        else
            bar:SetMinMaxValues(0, scaleMax)
            SetBarValue(bar, entry.displayPct, wasShown)
        end
        bar.showedSecret = hidden
        local r, g, b = GetBarColor(entry)
        Theme.PaintBar(bar, r, g, b, db.showGlow, db.glowIntensity)
        if entry.secretName then
            if not pcall(bar.nameText.SetText, bar.nameText, entry.secretName) then
                bar.nameText:SetText(entry.unit)
            end
        else
            bar.nameText:SetText(DecorateName(entry))
        end
        if db.showMarkers and IsAggroFlashing(entry) then
            bar.nameText:SetTextColor(1, 0.55, 0.12)
        else
            bar.nameText:SetTextColor(0.94, 0.96, 0.93)
        end
        LayoutColumns(bar)
        if db.showTPS then
            local tps
            if entry.isAggro then
                tps = nil
            elseif testMode then
                -- Testmodus: Fake-Werte wie in Omen (1300 - 50*i)
                tps = 1300 - 50 * i
            else
                tps = GetTPS(entry.guid)
            end
            bar.tpsText:SetText(tps and FormatThreatValue(tps) or "--")
        end
        local pctString = entry.pctUnknown and L.UNKNOWN_PCT
            or string.format("%d%%", math.floor(entry.displayPct + 0.5))
        if hidden then
            if not pcall(bar.pctText.SetFormattedText, bar.pctText, "%d%%", entry.secretScaled) then
                bar.pctText:SetText(L.UNKNOWN_PCT)
            end
        elseif db.showValue and not entry.isAggro then
            local valueString = entry.threatValue and FormatThreatValue(entry.threatValue) or L.UNKNOWN_PCT
            bar.pctText:SetText(string.format("%s (%s)", pctString, valueString))
        else
            bar.pctText:SetText(pctString)
        end
        bar:Show()
    end
    for i = shown + 1, #ORF.bars do
        ORF.bars[i]:SetScript("OnUpdate", nil)
        ORF.bars[i]:Hide()
    end

    if shown == 0 then
        ORF.emptyText:Show()
    else
        ORF.emptyText:Hide()
    end

    LayoutHeader()
    LayoutBars(shown)
    ORF.frame:Show()
    ApplyAutoCollapse(shown)
    DebugPrint(string.format("-> show, shown=%d", shown))
end

-- Derselbe Fehler hoechstens einmal pro Minute im Chat, sonst wird bei einem
-- wiederkehrenden Fehler (z. B. unbekannter geschuetzter Wert) der Chat geflutet.
local lastErrorText, lastErrorTime = nil, 0
local function RefreshBars()
    local ok, err = pcall(RefreshBarsImpl)
    if not ok then
        local text = tostring(err)
        local now = GetTime()
        if text ~= lastErrorText or now - lastErrorTime > 60 then
            lastErrorText, lastErrorTime = text, now
            print("|cffff0000" .. L.ERROR_PREFIX .. "|r " .. text)
        end
    end
end

-- Threat-Events koennen mehrfach pro Tick feuern (z.B. bei AoE); ein kurzer
-- Debounce verhindert, dass wir das Layout unnoetig oft neu aufbauen.
local pendingRefresh = false
local function RequestRefresh()
    if pendingRefresh then return end
    pendingRefresh = true
    C_Timer.After(0.15, function()
        pendingRefresh = false
        RefreshBars()
    end)
end
ORF.RequestRefresh = RequestRefresh

-- Echtes Fenster mit Rahmen/Titelleiste statt nur freischwebender Balken
-- (gleiche BackdropTemplate-Technik wie das LevelProgress-Optionsfenster,
-- in diesem Client bereits bestaetigt funktionsfaehig).
ORF.frame = CreateFrame("Frame", "OmenReloadedForeverFrame", UIParent, "BackdropTemplate")
ORF.frame:SetSize(db.width + FRAME_PADDING * 2, db.frameHeight)
-- Nine-slice assets match NeonCast's rounded card without stretching corners.
local neonBack = ORF.frame:CreateTexture(nil, "BACKGROUND", nil, -6)
neonBack:SetAllPoints()
neonBack:SetTexture("Interface\\AddOns\\NeonOmen\\Media\\NeonBack")
local neonRing = ORF.frame:CreateTexture(nil, "BORDER")
neonRing:SetAllPoints()
neonRing:SetTexture("Interface\\AddOns\\NeonOmen\\Media\\NeonRing")
for _, texture in ipairs({ neonBack, neonRing }) do
    if texture.SetTextureSliceMargins then
        texture:SetTextureSliceMargins(16, 16, 16, 16)
        if texture.SetTextureSliceMode and Enum and Enum.UITextureSliceMode then
            texture:SetTextureSliceMode(Enum.UITextureSliceMode.Stretched)
        end
    end
end
local neonGlow = ORF.frame:CreateTexture(nil, "BACKGROUND", nil, -7)
neonGlow:SetTexture("Interface\\AddOns\\NeonOmen\\Media\\NeonGlow")
neonGlow:SetPoint("TOPLEFT", -12, 12)
neonGlow:SetPoint("BOTTOMRIGHT", 12, -12)
neonGlow:SetBlendMode("ADD")
if neonGlow.SetTextureSliceMargins then
    neonGlow:SetTextureSliceMargins(24, 24, 24, 24)
    if neonGlow.SetTextureSliceMode and Enum and Enum.UITextureSliceMode then
        neonGlow:SetTextureSliceMode(Enum.UITextureSliceMode.Stretched)
    end
end
local neonStripe = ORF.frame:CreateTexture(nil, "ARTWORK")
neonStripe:SetSize(3, 13)
neonStripe:SetPoint("TOPLEFT", 6, -7)
function ORF.ApplyTheme()
    local c = db.themeColor
    local panel = Theme.colors.panel
    neonBack:SetVertexColor(panel[1], panel[2], panel[3], db.backgroundOpacity)
    neonRing:SetVertexColor(c.r, c.g, c.b, 0.24)
    neonGlow:SetVertexColor(c.r, c.g, c.b, db.glowIntensity * 0.25)
    neonGlow:SetShown(db.showGlow)
    neonStripe:SetColorTexture(c.r, c.g, c.b, 1)
end
ORF.ApplyTheme()
ORF.frame:SetPoint(db.point, UIParent, db.relPoint, db.x, db.y)
Theme.ApplyMeterLayer(ORF.frame)
ORF.frame:SetClampedToScreen(true)
ORF.frame:SetMovable(true)
ORF.frame:EnableMouse(true)
ORF.frame:SetResizable(true)
if ORF.frame.SetResizeBounds then
    pcall(ORF.frame.SetResizeBounds, ORF.frame, 140, 60, 600, 900)
elseif ORF.frame.SetMinResize then
    ORF.frame:SetMinResize(140, 60)
    if ORF.frame.SetMaxResize then ORF.frame:SetMaxResize(600, 900) end
end

ORF.title = ORF.frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
ORF.title:SetPoint("TOPLEFT", ORF.frame, "TOPLEFT", FRAME_PADDING + 2, -8)
ORF.title:SetPoint("TOPRIGHT", ORF.frame, "TOPRIGHT", -FRAME_PADDING - 2, -8)
ORF.title:SetJustifyH("CENTER")
ORF.title:SetWordWrap(false)
ORF.title:SetText(L.TITLE)
ORF.title:SetTextColor(unpack(Theme.colors.text))

ORF.headerName = ORF.frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
ORF.headerName:SetJustifyH("LEFT")
ORF.headerName:SetText(L.HEADER_NAME)

ORF.headerPct = ORF.frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
ORF.headerPct:SetJustifyH("RIGHT")
ORF.headerPct:SetText(L.HEADER_THREAT)

ORF.headerTPS = ORF.frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
ORF.headerTPS:SetJustifyH("RIGHT")
ORF.headerTPS:SetText(L.HEADER_TPS)
ORF.headerTPS:Hide()
for _, header in ipairs({ORF.headerName, ORF.headerPct, ORF.headerTPS}) do
    header:SetTextColor(unpack(Theme.colors.muted))
end

ORF.emptyText = ORF.frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
ORF.emptyText:SetJustifyH("CENTER")
ORF.emptyText:SetText(L.EMPTY_TEXT)
ORF.emptyText:Hide()

-- Groessen-Griff unten rechts, gleiche Standardtextur wie beim Chatfenster.
-- Genau wie im Original-Omen (Omen.Grip): rein natives StartSizing()/
-- StopMovingOrSizing(), keine eigene Pixel-zu-Balkenhoehe-Umrechnung mehr.
-- Breite UND Fensterhoehe werden 1:1 uebernommen; wie viele Balken in die
-- Hoehe passen, wird separat in GetMaxVisibleBars() aus der Balkenhoehe
-- (eigener Regler) berechnet -- die zwei Groessen kaempfen dadurch nicht
-- mehr gegeneinander. Bei Autocollapse zaehlt nur die Breite.
local resizeGrip = CreateFrame("Button", nil, ORF.frame)
resizeGrip:SetSize(16, 16)
resizeGrip:SetPoint("BOTTOMRIGHT", ORF.frame, "BOTTOMRIGHT", -4, 4)
resizeGrip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
resizeGrip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
resizeGrip:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
resizeGrip:SetScript("OnMouseDown", function()
    if db.locked then return end
    ORF.isSizing = true
    ORF.frame:StartSizing("BOTTOMRIGHT")
end)
-- Position und Groesse koennen im Kampf geschuetzt zurueckkommen, wenn das
-- Fenster gerade geschuetzte Werte zeigt. Dann nichts Kaputtes speichern,
-- sondern nach dem Kampf (PLAYER_REGEN_ENABLED) noch einmal versuchen.
local function SaveFrameSize()
    local width, height = ORF.frame:GetWidth(), ORF.frame:GetHeight()
    if IsSecret(width) or IsSecret(height) then
        ORF.saveSizePending = true
        return
    end
    ORF.saveSizePending = false
    db.width = math.min(math.max(width - FRAME_PADDING * 2, 100), 600)
    if not db.autoCollapse then
        db.frameHeight = math.min(math.max(height, 60), 900)
    end
end

local function SaveFramePosition()
    local point, _, relPoint, x, y = ORF.frame:GetPoint()
    if IsSecret(point) or IsSecret(relPoint) or IsSecret(x) or IsSecret(y) then
        ORF.savePositionPending = true
        return
    end
    ORF.savePositionPending = false
    db.point, db.relPoint, db.x, db.y = point, relPoint, x, y
end

function ORF.SavePendingGeometry()
    if ORF.saveSizePending then SaveFrameSize() end
    if ORF.savePositionPending then SaveFramePosition() end
end

resizeGrip:SetScript("OnMouseUp", function()
    ORF.frame:StopMovingOrSizing()
    ORF.isSizing = false
    SaveFrameSize()
    RequestRefresh()
end)

ORF.frame:RegisterForDrag("LeftButton")
ORF.frame:SetScript("OnDragStart", function(self)
    if not db.locked then
        ORF.isMoving = true
        self:StartMoving()
    end
end)
ORF.frame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    ORF.isMoving = false
    SaveFramePosition()
end)
ORF.frame:Hide()

-- Deckkraft, Skalierung, Durchklickbarkeit und Resize-Griff (Omens Alpha/
-- Scale/ClickThrough). Durchklickbar heisst: keine Maus mehr auf dem Fenster,
-- also auch kein Verschieben, kein Griff und kein Rechtsklick-Menue.
local function ApplyFrameSettings()
    ORF.frame:SetAlpha(db.alpha)
    ORF.frame:SetScale(db.scale)
    ORF.frame:EnableMouse(not db.clickThrough)
    resizeGrip:SetShown(not db.clickThrough and not db.locked)
end
ApplyFrameSettings()

local function ResetPosition()
    db.point, db.relPoint = "CENTER", "CENTER"
    db.x, db.y = 300, 150
    ORF.frame:ClearAllPoints()
    ORF.frame:SetPoint("CENTER", UIParent, "CENTER", 300, 150)
    db.width = 200
    db.frameHeight = 200
    ORF.frame:SetSize(db.width + FRAME_PADDING * 2, db.frameHeight)
    RequestRefresh()
end

local function ApplySavedPosition()
    ORF.frame:ClearAllPoints()
    ORF.frame:SetPoint(db.point, UIParent, db.relPoint, db.x, db.y)
end

-- Beim Reinschalten des Testmodus zwingend in Bildschirmmitte setzen: falls die
-- gespeicherte Position irgendwo (halb) ausserhalb des sichtbaren Bereichs
-- liegt, waere sonst trotz laufendem Testmodus nichts zu sehen. Beim
-- Ausschalten wird die gespeicherte Position wiederhergestellt.
local function SetTestMode(enabled)
    testMode = enabled
    if testMode then
        ORF.frame:ClearAllPoints()
        ORF.frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    else
        ApplySavedPosition()
    end
    if ORF.UpdateTestModeButton then ORF.UpdateTestModeButton() end
    RequestRefresh()
end

local function ToggleTestMode()
    SetTestMode(not testMode)
    Print(string.format(L.MSG_TESTMODE_FMT, testMode and L.ON or L.OFF))
end

-- Manuelles Ein-/Ausblenden (Taste, Menue, Shift-Klick Minimap, /orf toggle)
local function ToggleWindow()
    if ORF.frame:IsShown() then
        manualState = "hidden"
        Print(L.MSG_WINDOW_HIDDEN)
    else
        manualState = "shown"
        Print(L.MSG_WINDOW_SHOWN)
    end
    RefreshBars()
end

local function ToggleFocus()
    db.useFocus = not db.useFocus
    Print(string.format(L.MSG_FOCUS_FMT, db.useFocus and L.ON or L.OFF))
    RequestRefresh()
end

-- Globale Funktionen fuer Bindings.xml
function OmenReloadedForever_Toggle() ToggleWindow() end
function OmenReloadedForever_ToggleFocus() ToggleFocus() end
function OmenReloadedForever_ToggleTestMode() ToggleTestMode() end

-- The settings window reads the current DB through this adapter, so replacing
-- SavedVariables in ADDON_LOADED never leaves controls pointing at old defaults.
local openOptionsAfterCombat = false
local OpenOptions
local optionsUI = ns.Options.Create({
    L=L, DB=function() return db end, Frame=ORF.frame,
    ApplyFrameSettings=ApplyFrameSettings, ApplyTheme=ORF.ApplyTheme,
    ApplyWidth=function() ORF.frame:SetWidth(db.width+FRAME_PADDING*2) end,
    RequestRefresh=RequestRefresh, BarColor=GetBarColor,
    Classes=FILTER_CLASSES, Sounds=SOUND_CHOICES,
    SoundLabel=GetSoundLabel, PlaySound=PlaySoundChoice,
    ToggleTestMode=ToggleTestMode, IsTestMode=function() return testMode end,
    ResetPosition=ResetPosition, TestWarning=function() FireWarning(L.TESTDATA_TANK) end,
    UpdateMinimap=function() if ORF.UpdateMinimapButton then ORF.UpdateMinimapButton() end end,
    Open=function() OpenOptions() end,
    Version=function()
        local getMeta = (C_AddOns and C_AddOns.GetAddOnMetadata) or GetAddOnMetadata
        if getMeta then
            local ok,value=pcall(getMeta,addonName,"Version")
            if ok then return value or "NeonOmen" end
        end
        return "NeonOmen"
    end,
})
ns.Options.current = optionsUI
ORF.UpdateTestModeButton = optionsUI.Refresh
OpenOptions = function()
    if InCombatLockdown() then
        if not openOptionsAfterCombat then
            openOptionsAfterCombat = true
            Print(L.MSG_OPTIONS_COMBAT)
        end
        return
    end
    openOptionsAfterCombat = false
    optionsUI.Show()
end

-- ------------------------------------------------------------
-- Rechtsklick-Menue auf dem Fenster (Omens Titelleisten-Menue)
-- ------------------------------------------------------------
local contextMenu = CreateFrame("Frame", "OmenReloadedForeverContextMenu", UIParent, "UIDropDownMenuTemplate")

local function AddMenuToggle(level, text, isChecked, func)
    local info = UIDropDownMenu_CreateInfo()
    info.text = text
    info.checked = isChecked
    info.isNotRadio = true
    info.keepShownOnClick = true
    info.func = func
    UIDropDownMenu_AddButton(info, level)
end

local function AddMenuAction(level, text, func)
    local info = UIDropDownMenu_CreateInfo()
    info.text = text
    info.notCheckable = true
    info.func = func
    UIDropDownMenu_AddButton(info, level)
end

UIDropDownMenu_Initialize(contextMenu, function(self, level)
    local info = UIDropDownMenu_CreateInfo()
    info.text = L.TITLE
    info.isTitle = true
    info.notCheckable = true
    UIDropDownMenu_AddButton(info, level)

    AddMenuToggle(level, L.MENU_LOCK, db.locked, function()
        db.locked = not db.locked
        ApplyFrameSettings()
    end)
    AddMenuToggle(level, L.MENU_TESTMODE, testMode, ToggleTestMode)
    AddMenuToggle(level, L.MENU_FOCUS, db.useFocus, ToggleFocus)
    AddMenuToggle(level, L.MENU_TPS, db.showTPS, function()
        db.showTPS = not db.showTPS
        RequestRefresh()
    end)
    AddMenuToggle(level, L.MENU_AGGRO_BAR, db.showAggroBar, function()
        db.showAggroBar = not db.showAggroBar
        RequestRefresh()
    end)
    AddMenuAction(level, L.MENU_HIDE, function()
        manualState = "hidden"
        Print(L.MSG_WINDOW_HIDDEN)
        RefreshBars()
    end)
    AddMenuAction(level, L.MENU_OPTIONS, OpenOptions)
    AddMenuAction(level, L.MENU_CLOSE, function() CloseDropDownMenus() end)
end, "MENU")

ORF.frame:SetScript("OnMouseUp", function(self, button)
    if button == "RightButton" then
        ToggleDropDownMenu(1, nil, contextMenu, "cursor", 0, 0)
    end
end)

-- ------------------------------------------------------------
-- Minimap-Button (ohne LibDBIcon, aber in dessen klassischer Optik:
-- goldener Tracking-Rahmen + Addon-Icon; Drag-Logik wie bei LevelProgress)
-- ------------------------------------------------------------

local minimapBtn = CreateFrame("Button", "OmenReloadedForeverMinimapButton", Minimap)
minimapBtn:SetSize(31, 31)
minimapBtn:SetFrameStrata("MEDIUM")
minimapBtn:SetFrameLevel(Minimap:GetFrameLevel() + 8)
minimapBtn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
minimapBtn:RegisterForDrag("LeftButton")
minimapBtn:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

local minimapBg = minimapBtn:CreateTexture(nil, "BACKGROUND")
minimapBg:SetSize(20, 20)
minimapBg:SetPoint("TOPLEFT", 7, -5)
minimapBg:SetTexture("Interface\\Minimap\\UI-Minimap-Background")

local minimapIcon = minimapBtn:CreateTexture(nil, "ARTWORK")
minimapIcon:SetSize(17, 17)
minimapIcon:SetPoint("TOPLEFT", 7, -6)
minimapIcon:SetTexture("Interface\\Icons\\Spell_Nature_Reincarnation")
minimapIcon:SetTexCoord(0.05, 0.95, 0.05, 0.95)

local minimapBorder = minimapBtn:CreateTexture(nil, "OVERLAY")
minimapBorder:SetSize(53, 53)
minimapBorder:SetPoint("TOPLEFT")
minimapBorder:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")

local function UpdateMinimapButtonPosition()
    -- Radius dynamisch aus der echten Minimap-Groesse wie bei LibDBIcon
    -- (halbe Breite + Abstand), statt fest 80 -- auf WoW Forever ist die
    -- Minimap anders gross, mit festem Wert sass der Button neben dem Rand.
    local angle = math.rad(db.minimapAngle or 200)
    local radius = Minimap:GetWidth() / 2 + (db.minimapOffset or 10)
    minimapBtn:ClearAllPoints()
    minimapBtn:SetPoint("CENTER", Minimap, "CENTER",
        math.cos(angle) * radius, math.sin(angle) * radius)
end

function ORF.UpdateMinimapButton()
    UpdateMinimapButtonPosition()
    minimapBtn:SetShown(db.showMinimapButton)
end
ORF.UpdateMinimapButton()
-- Andere Addons/UI-Skalierung koennen die Minimap nachtraeglich vergroessern.
Minimap:HookScript("OnSizeChanged", UpdateMinimapButtonPosition)

minimapBtn:SetScript("OnDragStart", function(self)
    self:SetScript("OnUpdate", function()
        local mx, my = Minimap:GetCenter()
        local px, py = GetCursorPosition()
        local scale = Minimap:GetEffectiveScale()
        px, py = px / scale, py / scale
        db.minimapAngle = math.deg(math.atan2(py - my, px - mx))
        UpdateMinimapButtonPosition()
    end)
end)
minimapBtn:SetScript("OnDragStop", function(self)
    self:SetScript("OnUpdate", nil)
end)

minimapBtn:SetScript("OnClick", function(self, button)
    if button == "RightButton" then
        ToggleTestMode()
    elseif IsShiftKeyDown() then
        ToggleWindow()
    else
        OpenOptions()
    end
end)

minimapBtn:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:AddLine(L.TITLE)
    GameTooltip:AddLine(L.MINIMAP_TT_LEFT, 0.8, 0.8, 0.8)
    GameTooltip:AddLine(L.MINIMAP_TT_SHIFT, 0.8, 0.8, 0.8)
    GameTooltip:AddLine(L.MINIMAP_TT_RIGHT, 0.8, 0.8, 0.8)
    GameTooltip:AddLine(L.MINIMAP_TT_DRAG, 0.8, 0.8, 0.8)
    GameTooltip:Show()
end)
minimapBtn:SetScript("OnLeave", GameTooltip_Hide)

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
eventFrame:RegisterEvent("UNIT_THREAT_LIST_UPDATE")
eventFrame:RegisterEvent("UNIT_THREAT_SITUATION_UPDATE")
eventFrame:RegisterEvent("PLAYER_UPDATE_RESTING")
eventFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
eventFrame:RegisterEvent("UNIT_PET")
eventFrame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" then
        if arg1 ~= addonName then return end
        self:UnregisterEvent("ADDON_LOADED")
        -- Jetzt ist die gespeicherte Tabelle da: Standardwerte ergaenzen und
        -- Fenster/Minimap-Button auf den gespeicherten Stand bringen.
        InitDB()
        ORF.frame:SetSize(db.width + FRAME_PADDING * 2, db.frameHeight)
        ApplySavedPosition()
        ApplyFrameSettings()
        ORF.UpdateMinimapButton()
    elseif event == "PLAYER_REGEN_ENABLED" then
        ORF.SavePendingGeometry()
        if openOptionsAfterCombat then
            OpenOptions()
        end
    end
    RequestRefresh()
end)

-- Threat-Events kommen nur, wenn sich etwas aendert. Fuer die TPS-Anzeige
-- braucht es aber auch dann regelmaessige Messpunkte (z. B. waehrend man nur
-- zuschaut), darum im Kampf einmal pro Sekunde neu einlesen.
C_Timer.NewTicker(1, function()
    if db.showTPS and ORF.frame:IsShown() and UnitAffectingCombat("player") then
        RequestRefresh()
    end
end)

-- /orf debug: rohe API-Werte fuer Fehlermeldungen; geschuetzte Werte als <secret>.
local function PrintDebugInfoImpl()
    RefreshBars() -- aktuellen Stand einlesen, damit die Aggro-Verfolgung frisch ist
    local getMeta = (C_AddOns and C_AddOns.GetAddOnMetadata) or GetAddOnMetadata
    local version = getMeta and SafeCall(getMeta, addonName, "Version")
    local build, _, _, interface = GetBuildInfo()
    Print(string.format(L.DEBUG_HEADER, SafeText(version), SafeText(build), SafeText(interface),
        issecretvalue and L.ON or L.OFF))

    local mob = FindThreatTarget()
    if not mob then
        Print(L.DEBUG_NO_TARGET)
        return
    end
    local _, mobName = pcall(UnitName, mob)
    local _, mobTarget = pcall(UnitName, mob .. "target")
    Print(string.format(L.DEBUG_TARGET, mob, SafeText(mobName), SafeText(mobTarget)))

    local playerGUID = SafeCall(UnitGUID, "player") or "player"
    local lastTank = lastTankGUID == playerGUID and L.DEBUG_ME or SafeText(lastTankGUID)
    Print(string.format(L.DEBUG_AGGRO, lastTank, db.warnAggroTaken and L.ON or L.OFF,
        IsPlayerTankRole() and L.ON or L.OFF))

    for _, unit in ipairs({ "player", "pet" }) do
        if SafeCall(UnitExists, unit) == true then
            local ok, isTanking, status, scaledPct, rawPct, threatValue = pcall(UnitDetailedThreatSituation, unit, mob)
            if ok then
                local tps = GetTPS(SafeCall(UnitGUID, unit) or unit)
                Print(string.format(L.DEBUG_UNIT, unit, SafeText(isTanking), SafeText(status), SafeText(scaledPct),
                    SafeText(rawPct), SafeText(threatValue), tps and string.format("%.1f", tps) or "--"))
            end
        end
    end
end

local function PrintDebugInfo()
    local ok, err = pcall(PrintDebugInfoImpl)
    if not ok then
        print("|cffff0000" .. L.ERROR_PREFIX .. "|r " .. tostring(err))
    end
end

SLASH_OMENRELOADEDFOREVER1 = "/orf"
SLASH_OMENRELOADEDFOREVER2 = "/neonomen"
SlashCmdList["OMENRELOADEDFOREVER"] = function(msg)
    msg = (msg or ""):lower()
    if msg == "lock" then
        db.locked = true
        ApplyFrameSettings()
        Print(L.MSG_LOCKED)
    elseif msg == "unlock" then
        db.locked = false
        ApplyFrameSettings()
        Print(L.MSG_UNLOCKED)
    elseif msg == "reset" then
        ResetPosition()
        Print(L.MSG_RESET)
    elseif msg == "pets" then
        db.showPets = not db.showPets
        Print(db.showPets and L.MSG_PETS_SHOWN or L.MSG_PETS_HIDDEN)
        RequestRefresh()
    elseif msg == "minimap" then
        db.showMinimapButton = not db.showMinimapButton
        ORF.UpdateMinimapButton()
        Print(db.showMinimapButton and L.MSG_MINIMAP_SHOWN or L.MSG_MINIMAP_HIDDEN)
    elseif msg == "test" then
        ToggleTestMode()
    elseif msg == "toggle" then
        ToggleWindow()
    elseif msg == "focus" then
        ToggleFocus()
    elseif msg == "debug" then
        PrintDebugInfo()
    else
        OpenOptions()
    end
end

RequestRefresh()

import com.Components.WinComp;
import com.GameInterface.Tooltip.Tooltip;
import com.GameInterface.Tooltip.TooltipData;
import com.GameInterface.Tooltip.TooltipInterface;

//import com.Utils.Point;
import flash.geom.Point;

import gfx.core.UIComponent;
import mx.utils.Delegate;
import com.GameInterface.Chat;
import com.GameInterface.DistributedValue;
import com.Utils.Archive;
import com.GameInterface.UtilsBase;
import com.GameInterface.Game.Shortcut;

import com.GameInterface.Inventory;
import com.Utils.ID32;
import com.GameInterface.Game.Character;
import com.GameInterface.Tooltip.TooltipDataProvider;
import com.GameInterface.Lore
import com.GameInterface.Tooltip.TooltipManager;

import com.ElTorqiro.AddonUtils.AddonUtils;
import com.ElTorqiro.AegisHUD.AddonInfo;


// config window
var g_configWindow:WinComp;

// internal distributed value listeners
var g_showConfig:DistributedValue;

// hud visible DV
var g_hudEnabled:DistributedValue;

// Viper's Top Bar Information Overload (VTIO) integration
var g_VTIOIsLoadedMonitor:DistributedValue;
var g_isRegisteredWithVTIO:Boolean = false;

// icon objects
var g_icon:MovieClip;
var g_iconTooltipData:TooltipData;
var g_tooltip:TooltipInterface;

// config settings
var g_settings:Object;


/**
 * OnLoad
 * 
 * This has GMF_DONT_UNLOAD in Modules.xml so TSW module manager will not unload it during teleports etc.
 * Thus, all the global variables will persist, like settings and icon etc, only needing to be refreshed during onLoad() and saved during onUnload().
 */
function onLoad()
{
	// default config module settings
	g_settings = {
		configWindowPosition: new Point( 200, 200 ),
		iconPosition: new Point( (Stage.visibleRect.width - g_icon._width) / 2, (Stage.visibleRect.height - g_icon._width) / 4 ),
		iconScale: 100
	};

	// load module settings
	var loadData = DistributedValue.GetDValue(AddonInfo.Name + "_Config_Data");
	for ( var i:String in g_settings )
	{
		g_settings[i] = loadData.FindEntry( i, g_settings[i] );
	}

	CreateIcon();
	
	// VTIO integration, but don't try to reregister
	if ( !g_isRegisteredWithVTIO )
	{
		g_VTIOIsLoadedMonitor = DistributedValue.Create("VTIO_IsLoaded");
		g_VTIOIsLoadedMonitor.SignalChanged.Connect(CheckVTIOIsLoaded, this);

		// handle race condition for DV already having been set before our listener was connected
		CheckVTIOIsLoaded();
	}

	// hud enabled connector
	g_hudEnabled = DistributedValue.Create(AddonInfo.Name + "_HUD_Enabled");
	g_hudEnabled.SignalChanged.Connect(HUDEnabledHandler, this);
	HUDEnabledHandler();
	
	// config window toggle listener
	g_showConfig = DistributedValue.Create(AddonInfo.Name + "_ShowConfig");
	g_showConfig.SignalChanged.Connect(ToggleConfigWindow, this);
}


function OnModuleActivated():Void
{
}

function OnModuleDeactivated():Void
{
	// destroy config window
	g_showConfig.SetValue(false);
}

function OnUnload():Void
{
	g_hudEnabled.SignalChanged.Disconnect(HUDEnabledHandler, this);
	
	g_VTIOIsLoadedMonitor.SignalChanged.Disconnect(CheckVTIOIsLoaded, this);
	g_hudData.SignalChanged.Disconnect(HUDDataChanged, this);
	
	// save module settings
	var saveData = new Archive();
	for(var i:String in g_settings)
	{
		saveData.AddEntry( i, g_settings[i] );
	}
	
	// becaues LoginPrefs.xml has a reference to this DValue, the contents will be saved whenever the game thinks it is necessary (e.g. closing the game, reloadui etc)
	DistributedValue.SetDValue(AddonInfo.Name + "_Config_Data", saveData);
}

function CheckVTIOIsLoaded()
{
	// don't re-register with VTIO
	if ( !g_isRegisteredWithVTIO && g_VTIOIsLoadedMonitor.GetValue() )
	{
		// register with VTIO
		DistributedValue.SetDValue("VTIO_RegisterAddon", 
			AddonInfo.Name + "|" + AddonInfo.Author + "|" + AddonInfo.Version + "|" + AddonInfo.Name + "_ShowConfig|" + g_icon
		);
		
		g_isRegisteredWithVTIO = true;
		
		// recreate icon tooltip info to remove the icon handling instructions
		CreateTooltipData();
	}
}

function CreateIcon():Void
{
	// don't recreate if already there
	if ( g_icon != undefined )  return;
	
	// load config icon & tooltip
	g_icon = this.attachMovie("com.ElTorqiro.AegisHUD.Config.Icon", "m_Icon", this.getNextHighestDepth() );
	CreateTooltipData();

	// restore location
	g_icon._x = g_settings.iconPosition.x;
	g_icon._y = g_settings.iconPosition.y;
	g_icon._xscale = g_icon._yscale = g_settings.iconScale;
	// check for position sanity -- visible rect may have changed between sessions, don't want the icon to be positioned off screen
	PositionIcon();
	
	// add icon mouse event handlers
	g_icon.onMousePress = function(buttonID) {
		
		// dragging icon with CTRL held down, only if VTIO not present
		if ( !g_isRegisteredWithVTIO && buttonID == 1 && Key.isDown(Key.CONTROL) ) {
			CloseTooltip();
			g_icon.startDrag();
		}
		
		// left mouse click, toggle config window
		else if ( buttonID == 1 ) {
			CloseTooltip();
			DistributedValue.SetDValue(AddonInfo.Name + "_ShowConfig",	!DistributedValue.GetDValue(AddonInfo.Name + "_ShowConfig"));
		}
		
		// right mouse click, toggle hud enabled/disabled
		else if ( buttonID == 2 ) {
			_root["eltorqiro_aegishud\\hud"].Do( "option.hudEnabled", !g_hudEnabled.GetValue() );
		}
		
		// reset icon scale, only if VTIO not present
		else if (!g_isRegisteredWithVTIO && buttonID == 2 && Key.isDown(Key.CONTROL)) {
			ScaleIcon(100);
		}
	};
	
	// stop dragging icon
	g_icon.onRelease = g_icon.onReleaseOutside = function() {
		if ( !g_isRegisteredWithVTIO )  g_icon.stopDrag();
		PositionIcon();
	};
	
	// resize icon with CTRL mousewheel
	g_icon.onMouseWheel = function(delta) {
		if ( !g_isRegisteredWithVTIO && Key.isDown(Key.CONTROL))
		{
			CloseTooltip();
			
			// determine scale
			var scaleTo:Number = g_icon._xscale + (delta * 5);
			scaleTo = Math.max(scaleTo, 35);
			scaleTo = Math.min(scaleTo, 100);
			ScaleIcon(scaleTo);
		}
	};
	
	// mouse hover, show tooltip
	g_icon.onRollOver = function()
	{
		CloseTooltip();
		g_tooltip = TooltipManager.GetInstance().ShowTooltip(g_Icon,com.GameInterface.Tooltip.TooltipInterface.e_OrientationVertical,0,g_iconTooltipData);
	};

	// mouse out, hide tooltip
	g_icon.onRollOut = function()
	{
		CloseTooltip();
	};
}

function CreateTooltipData():Void
{
	// create icon tooltip data
	g_iconTooltipData = new com.GameInterface.Tooltip.TooltipData();
	g_iconTooltipData.AddAttribute("","<font face=\'_StandardFont\' size=\'14\' color=\'#00ccff\'><b>" + AddonInfo.Name + " v" + AddonInfo.Version + "</b></font>");
	g_iconTooltipData.AddAttributeSplitter();
	g_iconTooltipData.AddAttribute("","");
	g_iconTooltipData.AddAttribute("", "<font face=\'_StandardFont\' size=\'11\' color=\'#BFBFBF\'><b>Left Click</b> Open/Close configuration window.\n<b>Right Click</b> Toggle HUD visibility.</font>");
	
	// show icon handling control instructions if VTIO has not hijacked the icon
	if ( !g_isRegisteredWithVTIO )
	{
		g_iconTooltipData.AddAttributeSplitter();
		g_iconTooltipData.AddAttribute("","");		
		g_iconTooltipData.AddAttribute("", "<font face=\'_StandardFont\' size=\'12\' color=\'#FFFFFF\'><b>Icon</b>\n</font><font face=\'_StandardFont\' size=\'11\' color=\'#BFBFBF\'><b>CTRL + Left Drag</b> Move icon.\n<b>CTRL + Roll Mousewheel</b> Resize icon.\n<b>CTRL + Right Click</b> Reset icon size to 100%.</font>");
	}

	g_iconTooltipData.AddAttributeSplitter();
	g_iconTooltipData.AddAttribute("","");	
	g_iconTooltipData.AddAttribute("", "<font face=\'_StandardFont\' size=\'12\' color=\'#FFFFFF\'><b>HUD Bars</b>\n<font face=\'_StandardFont\' size=\'11\' color=\'#BFBFBF\'><b>CTRL + Left Drag</b> Move both HUD bars at once.\n<b>CTRL + Right Drag</b> Move an individual bar.\n<b>CTRL + Mouse Wheel roll</b> Scale HUD bars.\n<b>Shift + Mouse Wheel roll</b> Reset HUD scale.</font>");
	g_iconTooltipData.m_Padding = 8;
	g_iconTooltipData.m_MaxWidth = 256;	
}

function CloseTooltip():Void
{
	if( g_tooltip != undefined )  g_tooltip.Close();
}

function ScaleIcon(scale:Number):Void
{
	if ( g_icon != undefined && !g_isRegisteredWithVTIO )
	{
		var oldWidth:Number = g_icon._width;
		var oldHeight:Number = g_icon._height;

		g_icon._xscale = g_icon._yscale = scale;
		
		// scale around centre of icon
		PositionIcon( g_icon._x - (g_icon._width - oldWidth) / 2, g_icon._y - (g_icon._height - oldHeight) / 2 );

		g_settings.iconScale = scale;
	}
}

function PositionIcon(x:Number, y:Number)
{ 
	if ( g_icon != undefined && !g_isRegisteredWithVTIO )
	{
		if ( x != undefined )  g_icon._x = x;
		if ( y != undefined )  g_icon._y = y;
		
		var onScreenPos:Point = Utils.OnScreen( g_icon );
		
		g_icon._x = onScreenPos.x;
		g_icon._y = onScreenPos.y;
		
		g_settings.iconPosition = new Point(g_icon._x, g_icon._y);
	}
}


function ToggleConfigWindow():Void
{
	g_showConfig.GetValue() ? CreateConfigWindow() : DestroyConfigWindow();
}

function CreateConfigWindow():Void
{
	// do nothing if window already open
	if ( g_configWindow )  return;
	
	g_configWindow = WinComp(attachMovie( "com.ElTorqiro.AegisHUD.Config.WindowComponent", "m_ConfigWindow", getNextHighestDepth() ));
	g_configWindow.SetTitle(AddonInfo.Name + " v" + AddonInfo.Version);
	g_configWindow.ShowStroke(false);
	g_configWindow.ShowFooter(false);
	g_configWindow.ShowResizeButton(false);

	// load the content panel
	g_configWindow.SetContent( "com.ElTorqiro.AegisHUD.Config.WindowContent" );

	// set position -- rounding of the values is critical here, else it will not reposition reliably
	g_configWindow._x = Math.round(g_settings.configWindowPosition.x);
	g_configWindow._y = Math.round(g_settings.configWindowPosition.y);
	
	// wire up close button
	g_configWindow.SignalClose.Connect( function() {
		g_showConfig.SetValue(false);
	}, this);
}

function DestroyConfigWindow():Void
{
	if ( g_configWindow )
	{	
		g_configWindow.GetContent().Destroy();
		
		g_settings.configWindowPosition.x = g_configWindow._x;
		g_settings.configWindowPosition.y = g_configWindow._y;
		
		g_configWindow.removeMovieClip();
	}
}


function HUDEnabledHandler():Void {
	g_icon.gotoAndStop( g_hudEnabled.GetValue() ? "enabled" : "disabled" );
	
	/* VTIO doesn't use your original icon, it creates a dupe, so a different approach is needed if integrated with VTIO
	 * proof: g_icon._alpha = 100; g_icon._visible = true; g_icon._y = 150; UtilsBase.PrintChatText("f:" + g_icon._currentframe);
	*/
	
	// hack to wait for VTIO to have created the dupe icon after a full reload
	// VTIO creates its dupe icon forcibly in your movieclip (so it can use your SWFs assets) as "Icon"
	if ( this["Icon"] != undefined ) ColorizeVTIOIcon();
	else _global.setTimeout( Delegate.create( this, ColorizeVTIOIcon), 500 );

}

function ColorizeVTIOIcon():Void {
	if ( g_hudEnabled.GetValue() != undefined ) this["Icon"].gotoAndStop( g_hudEnabled.GetValue() ? "enabled" : "disabled"  );
}
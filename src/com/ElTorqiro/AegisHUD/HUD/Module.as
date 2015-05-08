import com.GameInterface.DistributedValue;
import com.Utils.Archive;
import com.GameInterface.Game.Character;

import com.ElTorqiro.AegisHUD.HUD.HUD;
import com.ElTorqiro.AegisHUD.AddonInfo;
import com.ElTorqiro.AegisHUD.HUD.SettingsPacks;

import com.GameInterface.UtilsBase;

// the HUD instance
var g_HUD:HUD;

// settings persistence objects
var g_playfieldMemoryBlacklist:Object;
var g_playfieldMemoryAutoSwap:Object;

var g_data:DistributedValue;
var g_playfieldMemory:DistributedValue;

//Init
function onLoad() : Void {
	g_data = DistributedValue.Create( AddonInfo.ID + "_HUD_Data" );
	g_playfieldMemory = DistributedValue.Create( AddonInfo.ID + "_HUD_PlayfieldMemory" );
}

// module activated (i.e. its distributed value set to 1)
function OnModuleActivated() : Void {

	var playfieldID:Number = Character.GetClientCharacter().GetPlayfieldID();
	
	// load settings
	var settings:Object = { };
	var settingsTemplate:Object = SettingsPacks.defaultSettings;
	var data:Archive = g_data.GetValue();

	// get any available HUD settings
	for ( var s:String in settingsTemplate ) {
		var setting = data.FindEntry( 'setting.' + s );
		if ( setting != undefined ) {
			settings[s] = setting;
		}
	}
	
	// load playfield memory lists
	var data:Archive = DistributedValue.GetDValue(AddonInfo.ID + "_HUD_PlayfieldMemory");

	// playfield visbility
	var playfields:Array = data.FindEntryArray( "blacklist" );
	g_playfieldMemoryBlacklist = { };
	
	for ( var s:String in playfields ) {
		if ( playfields[s] != undefined ) g_playfieldMemoryBlacklist[ playfields[s] ] = true;
	}

	settings.active = g_playfieldMemoryBlacklist[ playfieldID ] == undefined;
	
	// playfield autoswap
	var playfields:Array = data.FindEntryArray( "autoswap.blacklist" );
	g_playfieldMemoryAutoSwap = { };
	
	for ( var s:String in playfields ) {
		if ( playfields[s] != undefined ) g_playfieldMemoryAutoSwap[ playfields[s] ] = true;
	}	
	
	settings.autoSwap = g_playfieldMemoryAutoSwap[ playfieldID ] == undefined;

	
	// instantiate hud
	g_HUD = HUD(attachMovie( "com.ElTorqiro.AegisHUD.HUD.HUD", "m_HUD", getNextHighestDepth(), { settings: settings } ));
}


// module deactivated (i.e. its distributed value set to 0)
function OnModuleDeactivated() : Void {

	var playfieldID:Number = Character.GetClientCharacter().GetPlayfieldID();
	
	// push data into DVs ready for game to save them
	
	// HUD settings
	var settingsTemplate:Object = SettingsPacks.defaultSettings;
	var data:Archive = new Archive();
	
	for ( var s:String in settingsTemplate ) {
		var setting = g_HUD[s];
		if ( setting != undefined ) {
			data.AddEntry( 'setting.' + s, setting );
		}
	}
	
	g_data.SetValue( data );

	
	// playfield memory lists
	var data:Archive = new Archive();

	// blacklist memory
	// current playfield
	g_HUD.active ? delete g_playfieldMemoryBlacklist[ playfieldID ] : g_playfieldMemoryBlacklist[ playfieldID ] = true;
	
	for ( var s:String in g_playfieldMemoryBlacklist ) {
		data.AddEntry( 'blacklist', s );
	}
	
	
	// autoswap memory
	// current playfield
	g_HUD.autoSwap ? delete g_playfieldMemoryAutoSwap[ playfieldID ] : g_playfieldMemoryAutoSwap[ playfieldID ] = true;
	
	for ( var s:String in g_playfieldMemoryAutoSwap ) {
		data.AddEntry( 'autoswap.blacklist', s );
	}
	
	
	g_playfieldMemory.SetValue( data );
	
	// remove HUD
	g_HUD.removeMovieClip();
}

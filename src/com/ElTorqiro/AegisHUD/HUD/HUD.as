import com.GameInterface.DistributedValue;
import com.GameInterface.Game.Character;
import com.GameInterface.Inventory;
import com.GameInterface.UtilsBase;
import flash.geom.Point;
import gfx.core.UIComponent;
import com.GameInterface.Lore;
import com.GameInterface.Input;
import com.GameInterface.InventoryItem;
import com.Utils.ID32;
import com.Utils.LDBFormat;
import com.GameInterface.Tooltip.*;
import mx.utils.Delegate;
import flash.filters.GlowFilter;
import gfx.motion.Tween;
import mx.transitions.easing.Bounce;

import com.ElTorqiro.AegisHUD.AddonInfo;
import com.ElTorqiro.AegisHUD.HUD.HotkeyHijacker;
import com.ElTorqiro.AegisHUD.AddonUtils.AddonUtils;
import com.ElTorqiro.AegisHUD.HUD.SettingsPacks;

/**
 * 
 * 
 */
class com.ElTorqiro.AegisHUD.HUD.HUD extends UIComponent {

	// item type enum shortcuts
	public static var e_ItemTypeWeapon:Number = _global.Enums.ItemType.e_ItemType_Weapon;
	public static var e_ItemTypeAegisShield:Number = _global.Enums.ItemType.e_ItemType_AegisShield;		
	public static var e_ItemTypeAegisWeapon:Number = _global.Enums.ItemType.e_ItemType_AegisWeapon;

	// aegis type enum shortcuts
	public static var e_AegisTypePink:Number = _global.Enums.AegisTypes.e_AegisPink;
	public static var e_AegisTypeBlue:Number = _global.Enums.AegisTypes.e_AegisBlue;
	public static var e_AegisTypeRed:Number = _global.Enums.AegisTypes.e_AegisRed;

	// equipment position enum shortcuts
	public static var e_PrimaryWeaponPosition:Number = _global.Enums.ItemEquipLocation.e_Wear_First_WeaponSlot;
	public static var e_PrimaryAegis1Position:Number = _global.Enums.ItemEquipLocation.e_Aegis_Weapon_1;
	public static var e_PrimaryAegis2Position:Number = _global.Enums.ItemEquipLocation.e_Aegis_Weapon_1_2;
	public static var e_PrimaryAegis3Position:Number = _global.Enums.ItemEquipLocation.e_Aegis_Weapon_1_3;

	public static var e_SecondaryWeaponPosition:Number = _global.Enums.ItemEquipLocation.e_Wear_Second_WeaponSlot;
	public static var e_SecondaryAegis1Position:Number = _global.Enums.ItemEquipLocation.e_Aegis_Weapon_2;
	public static var e_SecondaryAegis2Position:Number = _global.Enums.ItemEquipLocation.e_Aegis_Weapon_2_2;
	public static var e_SecondaryAegis3Position:Number = _global.Enums.ItemEquipLocation.e_Aegis_Weapon_2_3;

	public static var e_AegisShieldPosition:Number = _global.Enums.ItemEquipLocation.e_Aegis_Head;
	
	// selected aegis disruptor position shortcuts
	public static var e_PrimaryActiveAegisStat:Number = _global.Enums.Stat.e_FirstActiveAegis;
	public static var e_SecondaryActiveAegisStat:Number = _global.Enums.Stat.e_SecondActiveAegis;

	// aegis unlock achivement id
	public static var e_AegisUnlockAchievement:Number = 6817;	// The Lore number that unlocks the AEGIS system
																// 6817 is pulled straight from Funcom's PassiveBar

	private var _active:Boolean;
	
	private var _slotSize:Number;
	private var _barPadding:Number;
	private var _slotSpacing:Number;
	private var _hudScale:Number;
	public  var maxHUDScale:Number;
	public  var minHUDScale:Number;
	
	private var _hideDefaultDisruptorSwapUI:Boolean;
	private var _hideDefaultShieldSwapUI:Boolean;
	
	private var _neonGlowEntireBar:Boolean;
	private var _lockBars:Boolean;
	private var _attachToPassiveBar:Boolean;
	private var _animateMovementsToDefaultPosition:Boolean;
	
	private var _showBarBackground:Boolean;
	private var _barBackgroundThin:Boolean;
	private var _tintBarBackgroundByActiveAegis:Boolean;
	private var _neonGlowBarBackground:Boolean;

	private var _showWeapons:Boolean;
	private var _showShield:Boolean;
	private var _primaryItemFirst:Boolean;
	private var _secondaryItemFirst:Boolean;
	private var _shieldItemFirst:Boolean;

	private var _aegisTypeIcons:Boolean;
	
	private var _tintWeaponIconByActiveAegis:Boolean;
	private var _neonGlowWeapon:Boolean;
	
	private var _showXP:Boolean;
	private var _hideXPWhenFull:Boolean;
	private var _fetchXPAntiSpamInterval:Number = 1000; // milliseconds

	private var _showTooltips:Boolean;
	private var _suppressTooltipsInCombat:Boolean;

	private var _tintAegisIconByType:Boolean;
	private var _showActiveAegisBackground:Boolean;
	private var _tintActiveAegisBackground:Boolean;
	private var _neonGlowActiveAegisBackground:Boolean;
	private var _neonGlowAegis:Boolean;
	
	private var _neonEnabled:Boolean;

	public  var dualSelectWithModifier:Boolean;
	public  var dualSelectWithButton:Boolean;
	private var _dualSelectByDefault:Boolean;
	private var _dualSelectFromHotkey:Boolean;
	
	private var _tints:Object = { none: 0xffffff };
	
	private var _autoSwap:Boolean;
	public var  autoSwapPrimaryEnabled:Boolean;
	public var  autoSwapSecondaryEnabled:Boolean;
	public var  autoSwapShieldEnabled:Boolean;
	
	public var playfieldMemoryEnabled:Boolean;
	
	// position restoration for windows
	private var _primaryPosition:Point;
	private var _secondaryPosition:Point;
	private var _shieldPosition:Point;

	// utility objects
	private var _character:Character;
	private var _equipped:Inventory;
	private var _backpack:Inventory;
	private var _iconLoader:MovieClipLoader;
	private var _tooltip:TooltipInterface;
	private var _fetchXPAntiSpamTimeoutID:Number;
	private var _lastXPFetchTime:Number = 0;
	private var _findPassiveBarThrashCount:Number = 0;
	private var _findPassiveBarTimeoutID:Number;
	private var _findPlayerInfoThrashCount:Number = 0;
	private var _swapTimeoutID:Number;
	private var _postSwapCatchupInterval:Number = 1000;
	private var _suspendVisualUpdates:Boolean;
	
	// internal movieclips
	private var m_Primary:MovieClip;
	private var m_Secondary:MovieClip;
	private var m_Shield:MovieClip;
	private var m_DragProxy:MovieClip;	// not on stage, instantiated dynamically during drag events

	// internal shortcuts
	private var _primary:Object = { };
	private var _secondary:Object = { };
	private var _shield:Object = { };
	private var _bars:Object = { };
	
	// internal states
	private var _dragging:Boolean = false;
	private var _mouseDown:Number = -1;
	
	// collection of drag objects used by drag proxy to move as one
	private var _dragObjects:Array;
	
	// behaviour modifier keys
	public var dualDragModifier:Number = Key.CONTROL;
	public var dualDragButton:Number = 0;

	public var singleDragModifier:Number = Key.CONTROL;
	public var singleDragButton:Number = 1;
	
	public var scaleModifier:Number = Key.CONTROL;
	public var scaleResetModifier:Number = Key.SHIFT;

	public var dualSelectModifier:Number = Key.SHIFT;
	public var dualSelectButton:Number = 1;
	
	public var singleSelectButton:Number = 0;

	// swap AEGIS RPC DV used as part of hotkey hijacking
	private var _swapDisruptorRPC:DistributedValue;

	// game scaling mechanism settings
    private var _guiResolutionScale:DistributedValue;
    private var _guiHUDScale:DistributedValue;
	
	// TSW user setting that shows/hides the swap UI
	private var _showAegisSwapUI:DistributedValue;
	
	// parameters passed in through initObj of attachMovie( ..., initObj)
	private var settings:Object;

	// slot reference shortcuts
	private var _slots:Array = [];
	private var _slotFromPosition:Object = { };
	private var _slotFromAegisID:Object = { };
	private var _staticPositions:Object = { };
	private var _staticShields:Object = { };

	// aegis item properties
	private var _aegisItemProps:Object = { };
	
	// autoswap related
	private var _lastSetTarget:Character;
	private var _lastSetTargetShieldType:Number;
	private var _lastSetTargetDisruptorType:Number;

	// broadcast for enabled/disabled value for HUD
	private var _hudState:DistributedValue;
	
	
	/**
	 * constructor
	 */
	public function HUD() {
		
		// start up hidden, Activate will take care of visibility later
		visible = false;
		
		_character = Character.GetClientCharacter();
		_equipped = new Inventory( new ID32(_global.Enums.InvType.e_Type_GC_WeaponContainer, Character.GetClientCharID().GetInstance()) );
		_backpack = new Inventory( new ID32(_global.Enums.InvType.e_Type_GC_BackpackContainer, Character.GetClientCharID().GetInstance()) );

		// other objects that need creating
		_iconLoader = new MovieClipLoader();
		_iconLoader.addListener(this);
		
		// initialise distributed values
		_hudState = DistributedValue.Create( AddonInfo.ID + "_HUD_Enabled" );
		_swapDisruptorRPC = DistributedValue.Create( AddonInfo.ID + "_Swap" );
		_guiResolutionScale = DistributedValue.Create("GUIResolutionScale");
		_guiHUDScale = DistributedValue.Create("GUIScaleHUD")
		_showAegisSwapUI = DistributedValue.Create( "ShowAegisSwapUI" );
		
		// hijack hotkeys
		HotkeyHijacker.Hijack();
	}

	public function onUnload():Void {
		super.onUnload();

		Deactivate();
		
		// restore default swap UI
		hideDefaultSwapButtons( false );
		hideDefaultShieldButton( false );
		
		// release hijacked hotkeys
		HotkeyHijacker.Release();
		
		// unwire signal listeners
		Lore.SignalTagAdded.Disconnect(SlotTagAdded, this);
		_showAegisSwapUI.SignalChanged.Disconnect( Activate, this );
	}
	
	public function Activate() : Void {
		
		if ( _suspendVisualUpdates ) return;
		
		// don't re-activate if already visible
		if ( visible ) return;
		
		// don't activate if aegis system not available
		if ( !_active || !_showAegisSwapUI.GetValue() || Lore.IsLocked(e_AegisUnlockAchievement) ) {
			Deactivate();
			return;
		}

		// wire up listener for disruptor swap RPC (as sent by hotkeys)
		_swapDisruptorRPC.SignalChanged.Connect( SwapDisruptorRPCHandler, this );
		
		// wire up scale related listeners
		_guiResolutionScale.SignalChanged.Connect( Layout, this );
		_guiHUDScale.SignalChanged.Connect( Layout, this );
		
		// layout bar internals
		LayoutBars();
		
		// position & scale the bars
		Layout();
		
		// initial load of equipment into slots
		RefreshItems();

		// update active aegis values
		UpdateActiveAegis();

		// fetch initial aegis xp values
		UpdateAegisXP();
		
		// selected disruptor listener
		_character.SignalStatChanged.Connect( SlotStatChanged, this);
		
		// inventory item update listeners
		setupInventorySignals( true );
		
		// aegis xp listener
		_character.SignalTokenAmountChanged.Connect( SlotTokenAmountChanged, this );
		
		// attach to passivebar if needed
		AttachToPassiveBar( _attachToPassiveBar );
		
		// wire up event listener
		this.addEventListener("select", this, "AegisSelectHandler");
		this.addEventListener("rollover", this, "AegisRollOverHandler");
		this.addEventListener("rollout", this, "AegisRollOutHandler");
		
		this.addEventListener("dragStart", this, "DragStartHandler");
		this.addEventListener("dragEnd", this, "DragEndHandler");
		
		this.addEventListener("scale", this, "ScaleHandler");

		// show UI
		visible = true;
		_hudState.SetValue(true);
		
		// manage autoswap
		manageAutoSwap();
	}
	
	public function Deactivate() : Void {
		// hide UI
		visible = false;
		_hudState.SetValue(false);
		
		// disconnect disruptor RPC listener
		_swapDisruptorRPC.SignalChanged.Disconnect( SwapDisruptorRPCHandler, this );
		
		// disconnect ui signal listeners
		_guiResolutionScale.SignalChanged.Disconnect( Layout, this );
		_guiHUDScale.SignalChanged.Disconnect( Layout, this );
		
		// close any open tooltip
		CloseTooltip();

		// undo passivebar attachment
		AttachToPassiveBar( false );

		// unwire aegis related listeners
		_character.SignalStatChanged.Disconnect( SlotStatChanged, this);
		_character.SignalTokenAmountChanged.Disconnect( SlotTokenAmountChanged, this );

		// tear down inventory listeners
		setupInventorySignals( false );
		
		// tear down autoswap
		manageAutoSwap();
		
		// remove event listeners
		this.removeAllEventListeners();
	}

	private function setupInventorySignals( connect:Boolean ) : Void {
		var fn:String = connect ? "Connect" : "Disconnect";
		
		var inventorySignals:Array = [
			"SignalItemAdded",
			"SignalItemLoaded",
			"SignalItemMoved",
			"SignalItemRemoved",
			"SignalItemChanged"
		];
		
		var inventories:Array = [ _equipped, _backpack ];
		for ( var s:String in inventories ) {
			for ( var i:String in inventorySignals ) {
				inventories[s][ inventorySignals[i] ][fn]( inventoryUpdateHandler, this );
			}
		}
	}
	
	// hide or show default buttons
	public function hideDefaultSwapButtons( hide:Boolean ) : Void {
		
		var pb:MovieClip = _root.passivebar;
		
		// wait for the passivebar to be loaded, as it actually gets unloaded during teleports etc, not just deactivated
		if ( pb.LoadAegisButtons == undefined ) {
			
			// only retry if we're trying to hide the default UI
			if( hide ) {
				// if the thrash count is exceeded, reset count and do nothing
				if (_findPassiveBarThrashCount++ == 10)  _findPassiveBarThrashCount = 0;
				// otherwise try again only if we aren't trying to restore the buttons
				else {
					_global.setTimeout( Delegate.create(this, hideDefaultSwapButtons), 300, hide );
				}
			}
			
			return;
		}
		// if we reached this far, reset thrash count
		_findPassiveBarThrashCount = 0;

		// hide buttons
		if ( hide ) {
			if ( pb.LoadPrimaryAegisButton_AegisHUD_Saved == undefined ) {
				pb.LoadPrimaryAegisButton_AegisHUD_Saved = pb.LoadPrimaryAegisButton;
				// break the link
				pb.LoadPrimaryAegisButton = undefined;
				pb.LoadPrimaryAegisButton = function() { };

				pb.LoadSecondaryAegisButton_AegisHUD_Saved = pb.LoadSecondaryAegisButton;
				// break the link
				pb.LoadSecondaryAegisButton = undefined;
				pb.LoadSecondaryAegisButton = function() { };
				
				// remove any existing movieclips
				pb.m_PrimaryAegisSwap.unloadMovie();
				pb.m_PrimaryAegisSwap.removeMovieClip();
				
				pb.m_SecondaryAegisSwap.unloadMovie();
				pb.m_SecondaryAegisSwap.removeMovieClip();
			}
		}
		
		// restore default buttons if they have been previously disabled
		else if ( pb.LoadPrimaryAegisButton_AegisHUD_Saved != undefined ) {
			pb.LoadPrimaryAegisButton = pb.LoadPrimaryAegisButton_AegisHUD_Saved;
			pb.LoadPrimaryAegisButton_AegisHUD_Saved = undefined;

			pb.LoadSecondaryAegisButton = pb.LoadSecondaryAegisButton_AegisHUD_Saved;
			pb.LoadSecondaryAegisButton_AegisHUD_Saved = undefined;

			// do a load to restore buttons naturally if they need to be visible
			pb.LoadAegisButtons();
		}	
	}

	// hide or show default buttons
	public function hideDefaultShieldButton( hide:Boolean ) : Void {
		
		var pi:MovieClip = _root.playerinfo.m_PlayerShield;
		
		// wait for the playerinfo panel to be loaded, as it actually gets unloaded during teleports etc, not just deactivated
		if ( pi == undefined ) {
			
			// only retry if we're trying to hide the default UI
			if( hide ) {
				// if the thrash count is exceeded, reset count and do nothing
				if (_findPlayerInfoThrashCount++ == 10)  _findPlayerInfoThrashCount = 0;
				// otherwise try again only if we aren't trying to restore the buttons
				else {
					_global.setTimeout( Delegate.create(this, hideDefaultShieldButton), 300, hide );
				}
			}
			
			return;
		}
		// if we reached this far, reset thrash count
		_findPlayerInfoThrashCount = 0;

		// hide/show button
		pi._visible = !hide;
	}
	
	
	private function configUI() : Void {
		super.configUI();

		// primary weapon bar
		_primary = {
			mc: m_Primary,
			activeAegisStat: e_PrimaryActiveAegisStat,
			slots: {
				item: { type: "weapon", inventory: _equipped, position: e_PrimaryWeaponPosition, mc: m_Primary.m_Item },
				aegis1: { type: "disruptor", inventory: _equipped, position: e_PrimaryAegis1Position, mc: m_Primary.m_Aegis1, next: e_PrimaryAegis2Position, prev: e_PrimaryAegis3Position, pair: e_SecondaryAegis1Position },
				aegis2: { type: "disruptor", inventory: _equipped, position: e_PrimaryAegis2Position, mc: m_Primary.m_Aegis2, next: e_PrimaryAegis3Position, prev: e_PrimaryAegis1Position, pair: e_SecondaryAegis2Position },
				aegis3: { type: "disruptor", inventory: _equipped, position: e_PrimaryAegis3Position, mc: m_Primary.m_Aegis3, next: e_PrimaryAegis1Position, prev: e_PrimaryAegis2Position, pair: e_SecondaryAegis3Position }
			}
		};
		
		// secondary weapon bar
		_secondary = {
			mc: m_Secondary,
			activeAegisStat: e_SecondaryActiveAegisStat,
			slots: {
				item: { type: "weapon", inventory: _equipped, position: e_SecondaryWeaponPosition, mc: m_Secondary.m_Item },
				aegis1: { type: "disruptor", inventory: _equipped, position: e_SecondaryAegis1Position, mc: m_Secondary.m_Aegis1, next: e_SecondaryAegis2Position, prev: e_SecondaryAegis3Position, pair: e_PrimaryAegis1Position },
				aegis2: { type: "disruptor", inventory: _equipped, position: e_SecondaryAegis2Position, mc: m_Secondary.m_Aegis2, next: e_SecondaryAegis3Position, prev: e_SecondaryAegis1Position, pair: e_PrimaryAegis2Position },
				aegis3: { type: "disruptor", inventory: _equipped, position: e_SecondaryAegis3Position, mc: m_Secondary.m_Aegis3, next: e_SecondaryAegis1Position, prev: e_SecondaryAegis2Position, pair: e_PrimaryAegis3Position }
			}
		};
		
		// shield bar
		_shield = {
			mc: m_Shield,
			slots: {
				item: { mc: m_Shield.m_Item, locked: true },
				aegis1: { type: "shield", mc: m_Shield.m_Aegis1, aegisID: 111 },
				aegis2: { type: "shield", mc: m_Shield.m_Aegis2, aegisID: 113 },
				aegis3: { type: "shield", mc: m_Shield.m_Aegis3, aegisID: 114 }
			}
		};

		_bars = { primary: _primary, secondary: _secondary, shield: _shield };

		for ( var s:String in _bars ) {
			
			SetupGlobalMouseHandlers( _bars[s].mc.m_Background );
			
			_bars[s].selectedAegisSlot = null;
			_bars[s].activeAegisSlot = undefined;
			
			for( var i:String in _bars[s].slots ) {
				
				var slot:Object = _bars[s].slots[i];

				_slots.push( slot );
				
				slot.bar = _bars[s];

				if( slot.position ) {
					_staticPositions[ slot.inventory.GetInventoryID().GetType() + "_" + slot.position ] = slot;
				}
				
				if ( slot.type == "shield" ) {
					_staticShields[ slot.aegisID ] = slot;
				}
				
				if ( slot.type == "disruptor" || slot.type == "shield" || slot.type == "weapon" ) {
					slot.slottable = true;
				}
				
				if ( slot.type == "disruptor" || slot.type == "shield" ) {
					slot.selectable = true;
				}
				
				// attach UI handlers
				SetupButtonHandlers( slot.mc );
			}
		}
		
		var keyPart:String = _equipped.GetInventoryID().GetType() + "_";
		for ( var s:String in _staticPositions ) {
			var slot:Object = _staticPositions[s];
			
			if ( slot.type == "disruptor" ) {
				slot.next = _staticPositions[ keyPart + slot.next ];
				slot.prev = _staticPositions[ keyPart + slot.prev ];
				slot.pair = _staticPositions[ keyPart + slot.pair ];
			}
		}
		
		// aegis item properties
		_aegisItemProps[103] = { id: 103, itemType: e_ItemTypeAegisWeapon, aegisType: e_AegisTypePink, tint: "psychic", icon: "disruptor-psychic" };
		_aegisItemProps[104] = { id: 104, itemType: e_ItemTypeAegisWeapon, aegisType: e_AegisTypePink, tint: "psychic", icon: "disruptor-psychic" };
		_aegisItemProps[105] = { id: 105, itemType: e_ItemTypeAegisWeapon, aegisType: e_AegisTypeBlue, tint: "cyber", icon: "disruptor-cyber" };
		_aegisItemProps[106] = { id: 106, itemType: e_ItemTypeAegisWeapon, aegisType: e_AegisTypeBlue, tint: "cyber", icon: "disruptor-cyber" };
		_aegisItemProps[107] = { id: 107, itemType: e_ItemTypeAegisWeapon, aegisType: e_AegisTypeRed, tint: "demonic", icon: "disruptor-demonic" };
		_aegisItemProps[108] = { id: 108, itemType: e_ItemTypeAegisWeapon, aegisType: e_AegisTypeRed, tint: "demonic", icon: "disruptor-demonic" };

		_aegisItemProps[111] = { id: 111, itemType: e_ItemTypeAegisShield, aegisType: e_AegisTypePink, tint: "psychic", icon: "shield-psychic" };
		_aegisItemProps[113] = { id: 113, itemType: e_ItemTypeAegisShield, aegisType: e_AegisTypeBlue, tint: "cyber", icon: "shield-cyber" };
		_aegisItemProps[114] = { id: 114, itemType: e_ItemTypeAegisShield, aegisType: e_AegisTypeRed, tint: "demonic", icon: "shield-demonic" };

		// if the toon doesn't have the AEGIS system unlocked already, listen in case it unlocks during session
		if ( Lore.IsLocked(e_AegisUnlockAchievement) )  Lore.SignalTagAdded.Connect(SlotTagAdded, this);
		
		// handle the TSW user config option for showing/hiding AEGIS HUD UI
		_showAegisSwapUI.SignalChanged.Connect( Activate, this);
		
		// apply initial settings based on defaults
		var initSettings:Object = SettingsPacks.defaultSettings;

		// mix in passed in settings with default settings
		// but only apply if settings are compatible with the current settings version
		// otherwise everything should be left as defaults to force a settings reset
		if ( settings.settingsVersion >= initSettings.settingsVersion ) {
			for ( var s:String in settings ) {
				initSettings[s] = settings[s];
			}
		}
		
		ApplySettingsPack( initSettings );
		delete settings;
		
		Activate();
	}

	// handler for situation where AEGIS system becomes unlocked during play session
	private function SlotTagAdded( tag:Number ) : Void {
		if ( tag == e_AegisUnlockAchievement ) {
			Lore.SignalTagAdded.Disconnect( SlotTagAdded, this );
			Activate();
		}
	}

	
	/**
	 * 
	 * autoswap related functions
	 * 
	 */

	private function manageAutoSwap() : Void {

		// only swap if visible and setting is enabled
		if ( visible && _autoSwap ) {
			_character.SignalOffensiveTargetChanged.Connect( offensiveTargetChangedHandler, this );
			_character.SignalToggleCombat.Connect( autoSwapAll, this );

			attachCurrentTarget();
		}

		else {
			_character.SignalOffensiveTargetChanged.Disconnect( offensiveTargetChangedHandler, this );
			_character.SignalToggleCombat.Disconnect( autoSwapAll, this );
			
			detachLastTarget();
		}
	}

	private function offensiveTargetChangedHandler(target:ID32) : Void {
		detachLastTarget();
		attachCurrentTarget();
	}

	private function attachCurrentTarget() : Void {
		// attach to current target
		_lastSetTarget = Character.GetCharacter( _character.GetOffensiveTarget() );
		_lastSetTarget.SignalStatChanged.Connect( targetStatChangedHandler, this );
		
		autoSwapAll();
	}
	
	private function detachLastTarget() : Void {
		// detach from previous target
		_lastSetTarget.SignalStatChanged.Disconnect( targetStatChangedHandler, this );
		_lastSetTarget = undefined;
	}
	
	// handler for target shield or disruptor type changing (for autoswap purposes)
	private function targetStatChangedHandler(stat:Number, value:Number) : Void {
		
		switch( stat ) {
			case _global.Enums.Stat.e_CurrentPinkShield:
			case _global.Enums.Stat.e_CurrentBlueShield:
			case _global.Enums.Stat.e_CurrentRedShield:
				autoSwapDisruptors();
			break;
			
			case _global.Enums.Stat.e_ColorCodedDamageType:
				autoSwapShield();
			break;
		}
		
	}

	private function autoSwapAll() : Void {
		autoSwapDisruptors();
		autoSwapShield();
	}
	
	private function autoSwapDisruptors() : Void {
		
		if ( !_autoSwap ) return;
		
		// get current target
		var target:Character = Character.GetCharacter(_character.GetOffensiveTarget());

		// the order is important here, as the shields are always overlaid in this sequence
		var shieldPriority:Array = [
			{ stat: _global.Enums.Stat.e_CurrentPinkShield, aegisType: e_AegisTypePink },
			{ stat: _global.Enums.Stat.e_CurrentBlueShield, aegisType: e_AegisTypeBlue },
			{ stat: _global.Enums.Stat.e_CurrentRedShield,  aegisType: e_AegisTypeRed }
		];
		
		var targetShieldType:Number;
		
		for ( var i:Number = 0; i < shieldPriority.length; i++ ) {
			if ( target.GetStat( shieldPriority[i].stat, 2 ) > 0 ) {
				targetShieldType = shieldPriority[i].aegisType;
				break;
			}
		}

		if( targetShieldType) {
		
			var weaponBars:Array = [ {bar: _primary, swap: autoSwapPrimaryEnabled}, {bar: _secondary, swap: autoSwapSecondaryEnabled} ];
			for ( var s:String in weaponBars ) {
				
				if ( !weaponBars[s].swap ) continue;
				
				var bar:Object = weaponBars[s].bar;
				
				// find first aegis on bar that matches the target aegis shield type
				for ( var i:String in bar.slots ) {
					var slot:Object = bar.slots[i];
					
					// if disruptor type matches target shield type, switch to it, explicitly with no dual-select
					if ( _aegisItemProps[slot.item.m_AegisItemType].aegisType == targetShieldType ) {
						SwapToAegisSlot( slot, false );
						break;
					}
				}
			}
		}
		
	}

	private function autoSwapShield() : Void {

		if ( !_autoSwap || !autoSwapShieldEnabled ) return;
		
		// get current target
		var target:Character = Character.GetCharacter(_character.GetOffensiveTarget());
		
		// discover the aegis damage type the target deals out
		var targetDisruptorType:Number = target.GetStat(_global.Enums.Stat.e_ColorCodedDamageType, 2);
		
		if ( targetDisruptorType ) {
			
			// swap shield
			for ( var s:String in _shield.slots ) {
				var slot:Object = _shield.slots[s];
				
				if ( _aegisItemProps[slot.item.m_AegisItemType].aegisType == targetDisruptorType ) {
					SwapToAegisSlot( slot );
					break;
				}
			}
		}
	}
	
	
	// layout bar internally
	private function LayoutBars():Void {

		if ( _suspendVisualUpdates ) return;		
		
		for ( var s:String in _bars ) {
			var bar = _bars[s].mc;
			
			// item slot visibility
			if ( (bar != m_Shield && _showWeapons) || (bar == m_Shield && _showShield) ) {
				bar.m_Item._visible = true;
				
				// item slot position
				if ( this["_" + s + "ItemFirst"] ) {
					bar.m_Item._x = _barPadding;
					bar.m_Aegis1._x = bar.m_Item._x + bar.m_Item._width + _slotSpacing;
					var lastButton:MovieClip = bar.m_Aegis3;
				}
				
				else {
					bar.m_Aegis1._x = _barPadding;
					bar.m_Item._x = bar.m_Aegis1._x + (bar.m_Aegis1._width * 3) + _slotSpacing;
					var lastButton:MovieClip = bar.m_Item;
				}
			}
			
			else {
				bar.m_Item._visible = false;
				bar.m_Aegis1._x = _barPadding;
				var lastButton:MovieClip = bar.m_Aegis3;
			}

			bar.m_Aegis2._x = bar.m_Aegis1._x + bar.m_Aegis1._width;
			bar.m_Aegis3._x = bar.m_Aegis2._x + bar.m_Aegis2._width;
			
			// position and resize background to wrap buttons
			bar.m_Background._width = lastButton._x + lastButton._width + (_barPadding);
			
			if ( _barBackgroundThin ) {
				bar.m_Background._y = 9;
				bar.m_Background._height = 6;
			}
			
			else {
				bar.m_Background._y = 0 - _barPadding;
				bar.m_Background._height = _slotSize + (_barPadding * 2);
			}
		}
		
		// if hud is attached to passivebar, reset to default swap button position
		if ( _attachToPassiveBar ) {
			MoveToDefaultPosition();
		}
	}
	
	/**
	 * layout bars in same location as default passivebar swap buttons
	 */
	public function MoveToDefaultPosition(userTriggered:Boolean):Void {

		// if passivebar is available, default position is directly above that
		if ( _root.passivebar.m_Bar != undefined ) {

			var pb = _root.passivebar;
			
			var pbx:Number = pb.m_BaseWidth / 2 + pb.m_Button._x; // - 4;
			var pby:Number = pb.m_Bar._y; // - 5;
			
			var globalPassiveBarPos:Point = new Point( pbx, pby );
			pb.localToGlobal( globalPassiveBarPos );
			this.globalToLocal( globalPassiveBarPos );

			var primaryDefaultPosition = new Point( globalPassiveBarPos.x - m_Primary._width - 3 - 9 - m_Shield._width / 2, globalPassiveBarPos.y - m_Primary._height - 3 );
			var secondaryDefaultPosition = new Point( primaryDefaultPosition.x + m_Primary._width + 6, primaryDefaultPosition.y );
			var shieldDefaultPosition = new Point( secondaryDefaultPosition.x + m_Secondary._width + 18, primaryDefaultPosition.y );
			
			// userTriggered parameter needed to prevent the annoying pop-in when first loading into an area
			// when the bars are initially positioned
			if( userTriggered && _animateMovementsToDefaultPosition ) {
			
				m_Primary.tweenTo(1, {
						_x: primaryDefaultPosition.x,
						_y: primaryDefaultPosition.y
					},
					Bounce.easeOut
				);
				
				m_Secondary.tweenTo(1, {
						_x: secondaryDefaultPosition.x,
						_y: secondaryDefaultPosition.y
					},
					Bounce.easeOut
				);
				
				m_Shield.tweenTo(1, {
						_x: shieldDefaultPosition.x,
						_y: shieldDefaultPosition.y
					},
					Bounce.easeOut
				);
				
			}
			else {
				m_Primary._x = primaryDefaultPosition.x;
				m_Primary._y = primaryDefaultPosition.y;
				m_Secondary._x = secondaryDefaultPosition.x;
				m_Secondary._y = secondaryDefaultPosition.y;
				m_Shield._x = shieldDefaultPosition.x;
				m_Shield._y = shieldDefaultPosition.y;
			}
			
		}
		
		// if no passivebar available, approximate a decent position at bottom of screen
		else {
			// align to stage method

			m_Primary._x =  ((Stage["visibleRect"].width / 2) - m_Primary._width - 3 );
			m_Secondary._x = ( m_Primary._x + m_Primary._width + 6 );
			m_Primary._y = m_Secondary._y = ( Stage["visibleRect"].height - 75 - m_Primary._height - 3 );
			
			m_Shield._x = ((Stage["visibleRect"].width / 2) - (m_Shield._width / 2) );
			m_Shield._y = m_Primary._y - m_Shield._height - 4;
		}

	}
	
	// sets the real scale & position of the AegisHUD, integrating with the game's resolution & HUD scaling
	private function Layout():Void {
		
		if ( _suspendVisualUpdates ) return;		

		// this is based on the trio: GUI resolution, GUI hud scale, this hud scale
		var guiResolutionScale:Number = _guiResolutionScale.GetValue();
		var guiHUDScale:Number = _guiHUDScale.GetValue();
		
		// some sanity checks in case somehow the game isn't providing these
		if ( guiResolutionScale == undefined ) guiResolutionScale = 1;
		if ( guiHUDScale == undefined ) guiHUDScale = 100;

		// calculate the real final scale
		var realScale:Number = guiResolutionScale * ( guiHUDScale * _hudScale / 100 );
		
		m_Primary._xscale = m_Primary._yscale = realScale;
		m_Secondary._xscale = m_Secondary._yscale = realScale;
		m_Shield._xscale = m_Shield._yscale = realScale;
		
		// if attached to passivebar, reset position
		if ( _attachToPassiveBar ) {
			MoveToDefaultPosition();
		}
		
		else {

			if ( _primaryPosition ) {
				// Despite Point.x being a number, the +0 below is a quick way to ensure the ._x accepts the Point.x property.
				// If not doing this, then the number prints out as "xxx", but seems to get sent to the _x property as "xxx.0000000000"
				// which the _x setter fails to interpret for some reason and does not set.
				m_Primary._x = _primaryPosition.x + 0;
				m_Primary._y = _primaryPosition.y + 0;
				
				m_Secondary._x = _secondaryPosition.x + 0;
				m_Secondary._y = _secondaryPosition.y + 0;
				
				m_Shield._x = _shieldPosition.x + 0;
				m_Shield._y = _shieldPosition.y + 0;
			}
			
			// set default positions to simulate the default buttons
			else {
				MoveToDefaultPosition();
			}
		}
	}
	

	// restore default tints
	public function ApplyDefaultTints():Void {
		
		var defaults:Object = SettingsPacks.defaultSettings;
		
		_suspendVisualUpdates = true;
		
		tintAegisPsychic = defaults.tintAegisPsychic;
		tintAegisCybernetic = defaults.tintAegisCybernetic;
		tintAegisDemonic = defaults.tintAegisDemonic;
		tintAegisEmpty = defaults.tintAegisEmpty;
		tintAegisStandard = defaults.tintAegisStandard;

		tintXPProgress = defaults.tintXPProgress;
		tintXPFull = defaults.tintXPFull;
		
		tintBarStandard = defaults.tintBarStandard;
		
		_suspendVisualUpdates = false;
		invalidate();
	}
	
	// restore all settings to default
	public function ApplyDefaultSettings() : Void {
		ApplySettingsPack( SettingsPacks.defaultSettings );
		LayoutBars();
		Layout();
	}
	
	
	// refresh shield item locations
	private function RefreshShieldPositions() : Void {

		var item:InventoryItem;
		var foundCount:Number = 0;
		
		// determine maximum number of shields to look for, can reduce hits on inventory significantly
		var maxShieldCount:Number = 0;
		for ( var s:String in _staticShields ) {
			maxShieldCount++;
		}
		
		// identify equipped shield
		item = _equipped.GetItemAt( e_AegisShieldPosition );
		
		if ( item.m_ItemType == e_ItemTypeAegisShield ) {
			inventoryUpdateHandler( _equipped.GetInventoryID(), e_AegisShieldPosition );
			foundCount = 1;
		}

		// find shields in backpack
		// stop once the most possible number of shields has been found
		for ( var i:Number = _backpack.GetMaxItems() - 1; foundCount <= maxShieldCount && i >= 0; i-- ) {
			foundCount += Number(inventoryUpdateHandler( _backpack.GetInventoryID(), i ));
		}
	}
	
	// refresh all slot items
	private function RefreshItems() : Void {
		
		RefreshShieldPositions();

		for ( var s:String in _staticPositions ) {
			var slot:Object = _staticPositions[s];
			inventoryUpdateHandler( slot.inventory.GetInventoryID(), slot.position );
		}
	}

	private function inventoryUpdateHandler(inventoryID:ID32, position:Number) : Boolean {
		
		var inventory:Inventory = inventoryID.GetType() == _equipped.GetInventoryID().GetType() ? _equipped : _backpack;
		var item:InventoryItem = inventory.GetItemAt( position );

		var key:String = inventoryID.GetType() + "_" + position;
		var slot:Object = _slotFromPosition[key];
		
		var handled:Boolean = false;
		
		// if the position keys back to a shield slot and the item going into it is not a shield (including empty)
		// or the slot is on the watchlist and is empty
		// clear the links and update the slot with empty item
		if ( (slot.type == "shield" && item.m_ItemType != e_ItemTypeAegisShield) || (item == undefined && _staticPositions[key]) ) {
			
			// if the slot used to have an aegis item in it, remove the link
			if ( slot.item.m_AegisItemType ) {
				delete _slotFromAegisID[ slot.item.m_AegisItemType ];
			}
			
			// remove the position link
			delete _slotFromPosition[key];
			
			// remove the item from the slot
			slot.item = undefined;
			
			handled = true;
		}

		// otherwise, if it is on the watchlist, update the links and update the slot with the item
		else if ( (slot = _staticShields[item.m_AegisItemType]) || (slot = _staticPositions[key]) ) {

			// update the slot item
			if ( slot != undefined ) {
				slot.item = item;
				slot.inventory = inventory;
				slot.position = position;

				loadIcon( slot );
			}
			
			// if it is an aegis item, add a link
			if ( item.m_AegisItemType ) {
				_slotFromAegisID[ item.m_AegisItemType ] = slot;

				// update the xp value
				UpdateAegisItemXP( item.m_AegisItemType );
			}

			// add a position link
			_slotFromPosition[key] = slot;
			
			handled = true;
		}
		
		// if this is the equipped shield slot, update the active shields
		UpdateActiveAegis();
		
		invalidate();
		
		return handled;
	}

	private function loadIcon(slot:Object) : Void {

		// aegis items can load different types of icons
		if ( slot.item.m_AegisItemType && _aegisTypeIcons ) {
			var iconClip:MovieClip = slot.mc.m_Icon.attachMovie( _aegisItemProps[slot.item.m_AegisItemType].icon, "m_Icon", 0 );
			iconClip._width = iconClip._height = 24;
		}
		
		else if ( slot.item ) {
			var iconRef:ID32 = slot.item.m_Icon;
			slot.mc.m_Icon.createEmptyMovieClip( "m_Icon", 0 );
			_iconLoader.loadClip( com.Utils.Format.Printf( "rdb:%.0f:%.0f", iconRef.GetType(), iconRef.GetInstance() ), slot.mc.m_Icon.m_Icon );
		}
		
	}
	
	// update all icons in all slots
	private function updateIcons() : Void {

		for ( var s:String in _slots ) {
			loadIcon( _slots[s] );
		}
		
	}
	
	// handler for MovieClipLoader.loadClip
	private function onLoadInit(target:MovieClip) : Void {
		// set proper scale of target element
		target._width = target._height = 24;
	}
	

	// highlight active aegis slot
	private function draw() : Void {
		
		if ( _suspendVisualUpdates ) return;

		// do for both aegis sides
		for ( var s:String in _bars ) {
			
			var bar = _bars[s];
			var barMC:MovieClip = bar.mc;
			
			// establish bar tint value
			var barTint = _tints[ _aegisItemProps[bar.selectedAegisSlot.item.m_AegisItemType].tint ];
			if ( barTint == undefined ) barTint = _tints.empty;

			// neon glow entire bar
			if ( _neonEnabled && _neonGlowEntireBar ) {
				var entireGlow:GlowFilter = new GlowFilter( barTint, 0.8, 8, 8, 1, 3, false, false );
				
				barMC.filters = [ entireGlow ];
			}
			else barMC.filters = [];

			
			// show or hide background (must use alpha so it remains a hit target for mouse)
			if ( _showBarBackground ) {
				barMC.m_Background._alpha = 100;

				// tint bar background
				AddonUtils.Colorize( barMC.m_Background, _tintBarBackgroundByActiveAegis ? barTint : _tints.barStandard );
				barMC.m_Background.gotoAndStop("white");
			
				// neon glow bar background
				if ( _tintBarBackgroundByActiveAegis && _neonEnabled && _neonGlowBarBackground ) {
					barMC.m_Background.gotoAndStop("black");

					var barGlow:GlowFilter =
					_barBackgroundThin ?  new GlowFilter( barTint, 0.8, 6, 6, 2, 3, false, false )
									   :  new GlowFilter( barTint, 0.8, 6, 6, 1, 3, false, false );
					
					barMC.m_Background.filters = [ barGlow ];
				}
				else barMC.m_Background.filters = [];
			}
			
			else {
				barMC.m_Background._alpha = 0;
			}

			
			// handle item slot
			var itemSlot = bar.slots.item;
			var itemSlotMC = itemSlot.mc;
			
			// show or hide item icon
			if ( itemSlot.item == undefined && !itemSlot.locked ) {
				itemSlotMC.m_Watermark._visible = true;
				itemSlotMC.m_Icon._visible = false;
			}
			
			else {
				itemSlotMC.m_Watermark._visible = false;
				itemSlotMC.m_Icon._visible = true;
			}
			

			// tint item icon
			var itemIconTint:Number = _tintWeaponIconByActiveAegis ? barTint : _tints.none;
			AddonUtils.Colorize( itemSlotMC.m_Icon, itemIconTint );
				

			// neon glow weapon
			if ( _neonEnabled && _neonGlowWeapon ) {
				var itemGlow = new GlowFilter( barTint, 0.8, 6, 6, 2, 3, false, false );
				itemSlotMC.filters = [ itemGlow ];
			}
			else itemSlotMC.filters = [];

			
			// iterate through aegis slots
			for ( var a:String in bar.slots ) {
				var slot = bar.slots[a];
				
				if ( slot.type != "disruptor" && slot.type != "shield" ) continue;
				
				var slotMC = slot.mc;
				var slotTint = _tints[ _aegisItemProps[slot.item.m_AegisItemType].tint ];
				if ( slotTint == undefined ) slotTint = _tints.empty;
				
				// show or hide aegis icon
				if ( slot.item == undefined ) {
					slotMC.m_Watermark._visible = true;
					slotMC.m_Icon._visible = false;
				}

				else {
					slotMC.m_Watermark._visible = false;
					slotMC.m_Icon._visible = true;
				}


				// tint aegis icon
				var iconTint:Number = _tintAegisIconByType ? slotTint : _tints.none;
				AddonUtils.Colorize( slotMC.m_Icon, iconTint );
				

				// show xp display
				if ( !_showXP || slot.item == undefined ) {
					slotMC.m_XP._visible = false;
				}

				else {
					var textFormat:TextFormat = new TextFormat();
					
					if( slot.aegisXP >= 100 ) {
						slotMC.m_XP._visible = !_hideXPWhenFull;
						textFormat.color = _tints.xpFull;
					}
					
					else {
						slotMC.m_XP._visible = true;
						textFormat.color = _tints.xpProgress;				
					}
					
					slotMC.m_XP.t_XP.setTextFormat( textFormat );
					slotMC.m_XP.t_XP.setNewTextFormat( textFormat );
				}


				// handle active aegis higlighting
				if ( slot == bar.selectedAegisSlot ) {

					// show aegis background
					if ( _showActiveAegisBackground ) {
						slotMC.m_Background._alpha = 100;

						
						// tint slot background
						var backgroundTint:Number = _tintActiveAegisBackground ? slotTint : _tints.standard;
						AddonUtils.Colorize( slotMC.m_Background, backgroundTint );
						slotMC.m_Background.gotoAndStop("white");
						

						// neon glow slot background
						if ( _tintActiveAegisBackground && _neonEnabled && _neonGlowActiveAegisBackground ) {
							slotMC.m_Background.gotoAndStop("black");
							var backgroundGlow:GlowFilter = new GlowFilter( barTint, 0.8, 6, 6, 3, 3, false, false );							
							slotMC.m_Background.filters = [ backgroundGlow ];
						}
						
						else {
							slotMC.m_Background.filters = [];
						}
						
					}
					
					else {
						slotMC.m_Background._alpha = 0;
					}

					
					// neon glow aegis icon
					if ( _neonEnabled && _neonGlowAegis ) {
						var aegisGlow = new GlowFilter( slotTint, 0.8, 6, 6, 3, 3, false, false );
						if( slotMC.m_Icon._visible ) {
							slotMC.m_Icon.filters = [ aegisGlow ];
						}
						
						else {
							slotMC.m_Watermark.filters = [ aegisGlow ];
						}
					}
					
					else {
						slotMC.m_Icon.filters = [];
						slotMC.m_Watermark.filters = [];
					}
				}
				
				else {
					slotMC.m_Background._alpha = 0;
					slotMC.m_Icon.filters = [];
					slotMC.m_Watermark.filters = [];
					slotMC.m_Background.filters = [];
				}
			}
		}	
	}
	
	// set the current active aegis stat straight from the game
	// note that this will NOT cause an invalidate() so no redraw will occur
	private function UpdateActiveAegis() : Void {
		
		var keyPrefix:String = _equipped.GetInventoryID().GetType() + "_";
		
		_primary.activeAegisSlot = _staticPositions[ keyPrefix + _character.GetStat( _primary.activeAegisStat ) ];
		_secondary.activeAegisSlot = _staticPositions[ keyPrefix + _character.GetStat( _secondary.activeAegisStat ) ];
		
		_shield.activeAegisSlot = _slotFromPosition[ keyPrefix + e_AegisShieldPosition ];
		
		// if this happens when the selection catchup timer isn't running, update the selected as well
		if ( _swapTimeoutID == undefined ) {
			SyncSelectedWithActive();
		}
	}

	// swap to an aegis slot
	private function SwapToAegisSlot(slot:Object, dualSelect:Boolean) : Void {
		
		// do nothing if no slot provided
		if ( slot == undefined) return;
		
		var fromSlot:Object = slot.bar.selectedAegisSlot;
		
		// swapping to shields involves "using" the item
		if ( slot.bar == _shield ) {

			// swapping shields can only be done out of combat			
			if ( _character.IsInCombat() || _character.IsGhosting() || _character.IsDead() ) return;
				
			// check that the item linked to the slot is actually still in the inventory position (sync check)
			if ( slot.item != slot.inventory.GetItemAt(slot.position) ) {
				RefreshShieldPositions();
			}

			// don't unequip the slotted shield if it is clicked, or if there is no item in the slot
			if ( slot.inventory == _equipped || slot.item == undefined ) return;

			// make sure we're not trying to switch to an already selected position, to avoid swap-backs
			if ( slot == fromSlot ) return;
			
			// otherwise use the item to initiate a swap
			slot.inventory.UseItem( slot.position );

			// clear existing post-swap callback
			PostSwapCatchup(true);
			
			// important to update the internal pointer for the aegis location
			// even before we find out if the swap was successful
			// otherwise rapid clicks can cause the selection to do a swapback
			slot.bar.selectedAegisSlot = slot;
		}
		
		// disruptors rotate through available slots
		else {
		
			// switch forward?
			if ( fromSlot.next == slot )
			{
				// first param is first/second aegis, second param is forward/back
				Character.SwapAegisController( slot.bar == _primary, true);
			}
			
			// or switch back? (doing the extra check instead of an arbitrary 'else' prevents double-jumps caused by switch latency)
			else if ( fromSlot.prev == slot )
			{
				Character.SwapAegisController( slot.bar == _primary, false);
			}
			
			// clear existing post-swap callback
			PostSwapCatchup(true);
			
			// important to update the internal pointer for the aegis location
			// even before we find out if the swap was successful
			// otherwise rapid clicks can cause the selection to jump 2 spots
			slot.bar.selectedAegisSlot = slot;
			
			// select other side partner slot if dualSelect in use
			if ( dualSelect ) {
				SwapToAegisSlot( slot.pair );
			}
		}
		
		invalidate();
	}

	// post-swap callback that will catch up the selectedAegisSlot for each bar
	// this is needed in case of users going bonkers with very rapid clicks, which can
	// get out of sync with the server if the server drops one of the request packets
	// (yes it happens often under command spam)
	private function PostSwapCatchup(restart:Boolean):Void {
		if ( _swapTimeoutID != undefined ) {
			_global.clearTimeout( _swapTimeoutID );
			_swapTimeoutID = undefined;
		}
		
		// if restarting timer, set up timer again
		if ( restart ) {
			_swapTimeoutID = setTimeout( Delegate.create(this, PostSwapCatchup), _postSwapCatchupInterval );
		}
		
		// otherwise action the catchup
		else {
			SyncSelectedWithActive();
		}
	}
	
	private function SyncSelectedWithActive():Void {

		var invalid:Boolean = false;
		
		// the check is to avoid a lot of unnecessary redraws via invalidate
		for ( var s:String in _bars) {
			if ( _bars[s].selectedAegisSlot != _bars[s].activeAegisSlot ) {
				_bars[s].selectedAegisSlot = _bars[s].activeAegisSlot;
				invalid = true;
			}
		}
		
		if ( invalid )  invalidate();
	}
	
	// handle mouse clicks that select an aegis
	private function AegisSelectHandler(event:Object):Void {
		SwapToAegisSlot( event.slot, event.dualSelect );
	}

	// handle mouse rolling over an aegis
	private function AegisRollOverHandler(event:Object):Void {
		// prepare tooltip data
		OpenTooltip( event.slot );
	}

	private function AegisRollOutHandler(event:Object):Void {
		CloseTooltip();
	}
	
    private function OpenTooltip(slot:Object) : Void {
		// close any existing tooltip
		CloseTooltip();
		
		// don't show anything if setting disabled OR if the hud elements are currently being dragged
		if ( !_showTooltips || _dragging || (!_suppressTooltipsInCombat && _character.IsInCombat()) || slot.item == undefined ) return;

		var tooltipData:TooltipData = TooltipDataProvider.GetInventoryItemTooltip( slot.inventory.GetInventoryID(), slot.position );
		
		// add raw xp value
		//tooltipData.AddAttributeSplitter();
		if ( slot.item.m_AegisItemType ) {
			tooltipData.AddDescription( 'AEGIS Item ID: <font color="#ffff00">' + slot.item.m_AegisItemType + '</font>, XP: <font color="#ffff00">' + _character.GetTokens(slot.item.m_AegisItemType) + '</font>' );
		}
		
		_tooltip = TooltipManager.GetInstance().ShowTooltip( slot.mc, TooltipInterface.e_OrientationVertical, -1, tooltipData );
    }
    
    private function CloseTooltip():Void {
        if (_tooltip != undefined) {
            _tooltip.Close();
			_tooltip = undefined;
        }
    }

	// handle move / drag start of one or both bars
	private function DragStartHandler(event:Object):Void {

		// do nothing if scale and movement is prevented
		if ( _lockBars || _attachToPassiveBar ) return;
		
		// close any open tooltip
		CloseTooltip();
		
		// instantiate the drag proxy
		m_DragProxy = this.createEmptyMovieClip("m_DragProxy", this.getNextHighestDepth());

		if ( event.dual ) {
			_dragObjects = [ _primary.mc, _secondary.mc, _shield.mc ];
		}
		else {
			_dragObjects = [ event.bar ];
		}
		
		this.onMouseMove = DragMovementHandler;
		m_DragProxy.startDrag();
		
	}
	
	private function DragMovementHandler():Void {
		
		for ( var i:Number = 0; i < _dragObjects.length; i++ ) {
			
			var moveObject:MovieClip = _dragObjects[i];
			moveObject._x += m_DragProxy._x - m_DragProxy._prevX;
			moveObject._y += m_DragProxy._y - m_DragProxy._prevY;
			
		}
		
		m_DragProxy._prevX = m_DragProxy._x;
		m_DragProxy._prevY = m_DragProxy._y;		
	}
	
	private function DragEndHandler(event:Object):Void {

		_dragObjects = undefined;
		
		this.onMouseMove = undefined;
		m_DragProxy.stopDrag();
		m_DragProxy.unloadMovie();
		m_DragProxy.removeMovieClip();
	}
	
	private function handleMousePress(controllerIdx:Number, keyboardOrMouse:Number, button:Number):Void {
		// only allow one mouse button to be pressed at once
		if ( _mouseDown != -1 ) return;
		_mouseDown = button;

		// TODO: check if no modifiers held down, and only fire click if that is the case, otherwise fire appropriate start drag etc
		if ( !_lockBars && !_attachToPassiveBar && Key.isDown( dualDragModifier ) && button == dualDragButton ) {
			_dragging = true;
			dispatchEvent( { type:"dragStart", modifier:dualDragModifier, button:button, dual:true, bar: getBarMouseOver() } );
		}
		
		else if ( !lockBars && !_attachToPassiveBar && Key.isDown( singleDragModifier ) && button == singleDragButton ) {
			_dragging = true;
			dispatchEvent( { type:"dragStart", modifier:singleDragModifier, button:button, dual:false, bar: getBarMouseOver() } );
		}
		
		else {
			// check if an aegis selector button was involved
			var slot:Object = getSlotMouseOver();

			if ( slot.selectable ) {
				var dual:Boolean;
				if ( _dualSelectByDefault ) {
					dual = !(dualSelectWithModifier && Key.isDown(dualSelectModifier)) && !(dualSelectWithButton && button == dualSelectButton);
				}
				else {
					dual = (dualSelectWithModifier && Key.isDown(dualSelectModifier)) || (dualSelectWithButton && button == dualSelectButton);
				}

				dispatchEvent({ type:"select", modifier:dualSelectModifier, button:button, slot:slot, dualSelect:dual });
			}
		}
	}
	
	private function handleMouseRelease(controllerIdx:Number, keyboardOrMouse:Number, button:Number):Void {
		// only propogate if the release is associated with the originally held down button
		if ( _mouseDown != button ) return;
		_mouseDown = -1;

		if ( _dragging ) {
			dispatchEvent( { type:"dragEnd", button:button } );
			_dragging = false;
		}
	}
	
	private function handleReleaseOutside(controllerIdx:Number, button:Number):Void {
		handleMouseRelease(controllerIdx, 0, button);
	}

	private function handleRollOver(mouseIdx:Number):Void {
		// check which aegis selector button was involved
		var slot:Object = getSlotMouseOver();
		dispatchEvent( { type:"rollover", slot:slot } );
	}

	private function handleRollOut(mouseIdx:Number):Void {
		dispatchEvent( { type:"rollout" } );
	}
	
	private function handleMouseWheel(delta:Number, targetPath:String):Void {
		if( Key.isDown(scaleResetModifier) ) dispatchEvent( { type:"scale", delta:delta, targetPath:targetPath, reset:true } );
		else if ( Key.isDown(scaleModifier) ) dispatchEvent( { type:"scale", delta:delta, targetPath:targetPath, reset:false } );
	}

	
	private function getSlotMouseOver():Object {

		for ( var s:String in _bars ) {
			var bar:Object = _bars[s];
			for ( var i:String in bar.slots ) {
				var slot:Object = bar.slots[i];
				if ( slot.mc.hitTest(_root._xmouse, _root._ymouse, true, true) ) {
					return slot;
				}
			}
		}

		return undefined;
	}
	
	private function getBarMouseOver():MovieClip {
		
		for ( var s:String in _bars ) {
			if ( _bars[s].mc.hitTest(_root._xmouse, _root._ymouse, true, true) ) return _bars[s].mc;
		}
		
		return undefined;
	}
	
	/**
	 * Sets up mouse event handlers for hud or bar movement
	 * 
	 * @param	mc Movieclip to configure handlers on
	 */
	private function SetupGlobalMouseHandlers(mc:MovieClip) {
		
		if ( !mc ) return;
		
		mc.onPress = Delegate.create(this, handleMousePress);
		mc.onRelease = Delegate.create(this, handleMouseRelease);
		mc.onReleaseOutside = Delegate.create(this, handleReleaseOutside);
		mc["onPressAux"] = mc.onPress;
		mc["onReleaseAux"] = mc.onRelease;
		mc["onReleaseOutsideAux"] = mc.onReleaseOutside;
		
		mc["onMouseWheel"] = Delegate.create( this, handleMouseWheel );
	}
	
	
	/**
	 * Sets up mouse event handlers for aegis selector buttons
	 * 
	 * @param	mc Movieclip to configure handlers on
	 */
	private function SetupButtonHandlers(mc:MovieClip) {

		if ( !mc ) return;
		
		SetupGlobalMouseHandlers( mc );
		
		mc.onRollOver = Delegate.create(this, handleRollOver);
		mc.onRollOut = Delegate.create(this, handleRollOut);
		mc.onDragOut = mc.onRollOut;
		mc.onDragOutAux = mc.onRollOut;
	}

	private function ScaleHandler(event:Object):Void {
		
		// simplified scale handler which doesn't bother scaling around centre of entire hud, unlike previous version

		// do nothing if scale and movement is prevented
		if ( _lockBars ) return;

		// scale in 5% increments
		if ( event.reset ) {
			hudScale = 100;
		}
		else {
			hudScale += event.delta * 5;
		}
	}

	
	// fetch aegis XP for each slotted controller, using tooltip data as the source of the values
	private function UpdateAegisXP():Void {
		
		// do nothing if XP isn't being shown
		if ( !_showXP ) {
			if ( _fetchXPAntiSpamTimeoutID != undefined ) _global.clearTimeout( _fetchXPAntiSpamTimeoutID );
			_fetchXPAntiSpamTimeoutID = undefined;
			
			return;
		}
		
		// calculate interval values
		var now:Number = Number(new Date());
		var timeSinceFetch:Number = now - _lastXPFetchTime;

		// if within the spam interval since last successful fetch, start the timer or just wait for an existing one to finish
		if ( timeSinceFetch < _fetchXPAntiSpamInterval ) {
			if ( _fetchXPAntiSpamTimeoutID == undefined) {
				_fetchXPAntiSpamTimeoutID = _global.setTimeout( Delegate.create(this, UpdateAegisXP), _fetchXPAntiSpamInterval ); // Math.max(_fetchXPAntiSpamInterval - timeSinceFetch, 100) );
			}
			return;
		}
		
		// otherwise cancel any outstanding timer
		else if ( _fetchXPAntiSpamTimeoutID != undefined) _global.clearTimeout( _fetchXPAntiSpamTimeoutID );

		_fetchXPAntiSpamTimeoutID = undefined;

		// update last run time
		_lastXPFetchTime = now;
		
		// for each aegis controller, get the tooltip data and extract the XP value
		for ( var s:String in _slotFromAegisID ) {
			UpdateAegisItemXP( s );
		}
	}
	
	// update aegis xp for a single item
	private function UpdateAegisItemXP(aegisID:Number) : Void {
		
		// do nothing if there is nothing sensible to act on
		if ( !_showXP ) return;

		var slot:Object = _slotFromAegisID[ aegisID ];
		
		// check that the slot has a valid item in it
		if ( slot == undefined || slot.item == undefined || slot.inventory.GetItemAt(slot.position).m_AegisItemType != aegisID ) return;

		// fetch tooltip for item
		var tooltipData:TooltipData = TooltipDataProvider.GetInventoryItemTooltip( slot.inventory.GetInventoryID(), slot.position );

		// break out xp value
		var xpString:String = tooltipData.m_Descriptions[2];

		// get the first occurence of %
		var endPos:Number = xpString.indexOf('%');
		
		if ( LDBFormat.GetCurrentLanguageCode() == 'de' ) endPos--;	// german client has a space between number and %

		for ( var startPos:Number = endPos; startPos >= 0; startPos-- ) {
			
			var char:String = xpString.charAt(startPos);
			
			// not a number sequence
			if ( char == ' ' || char == '>' ) {
				break;
			}
		}

		var xp:Number = Math.floor( Number(xpString.substring(++startPos, endPos)) );

		// put xp value into slot and publish into component
		slot.aegisXP = xp == Number.NaN ? undefined : xp;
		
		// text display being used
		slot.mc.m_XP.t_XP.text = xp == Number.NaN ? "?" : xp;
		
		// progress bar being used
		slot.mc.m_XPBar.m_Progress._xscale = xp == Number.NaN ? 0: xp;
		
		// when reaching 100, redraw to show the "Full" elements
		if ( xp <= 0 || xp >= 100 ) invalidate();
	}
	
	
	// signal handlers for inventory and character stat changes
	
	// handles active aegis being swapped
	private function SlotStatChanged(statID:Number, value:Number):Void {
		// only proceed if stat is to do with selected disruptor
		if ( statID == _primary.activeAegisStat || statID == _secondary.activeAegisStat) {
			UpdateActiveAegis();
		}
	}

	// aegis xp listener
	private function SlotTokenAmountChanged( tokenID:Number, newValue:Number, oldNumber:Number ) {
		UpdateAegisItemXP( tokenID );
	}
	
	
	// separating this from AttachToPassiveBar to ensure only one of them runs at once, given how quickly it could be called in succession at startup
	private function FindPassiveBarToAttach(attach:Boolean):Void {
		if ( _root.passivebar.m_Bar.onTweenComplete == undefined ) {
			// if the thrash count is exceeded, reset count and do nothing
			if (_findPassiveBarThrashCount++ == 30) {
				_findPassiveBarThrashCount = 0;
				_findPassiveBarTimeoutID = undefined;
			}
			// otherwise try again
			else _findPassiveBarTimeoutID = _global.setTimeout( Delegate.create(this, AttachToPassiveBar), 100, attach );
			
			return;
		}

		// if we reached this far, reset thrash count
		_findPassiveBarThrashCount = 0;
		_findPassiveBarTimeoutID = undefined;
		
		AttachToPassiveBar( attach );
	}
	
	// hooks into the passivebar to set up proxies for open/close
	private function AttachToPassiveBar(attach:Boolean):Void {
		
		if ( _findPassiveBarTimeoutID != undefined ) return;
		
		var passivebar = _root.passivebar;
		
		// set up proxies and force HUD into position
		if ( attach ) {
			
			// make sure not to "re-attach" if already attached
			if( passivebar.m_Bar.onTweenComplete_AegisHUD_Saved == undefined ) {
				passivebar.m_Bar.onTweenComplete_AegisHUD_Saved = passivebar.m_Bar.onTweenComplete;
				// break the link
				passivebar.m_Bar.onTweenComplete = undefined;
				passivebar.m_Bar.onTweenComplete = Delegate.create(this, PassiveBarOnTweenCompleteProxy);
				
				MoveToDefaultPosition();
			}
		}
		
		// remove proxy and restore original function -- make sure not to detach when not attached
		else if( passivebar.m_Bar.onTweenComplete_AegisHUD_Saved != undefined ) {
			passivebar.m_Bar.onTweenComplete = passivebar.m_Bar.onTweenComplete_AegisHUD_Saved;
			passivebar.m_Bar.onTweenComplete_AegisHUD_Saved = undefined;
		}
	}
	
	// proxy function for hooking into the passivebar onTweenComplete listener that fires after each open/close
	private function PassiveBarOnTweenCompleteProxy():Void {
		// let the original function run
		_root.passivebar.m_Bar.onTweenComplete_AegisHUD_Saved();
		MoveToDefaultPosition(true);
	}

	
	// apply a bundle of settings all at once
	public function ApplySettingsPack(pack:Object) {
		
		_suspendVisualUpdates = true;
		
		for ( var s:String in pack ) {
			// TODO : implement something equivalent to AS3's .hasOwnProperty(name)
			this[s] = pack[s];
		}
		
		_suspendVisualUpdates = false;
		invalidate();
	}

	/**
	 * handler for the swap disruptor RPC calls
	 * 
	 * these calls typically arrive only from the hotkey hijacker, but there is nothing stopping other things sending them
	 * 
	 * format of message is specific:
	 * <primary|secondary>.<next|prev>.<sequence>
	 * 
	 * sequence is just a unique number that forces the DValue SignalChanged to fire (because the value has changed)
	 * so if the same command is sent twice in a row it still triggers twice
	 * 
	 */
	private function SwapDisruptorRPCHandler():Void {
		
		// split message into component parts
		var parts:Array = String(_swapDisruptorRPC.GetValue()).split('.');
		var bar:Object = _bars[ parts[0] ];
		var direction:String = parts[1];
		
		if ( bar && (direction == "next" || direction == "prev") ) {
			SwapToAegisSlot( bar.selectedAegisSlot[direction], _dualSelectByDefault && _dualSelectFromHotkey);
		}
	}
	
	
	/**
	 * 
	 * getters & setters
	 * 
	 */
	
	public function get showWeapons():Boolean { return _showWeapons; }
	public function set showWeapons(value:Boolean) {
		if( _showWeapons != value) {
			_showWeapons = value;
			LayoutBars();
		}
	}

	public function get showShield():Boolean { return _showShield; }
	public function set showShield(value:Boolean) {
		if( _showShield != value) {
			_showShield = value;
			LayoutBars();
		}
	}
	
	public function get showBarBackground():Boolean { return _showBarBackground; }
	public function set showBarBackground(value:Boolean) {
		if( _showBarBackground != value) {
			_showBarBackground = value;
			invalidate();
		}
	}

	public function get barBackgroundThin():Boolean { return _barBackgroundThin; }
	public function set barBackgroundThin(value:Boolean) {
		if( _barBackgroundThin != value) {
			_barBackgroundThin = value;
			LayoutBars();
			invalidate();
		}
	}
	
	public function get showXP():Boolean { return _showXP; }
	public function set showXP(value:Boolean) {
		if( _showXP != value ) {
			_showXP = value;
			
			if (_showXP) UpdateAegisXP();
			
			invalidate();
		}
	}
	
	public function get showTooltips():Boolean { return _showTooltips; }
	public function set showTooltips(value:Boolean) { _showTooltips = value; }
	
	public function get primaryPosition():Point { return new Point(m_Primary._x, m_Primary._y); }
	public function set primaryPosition(value:Point) {
		_primaryPosition = setBarPosition( m_Primary, value );
	}

	public function get secondaryPosition():Point { return new Point(m_Secondary._x, m_Secondary._y); }
	public function set secondaryPosition(value:Point) {
		_secondaryPosition = setBarPosition( m_Secondary, value );
	}

	public function get shieldPosition():Point { return new Point(m_Shield._x, m_Shield._y); }
	public function set shieldPosition(value:Point) {
		_shieldPosition = setBarPosition( m_Shield, value );
	}

	/**
	 * handles updating the properties controlling position of the bars
	 * 
	 * @param	bar			movieclip of the bar to position
	 * @param	position	point to move the bar to
	 * 
	 * @return	point bar was moved to, can be undefined if undefined is passed in the position parameter
	 */
	private function setBarPosition( bar:MovieClip, position:Point ) : Point {
		if ( position != undefined ) {
			bar._x = position.x;
			bar._y = position.y;
		}

		Layout();
		
		return position;
	}
	
	// overall hud scale
	public function get hudScale():Number { return _hudScale; }
	public function set hudScale(value:Number) {
		if ( _hudScale == value ) return;

		if ( value < minHUDScale ) _hudScale = minHUDScale;
		else if ( value > maxHUDScale ) _hudScale = maxHUDScale;
		else if ( value == Number.NaN ) _hudScale = 100;
		else _hudScale = value;
		
		// apply actual scale to bars
		Layout();
	}
	

	public function get primaryItemFirst():Boolean { return _primaryItemFirst; }
	public function set primaryItemFirst(value:Boolean) {
		if( _primaryItemFirst != value ) {
			_primaryItemFirst = value;
			LayoutBars();
		}
	}

	public function get secondaryItemFirst():Boolean { return _secondaryItemFirst; }
	public function set secondaryItemFirst(value:Boolean) {
		if( _secondaryItemFirst != value ) {
			_secondaryItemFirst = value;
			LayoutBars();
		}
	}

	public function get shieldItemFirst():Boolean { return _shieldItemFirst; }
	public function set shieldItemFirst(value:Boolean) {
		if( _shieldItemFirst != value ) {
			_shieldItemFirst = value;
			LayoutBars();
		}
	}
	
	public function get lockBars():Boolean { return _lockBars; }
	public function set lockBars(value:Boolean) { _lockBars = value; }
		
	public function get neonGlowEntireBar():Boolean { return _neonGlowEntireBar; }
	public function set neonGlowEntireBar(value:Boolean):Void {
		if ( _neonGlowEntireBar != value ) {
			_neonGlowEntireBar = value;
			invalidate();
		}
	}
	
	public function get attachToPassiveBar():Boolean { return _attachToPassiveBar; }
	public function set attachToPassiveBar(value:Boolean):Void {
		_attachToPassiveBar = value;
		AttachToPassiveBar(_attachToPassiveBar);
	}
	
	public function get tintBarBackgroundByActiveAegis():Boolean { return _tintBarBackgroundByActiveAegis; }
	public function set tintBarBackgroundByActiveAegis(value:Boolean):Void {
		if ( _tintBarBackgroundByActiveAegis != value ) {
			_tintBarBackgroundByActiveAegis = value;
			invalidate();
		}
	}
	
	public function get neonGlowBarBackground():Boolean { return _neonGlowBarBackground; }
	public function set neonGlowBarBackground(value:Boolean):Void {
		if ( _neonGlowBarBackground != value ) {
			_neonGlowBarBackground = value;
			invalidate();
		}
	}
	
	public function get tintWeaponIconByActiveAegis():Boolean { return _tintWeaponIconByActiveAegis; }
	public function set tintWeaponIconByActiveAegis(value:Boolean):Void {
		if( _tintWeaponIconByActiveAegis != value ) {
			_tintWeaponIconByActiveAegis = value;
			invalidate();
		}
	}
	
	public function get neonGlowWeapon():Boolean { return _neonGlowWeapon; }
	public function set neonGlowWeapon(value:Boolean):Void {
		if( _neonGlowWeapon != value ) {
			_neonGlowWeapon = value;
			invalidate();
		}
	}
	
	public function get showActiveAegisBackground():Boolean { return _showActiveAegisBackground; }
	public function set showActiveAegisBackground(value:Boolean):Void {
		if( _showActiveAegisBackground != value ) {
			_showActiveAegisBackground = value;
			invalidate();
		}
	}

	public function get tintActiveAegisBackground():Boolean { return _tintActiveAegisBackground; }
	public function set tintActiveAegisBackground(value:Boolean):Void {
		if( _tintActiveAegisBackground != value ) {
			_tintActiveAegisBackground = value;
			invalidate();
		}
	}
	
	public function get neonGlowActiveAegisBackground():Boolean { return _neonGlowActiveAegisBackground; }
	public function set neonGlowActiveAegisBackground(value:Boolean):Void {
		if( _neonGlowActiveAegisBackground != value ) {
			_neonGlowActiveAegisBackground = value;
			invalidate();
		}
	}
	
	public function get neonGlowAegis():Boolean { return _neonGlowAegis; }
	public function set neonGlowAegis(value:Boolean):Void {
		if( _neonGlowAegis != value ) {
			_neonGlowAegis = value;
			invalidate();
		}
	}
	
	public function get neonEnabled():Boolean { return _neonEnabled; }
	public function set neonEnabled(value:Boolean):Void {
		if( _neonEnabled != value ) {
			_neonEnabled = value;
			invalidate();
		}
	}

	public function get animateMovementsToDefaultPosition():Boolean { return _animateMovementsToDefaultPosition; }
	public function set animateMovementsToDefaultPosition(value:Boolean):Void {
		_animateMovementsToDefaultPosition = value;
	}

	public function get dualSelectByDefault():Boolean { return _dualSelectByDefault; }
	public function set dualSelectByDefault(value:Boolean):Void { _dualSelectByDefault = value; }

	public function get dualSelectFromHotkey():Boolean { return _dualSelectFromHotkey; }
	public function set dualSelectFromHotkey(value:Boolean):Void { _dualSelectFromHotkey = value; }

	public function get tintAegisIconByType():Boolean { return _tintAegisIconByType; }
	public function set tintAegisIconByType(value:Boolean):Void {
		if ( _tintAegisIconByType != value ) {
			_tintAegisIconByType = value;
			invalidate();
		}
	}

	public function get aegisTypeIcons():Boolean { return _aegisTypeIcons; }
	public function set aegisTypeIcons(value:Boolean):Void {
		if ( _aegisTypeIcons != value ) {
			_aegisTypeIcons = value;
			
			updateIcons();
		}
	}
	
	public function get autoSwap():Boolean { return _autoSwap; }
	public function set autoSwap(value:Boolean):Void {
		if( _autoSwap != value ) {
			_autoSwap = value;
			manageAutoSwap();
		}
	}
	
	public function get slotSize():Number { return _slotSize; }
	public function set slotSize(value:Number):Void {
		if( _slotSize != value ) {
			_slotSize = value;
			LayoutBars();
		}
	}
	public function get barPadding():Number { return _barPadding; }
	public function set barPadding(value:Number):Void {
		if( _barPadding != value ) {
			_barPadding = value;
			LayoutBars();
		}
	}
	public function get slotSpacing():Number { return _slotSpacing; }
	public function set slotSpacing(value:Number):Void {
		if ( _slotSpacing != value ) {
			_slotSpacing = value;
			LayoutBars();
		}
	}

	public function get tintAegisPsychic():Number { return _tints.psychic };
	public function set tintAegisPsychic(value:Number):Void {
		if ( _tints.psychic != value && AddonUtils.isRGB(value)) {
			_tints.psychic = value;
			invalidate();
		}
	}
	
	public function get tintAegisCybernetic():Number { return _tints.cyber };
	public function set tintAegisCybernetic(value:Number):Void {
		if ( _tints.cyber != value && AddonUtils.isRGB(value)) {
			_tints.cyber = value;
			invalidate();
		}
	}

	public function get tintAegisDemonic():Number { return _tints.demonic };
	public function set tintAegisDemonic(value:Number):Void {
		if ( _tints.demonic != value && AddonUtils.isRGB(value)) {
			_tints.demonic = value;
			invalidate();
		}
	}

	public function get tintAegisEmpty():Number { return _tints.empty };
	public function set tintAegisEmpty(value:Number):Void {
		if ( _tints.empty != value && AddonUtils.isRGB(value)) {
			_tints.empty = value;
			invalidate();
		}
	}

	public function get tintAegisStandard():Number { return _tints.standard };
	public function set tintAegisStandard(value:Number):Void {
		if ( _tints.standard != value && AddonUtils.isRGB(value)) {
			_tints.standard = value;
			invalidate();
		}
	}
	
	public function get tintXPProgress():Number { return _tints.xpProgress };
	public function set tintXPProgress(value:Number):Void {
		if ( _tints.xpProgress != value && AddonUtils.isRGB(value)) {
			_tints.xpProgress = value;
			invalidate();
		}
	}

	public function get tintXPFull():Number { return _tints.xpFull };
	public function set tintXPFull(value:Number):Void {
		if ( _tints.xpFull != value && AddonUtils.isRGB(value)) {
			_tints.xpFull = value;
			invalidate();
		}
	}

	public function get tintBarStandard():Number { return _tints.barStandard };
	public function set tintBarStandard(value:Number):Void {
		if ( _tints.barStandard != value && AddonUtils.isRGB(value)) {
			_tints.barStandard = value;
			invalidate();
		}
	}

	public function get hideXPWhenFull():Boolean { return _hideXPWhenFull; }
	public function set hideXPWhenFull(value:Boolean):Void {
		if ( _hideXPWhenFull != value ) {
			_hideXPWhenFull = value;
			
			if ( showXP ) invalidate();
		}
	}

	public function get hideDefaultDisruptorSwapUI():Boolean { return _hideDefaultDisruptorSwapUI; }
	public function set hideDefaultDisruptorSwapUI(value:Boolean):Void {
		if ( _hideDefaultDisruptorSwapUI != value ) {
			_hideDefaultDisruptorSwapUI = value;
			
			hideDefaultSwapButtons(_hideDefaultDisruptorSwapUI);
		}
	}

	public function get hideDefaultShieldSwapUI():Boolean { return _hideDefaultShieldSwapUI; }
	public function set hideDefaultShieldSwapUI(value:Boolean):Void {
		if ( _hideDefaultShieldSwapUI != value ) {
			_hideDefaultShieldSwapUI = value;
			
			hideDefaultShieldButton(_hideDefaultShieldSwapUI);
		}
	}
	
	public function get active():Boolean { return _active; }
	public function set active(value:Boolean):Void {
		if ( _active != value ) {
			_active = value;
			
			_active ? Activate() : Deactivate();
		}
	}
	
}
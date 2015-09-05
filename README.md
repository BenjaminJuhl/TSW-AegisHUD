ElTorqiro_AegisHUD
==================
AegisHUD UI mod for the MMORPG "The Secret World"
   
   
What is this?
-------------
ElTorqiro_AegisHUD is a drop-in heads-up-display module for selecting active Aegis controllers, and is intended to replace the default in-game Aegis selector buttons.
Feedback, updates and community forum can be found at http://forums.thesecretworld.com/showthread.php?t=80429
   
   
User Configuration
------------------
The mod provides an interactive on-screen icon which can be used to bring up a comprehensive configuration panel.  Hover the mouse over the icon for instructions.  If you have Viper's Topbar Information Overload (VTIO) installed, or an equivalent handler, the icon will be available in a VTIO slot.
   
You can also toggle the configuration window with the option ElTorqiro_AegisHUD_ShowConfig, which can be set via a chat command as follows:
/setoption ElTorqiro_AegisHUD_ShowConfig 1
(1 = open, 0 = closed)
   
   
Known Issues and Gotchas
------------------------
* On some rare occasions, when using bulk Aegis XP cannisters the "XP gain" trigger event is not fired by the game API.  This leaves the XP display on the AegisHUD on the old value.  Re-equipping the affected controller, doing a /reloadui, or waiting for a regular XP gain event will fetch the new value.
   
   
Installation
------------
Extract the contents of the zip file into: YOUR_TSW_DIRECTORY\Data\Gui\Customized\Flash
This will add the appropriate directory and put the files in the right place.

Uninstallation
--------------
Delete the directory: YOUR_TSW_DIRECTORY\Data\Gui\Customized\Flash\ElTorqiro_AegisHUD
   
   
Order of Aegis controllers on the bars
--------------------------------------
On the server side, each Aegis slot for your character is numbered 1-3 for each side (left/right). It's not obvious in the character panel because of the way the default UI is built, but when you rotate an active Aegis it doesn't actually move items around in slots. The whole "rotating" concept is quite misleading. All the rotation actually does is update an internal "active Aegis" pointer which points to one of the Aegis slots, no equipment is moved. Additionally, the foreground slot in the character panel is not "SLOT #1" -- it shows the current "active" slot.  This is a new way of representing gear, as no other equipment in TSW works this way.
   
In the AegisHUD bars, the slots are laid out in order, 1-3, for each side. This gives you the ultimate freedom to slot your Aegis in whatever order best makes sense to you. To get the order you want, open up your character panel and remove all your Aegis controllers.  Now drag a controller into one of the character panel slots and you can see in realtime where it appears in the AegisHUD.  If it's not in the right position, remove it and try a different character panel slot.  Did you know you can drag controllers onto the "rear" slots in the character panel? Now you do! Repeat the process until your controllers are all in your preferred order in the AegisHUD. Because the layout in AegisHUD is always 1-2-3, next time you login the order will still be the same.
  
An exception to this is the Shield bar. Because Aegis shields could be anywhere in your backpack, or equipped as the active shield, there is no UI-supported ordering that would make any sense. Thus, the order of shields is set to the shield priority ordering, i.e. Psychic => Cybernetic => Demonic.
   
   
Source Code
-----------
You can get the source from GitHub at https://github.com/eltorqiro/TSW-AegisHUD
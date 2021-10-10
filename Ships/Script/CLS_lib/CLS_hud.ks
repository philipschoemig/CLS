// CLS_hud.ks - A library of functions specific to how the CLS (Common Launch Script) prints to the in-game terminal
// Copyright © 2021 Qwarkk6
// Lic. CC-BY-SA-4.0 

@lazyglobal off.

// Scroll print function
// Credit to /u/only_to_downvote / mileshatem for the original (and much more straightforward) scrollprint function that this is an adaptation of
Function scrollprint {
	Parameter nextprint.
	Parameter timeStamp is true.
	local maxlinestoprint is 33.	// Max number of lines in scrolling print list
	//local listlinestart is 6.	// First line For scrolling print list
	local TtLaunch is "T" + d_mt(cdown).
	local ElapsedTime is "T" + d_mt(missiontime).

	if timeStamp = true {
		if runmode = -1 {
			printlist:add(TtLaunch + " - " + nextprint).
		} else {
			printlist:add(ElapsedTime + " - " + nextprint).
		}
	} else {
		printlist:add(nextprint).
	}

	if printlist:length < maxlinestoprint {
		For printline in printlist {
			print printlist[printlist:length-1] at (0,(printlist:length-1)+listlinestart).
		}
	} else {
		printlist:remove(0).
		local currentline is listlinestart.
		until currentLine = 38 {
			For printline in printlist {
				Print "                                                 " at (0,currentLine).
				Print printline at (0,currentline).
				Set currentline to currentline+1.
			}
		}
	}
}

// presents time of day in hh:mm:ss format
Function t_o_d {
	parameter ts.
	
	global hpd is round(body:rotationperiod).
	global dd is floor(ts/(hpd*3600)).  
	global hh is floor((ts-hpd*3600*dd)/3600).  
	global mm is floor((ts-3600*hh-hpd*3600*dd)/60).  
	global ss is round(ts) - mm*60 -   hh*3600 - hpd*3600*dd. 

	if ss = 60 {
	global ss is 0.
		global mm is mm+1.
	}
	
	if ss < 10 and mm > 10 {
		return hh + ":" + mm + ":0" + ss.
	}
	else if ss > 10 and mm < 10 {
		return hh + ":0" + mm + ":" + ss.
	}
	else if ss < 10 and mm < 10 {
		return hh + ":0" + mm + ":0" + ss.
	}
	else {
	return hh + ":" + mm + ":" + ss.
	}	
}

// presents mission time to mm:ss format
function d_mt {
	parameter mt.
	local m is floor(Abs(mt)/60).
	local s is round(Abs(mt))-(m*60).
	local t is "-".
	
	If mt < 0 {
		set t to "-".
	} else {
		set t to "+".
	}
	
	if s < 10 {
		set s to "0" + s.
	}
	if s = 60 {
		set m to m+1.
		set s to "00".
	}
	if m < 10 {
		set m to "0" + m.
	}
	
	return t + m + ":" + s.
}

// Converts stage number to engine readout text.
Function engineReadout {
	parameter stage.
	local stageNum is list(0,1,2,3).
	local string is list("-","Main Engine","Second Engine","Third Engine").
	
	if stage > 3 {
		Return "Engine".
	} else {
		return string[stageNum:find(stage)].
	}
}

// Periodic readouts for vehicle speed, altitude and downrange distance
Function eventLog {
	local logTimeIncrement is 60.
	local shipGEO is ship:geoposition.
	
	If runMode > 1 {
		if ship:q*15 > 10 and maxQReadout = false {
			scrollPrint(Ship:name + " is experiencing Max Q").
			set maxQReadout to true.
		}
		if ship:q*15 < 10 and maxQReadout = true and passQReadout = false {
			scrollPrint(Ship:name + " has passed through Max Q").
			set passQReadout to true.
		}			
		If missiontime >= logTime {
			
			//Downrange calculations
			local v1 is shipGEO:position - ship:body:position.
			local v2 is launchLoc:position - ship:body:position.
			local distAng is vang(v1,v2).
			local downRangeDist is distAng * constant:degtorad * ship:body:radius.
			
			scrollPrint("Speed: "+FLOOR(Ship:AIRSPEED*3.6) + "km/h").
			scrollPrint("          Altitude: "+ROUND(Altitude/1000,2)+"km",false).
			scrollPrint("          Downrange: "+ROUND(downRangeDist/1000,2)+"km",false).
			If runMode < 3 {
				Set logTime to logTime + (logTimeIncrement).
			} else {
				Set logTime to logTime + 100000.
			}
		}
	}
}

// Initiates the HUD on the terminal
Function HUDinit {
	Parameter launchtime.
	Parameter targetapoapsis.
	Parameter targetinclination.
	Parameter logging.
	
	Print Ship:name + " Launch Sequence Initialised" at (0,0).
	Print "Target Launch Time: NET " + T_O_D(launchtime) at (0,1).
	if targetapoapsis = maxApo {
		Print "Target Parking Orbit: Highest Possible" at (0,2).
	} else {
		Print "Target Parking Orbit: " + Ceiling(targetapoapsis,2) + "m" at (0,2).
	}
	Print "Target Orbit Inclination: " + Ceiling(ABS(targetinclination),2) + "°" at (0,3).
	if logging {
		Print "-Logging-Data---------------------------------------" at (0,40).
	} else {
		Print "----------------------------------------------------" at (0,40).
	}
	Print "Fuel: 000s" at (41,42).
	Print "Offset: --°" at (1,42).
	Print "Apo:  000s" at (41,41).
}

// Handles countdown 
Function countdown {
	Parameter tminus.
	Parameter cdown.
	local cdlist is list(19,17,15,13,11,9,8,7,5,4).
	
	if cdlist[cdownreadout] = tminus and tminus > 3 {
		if ABS(cdown) <= tminus {
			scrollPrint("T" + d_mt(cdown),false).
			set cdownreadout to min(cdownreadout+1,9).
			global tminus is tminus-1.
		}
	} 
}

// Identifies / Calculates data to be displayed on the terminal HUD.
Function AscentHUD {
	
	local hud_met is "Mission Elapsed Time: " + "T" + D_MT(missiontime) + " (" + runmode + ") ".
	local hud_pitch is "Pitch: " + padding(Round(trajectorypitch,1),2,1,false) + "° ".
	local hud_stage is "Stage: " + currentstagenum + "/" + MaxStages.
	local hud_staging is "-------".								
	local hud_var1 is "Aero: " + padding(Round(ship:q,2),1,2,false).
	local hud_var2 is "Mode:  " + mode.
	local hud_twr is "TWR:  " + padding(Round(max(twr(),0),2),1,2,false).
	local hud_apo is "Apo:  000s ".
	local hud_fuel is "Fuel: " + padding(0,3,0,false) + "s".
	local hud_azimuth is "Head:  " + padding(Round(launchazimuth,1),2,1,false) + "°".
	
	if runmode > -1 {
		if eta:apoapsis < eta:periapsis {
			if eta:apoapsis < 998 {
				set hud_apo to "Apo:  " + padding(round(eta:apoapsis),3,0,false) + "s ".
			} else {
				set hud_apo to "Apo:  " + padding(floor(eta:apoapsis/60),3,0,false) + "m ".
			}
		} else {
			if eta:periapsis < 998 {
				set hud_apo to "Peri: " + padding(round(eta:periapsis),3,0,false) + "s ".
			} else {
				set hud_apo to "Peri: " + padding(floor(eta:periapsis/60),3,0,false) + "m ".
			}
		}
		if mode = 0 {
			local f is RemainingBurn().
			set hud_fuel to "Fuel: " + padding(min(999,Round(f)),3,0,false) + "s".
			if f > 999 {
				set hud_fuel to "Fuel: 999s".
			}
		} else {
			set hud_fuel to "Fuel: " + padding(min(999,Round(remainingBurnSRB())),3,0,false) + "s".
		}
	}
	If staginginprogress or ImpendingStaging {
		set hud_staging to "Staging".
	} 
	if ship:apoapsis > body:atm:height and currentstagenum > 1 and (Time:seconds - stagefinishtime) >= 5 {
		if LEO = true {
			if threeBurn = true {
				set hud_var1 to "Circ: " + padding(Round(BurnDv(targetapoapsis)+ABS(circDVTargetPeri(targetapoapsis))),2,0,false) + "m/s ".
			} else {
				set hud_var1 to "Circ: " + padding(Round(ABS(circDVPeri)),2,0,false) + "m/s ".
			}
		} else {
			set hud_var1 to "Circ: " + padding(Round(CircDVApo()),2,0,false) + "m/s ".
		}
		set hud_var2 to "dV: " + padding(Round(StageDV(PayloadProtection)),2,0,false) + "m/s ".
		set hud_azimuth to "Inc: " + padding(Round(ship:orbit:inclination,5),1,5,false) + "°".
		set hud_pitch to "Ecc: " + padding(Round(ship:orbit:eccentricity,5),1,5,false).
	}

	local hud_printlist is list(hud_met,hud_pitch,hud_stage,hud_staging,hud_var1,hud_var2,hud_twr,hud_apo,hud_fuel,hud_azimuth).
	local hud_printlocx is list(00,01,29,23,15,29,15,41,41,01).
	local hud_printlocy is list(04,41,42,40,41,41,42,41,42,42).
	
	local printLine is 0.
	until printLine = hud_printlist:length {
        print hud_printlist[printLine] at (hud_printlocx[printLine],hud_printlocy[printLine]).
		set printLine to printLine+1.
	}
}

// GUI for unexpected issues during countdown
Function scrubGUI {
	Parameter scrubreason.
	Parameter runmode.
	
	local isDone is false.
	local proceedMode is 0.
	local gui is gui(290).
	local scrubInfo is "Unknown Scrub Reason".
	local scrubInfoCont is "".
	
	if scrubreason = "MFT Detect Issue" {
		set scrubInfo to "CLS has failed to gather necessary info about the vehicles fuel type, mass & capacity. CLS will not function as intended without this information. Continue at your own risk!".
	} else if scrubreason = "Subnominal Staging Detected" {
		set scrubInfo to "Something is wrong with vehicle staging order. Staging requirements are as follows:".
		set scrubInfoCont to "• Initial launch engines must be placed into stage 1.  • SRBs (if present) must be placed into stage 2.       • Launch clamps must be placed into stage 3 (if the rocket has SRBs) or stage 2 (if the rocket has no SRBs).".
	} else if  scrubreason = "AG10 Advisory" {
		set scrubInfo to "There is nothing in action group 10. AG10 is reserved for fairing jettison".
	} else if scrubreason = "Crew Abort Procedure Error" {
		set scrubInfo to "CLS has detected crew onboard, but nothing in the abort action group".
	} else if scrubreason = "Insufficient Power" {
		set scrubInfo to "Vehicle electric charge is below 40%".
	}.
	
	//Label 0
	local label0 is gui:addLabel("<size=18>Unplanned Hold</size>").
	set label0:style:align to "center".
	set label0:style:hstretch to true. // fill horizontally
	
	//Label 1
	local label1 is gui:addLabel(scrubreason).
	set label1:style:fontsize to 16.
	set label1:style:align to "center".
	set label1:style:hstretch to true. // fill horizontally
	
	//Buttons
	local buttonline1 is gui:addhlayout().
	local buttonline2 is gui:addhlayout().
	local continue is buttonline1:addbutton("Continue Countdown").
	set continue:style:width to 145.
	local recycle is buttonline1:addbutton("Recycle Countdown").
	set recycle:style:width to 145.
	local scrub is buttonline2:addbutton("Scrub Launch").
	set scrub:style:width to 145.
	local explain is buttonline2:addbutton("More info").
	set explain:style:width to 145.
	
	//Label2
	local label2 is gui:addLabel(scrubInfo).
	set label2:style:align to "center".
	set label2:style:hstretch to true.	
	label2:hide().
	
	//Label3
	local label3 is gui:addLabel(scrubInfoCont).
	//set label3:style:align to "center".
	set label3:style:hstretch to true.	
	label3:hide().
	
	set continue:onclick to {
		set isDone to true.
		set proceedMode to 1.
	}.
	set recycle:onclick to {
		set isDone to true.
		set proceedMode to 2.
	}.
	set scrub:onclick to {
		set isDone to true.
		set proceedMode to 3.
	}.
	set explain:onclick to {
		label2:show().
		if label3:text:length > 0 { label3:show(). }
	}.
	gui:show().
	wait until isDone.
	gui:hide().
	return proceedMode.
}.
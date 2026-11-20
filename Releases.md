# 0.0.4

First Gripora release of the EdgeTX scripts, for RC cars. Require MSP API 33.0 (the 0.0.2 firmware and later; the 0.0.4 firmware for the drive telemetry); WingFlight and Gripora 0.0.1 firmware are refused. The scripts install to /SCRIPTS/GR, so they can sit beside the WingFlight ones.
Add a Drive Aids page for the current PID profile: ABS, Traction (Off/Ramp, ramp time) and Launch (Off/Switch, start throttle, ramp time). Firmware that sends fewer settings shows the missing fields read-only.
Add a Drift page for the DRIFT mode: counter gain, allowed rate and counter limit of the current PID profile. Firmware without drift mode shows it read-only.
Add the drive status (DrvS) and wheel speed (Spd, km/h, negative in reverse) telemetry sensors for CRSF/ELRS and SmartPort (0.0.4 firmware). DrvS replaces the old Gov sensor; sensors 60 and 61 are now Mspd and M2sp, the motor 1 and motor 2 speeds.
Set the speed attenuation range to 10..300 km/h.

Label the yaw axis Steering and mark roll and pitch "(unused)"; the master gain group is now Driving Feel.
Show the car model types (Car, Custom) on the Mixer page, under Model type.
Remove the Tune Advisor page, and the Trainer, Angle Mode, Cross-Axis Relax, Snap Relax, Prop Hang and Attitude Hold settings from the profile pages.
Name the speed attenuation group Speed on Profile - Various, since the speed comes from motor RPM or GPS.
Change the adjustment teller to the car's functions: drop the heli, rescue, Angle/Trainer and governor ones, and add Battery Profile, Steering Master Gain and Steering Servo Trim (value only, no voice file yet).
Change the wording for a car: car instead of craft, and runs instead of flights on the Model page and the GR Stats widget.

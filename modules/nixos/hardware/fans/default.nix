{ lib
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;
  cfg = config.${namespace}.hardware.fans;
in
{
  options.${namespace}.hardware.fans = {
    enable = mkBoolOpt false "Enable fancontrol fan regulation";
  };
  config = mkIf cfg.enable {
    hardware.fancontrol = {
      enable = true;
      config = ''
        {
        "__VERSION__": "209",
        "Main": {
        "Controls": [
        {
        "Calibration": [
        	[ 0, 301 ],
        	[ 10, 302 ],
        	[ 20, 490 ],
        	[ 30, 720 ],
        	[ 40, 894 ],
        	[ 50, 1042 ],
        	[ 60, 1196 ],
        	[ 70, 1332 ],
        	[ 80, 1453 ],
        	[ 90, 1564 ],
        	[ 100, 1680 ]
        ],
        "Enable": true,
        "ForceApply": false,
        "Identifier": "/lpc/nct6687d/control/0",
        "IsHidden": false,
        "ManualControl": false,
        "ManualControlValue": 50,
        "MinimumPercent": 0,
        "Name": "CPU Fan",
        "NickName": "CPU Fan",
        "PairedFanSensor": {
        	"Identifier": "/lpc/nct6687d/fan/0",
        	"IsHidden": false,
        	"Name": "CPU Fan",
        	"NickName": "CPU Fan"
        },
        "SelectedCommandStepDown": 8.0,
        "SelectedCommandStepUp": 8.0,
        "SelectedFanCurve": {
        	"CommandMode": 0,
        	"IgnoreHysteresisAtLimits": true,
        	"IsHidden": false,
        	"MaximumCommand": 100,
        	"MaximumTemperature": 100.0,
        	"MinimumTemperature": 20.0,
        	"Name": "CPU Temp",
        	"OneWayHysteresis": false,
        	"Points": [
        		"20,0",
        		"40,20",
        		"60,45",
        		"70,66.7",
        		"80,100"
        	],
        	"SelectedHysteresis": 5.0,
        	"SelectedResponseTime": 3,
        	"SelectedTempSource": {
        		"Identifier": "/intelcpu/0/temperature/18",
        		"IsHidden": false,
        		"Name": "CPU Package",
        		"NickName": "CPU Package"
        	}
        },
        "SelectedOffset": 0,
        "SelectedStart": 0,
        "SelectedStop": 0
        },
        {
        "Calibration": [
        	[ 30, 0 ],
        	[ 40, 584 ],
        	[ 50, 707 ],
        	[ 60, 827 ],
        	[ 70, 935 ],
        	[ 80, 1049 ],
        	[ 90, 1144 ],
        	[ 100, 1253 ]
        ],
        "Enable": true,
        "ForceApply": false,
        "Identifier": "/lpc/nct6687d/control/2",
        "IsHidden": false,
        "ManualControl": false,
        "ManualControlValue": 50,
        "MinimumPercent": 0,
        "Name": "System Fan #1",
        "NickName": "Rear Exhaust - NF-S12B",
        "PairedFanSensor": {
        	"Identifier": "/lpc/nct6687d/fan/2",
        	"IsHidden": false,
        	"Name": "System Fan #1",
        	"NickName": "System Fan #1"
        },
        "SelectedCommandStepDown": 8.0,
        "SelectedCommandStepUp": 8.0,
        "SelectedFanCurve": {
        	"CommandMode": 0,
        	"IsHidden": false,
        	"Name": "Case Mix",
        	"SelectedFanCurves": [
        		{
        			"CommandMode": 0,
        			"IgnoreHysteresisAtLimits": true,
        			"IsHidden": false,
        			"MaximumCommand": 100,
        			"MaximumTemperature": 100.0,
        			"MinimumTemperature": 20.0,
        			"Name": "CPU Temp",
        			"OneWayHysteresis": false,
        			"Points": [
        				"20,0",
        				"40,20",
        				"60,45",
        				"70,66.7",
        				"80,100"
        			],
        			"SelectedHysteresis": 5.0,
        			"SelectedResponseTime": 3,
        			"SelectedTempSource": {
        				"Identifier": "/intelcpu/0/temperature/18",
        				"IsHidden": false,
        				"Name": "CPU Package",
        				"NickName": "CPU Package"
        			}
        		},
        		{
        			"CommandMode": 0,
        			"IgnoreHysteresisAtLimits": true,
        			"IsHidden": false,
        			"MaximumCommand": 100,
        			"MaximumTemperature": 90.0,
        			"MinimumTemperature": 20.0,
        			"Name": "GPU Temp",
        			"OneWayHysteresis": false,
        			"Points": [
        				"20,0",
        				"35,10",
        				"55,33.3",
        				"70,66.7",
        				"80,100"
        			],
        			"SelectedHysteresis": 5.0,
        			"SelectedResponseTime": 3,
        			"SelectedTempSource": {
        				"Identifier": "NVApiWrapper/0-AD102-A/sensor/0",
        				"IsHidden": false,
        				"Name": "GPU",
        				"NickName": "GPU"
        			}
        		}
        	],
        	"SelectedMixFunction": 0
        },
        "SelectedOffset": 0,
        "SelectedStart": 37,
        "SelectedStop": 35
        },
        {
        "Calibration": [
        	[ 30, 0 ],
        	[ 40, 665 ],
        	[ 50, 830 ],
        	[ 60, 979 ],
        	[ 70, 1107 ],
        	[ 80, 1249 ],
        	[ 90, 1370 ],
        	[ 100, 1511 ]
        ],
        "Enable": true,
        "ForceApply": false,
        "Identifier": "/lpc/nct6687d/control/7",
        "IsHidden": false,
        "ManualControl": false,
        "ManualControlValue": 50,
        "MinimumPercent": 0,
        "Name": "System Fan #6",
        "NickName": "Top Exhaust - NF-A14",
        "PairedFanSensor": {
        	"Identifier": "/lpc/nct6687d/fan/7",
        	"IsHidden": false,
        	"Name": "System Fan #6",
        	"NickName": "Top Exhaust - NF-A14"
        },
        "SelectedCommandStepDown": 8.0,
        "SelectedCommandStepUp": 8.0,
        "SelectedFanCurve": {
        	"CommandMode": 0,
        	"IsHidden": false,
        	"Name": "Case Mix",
        	"SelectedFanCurves": [
        		{
        			"CommandMode": 0,
        			"IgnoreHysteresisAtLimits": true,
        			"IsHidden": false,
        			"MaximumCommand": 100,
        			"MaximumTemperature": 100.0,
        			"MinimumTemperature": 20.0,
        			"Name": "CPU Temp",
        			"OneWayHysteresis": false,
        			"Points": [
        				"20,0",
        				"40,20",
        				"60,45",
        				"70,66.7",
        				"80,100"
        			],
        			"SelectedHysteresis": 5.0,
        			"SelectedResponseTime": 3,
        			"SelectedTempSource": {
        				"Identifier": "/intelcpu/0/temperature/18",
        				"IsHidden": false,
        				"Name": "CPU Package",
        				"NickName": "CPU Package"
        			}
        		},
        		{
        			"CommandMode": 0,
        			"IgnoreHysteresisAtLimits": true,
        			"IsHidden": false,
        			"MaximumCommand": 100,
        			"MaximumTemperature": 90.0,
        			"MinimumTemperature": 20.0,
        			"Name": "GPU Temp",
        			"OneWayHysteresis": false,
        			"Points": [
        				"20,0",
        				"35,10",
        				"55,33.3",
        				"70,66.7",
        				"80,100"
        			],
        			"SelectedHysteresis": 5.0,
        			"SelectedResponseTime": 3,
        			"SelectedTempSource": {
        				"Identifier": "NVApiWrapper/0-AD102-A/sensor/0",
        				"IsHidden": false,
        				"Name": "GPU",
        				"NickName": "GPU"
        			}
        		}
        	],
        	"SelectedMixFunction": 0
        },
        "SelectedOffset": 0,
        "SelectedStart": 37,
        "SelectedStop": 35
        },
        {
        "Calibration": [
        	[ 0, 0 ],
        	[ 30, 1088 ],
        	[ 40, 1312 ],
        	[ 50, 1532 ],
        	[ 60, 1766 ],
        	[ 70, 1994 ],
        	[ 80, 2220 ],
        	[ 90, 2453 ],
        	[ 100, 2669 ]
        ],
        "Enable": true,
        "ForceApply": false,
        "Identifier": "NVApiWrapper/0-AD102-A/control/0",
        "IsHidden": false,
        "ManualControl": false,
        "ManualControlValue": 50,
        "MinimumPercent": 0,
        "Name": "Control 1 - NVIDIA GeForce RTX 4090",
        "NickName": "Control 1 - NVIDIA GeForce RTX 4090",
        "PairedFanSensor": {
        	"Identifier": "NVApiWrapper/0-AD102-A/fan/0",
        	"IsHidden": false,
        	"Name": "Fan 1 - NVIDIA GeForce RTX 4090",
        	"NickName": "Fan 1 - NVIDIA GeForce RTX 4090"
        },
        "SelectedCommandStepDown": 8.0,
        "SelectedCommandStepUp": 8.0,
        "SelectedFanCurve": {
        	"CommandMode": 0,
        	"IgnoreHysteresisAtLimits": true,
        	"IsHidden": false,
        	"MaximumCommand": 100,
        	"MaximumTemperature": 90.0,
        	"MinimumTemperature": 20.0,
        	"Name": "GPU Temp",
        	"OneWayHysteresis": false,
        	"Points": [
        		"20,0",
        		"35,10",
        		"55,33.3",
        		"70,66.7",
        		"80,100"
        	],
        	"SelectedHysteresis": 5.0,
        	"SelectedResponseTime": 3,
        	"SelectedTempSource": {
        		"Identifier": "NVApiWrapper/0-AD102-A/sensor/0",
        		"IsHidden": false,
        		"Name": "GPU",
        		"NickName": "GPU"
        	}
        },
        "SelectedOffset": 0,
        "SelectedStart": 10,
        "SelectedStop": 10
        },
        {
        "Calibration": [
        	[ 0, 0 ],
        	[ 30, 1091 ],
        	[ 40, 1318 ],
        	[ 50, 1541 ],
        	[ 60, 1767 ],
        	[ 70, 1961 ],
        	[ 80, 2220 ],
        	[ 90, 2452 ],
        	[ 100, 2659 ]
        ],
        "Enable": true,
        "ForceApply": false,
        "Identifier": "NVApiWrapper/0-AD102-A/control/1",
        "IsHidden": false,
        "ManualControl": false,
        "ManualControlValue": 50,
        "MinimumPercent": 0,
        "Name": "Control 2 - NVIDIA GeForce RTX 4090",
        "NickName": "Control 2 - NVIDIA GeForce RTX 4090",
        "PairedFanSensor": {
        	"Identifier": "NVApiWrapper/0-AD102-A/fan/1",
        	"IsHidden": false,
        	"Name": "Fan 2 - NVIDIA GeForce RTX 4090",
        	"NickName": "Fan 2 - NVIDIA GeForce RTX 4090"
        },
        "SelectedCommandStepDown": 8.0,
        "SelectedCommandStepUp": 8.0,
        "SelectedFanCurve": {
        	"CommandMode": 0,
        	"IgnoreHysteresisAtLimits": true,
        	"IsHidden": false,
        	"MaximumCommand": 100,
        	"MaximumTemperature": 90.0,
        	"MinimumTemperature": 20.0,
        	"Name": "GPU Temp",
        	"OneWayHysteresis": false,
        	"Points": [
        		"20,0",
        		"35,10",
        		"55,33.3",
        		"70,66.7",
        		"80,100"
        	],
        	"SelectedHysteresis": 5.0,
        	"SelectedResponseTime": 3,
        	"SelectedTempSource": {
        		"Identifier": "NVApiWrapper/0-AD102-A/sensor/0",
        		"IsHidden": false,
        		"Name": "GPU",
        		"NickName": "GPU"
        	}
        },
        "SelectedOffset": 0,
        "SelectedStart": 10,
        "SelectedStop": 10
        },
        {
        "Calibration": [
        	[ 20, 0 ],
        	[ 30, 582 ],
        	[ 40, 763 ],
        	[ 50, 933 ],
        	[ 60, 1109 ],
        	[ 70, 1243 ],
        	[ 80, 1388 ],
        	[ 90, 1524 ],
        	[ 100, 1662 ]
        ],
        "Enable": true,
        "ForceApply": false,
        "Identifier": "/lpc/nct6687d/control/4",
        "IsHidden": false,
        "ManualControl": false,
        "ManualControlValue": 50,
        "MinimumPercent": 0,
        "Name": "System Fan #3",
        "NickName": "Front Intake - Arctic P14s",
        "PairedFanSensor": {
        	"Identifier": "/lpc/nct6687d/fan/4",
        	"IsHidden": false,
        	"Name": "System Fan #3",
        	"NickName": "Front Intake - Arctic P14"
        },
        "SelectedCommandStepDown": 8.0,
        "SelectedCommandStepUp": 8.0,
        "SelectedFanCurve": {
        	"CommandMode": 0,
        	"IsHidden": false,
        	"Name": "Case Mix",
        	"SelectedFanCurves": [
        		{
        			"CommandMode": 0,
        			"IgnoreHysteresisAtLimits": true,
        			"IsHidden": false,
        			"MaximumCommand": 100,
        			"MaximumTemperature": 100.0,
        			"MinimumTemperature": 20.0,
        			"Name": "CPU Temp",
        			"OneWayHysteresis": false,
        			"Points": [
        				"20,0",
        				"40,20",
        				"60,45",
        				"70,66.7",
        				"80,100"
        			],
        			"SelectedHysteresis": 5.0,
        			"SelectedResponseTime": 3,
        			"SelectedTempSource": {
        				"Identifier": "/intelcpu/0/temperature/18",
        				"IsHidden": false,
        				"Name": "CPU Package",
        				"NickName": "CPU Package"
        			}
        		},
        		{
        			"CommandMode": 0,
        			"IgnoreHysteresisAtLimits": true,
        			"IsHidden": false,
        			"MaximumCommand": 100,
        			"MaximumTemperature": 90.0,
        			"MinimumTemperature": 20.0,
        			"Name": "GPU Temp",
        			"OneWayHysteresis": false,
        			"Points": [
        				"20,0",
        				"35,10",
        				"55,33.3",
        				"70,66.7",
        				"80,100"
        			],
        			"SelectedHysteresis": 5.0,
        			"SelectedResponseTime": 3,
        			"SelectedTempSource": {
        				"Identifier": "NVApiWrapper/0-AD102-A/sensor/0",
        				"IsHidden": false,
        				"Name": "GPU",
        				"NickName": "GPU"
        			}
        		}
        	],
        	"SelectedMixFunction": 0
        },
        "SelectedOffset": 0,
        "SelectedStart": 22,
        "SelectedStop": 16
        },
        {
        "Calibration": [],
        "Enable": false,
        "ForceApply": false,
        "Identifier": "/lpc/nct6687d/control/1",
        "IsHidden": true,
        "ManualControl": false,
        "ManualControlValue": 50,
        "MinimumPercent": 0,
        "Name": "Pump Fan",
        "NickName": "Pump Fan",
        "PairedFanSensor": null,
        "SelectedCommandStepDown": 8.0,
        "SelectedCommandStepUp": 8.0,
        "SelectedFanCurve": null,
        "SelectedOffset": 0,
        "SelectedStart": 0,
        "SelectedStop": 0
        },
        {
        "Calibration": [],
        "Enable": false,
        "ForceApply": false,
        "Identifier": "/lpc/nct6687d/control/3",
        "IsHidden": true,
        "ManualControl": false,
        "ManualControlValue": 50,
        "MinimumPercent": 0,
        "Name": "System Fan #2",
        "NickName": "System Fan #2",
        "PairedFanSensor": null,
        "SelectedCommandStepDown": 8.0,
        "SelectedCommandStepUp": 8.0,
        "SelectedFanCurve": null,
        "SelectedOffset": 0,
        "SelectedStart": 0,
        "SelectedStop": 0
        },
        {
        "Calibration": [],
        "Enable": false,
        "ForceApply": false,
        "Identifier": "/lpc/nct6687d/control/5",
        "IsHidden": true,
        "ManualControl": false,
        "ManualControlValue": 50,
        "MinimumPercent": 0,
        "Name": "System Fan #4",
        "NickName": "System Fan #4",
        "PairedFanSensor": null,
        "SelectedCommandStepDown": 8.0,
        "SelectedCommandStepUp": 8.0,
        "SelectedFanCurve": null,
        "SelectedOffset": 0,
        "SelectedStart": 0,
        "SelectedStop": 0
        },
        {
        "Calibration": [],
        "Enable": false,
        "ForceApply": false,
        "Identifier": "/lpc/nct6687d/control/6",
        "IsHidden": true,
        "ManualControl": false,
        "ManualControlValue": 50,
        "MinimumPercent": 0,
        "Name": "System Fan #5",
        "NickName": "System Fan #5",
        "PairedFanSensor": null,
        "SelectedCommandStepDown": 8.0,
        "SelectedCommandStepUp": 8.0,
        "SelectedFanCurve": {
        	"CommandMode": 0,
        	"IsHidden": false,
        	"Name": "Case Mix",
        	"SelectedFanCurves": [
        		{
        			"CommandMode": 0,
        			"IgnoreHysteresisAtLimits": true,
        			"IsHidden": false,
        			"MaximumCommand": 100,
        			"MaximumTemperature": 100.0,
        			"MinimumTemperature": 20.0,
        			"Name": "CPU Temp",
        			"OneWayHysteresis": false,
        			"Points": [
        				"20,0",
        				"40,20",
        				"60,45",
        				"70,66.7",
        				"80,100"
        			],
        			"SelectedHysteresis": 5.0,
        			"SelectedResponseTime": 3,
        			"SelectedTempSource": {
        				"Identifier": "/intelcpu/0/temperature/18",
        				"IsHidden": false,
        				"Name": "CPU Package",
        				"NickName": "CPU Package"
        			}
        		},
        		{
        			"CommandMode": 0,
        			"IgnoreHysteresisAtLimits": true,
        			"IsHidden": false,
        			"MaximumCommand": 100,
        			"MaximumTemperature": 90.0,
        			"MinimumTemperature": 20.0,
        			"Name": "GPU Temp",
        			"OneWayHysteresis": false,
        			"Points": [
        				"20,0",
        				"35,10",
        				"55,33.3",
        				"70,66.7",
        				"80,100"
        			],
        			"SelectedHysteresis": 5.0,
        			"SelectedResponseTime": 3,
        			"SelectedTempSource": {
        				"Identifier": "NVApiWrapper/0-AD102-A/sensor/0",
        				"IsHidden": false,
        				"Name": "GPU",
        				"NickName": "GPU"
        			}
        		}
        	],
        	"SelectedMixFunction": 0
        },
        "SelectedOffset": 0,
        "SelectedStart": 0,
        "SelectedStop": 0
        }
        ],
        "CustomSensors": [],
        "Fahrenheit": false,
        "FanCurves": [
        {
        "CommandMode": 0,
        "IsHidden": false,
        "Name": "Case Mix",
        "SelectedFanCurves": [
        	{
        		"CommandMode": 0,
        		"IgnoreHysteresisAtLimits": true,
        		"IsHidden": false,
        		"MaximumCommand": 100,
        		"MaximumTemperature": 100.0,
        		"MinimumTemperature": 20.0,
        		"Name": "CPU Temp",
        		"OneWayHysteresis": false,
        		"Points": [
        			"20,0",
        			"40,20",
        			"60,45",
        			"70,66.7",
        			"80,100"
        		],
        		"SelectedHysteresis": 5.0,
        		"SelectedResponseTime": 3,
        		"SelectedTempSource": {
        			"Identifier": "/intelcpu/0/temperature/18",
        			"IsHidden": false,
        			"Name": "CPU Package",
        			"NickName": "CPU Package"
        		}
        	},
        	{
        		"CommandMode": 0,
        		"IgnoreHysteresisAtLimits": true,
        		"IsHidden": false,
        		"MaximumCommand": 100,
        		"MaximumTemperature": 90.0,
        		"MinimumTemperature": 20.0,
        		"Name": "GPU Temp",
        		"OneWayHysteresis": false,
        		"Points": [
        			"20,0",
        			"35,10",
        			"55,33.3",
        			"70,66.7",
        			"80,100"
        		],
        		"SelectedHysteresis": 5.0,
        		"SelectedResponseTime": 3,
        		"SelectedTempSource": {
        			"Identifier": "NVApiWrapper/0-AD102-A/sensor/0",
        			"IsHidden": false,
        			"Name": "GPU",
        			"NickName": "GPU"
        		}
        	}
        ],
        "SelectedMixFunction": 0
        },
        {
        "CommandMode": 0,
        "IgnoreHysteresisAtLimits": true,
        "IsHidden": false,
        "MaximumCommand": 100,
        "MaximumTemperature": 100.0,
        "MinimumTemperature": 20.0,
        "Name": "CPU Temp",
        "OneWayHysteresis": false,
        "Points": [
        	"20,0",
        	"40,20",
        	"60,45",
        	"70,66.7",
        	"80,100"
        ],
        "SelectedHysteresis": 5.0,
        "SelectedResponseTime": 3,
        "SelectedTempSource": {
        	"Identifier": "/intelcpu/0/temperature/18",
        	"IsHidden": false,
        	"Name": "CPU Package",
        	"NickName": "CPU Package"
        }
        },
        {
        "CommandMode": 0,
        "IgnoreHysteresisAtLimits": true,
        "IsHidden": false,
        "MaximumCommand": 100,
        "MaximumTemperature": 90.0,
        "MinimumTemperature": 20.0,
        "Name": "GPU Temp",
        "OneWayHysteresis": false,
        "Points": [
        	"20,0",
        	"35,10",
        	"55,33.3",
        	"70,66.7",
        	"80,100"
        ],
        "SelectedHysteresis": 5.0,
        "SelectedResponseTime": 3,
        "SelectedTempSource": {
        	"Identifier": "NVApiWrapper/0-AD102-A/sensor/0",
        	"IsHidden": false,
        	"Name": "GPU",
        	"NickName": "GPU"
        }
        }
        ],
        "FanSensors": [
        {
        "Identifier": "/lpc/nct6687d/fan/0",
        "IsHidden": false,
        "Name": "CPU Fan",
        "NickName": "CPU Fan"
        },
        {
        "Identifier": "/lpc/nct6687d/fan/1",
        "IsHidden": false,
        "Name": "Pump Fan",
        "NickName": "Pump Fan"
        },
        {
        "Identifier": "/lpc/nct6687d/fan/2",
        "IsHidden": false,
        "Name": "System Fan #1",
        "NickName": "System Fan #1"
        },
        {
        "Identifier": "/lpc/nct6687d/fan/3",
        "IsHidden": false,
        "Name": "System Fan #2",
        "NickName": "System Fan #2"
        },
        {
        "Identifier": "/lpc/nct6687d/fan/4",
        "IsHidden": false,
        "Name": "System Fan #3",
        "NickName": "Front Intake - Arctic P14"
        },
        {
        "Identifier": "/lpc/nct6687d/fan/5",
        "IsHidden": false,
        "Name": "System Fan #4",
        "NickName": "System Fan #4"
        },
        {
        "Identifier": "/lpc/nct6687d/fan/6",
        "IsHidden": false,
        "Name": "System Fan #5",
        "NickName": "Rear Exhaust - SB-12B"
        },
        {
        "Identifier": "/lpc/nct6687d/fan/7",
        "IsHidden": false,
        "Name": "System Fan #6",
        "NickName": "Top Exhaust - NF-A14"
        },
        {
        "Identifier": "NVApiWrapper/0-AD102-A/fan/0",
        "IsHidden": false,
        "Name": "Fan 1 - NVIDIA GeForce RTX 4090",
        "NickName": "Fan 1 - NVIDIA GeForce RTX 4090"
        },
        {
        "Identifier": "NVApiWrapper/0-AD102-A/fan/1",
        "IsHidden": false,
        "Name": "Fan 2 - NVIDIA GeForce RTX 4090",
        "NickName": "Fan 2 - NVIDIA GeForce RTX 4090"
        }
        ],
        "HideCalibration": false,
        "HideFanSpeedCards": true,
        "HorizontalUIOrientation": false,
        "PrimaryColor": "#FF607D8B",
        "SecondaryColor": "#FFAEEA00",
        "SelectedTheme": "Dark",
        "ShowHiddenCards": true,
        "SyncThemeWithWindows": false,
        "SyncTrayIconColorWithWindows": false,
        "TemperatureSensors": [],
        "TrayIconColor": "#FFFFFFFF",
        "TrayIcons": [
        {
        "Color": "#FF375CDD",
        "SensorId": {
        	"Identifier": "/intelcpu/0/temperature/18",
        	"IsHidden": false,
        	"Name": "CPU Package",
        	"NickName": "CPU Package"
        }
        },
        {
        "Color": "#FF20880A",
        "SensorId": {
        	"Identifier": "NVApiWrapper/0-AD102-A/sensor/0",
        	"IsHidden": false,
        	"Name": "GPU",
        	"NickName": "GPU"
        }
        }
        ]
        },
        "Sensors": {
        "AdlxWrapperSettings": {
        "Enabled": false
        },
        "DisabledPlugins": [],
        "DisableStorageSensors": true,
        "LibreHardwareMonitorSettings": {
        "Controller": false,
        "CPU": true,
        "EmbeddedEC": true,
        "GPU": true,
        "InpOut": false,
        "Memory": false,
        "Motherboard": true,
        "PSU": true,
        "Storage": false,
        "ZeroRPMOverride": true
        },
        "NvAPIWrapperSettings": {
        "Enabled": true,
        "ZeroRPMOverride": true
        },
        "SensorCount": 63
        }
        }
      '';
    };
  };
}

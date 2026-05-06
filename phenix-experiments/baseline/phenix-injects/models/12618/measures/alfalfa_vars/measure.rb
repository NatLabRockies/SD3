# *******************************************************************************
# OpenStudio(R), Copyright (c) 2008-2024, Alliance for Sustainable Energy, LLC.
# All rights reserved.
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# (1) Redistributions of source code must retain the above copyright notice,
# this list of conditions and the following disclaimer.
#
# (2) Redistributions in binary form must reproduce the above copyright notice,
# this list of conditions and the following disclaimer in the documentation
# and/or other materials provided with the distribution.
#
# (3) Neither the name of the copyright holder nor the names of any contributors
# may be used to endorse or promote products derived from this software without
# specific prior written permission from the respective party.
#
# (4) Other than as required in clauses (1) and (2), distributions in any form
# of modifications or other derivative works may not use the "OpenStudio"
# trademark, "OS", "os", or any other confusingly similar designation without
# specific prior written permission from Alliance for Sustainable Energy, LLC.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDER(S) AND ANY CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
# THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER(S), ANY CONTRIBUTORS, THE
# UNITED STATES GOVERNMENT, OR THE UNITED STATES DEPARTMENT OF ENERGY, NOR ANY OF
# THEIR EMPLOYEES, BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
# EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT
# OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
# STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
# OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
# *******************************************************************************

# start the measure
class AlfalfaVariables < OpenStudio::Measure::ModelMeasure

  # human readable name
  def name
    return 'Alfalfa Variables'
  end

  # human readable description
  def description
    return 'Add custom variables for Alfalfa'
  end

  # human readable description of modeling approach
  def modeler_description
    return 'Add EMS global variables required by Alfalfa'
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    # is the add battery measure a part of the workflow
    add_batt = OpenStudio::Measure::OSArgument.makeBoolArgument(
      'add_batt',
      true
    )
    add_batt.setDisplayName('Add Battery?')
    add_batt.setDescription('Add battery measure is a part of the workflow')
    add_batt.setUnits('')
    add_batt.setDefaultValue(false)
    args << add_batt

    return args
  end

  def create_input(model, name, freq)

    # create an alfalfa input
    glob = OpenStudio::Model::EnergyManagementSystemGlobalVariable.new(
      model,
      name
    )
    glob.setExportToBCVTB(true)

    # the global variable's value must be sent to output an variable
    glob_ems_out = OpenStudio::Model::EnergyManagementSystemOutputVariable.new(
      model,
      glob
    )
    glob_ems_out.setName(name + '_EMS_Value')
    glob_ems_out.setUpdateFrequency('SystemTimestep')

    # request the custom EMS output variable created in the previous step
    glob_out = OpenStudio::Model::OutputVariable.new(
      glob_ems_out.nameString(),
      model
    )
    glob_out.setName(name + '_Value')
    glob_out.setReportingFrequency(freq)
    glob_out.setKeyValue('EMS')
    glob_out.setExportToBCVTB(true)

    # repeat the previous steps for an "enable" input
    glob_enable = OpenStudio::Model::EnergyManagementSystemGlobalVariable.new(
      model,
      name + '_Enable'
    )
    glob_enable.setExportToBCVTB(true)
    glob_enable_ems_out = OpenStudio::Model::EnergyManagementSystemOutputVariable.new(
      model,
      glob_enable
    )
    glob_enable_ems_out.setName(name + '_Enable_EMS_Value')
    glob_enable_ems_out.setUpdateFrequency('SystemTimestep')
    glob_enable_out = OpenStudio::Model::OutputVariable.new(
      glob_enable_ems_out.nameString(),
      model
    )
    glob_enable_out.setName(name + '_Enable_Value')
    glob_enable_out.setReportingFrequency(freq)
    glob_enable_out.setKeyValue('EMS')
    glob_enable_out.setExportToBCVTB(true)
  end

  def create_output(model, var, key, name, freq)
    new_var = OpenStudio::Model::OutputVariable.new(
      var,
      model
    )
    new_var.setName(name)
    new_var.setReportingFrequency(freq)
    new_var.setKeyValue(key)
    new_var.setExportToBCVTB(true)
  end

  # define what happens when the measure is run
  def run(model, runner, usr_args)

    # call the parent class method
    super(model, runner, usr_args)

    # use the built-in error checking
    return false unless runner.validateUserArguments(
      arguments(model),
      usr_args
    )

    # assign the user inputs to variables
    add_batt = runner.getBoolArgumentValue(
      'add_batt',
      usr_args
    )

    # alfalfa inputs
    create_input(model, 'setChargeDischargeRate', 'Timestep')
    create_input(model, 'Voltage', 'Timestep') # currently a "dummy" input
    create_input(model, 'setPF', 'Timestep')  # currently a "dummy" input

    # alfalfa output for ASHRAE 55 time not comfortable
    create_output(
      model,
      'Facility Thermal Comfort ASHRAE 55 Simple Model Summer or Winter Clothes Not Comfortable Time',
      'Facility',
      'ASHRAE 55 Time Not Comfortable',
      'Timestep'
    )

    # # alfalfa output for summer ASHRAE 55 time not comfortable
    # create_output(
    #   model,
    #   'Facility Thermal Comfort ASHRAE 55 Simple Model Summer Clothes Not Comfortable',
    #   'Facility',
    #   'ASHRAE 55 Time Not Comfortable Summer',
    #   'Timestep'
    # )

    # # alfalfa output for winter ASHRAE 55 time not comfortable
    # create_output(
    #   model,
    #   'Facility Thermal Comfort ASHRAE 55 Simple Model Winter Clothes Not Comfortable',
    #   'Facility',
    #   'ASHRAE 55 Time Not Comfortable Winter',
    #   'Timestep'
    # )


    # alfalfa output for Facility Heating Setpoint Not Met While Occupied Time
    create_output(
      model,
      'Facility Heating Setpoint Not Met While Occupied Time',
      'Facility',
      'Facility Heating Setpoint Not Met While Occupied Time',
      'Timestep'
    )

    # alfalfa output for Facility Cooling Setpoint Not Met While Occupied Time,hourly
    create_output(
      model,
      'Facility Cooling Setpoint Not Met While Occupied Time',
      'Facility',
      'Facility Cooling Setpoint Not Met While Occupied Time',
      'Timestep'
    )


    # create_output(
    #   model,
    #   'Facility Total Building Electricity Demand Rate',
    #   'Facility',
    #   'Facility Total Building Electricity Demand Rate',
    #   'Timestep'
    # )

    # create_output(
    #   model,
    #   'Facility Total HVAC Electricity Demand Rate',
    #   'Facility',
    #   'Facility Total HVAC Electricity Demand Rate',
    #   'Timestep'
    # )

    # create_output(
    #   model,
    #   'Facility Total Electricity Demand Rate',
    #   'Facility',
    #   'Facility Total Electricity Demand Rate',
    #   'Timestep'
    # )

    # # alfalfa output for Facility Any Zone Ventilation Below Target Voz Time
    # create_output(
    #   model,
    #   'Facility Any Zone Ventilation Below Target Voz Time',
    #   'Facility',
    #   'Facility Any Zone Ventilation Below Target Voz Time',
    #   'Timestep'
    # )

    # # alfalfa output for Facility Any Zone Ventilation Above Target Voz Time
    # create_output(
    #   model,
    #   'Facility Any Zone Ventilation Above Target Voz Time',
    #   'Facility',
    #   'Facility Any Zone Ventilation Above Target Voz Time',
    #   'Timestep'
    # )

    model.getThermalZones.each do |zone|

      # alfalfa output for Heat Index
      create_output(
        model, 
        'Zone Heat Index',
        zone.name.get,
        'Zone Heat Index',
        'Timestep'
      )

      # alfalfa output for Humidity Index
      create_output(
        model, 
        'Zone Humidity Index',
        zone.name.get,
        'Zone Humidity Index',
        'Timestep'
      )

      # alfalfa output for Zone mean air temperature
      create_output(
        model, 
        'Zone Mean Air Temperature',
        zone.name.get,
        'Zone Mean Air Temperature',
        'Timestep'
      )

      # alfalfa output for Zone operatice temperature
      create_output(
        model, 
        'Zone Operative Temperature',
        zone.name.get,
        'Zone Operative Temperature',
        'Timestep'
      )

    end

        
    def sanitize_ems_name(name)
      name.gsub(/[^A-Za-z0-9_]/, '')[0..59] # Remove special chars, limit to 60 chars
    end
    # Add output variables for Facility Total Purchased Electricity Energy, Facility Total Surplus Electricity Energy,
    # Facility Net Purchased Electricity Energy, Facility Total Produced Electricity Energy in Wh and J.
    # These are added regardless of whether a battery is present or not.
    variables = [
      'Facility Total Purchased Electricity Energy',
      'Facility Total Surplus Electricity Energy',
      'Facility Net Purchased Electricity Energy',
      'Facility Total Produced Electricity Energy'
    ]
    variables.each do |var_name|
      glob_name = sanitize_ems_name(var_name)
      #  Output variable
      out_var = OpenStudio::Model::OutputVariable.new(var_name, model)
      out_var.setName(glob_name)
      out_var.setReportingFrequency('Timestep')
      #  EMS Sensor
      sensor_name = glob_name + "_Sensor"
      sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, var_name)
      sensor.setName(sensor_name)
      sensor.setKeyName("Whole Building")
      #  EMS Global Variable (in Wh)
      glob_name_wh = glob_name + "_Wh"
      glob = OpenStudio::Model::EnergyManagementSystemGlobalVariable.new(model, glob_name_wh)
      #  EMS Global Variable (in J)
      glob_name_j = glob_name + "_J"
      glob_j = OpenStudio::Model::EnergyManagementSystemGlobalVariable.new(model, glob_name_j)
      #  EMS Program (J to Wh conversion)
      prog_name = "Convert_" + glob_name
      ems_program = OpenStudio::Model::EnergyManagementSystemProgram.new(model)
      ems_program.setName(prog_name)
      ems_program.addLine("SET #{glob_name_j} = #{sensor_name}")
      ems_program.addLine("SET #{glob_name_wh} = #{sensor_name} / 3600")
      #  Program Calling Manager
      pcm_name = "Run_" + glob_name
      pcm = OpenStudio::Model::EnergyManagementSystemProgramCallingManager.new(model)
      pcm.setName(pcm_name)
      pcm.setCallingPoint("EndOfSystemTimestepBeforeHVACReporting")
      pcm.addProgram(ems_program)
      #  EMS OutputVariable for Wh value
      ems_output = OpenStudio::Model::EnergyManagementSystemOutputVariable.new(model, glob)
      ems_output.setName("EMS_#{glob_name}_Wh")
      ems_output.setUpdateFrequency("Timestep")
      #  OutputVariable Wh(Alfalfa-readable)
      out_var_wh = OpenStudio::Model::OutputVariable.new("EMS_#{glob_name}_Wh", model)
      out_var_wh.setName("#{glob_name}_Wh")
      out_var_wh.setReportingFrequency("Timestep")
      out_var_wh.setKeyValue("EMS")
      out_var_wh.setExportToBCVTB(true)
      #  EMS OutputVariable for J value
      ems_output = OpenStudio::Model::EnergyManagementSystemOutputVariable.new(model, glob_j)
      ems_output.setName("EMS_#{glob_name}_J")
      ems_output.setUpdateFrequency("Timestep")
      #  OutputVariable J(Alfalfa-readable)
      out_var_j = OpenStudio::Model::OutputVariable.new("EMS_#{glob_name}_J", model)
      out_var_j.setName("#{glob_name}_J")
      out_var_j.setReportingFrequency("Timestep")
      out_var_j.setKeyValue("EMS")
      out_var_j.setExportToBCVTB(true)
    end


    # Add output meters for building, facility, net, purchased, and surplus sold electricity in Wh. 
    # These are added regardless of whether a battery is present or not.

    meters = [
      'Electricity:Building',
      'Electricity:Facility',
      'ElectricityNet:Facility',
      'ElectricityPurchased:Facility',
      'ElectricitySurplusSold:Facility'
    ]

    meters.each do |meter_name|
      #  Output:Meter
      out_meter = OpenStudio::Model::OutputMeter.new(model)
      out_meter.setName(meter_name)
      out_meter.setReportingFrequency('Timestep')

      #  EMS Sensor
      sensor_name = meter_name.gsub(':', '_') + "_Sensor"
      sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, meter_name)
      sensor.setName(sensor_name)

      #  EMS Global Variable (in Wh)
      glob_name = meter_name.gsub(':', '_') + "_Wh"
      glob = OpenStudio::Model::EnergyManagementSystemGlobalVariable.new(model, glob_name)

      #  EMS Program (J to Wh conversion)
      prog_name = "Convert_" + meter_name.gsub(':', '_')
      ems_program = OpenStudio::Model::EnergyManagementSystemProgram.new(model)
      ems_program.setName(prog_name)
      ems_program.addLine("SET #{glob_name} = #{sensor_name} / 3600")

      #  Program Calling Manager
      pcm_name = "Run_" + meter_name.gsub(':', '_')
      pcm = OpenStudio::Model::EnergyManagementSystemProgramCallingManager.new(model)
      pcm.setName(pcm_name)
      pcm.setCallingPoint("EndOfSystemTimestepBeforeHVACReporting")
      pcm.addProgram(ems_program)

      #  EMS OutputVariable
      ems_output = OpenStudio::Model::EnergyManagementSystemOutputVariable.new(model, glob)
      ems_output.setName("EMS_#{glob_name}")
      ems_output.setUpdateFrequency("Timestep")

      #  OutputVariable (Alfalfa-readable)
      out_var = OpenStudio::Model::OutputVariable.new("EMS_#{glob_name}", model)
      out_var.setName("#{glob_name}")
      out_var.setReportingFrequency("Timestep")
      out_var.setKeyValue("EMS")
      out_var.setExportToBCVTB(true)

    end

    if add_batt
      # battery variables
      bv = [
        ['Electric Storage Operating Mode Index', 'operationalModeStatus [-]'],
        ['Electric Storage Charge Fraction', 'batteryStorageChargeFraction [%]'],
        ['Electric Storage Charge Power', 'batteryStorageChargePower [W]'],
        ['Electric Storage Discharge Power', 'batteryStorageDischargePower [W]'],
        ['Electric Storage Total Current', 'batteryCurrent [A]'],
        ['Electric Storage Total Voltage', 'batteryVoltage [V]']
      ]

      # alfalfa output - battery variables
      bv.each do |v|
        create_output(
          model,
          v[0],
          'Battery',
          v[1],
          'Timestep'
        )
      end

      # energy management system variables
      ev = [
        ['Battery Minimum State of Charge', 'setPercMinUsCap [%]'],
        ['Battery Nameplate Charge Rate', 'rtgMaxChargeRateW [W]'],
        ['Battery Nameplate Discharge Rate', 'rtgMaxDischargeRateW [W]'],
        ['Battery Nameplate Capacity', 'rtgMaxWh [Wh]'],
        ['Battery Discharge Energy', 'activeDischargeEnergyStatus [Wh]'],
        ['Battery Charge Energy', 'activeChargeEnergyStatus [Wh]'],
        ['Battery Net Energy', 'activeEnergyStatus [Wh]'],
        ['Battery Charge State', 'stateOfChargeStatus [Wh]'],
        ['Facility Electricity Produced', 'Fac Elec Prod [Wh]']
      ]

      # alfalfa output - energy management system variables
      ev.each do |v|
        create_output(
          model,
          v[0],
          'EMS',
          v[1],
          'Timestep'
        )
      end

      # python plugin variables
      pv = [
        ['Heating Submeter', 'HeatingSubmtr [Wh]'],
        ['Cooling Submeter', 'CoolingSubmtr [Wh]'],
        ['Interior Lighting Submeter', 'InteriorLightSubmtr [Wh]'],
        ['Exterior Lighting Submeter', 'ExteriorLightSubmtr [Wh]'],
        ['Interior Equipment Submeter', 'InteriorEquipSubmtr [Wh]'],
        ['Exterior Equipment Submeter', 'ExteriorEquipSubmtr [Wh]'],
        ['Fans Submeter', 'FansSubmtr [Wh]'],
        ['Pumps Submeter', 'PumpsSubmtr [Wh]'],
        ['Heat Rejection Submeter', 'HeatRejectionSubmtr [Wh]'],
        ['Humidification Submeter', 'HumidificationSubmtr [Wh]'],
        ['Heat Recovery Submeter', 'HeatRecoverySubmtr [Wh]'],
        ['Service Water Heating Submeter', 'SWHSubmtr [Wh]'],
        ['Refrigeration Submeter', 'RefrigerationSubmtr [Wh]'],
        ['Generators Submeter', 'GeneratorsSubmtr [Wh]'],
        ['Total Submeter', 'activePowerStatusBuilding [W]'],
        ['Building Reactive Power', 'reactivePowerStatusBuilding [VAR]'],
        ['Battery Power Factor', 'setPF [-]'],
        ['Battery Active Power', 'activePowerStatusBattery [W]'],
        ['Battery Reactive Power', 'reactivePowerStatusBattery [VAR]'],
        ['Total Active Power', 'activePowerStatusTotal [W]'],
        ['Total Reactive Power', 'reactivePowerStatusTotal [VAR]']
      ]

    else

      # python plugin variables
      pv = [
        ['Heating Submeter', 'HeatingSubmtr [Wh]'],
        ['Cooling Submeter', 'CoolingSubmtr [Wh]'],
        ['Interior Lighting Submeter', 'InteriorLightSubmtr [Wh]'],
        ['Exterior Lighting Submeter', 'ExteriorLightSubmtr [Wh]'],
        ['Interior Equipment Submeter', 'InteriorEquipSubmtr [Wh]'],
        ['Exterior Equipment Submeter', 'ExteriorEquipSubmtr [Wh]'],
        ['Fans Submeter', 'FansSubmtr [Wh]'],
        ['Pumps Submeter', 'PumpsSubmtr [Wh]'],
        ['Heat Rejection Submeter', 'HeatRejectionSubmtr [Wh]'],
        ['Humidification Submeter', 'HumidificationSubmtr [Wh]'],
        ['Heat Recovery Submeter', 'HeatRecoverySubmtr [Wh]'],
        ['Service Water Heating Submeter', 'SWHSubmtr [Wh]'],
        ['Refrigeration Submeter', 'RefrigerationSubmtr [Wh]'],
        ['Generators Submeter', 'GeneratorsSubmtr [Wh]'],
        ['Total Submeter', 'activePowerStatusBuilding [W]'],
        ['Building Reactive Power', 'reactivePowerStatusBuilding [VAR]'],
        ['Battery Power Factor', 'setPF [-]'],
        ['Battery Active Power', 'activePowerStatusBattery [W]'],
        ['Battery Reactive Power', 'reactivePowerStatusBattery [VAR]'],
        ['Total Active Power', 'activePowerStatusTotal [W]'],
        ['Total Reactive Power', 'reactivePowerStatusTotal [VAR]'],
        ['Electric Storage Operating Mode Index', 'operationalModeStatus [-]'],
        ['Electric Storage Charge Fraction', 'batteryStorageChargeFraction [%]'],
        ['Electric Storage Charge Power', 'batteryStorageChargePower [W]'],
        ['Electric Storage Discharge Power', 'batteryStorageDischargePower [W]'],
        ['Electric Storage Total Current', 'Current [A]'],
        ['Electric Storage Total Voltage', 'Voltage [V]'],
        ['Battery Minimum State of Charge', 'setPercMinUsCap [%]'],
        ['Battery Nameplate Charge Rate', 'rtgMaxChargeRateW [W]'],
        ['Battery Nameplate Discharge Rate', 'rtgMaxDischargeRateW [W]'],
        ['Battery Nameplate Capacity', 'rtgMaxWh [Wh]'],
        ['Battery Discharge Energy', 'activeDischargeEnergyStatus [Wh]'],
        ['Battery Charge Energy', 'activeChargeEnergyStatus [Wh]'],
        ['Battery Net Energy', 'activeEnergyStatus [Wh]'],
        ['Battery Charge State', 'stateOfChargeStatus [Wh]'],
        ['Facility Electricity Produced', 'Fac Elec Prod [Wh]']
      ]

    end

    # alfalfa output - python plugin variables
    pv.each do |v|
      create_output(
        model,
        'PythonPlugin:OutputVariable',
        v[0],
        v[1],
        'Timestep'
      )
    end

    # output tables as HTML and CSV
    octs = model.getOutputControlTableStyle
    octs.setColumnSeparator('CommaAndHTML')

    # add output control files
    ocf = model.getOutputControlFiles
    ocf.setOutputCSV(true)
    ocf.setOutputMTR(false)
    ocf.setOutputESO(false)
    ocf.setOutputEIO(false)
    ocf.setOutputTabular(true)
    ocf.setOutputSQLite(false)
    ocf.setOutputJSON(false)
    ocf.setOutputAUDIT(false)
    ocf.setOutputZoneSizing(false)
    ocf.setOutputSystemSizing(false)
    ocf.setOutputDXF(false)
    ocf.setOutputBND(false)
    ocf.setOutputRDD(true)
    ocf.setOutputMDD(true)
    ocf.setOutputMTD(false)
    ocf.setOutputSHD(false)
    ocf.setOutputDFS(false)
    ocf.setOutputGLHE(false)
    ocf.setOutputDelightIn(false)
    ocf.setOutputDelightELdmp(false)
    ocf.setOutputDelightDFdmp(false)
    ocf.setOutputEDD(false)
    ocf.setOutputDBG(false)
    ocf.setOutputPerfLog(false)
    ocf.setOutputSLN(false)
    ocf.setOutputSCI(false)
    ocf.setOutputWRL(false)
    ocf.setOutputScreen(false)
    ocf.setOutputExtShd(false)
    ocf.setOutputTarcog(false)

    return true
  end
end

# register the measure to be used by the application
AlfalfaVariables.new.registerWithApplication

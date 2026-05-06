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
class AddBattery < OpenStudio::Measure::EnergyPlusMeasure

  # define the name that a user will see
  def name
    return 'Add Battery'
  end

  # human readable description
  def description
    return 'Add Li-ion battery'
  end

  # human readable description of modeling approach
  def modeler_description
    return 'Add Li-ion NMC battery model from the System Advisor Model (SAM)'
  end

  # define the arguments that the user will input
  def arguments(ws)
    args = OpenStudio::Measure::OSArgumentVector.new

    # battery kwh
    size_kwh = OpenStudio::Measure::OSArgument.makeDoubleArgument(
      'size_kwh',
      true
    )
    size_kwh.setDisplayName('Battery kWh')
    size_kwh.setDescription('Battery kWh')
    size_kwh.setUnits('kWh')
    size_kwh.setDefaultValue(14)
    args << size_kwh

    # battery kw
    size_kw = OpenStudio::Measure::OSArgument.makeDoubleArgument(
      'size_kw',
      true
    )
    size_kw.setDisplayName('Battery kW')
    size_kw.setDescription('Battery kW')
    size_kw.setUnits('kW')
    size_kw.setDefaultValue(5)
    args << size_kw

    # battery voltage
    batt_v = OpenStudio::Measure::OSArgument.makeDoubleArgument(
      'batt_v',
      true
    )
    batt_v.setDisplayName('Battery Voltage')
    batt_v.setDescription('Battery Voltage')
    batt_v.setUnits('V')
    batt_v.setDefaultValue(50)
    args << batt_v

    # battery initial soc
    soc_init_pct = OpenStudio::Measure::OSArgument.makeDoubleArgument(
      'soc_init_pct',
      true
    )
    soc_init_pct.setDisplayName('Battery Initial SOC')
    soc_init_pct.setDescription('Battery Initial SOC')
    soc_init_pct.setUnits('%')
    soc_init_pct.setDefaultValue(100)
    args << soc_init_pct

    # battery max soc
    soc_max_pct = OpenStudio::Measure::OSArgument.makeDoubleArgument(
      'soc_max_pct',
      true
    )
    soc_max_pct.setDisplayName('Battery Max SOC')
    soc_max_pct.setDescription('Battery Max SOC')
    soc_max_pct.setUnits('%')
    soc_max_pct.setDefaultValue(100)
    args << soc_max_pct

    # battery initial soc
    soc_min_pct = OpenStudio::Measure::OSArgument.makeDoubleArgument(
      'soc_min_pct',
      true
    )
    soc_min_pct.setDisplayName('Battery Min SOC')
    soc_min_pct.setDescription('Battery Min SOC')
    soc_min_pct.setUnits('%')
    soc_min_pct.setDefaultValue(3.571)
    args << soc_min_pct

    # battery mass
    batt_mass = OpenStudio::Measure::OSArgument.makeDoubleArgument(
      'batt_mass',
      true
    )
    batt_mass.setDisplayName('Battery Mass')
    batt_mass.setDescription('Battery Mass')
    batt_mass.setUnits('kg')
    batt_mass.setDefaultValue(114)
    args << batt_mass

    # battery surface area
    batt_surf_area = OpenStudio::Measure::OSArgument.makeDoubleArgument(
      'batt_surf_area',
      true
    )
    batt_surf_area.setDisplayName('Battery Surface Area')
    batt_surf_area.setDescription('Battery Surface Area')
    batt_surf_area.setUnits('m2')
    batt_surf_area.setDefaultValue(2.297)
    args << batt_surf_area

    return args
  end

  # define what happens when the measure is run
  def run(ws, runner, usr_args)

    # call the parent class method
    super(ws, runner, usr_args)

    # use the built-in error checking
    return false unless runner.validateUserArguments(
      arguments(ws),
      usr_args
    )

    # assign the user inputs to variables
    size_kwh = runner.getDoubleArgumentValue(
      'size_kwh',
      usr_args
    )
    size_kw = runner.getDoubleArgumentValue(
      'size_kw',
      usr_args
    )
    batt_v = runner.getDoubleArgumentValue(
      'batt_v',
      usr_args
    )
    soc_init_pct = runner.getDoubleArgumentValue(
      'soc_init_pct',
      usr_args
    )
    soc_max_pct = runner.getDoubleArgumentValue(
      'soc_max_pct',
      usr_args
    )
    soc_min_pct = runner.getDoubleArgumentValue(
      'soc_min_pct',
      usr_args
    )
    batt_mass = runner.getDoubleArgumentValue(
      'batt_mass',
      usr_args
    )
    batt_surf_area = runner.getDoubleArgumentValue(
      'batt_surf_area',
      usr_args
    )

    # convert kWh to cells in serial/parallel
    cell_v = 3.6
    cell_ah = 5
    cells_in_series = (batt_v / cell_v).round(0)
    cells_in_parallel = (((size_kwh * 1000) / batt_v) / cell_ah).round(0)

    # add always on schedule type limits
    ot = 'ScheduleTypeLimits'.to_IddObjectType
    no = OpenStudio::IdfObject.new(ot)
    no.setString(0, 'Battery Binary Sch Type Limits')
    no.setInt(1, 0)
    no.setInt(2, 1)
    no.setString(3, 'Discrete')
    ws.addObject(no)

    # add always on schedule
    ot = 'Schedule_Constant'.to_IddObjectType
    no = OpenStudio::IdfObject.new(ot)
    no.setString(0, 'Battery Always On Sch')
    no.setString(1, 'Battery Binary Sch Type Limits')
    no.setInt(2, 1)
    ws.addObject(no)

    # add battery charge/discharge schedule type limits
    ot = 'ScheduleTypeLimits'.to_IddObjectType
    no = OpenStudio::IdfObject.new(ot)
    no.setString(0, 'Battery Fraction Sch Type Limits')
    no.setInt(1, -2)
    no.setInt(2, 2)
    no.setString(3, 'Continuous')
    ws.addObject(no)

    # add battery charge schedule
    ot = 'Schedule_Constant'.to_IddObjectType
    no = OpenStudio::IdfObject.new(ot)
    no.setString(0, 'Battery Charge Sch')
    no.setString(1, 'Battery Fraction Sch Type Limits')
    no.setInt(2, 0)
    ws.addObject(no)

    # add battery discharge schedule
    ot = 'Schedule_Constant'.to_IddObjectType
    no = OpenStudio::IdfObject.new(ot)
    no.setString(0, 'Battery Discharge Sch')
    no.setString(1, 'Battery Fraction Sch Type Limits')
    no.setInt(2, 0)
    ws.addObject(no)

    # add battery
    ot = 'ElectricLoadCenter_Storage_LiIonNMCBattery'.to_IddObjectType
    no = OpenStudio::IdfObject.new(ot)
    no.setString(0, 'Battery')
    no.setString(1, 'Battery Always On Sch')
    no.setString(2, '') # todo: add to zone in the model
    no.setDouble(3, 0)
    no.setString(4, 'None')
    no.setDouble(5, cells_in_series)
    no.setDouble(6, cells_in_parallel)
    no.setDouble(7, soc_init_pct / 100)
    no.setString(8, '')
    no.setDouble(9, batt_mass)
    no.setDouble(10, batt_surf_area)
    no.setString(11, '')
    no.setString(12, '')
    no.setString(13, '')
    no.setString(14, '')
    no.setString(15, '')
    no.setString(16, '')
    no.setString(17, '')
    no.setString(18, '')
    no.setString(19, '')
    no.setString(20, '')
    no.setString(21, '')
    ws.addObject(no)

    # add converter
    ot = 'ElectricLoadCenter_Storage_Converter'.to_IddObjectType
    no = OpenStudio::IdfObject.new(ot)
    no.setString(0, 'Battery Charger')
    no.setString(1, 'Battery Always On Sch')
    no.setString(2, 'SimpleFixed')
    no.setDouble(3, 1)
    no.setString(4, '')
    no.setString(5, '')
    no.setString(6, '')
    no.setString(7, '') # todo: add to zone in the model
    no.setString(8, '')
    ws.addObject(no)

    # add inverter curve
    ot = 'Curve_Linear'.to_IddObjectType
    no = OpenStudio::IdfObject.new(ot)
    no.setString(0, 'Battery Inverter Curve')
    no.setDouble(1, 1)
    no.setDouble(2, 0)
    no.setDouble(3, 0)
    no.setDouble(4, size_kw * 1000 * 1.25)
    ws.addObject(no)

    # add inverter
    ot = 'ElectricLoadCenter_Inverter_FunctionOfPower'.to_IddObjectType
    no = OpenStudio::IdfObject.new(ot)
    no.setString(0, 'Battery Inverter')
    no.setString(1, 'Battery Always On Sch')
    no.setString(2, '') # todo: add to zone in the model
    no.setDouble(3, 0.3)
    no.setString(4, 'Battery Inverter Curve')
    no.setDouble(5, size_kw * 1000)
    no.setDouble(6, 0)
    no.setDouble(7, 1)
    no.setDouble(8, size_kw * 1000 * 0)
    no.setDouble(9, size_kw * 1000 * 2)
    no.setDouble(10, 0)
    ws.addObject(no)

    # add distribution
    ot = 'ElectricLoadCenter_Distribution'.to_IddObjectType
    no = OpenStudio::IdfObject.new(ot)
    no.setString(0, 'Battery Load Center')
    no.setString(1, '')
    no.setString(2, '')
    no.setString(3, '')
    no.setString(4, '')
    no.setString(5, '')
    no.setString(6, 'DirectCurrentWithInverterDCStorage')
    no.setString(7, 'Battery Inverter')
    no.setString(8, 'Battery')
    no.setString(9, '')
    no.setString(10, 'TrackChargeDischargeSchedules')
    no.setString(11, '')
    no.setString(12, 'Battery Charger')
    no.setDouble(13, soc_max_pct / 100)
    no.setDouble(14, soc_min_pct / 100)
    no.setDouble(15, size_kw * 1000)
    no.setString(16, 'Battery Charge Sch')
    no.setDouble(17, size_kw * 1000)
    no.setString(18, 'Battery Discharge Sch')
    no.setString(19, '')
    no.setString(20, '')
    ws.addObject(no)

    # add ems sensor for facility produced electricity
    ot = 'EnergyManagementSystem_Sensor'.to_IddObjectType
    no = OpenStudio::IdfObject.new(ot)
    no.setString(0, 'Fac_Elec_Prod_Sen')
    no.setString(1, 'Whole Building')
    no.setString(2, 'Facility Total Produced Electricity Energy')
    ws.addObject(no)

    # add ems sensor for battery charge state
    ot = 'EnergyManagementSystem_Sensor'.to_IddObjectType
    no = OpenStudio::IdfObject.new(ot)
    no.setString(0, 'Batt_Charge_State_Sen')
    no.setString(1, 'Battery')
    no.setString(2, 'Electric Storage Battery Charge State')
    ws.addObject(no)

    # add ems sensor for battery discharge energy
    ot = 'EnergyManagementSystem_Sensor'.to_IddObjectType
    no = OpenStudio::IdfObject.new(ot)
    no.setString(0, 'Batt_Discharge_Energy_Sen')
    no.setString(1, 'Battery')
    no.setString(2, 'Electric Storage Discharge Energy')
    ws.addObject(no)

    # add ems sensor for battery charge energy
    ot = 'EnergyManagementSystem_Sensor'.to_IddObjectType
    no = OpenStudio::IdfObject.new(ot)
    no.setString(0, 'Batt_Charge_Energy_Sen')
    no.setString(1, 'Battery')
    no.setString(2, 'Electric Storage Charge Energy')
    ws.addObject(no)

    # add ems sensor for battery charge state
    ot = 'EnergyManagementSystem_Sensor'.to_IddObjectType
    no = OpenStudio::IdfObject.new(ot)
    no.setString(0, 'Batt_Volt_Sen')
    no.setString(1, 'Battery')
    no.setString(2, 'Electric Storage Total Voltage')
    ws.addObject(no)

    # add ems actuator for battery charge schedule
    ot = 'EnergyManagementSystem_Actuator'.to_IddObjectType
    no = OpenStudio::IdfObject.new(ot)
    no.setString(0, 'Batt_Charge_Sch_Act')
    no.setString(1, 'Battery Charge Sch')
    no.setString(2, 'Schedule:Constant')
    no.setString(3, 'Schedule Value')
    ws.addObject(no)

    # add ems actuator for battery discharge schedule
    ot = 'EnergyManagementSystem_Actuator'.to_IddObjectType
    no = OpenStudio::IdfObject.new(ot)
    no.setString(0, 'Batt_Discharge_Sch_Act')
    no.setString(1, 'Battery Discharge Sch')
    no.setString(2, 'Schedule:Constant')
    no.setString(3, 'Schedule Value')
    ws.addObject(no)

    # add ems program
    ot = 'EnergyManagementSystem_Program'.to_IddObjectType
    no = OpenStudio::IdfObject.new(ot); i=0
    no.setString(i, 'Battery_Prgm'); i+=1
    no.setString(i, 'SET batt_sig = setChargeDischargeRate'); i+=1
    no.setString(i, 'IF batt_sig == 0'); i+=1
    no.setString(i, 'SET Batt_Charge_Sch_Act = NULL'); i+=1
    no.setString(i, 'SET Batt_Discharge_Sch_Act = NULL'); i+=1
    no.setString(i, 'ELSEIF batt_sig > 0'); i+=1
    no.setString(i, 'SET Batt_Charge_Sch_Act = batt_sig'); i+=1
    no.setString(i, 'SET Batt_Discharge_Sch_Act = 0'); i+=1
    no.setString(i, 'ELSEIF batt_sig < 0'); i+=1
    no.setString(i, 'SET Batt_Charge_Sch_Act = 0'); i+=1
    no.setString(i, 'SET Batt_Discharge_Sch_Act = @Abs batt_sig'); i+=1
    no.setString(i, 'ENDIF'); i+=1
    no.setString(i, "SET batt_min_soc = #{soc_min_pct}"); i+=1
    no.setString(i, "SET batt_chrg_rate = #{size_kw * 1000}"); i+=1
    no.setString(i, "SET batt_dischrg_rate = #{size_kw * 1000}"); i+=1
    no.setString(i, "SET batt_max_wh = #{size_kwh * 1000}"); i+=1
    no.setString(i, 'SET batt_dischrg_j = Batt_Discharge_Energy_Sen'); i+=1
    no.setString(i, 'SET j_to_wh = 1 / (60 * 60)'); i+=1
    no.setString(i, 'SET batt_dischrg_wh = batt_dischrg_j * j_to_wh'); i+=1
    no.setString(i, 'SET batt_chrge_j = Batt_Charge_Energy_Sen'); i+=1
    no.setString(i, 'SET batt_chrg_wh = batt_chrge_j * j_to_wh'); i+=1
    no.setString(i, 'IF batt_dischrg_wh > 0'); i+=1
    no.setString(i, 'SET batt_net_energy_wh = ( -1 ) * batt_dischrg_wh'); i+=1
    no.setString(i, 'ELSEIF batt_chrg_wh > 0'); i+=1
    no.setString(i, 'SET batt_net_energy_wh = batt_chrg_wh'); i+=1
    no.setString(i, 'ENDIF'); i+=1
    no.setString(i, 'SET batt_chrg_state_ah = Batt_Charge_State_Sen'); i+=1
    no.setString(i, 'SET batt_v = Batt_Volt_Sen'); i+=1
    no.setString(i, 'SET batt_chrg_state_wh = batt_chrg_state_ah * batt_v'); i+=1
    no.setString(i, 'SET fac_elec_prod_j = Fac_Elec_Prod_Sen'); i+=1
    no.setString(i, 'SET fac_elec_prod_wh = fac_elec_prod_j * j_to_wh'); i+=1
    ws.addObject(no)

    # add ems program calling manager
    ot = 'EnergyManagementSystem_ProgramCallingManager'.to_IddObjectType
    no = OpenStudio::IdfObject.new(ot)
    no.setString(0, 'Battery Mngr')
    no.setString(1, 'BeginTimestepBeforePredictor')
    no.setString(2, 'Battery_Prgm')
    ws.addObject(no)

    ov = [
      ['Battery Minimum State of Charge', 'batt_min_soc', 'Averaged'],
      ['Battery Nameplate Charge Rate', 'batt_chrg_rate', 'Summed'],
      ['Battery Nameplate Discharge Rate', 'batt_dischrg_rate', 'Summed'],
      ['Battery Nameplate Capacity', 'batt_max_wh', 'Averaged'],
      ['Battery Discharge Energy', 'batt_dischrg_wh', 'Summed'],
      ['Battery Charge Energy', 'batt_chrg_wh', 'Summed'],
      ['Battery Net Energy', 'batt_net_energy_wh', 'Summed'],
      ['Battery Charge State', 'batt_chrg_state_wh', 'Summed'],
      ['Facility Electricity Produced', 'fac_elec_prod_wh', 'Summed']
    ]

    ov.each do |v|
      ot = 'EnergyManagementSystem_OutputVariable'.to_IddObjectType
      no = OpenStudio::IdfObject.new(ot)
      no.setString(0, v[0])
      no.setString(1, v[1])
      no.setString(2, v[2])
      no.setString(3, 'ZoneTimestep')
      no.setString(4, 'Battery_Prgm')
      no.setString(5, '')
      ws.addObject(no)
    end

    return true
  end
end

# this allows the measure to be used by the application
AddBattery.new.registerWithApplication

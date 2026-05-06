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
class ReactivePwr < OpenStudio::Measure::EnergyPlusMeasure

  # human readable name
  def name
    return 'Reactive power'
  end

  # human readable description
  def description
    return 'Calculate reactive power'
  end

  # human readable description of modeling approach
  def modeler_description
    return 'Add python plugin to calculate reactive power'
  end

  # define the arguments that the user will input
  def arguments(workspace)
    args = OpenStudio::Measure::OSArgumentVector.new
    return args
  end

  # define what happens when the measure is run
  def run(ws, runner, usr_args)

    # call the parent class method
    super(ws, runner, usr_args)

    # add python plugin search paths
    ot = 'PythonPlugin_SearchPaths'.to_IddObjectType
    no = OpenStudio::IdfObject.new(ot)
    no.setString(0, 'Python Plugin Search Paths')
    no.setString(1, 'No')
    no.setString(2, 'No')
    no.setString(3, 'No')
    no.setString(4, "#{__dir__}/resources")
    ws.addObject(no)

    # add python plugin instance
    ot = 'PythonPlugin_Instance'.to_IddObjectType
    no = OpenStudio::IdfObject.new(ot)
    no.setString(0, 'React Pwr Prgm')
    no.setString(1, 'No')
    no.setString(2, 'in')
    no.setString(3, 'React_Pwr_Prgm')
    ws.addObject(no)

    pv = [
      ['batt_pf', 'Battery Power Factor'],
      ['htg_mtr', 'Heating Submeter'],
      ['clg_mtr', 'Cooling Submeter'],
      ['inl_mtr', 'Interior Lighting Submeter'],
      ['exl_mtr', 'Exterior Lighting Submeter'],
      ['ine_mtr', 'Interior Equipment Submeter'],
      ['exe_mtr', 'Exterior Equipment Submeter'],
      ['fan_mtr', 'Fans Submeter'],
      ['pmp_mtr', 'Pumps Submeter'],
      ['hrj_mtr', 'Heat Rejection Submeter'],
      ['hum_mtr', 'Humidification Submeter'],
      ['hrc_mtr', 'Heat Recovery Submeter'],
      ['swh_mtr', 'Service Water Heating Submeter'],
      ['ref_mtr', 'Refrigeration Submeter'],
      ['gen_mtr', 'Generators Submeter'],
      ['tot_mtr', 'Total Submeter'],
      ['bld_rct', 'Building Reactive Power'],
      ['bat_act', 'Battery Active Power'],
      ['bat_rct', 'Battery Reactive Power'],
      ['tot_act', 'Total Active Power'],
      ['tot_rct', 'Total Reactive Power'],
      ['mod_idx', 'Electric Storage Operating Mode Index'],
      ['chg_frc', 'Electric Storage Charge Fraction'],
      ['chg_pwr', 'Electric Storage Charge Power'],
      ['dis_pwr', 'Electric Storage Discharge Power'],
      ['bat_cur', 'Electric Storage Total Current'],
      ['bat_vlt', 'Electric Storage Total Voltage'],
      ['min_soc', 'Battery Minimum State of Charge'],
      ['chg_rat', 'Battery Nameplate Charge Rate'],
      ['dis_rat', 'Battery Nameplate Discharge Rate'],
      ['bat_cap', 'Battery Nameplate Capacity'],
      ['dis_nrg', 'Battery Discharge Energy'],
      ['chg_nrg', 'Battery Charge Energy'],
      ['net_nrg', 'Battery Net Energy'],
      ['chg_stt', 'Battery Charge State'],
      ['ele_pro', 'Facility Electricity Produced']
    ]

    # add python plugin instance
    ot = 'PythonPlugin_Variables'.to_IddObjectType
    no = OpenStudio::IdfObject.new(ot); i=0
    no.setString(i, 'Python Plugin Variables'); i+=1
    pv.each {|v| no.setString(i, v[0]); i+=1}
    ws.addObject(no)

    # check for battery and inverter
    ot = 'ElectricLoadCenter_Storage_LiIonNMCBattery'.to_IddObjectType
    unless ws.getObjectsByType(ot).empty?
      ot = 'ElectricLoadCenter_Inverter_FunctionOfPower'.to_IddObjectType
      unless ws.getObjectsByType(ot).empty?

        # add output variables for python plugin if not there
        ['Discharge Power', 'Total Current', 'Total Voltage'].each do |s|
          ex = false
          ot = 'Output_Variable'.to_IddObjectType
          ws.getObjectsByType(ot).each do |o|
            if "Electric Storage #{s}" == o.getString(0, false).get
              ex = true
            end
          end
          if ex
            no = OpenStudio::IdfObject.new(ot)
            no.setString(0, 'Battery')
            no.setString(1, "Electric Storage #{s}")
            no.setString(2, 'Timestep')
            ws.addObject(no)
          end
        end

      end
    end

    # add python plugin output variables
    pv.each do |v|
    ot = 'PythonPlugin_OutputVariable'.to_IddObjectType
      no = OpenStudio::IdfObject.new(ot)
      no.setString(0, v[1])
      no.setString(1, v[0])
      no.setString(2, 'Summed')
      no.setString(3, 'ZoneTimestep')
      no.setString(4, '')
      ws.addObject(no)
    end

  return true
  end
end

# register the measure to be used by the application
ReactivePwr.new.registerWithApplication

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
class Blackout < OpenStudio::Measure::EnergyPlusMeasure

  # human readable name
  def name
    return 'Blackout'
  end

  # human readable description
  def description
    return 'Models loss of power to a building'
  end

  # human readable description of modeling approach
  def modeler_description
    return 'Add EMS to set all schedules to zero'
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new
    return args
  end

  # define what happens when the measure is run
  def run(ws, runner, usr_args)

    # call the parent class method
    super(ws, runner, usr_args)

    # define schedule types
    sch_typs = [
      'Schedule_Day_Hourly',
      'Schedule_Day_Interval',
      'Schedule_Day_List',
      'Schedule_Week_Daily',
      'Schedule_Week_Compact',
      'Schedule_Year',
      'Schedule_Compact',
      'Schedule_Constant',
      'Schedule_File',
      'Schedule_File_Shading'
    ]

    # populate array of schedule objects
    sch_objs = []
    sch_typs.each do |t|
      sch_objs << ws.getObjectsByType(t.to_IddObjectType)
    end
    sch_objs.flatten!

    # populate array of schedule names
    sch_name = []
    sch_objs.each do |o|
      sch_name << [
        o.getString(0, false).get,
        o.iddObject.name
      ]
    end

    # make ems actuator for each schedule
    ot = 'EnergyManagementSystem_Actuator'.to_IddObjectType
    sch_name.each do |n|
      cn = n[0].gsub(' ', '_').gsub('-', '_').gsub('.', '_')
      no = OpenStudio::IdfObject.new(ot)
      no.setString(0, "#{cn}_Act")
      no.setString(1, n[0])
      no.setString(2, n[1])
      no.setString(3, 'Schedule Value')
      ws.addObject(no)
    end

    # add ems program
    ot = 'EnergyManagementSystem_Program'.to_IddObjectType
    no = OpenStudio::IdfObject.new(ot); i=0
    no.setString(i, 'Blackout_Prgm'); i+=1
    no.setString(i, 'SET pwr_out = 0'); i+=1
    no.setString(i, 'IF pwr_out == 1'); i+=1
    sch_name.each do |n|
      cn = n[0].gsub(' ', '_').gsub('-', '_').gsub('.', '_')
      no.setString(i, "SET #{cn}_Act = 0"); i+=1
    end
    no.setString(i, 'ELSE'); i+=1
    sch_name.each do |n|
      cn = n[0].gsub(' ', '_').gsub('-', '_').gsub('.', '_')
      no.setString(i, "SET #{n[0]}_Act = NULL"); i+=1
    end
    no.setString(i, 'ENDIF'); i+=1
    ws.addObject(no)

    # add ems program calling manager
    ot = 'EnergyManagementSystem_ProgramCallingManager'.to_IddObjectType
    no = OpenStudio::IdfObject.new(ot)
    no.setString(0, 'Blackout Mngr')
    no.setString(1, 'BeginTimestepBeforePredictor')
    no.setString(2, 'Blackout_Prgm')
    ws.addObject(no)

    return true
  end
end

# this allows the measure to be used by the application
Blackout.new.registerWithApplication

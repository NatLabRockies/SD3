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
class AddZoneCapMult < OpenStudio::Measure::EnergyPlusMeasure

  # define the name that a user will see
  def name
    return 'Add Zone Cap Mult'
  end

  # human readable description
  def description
    return 'Add zone capacitance multiplier'
  end

  # human readable description of modeling approach
  def modeler_description
    return 'Add ZoneCapacitanceMultiplier:ResearchSpecial to each zone'
  end

  # define the arguments that the user will input
  def arguments(ws)
    args = OpenStudio::Measure::OSArgumentVector.new

    # zone capacitance multiplier
    zn_cap_mult = OpenStudio::Measure::OSArgument.makeDoubleArgument(
      'zn_cap_mult',
      true
    )
    zn_cap_mult.setDisplayName('Zone Cap Mult')
    zn_cap_mult.setDescription('Zone Capacitance Multiplier')
    zn_cap_mult.setUnits('-')
    zn_cap_mult.setDefaultValue(7)
    args << zn_cap_mult

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
    zn_cap_mult = runner.getDoubleArgumentValue(
      'zn_cap_mult',
      usr_args
    )

    # add zone capacitance multiplier
    ws.getObjectsByType('Zone'.to_IddObjectType).each do |o|
      zn = o.name.get
      ot = 'ZoneCapacitanceMultiplier_ResearchSpecial'.to_IddObjectType
      no = OpenStudio::IdfObject.new(ot)
      no.setString(0, "{o.name.get} Cap Mult")
      no.setString(1, o.name.get)
      no.setDouble(2, zn_cap_mult)
      no.setDouble(3, zn_cap_mult)
      no.setDouble(4, zn_cap_mult)
      no.setDouble(5, zn_cap_mult)
      ws.addObject(no)
    end

    return true
  end
end

# this allows the measure to be used by the application
AddZoneCapMult.new.registerWithApplication

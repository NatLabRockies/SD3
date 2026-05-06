from pyenergyplus.plugin import EnergyPlusPlugin
import math

class React_Pwr_Prgm(EnergyPlusPlugin):

    def __init__(self):

        # init parent class
        super().__init__()

        # handles flag
        self.need_to_get_handles = True

        # enduse power factors
        self.htg_pf = 1
        self.clg_pf = 0.96
        self.inl_pf = 1
        self.exl_pf = 1
        self.ine_pf = 0.95
        self.exe_pf = 1 # todo: check value
        self.fan_pf = 0.87
        self.pmp_pf = 0.84
        self.hrj_pf = 0.84
        self.hum_pf = 1 # todo: check value
        self.hrc_pf = 0.85
        self.swh_pf = 0.84
        self.ref_pf = 0.8
        self.gen_pf = 1 # todo: check value

        # battery power factor
        self.batt_pf = 1.0

        # output meter handles
        self.htg_mtr_hndl = None
        self.clg_mtr_hndl = None
        self.inl_mtr_hndl = None
        self.exl_mtr_hndl = None
        self.ine_mtr_hndl = None
        self.exe_mtr_hndl = None
        self.fan_mtr_hndl = None
        self.pmp_mtr_hndl = None
        self.hrj_mtr_hndl = None
        self.hum_mtr_hndl = None
        self.hrc_mtr_hndl = None
        self.swh_mtr_hndl = None
        self.ref_mtr_hndl = None
        self.gen_mtr_hndl = None

        # output variable handles
        self.dis_pwr_hndl = None
        self.bat_cur_hndl = None
        self.bat_vlt_hndl = None

        # global handles
        self.batt_pf_hndl = None
        self.htg_glb_hndl = None
        self.clg_glb_hndl = None
        self.inl_glb_hndl = None
        self.exl_glb_hndl = None
        self.ine_glb_hndl = None
        self.exe_glb_hndl = None
        self.fan_glb_hndl = None
        self.pmp_glb_hndl = None
        self.hrj_glb_hndl = None
        self.hum_glb_hndl = None
        self.hrc_glb_hndl = None
        self.swh_glb_hndl = None
        self.ref_glb_hndl = None
        self.gen_glb_hndl = None
        self.tot_mtr_hndl = None
        self.bld_rct_hndl = None
        self.bat_act_hndl = None
        self.bat_rct_hndl = None
        self.tot_act_hndl = None
        self.tot_rct_hndl = None

        # inverter curve actuator handle
        self.inv_crv_hndl = None

    def get_handles(self, state):

        # get heating output meter handle
        self.htg_mtr_hndl = self.api.exchange.get_meter_handle(
            state,
            'Heating:Electricity'
        )

        # get cooling output meter handle
        self.clg_mtr_hndl = self.api.exchange.get_meter_handle(
            state,
            'Cooling:Electricity'
        )

        # get interior lighting output meter handle
        self.inl_mtr_hndl = self.api.exchange.get_meter_handle(
            state,
            'InteriorLights:Electricity'
        )

        # get exterior lighting output meter handle
        self.exl_mtr_hndl = self.api.exchange.get_meter_handle(
            state,
            'ExteriorLights:Electricity'
        )

        # get interior equipment output meter handle
        self.ine_mtr_hndl = self.api.exchange.get_meter_handle(
            state,
            'InteriorEquipment:Electricity'
        )

        # get exterior equipment output meter handle
        self.exe_mtr_hndl = self.api.exchange.get_meter_handle(
            state,
            'ExteriorEquipment:Electricity'
        )

        # get fan output meter handle
        self.fan_mtr_hndl = self.api.exchange.get_meter_handle(
            state,
            'Fans:Electricity'
        )

        # get pump output meter handle
        self.pmp_mtr_hndl = self.api.exchange.get_meter_handle(
            state,
            'Pumps:Electricity'
        )

        # get heat rejection output meter handle
        self.hrj_mtr_hndl = self.api.exchange.get_meter_handle(
            state,
            'HeatRejection:Electricity'
        )

        # get humidification output meter handle
        self.hum_mtr_hndl = self.api.exchange.get_meter_handle(
            state,
            'Humidification:Electricity'
        )

        # get heat recovery output meter handle
        self.hrc_mtr_hndl = self.api.exchange.get_meter_handle(
            state,
            'HeatRecovery:Electricity'
        )

        # get service water heating output meter handle
        self.swh_mtr_hndl = self.api.exchange.get_meter_handle(
            state,
            'WaterSystems:Electricity'
        )

        # get refrigeration output meter handle
        self.ref_mtr_hndl = self.api.exchange.get_meter_handle(
            state,
            'Refrigeration:Electricity'
        )

        # get generators output meter handle
        self.gen_mtr_hndl = self.api.exchange.get_meter_handle(
            state,
            'Generators:Electricity'
        )

        # get battery discharge power output variable handle
        self.dis_pwr_hndl = self.api.exchange.get_variable_handle(
            state,
            'Electric Storage Discharge Power',
            'Battery'
        )

        # get battery current output variable handle
        self.bat_cur_hndl = self.api.exchange.get_variable_handle(
            state,
            'Electric Storage Total Current',
            'Battery'
        )

        # get battery voltage output variable handle
        self.bat_vlt_hndl = self.api.exchange.get_variable_handle(
            state,
            'Electric Storage Total Voltage',
            'Battery'
        )

        # get battery power factor global handle
        self.batt_pf_hndl = self.api.exchange.get_global_handle(
            state,
            'batt_pf'
        )

        # get heating global handle
        self.htg_glb_hndl = self.api.exchange.get_global_handle(
            state,
            'htg_mtr'
        )

        # get cooling global handle
        self.clg_glb_hndl = self.api.exchange.get_global_handle(
            state,
            'clg_mtr'
        )

        # get interior lighting global handle
        self.inl_glb_hndl = self.api.exchange.get_global_handle(
            state,
            'inl_mtr'
        )

        # get exterior lighting global handle
        self.exl_glb_hndl = self.api.exchange.get_global_handle(
            state,
            'exl_mtr'
        )

        # get interior equipment global handle
        self.ine_glb_hndl = self.api.exchange.get_global_handle(
            state,
            'ine_mtr'
        )

        # get exterior equipment global handle
        self.exe_glb_hndl = self.api.exchange.get_global_handle(
            state,
            'exe_mtr'
        )

        # get fan global handle
        self.fan_glb_hndl = self.api.exchange.get_global_handle(
            state,
            'fan_mtr'
        )

        # get pump global handle
        self.pmp_glb_hndl = self.api.exchange.get_global_handle(
            state,
            'pmp_mtr'
        )

        # get heat rejection global handle
        self.hrj_glb_hndl = self.api.exchange.get_global_handle(
            state,
            'hrj_mtr'
        )

        # get humidification global handle
        self.hum_glb_hndl = self.api.exchange.get_global_handle(
            state,
            'hum_mtr'
        )

        # get heat recovery global handle
        self.hrc_glb_hndl = self.api.exchange.get_global_handle(
            state,
            'hrc_mtr'
        )

        # get service water heating global handle
        self.swh_glb_hndl = self.api.exchange.get_global_handle(
            state,
            'swh_mtr'
        )

        # get refrigeration global handle
        self.ref_glb_hndl = self.api.exchange.get_global_handle(
            state,
            'ref_mtr'
        )

        # get generators global handle
        self.gen_glb_hndl = self.api.exchange.get_global_handle(
            state,
            'gen_mtr'
        )

        # get total meter handle
        self.tot_mtr_hndl = self.api.exchange.get_global_handle(
            state,
            'tot_mtr'
        )

        # get building reactive power global handle
        self.bld_rct_hndl = self.api.exchange.get_global_handle(
            state,
            'bld_rct'
        )

        # get battery active power global handle
        self.bat_act_hndl = self.api.exchange.get_global_handle(
            state,
            'bat_act'
        )

        # get battery reactive power global handle
        self.bat_rct_hndl = self.api.exchange.get_global_handle(
            state,
            'bat_rct'
        )

        # get total active power global handle
        self.tot_act_hndl = self.api.exchange.get_global_handle(
            state,
            'tot_act'
        )

        # get total reactive power global handle
        self.tot_rct_hndl = self.api.exchange.get_global_handle(
            state,
            'tot_rct'
        )

        # get battery inverter curve actuator handle
        self.inv_crv_hndl = self.api.exchange.get_actuator_handle(
            state,
            'Curve',
            'Curve Result',
            'Battery Inverter Curve',
        )

        # set get handles to false
        self.need_to_get_handles = False

    def on_end_of_zone_timestep_after_zone_reporting(self, state) -> int:

        # wait until api is ready
        if not self.api.exchange.api_data_fully_ready(state):
            return 0

        # get handles
        if self.need_to_get_handles:
            self.get_handles(state)

        # set total meter and building reactive power to zero
        self.tot_mtr = 0
        self.bld_rct = 0

        # get zone timestep
        self.zn_ts_h = self.api.exchange.zone_time_step(state)
        self.zn_ts_s = self.zn_ts_h * 60 * 60

        # get heating output meter value if it exists
        if self.htg_mtr_hndl != -1:
            self.htg_mtr = self.api.exchange.get_meter_value(
                state,
                self.htg_mtr_hndl
            )
            # convert to watts
            self.htg_mtr = self.htg_mtr / self.zn_ts_s
        else:
            self.htg_mtr = 0
        # set global, convert to Wh
        self.api.exchange.set_global_value(
            state,
            self.htg_glb_hndl,
            self.htg_mtr * self.zn_ts_h
        )
        # calculate reactive power and sum
        self.htg_rct = self.htg_mtr * math.sin(math.acos(self.htg_pf))
        self.bld_rct = self.bld_rct + self.htg_rct
        # sum active power
        self.tot_mtr = self.tot_mtr + self.htg_mtr

        # get cooling output meter value if it exists
        if self.clg_mtr_hndl != -1:
            self.clg_mtr = self.api.exchange.get_meter_value(
                state,
                self.clg_mtr_hndl
            )
            # convert to watts
            self.clg_mtr = self.clg_mtr / self.zn_ts_s
        else:
            self.clg_mtr = 0
        # set global, convert to Wh
        self.api.exchange.set_global_value(
            state,
            self.clg_glb_hndl,
            self.clg_mtr * self.zn_ts_h
        )
        # calculate reactive power and sum
        self.clg_rct = self.clg_mtr * math.sin(math.acos(self.clg_pf))
        self.bld_rct = self.bld_rct + self.clg_rct
        # sum active power
        self.tot_mtr = self.tot_mtr + self.clg_mtr

        # get interior lighting output meter value if it exists
        if self.inl_mtr_hndl != -1:
            self.inl_mtr = self.api.exchange.get_meter_value(
                state,
                self.inl_mtr_hndl
            )
            # convert to watts
            self.inl_mtr = self.inl_mtr / self.zn_ts_s
        else:
            self.inl_mtr = 0
        # set global, convert to Wh
        self.api.exchange.set_global_value(
            state,
            self.inl_glb_hndl,
            self.inl_mtr * self.zn_ts_h
        )
        # calculate reactive power and sum
        self.inl_rct = self.inl_mtr * math.sin(math.acos(self.inl_pf))
        self.bld_rct = self.bld_rct + self.inl_rct
        # sum active power
        self.tot_mtr = self.tot_mtr + self.inl_mtr

        # get exterior lighting output meter value if it exists
        if self.exl_mtr_hndl != -1:
            self.exl_mtr = self.api.exchange.get_meter_value(
                state,
                self.exl_mtr_hndl
            )
            # convert to watts
            self.exl_mtr = self.exl_mtr / self.zn_ts_s
        else:
            self.exl_mtr = 0
        # set global, convert to Wh
        self.api.exchange.set_global_value(
            state,
            self.exl_glb_hndl,
            self.exl_mtr * self.zn_ts_h
        )
        # calculate reactive power and sum
        self.exl_rct = self.exl_mtr * math.sin(math.acos(self.exl_pf))
        self.bld_rct = self.bld_rct + self.exl_rct
        # sum active power
        self.tot_mtr = self.tot_mtr + self.exl_mtr

        # get interior equipment output meter value if it exists
        if self.ine_mtr_hndl != -1:
            self.ine_mtr = self.api.exchange.get_meter_value(
                state,
                self.ine_mtr_hndl
            )
            # convert to watts
            self.ine_mtr = self.ine_mtr / self.zn_ts_s
        else:
            self.ine_mtr = 0
        # set global, convert to Wh
        self.api.exchange.set_global_value(
            state,
            self.ine_glb_hndl,
            self.ine_mtr * self.zn_ts_h
        )
        # calculate reactive power and sum
        self.ine_rct = self.ine_mtr * math.sin(math.acos(self.ine_pf))
        self.bld_rct = self.bld_rct + self.ine_rct
        # sum active power
        self.tot_mtr = self.tot_mtr + self.ine_mtr

        # get exterior equipment output meter value if it exists
        if self.exe_mtr_hndl != -1:
            self.exe_mtr = self.api.exchange.get_meter_value(
                state,
                self.exe_mtr_hndl
            )
            # convert to watts
            self.exe_mtr = self.exe_mtr / self.zn_ts_s
        else:
            self.exe_mtr = 0
        # set global, convert to Wh
        self.api.exchange.set_global_value(
            state,
            self.exe_glb_hndl,
            self.exe_mtr * self.zn_ts_h
        )
        # calculate reactive power and sum
        self.exe_rct = self.exe_mtr * math.sin(math.acos(self.exe_pf))
        self.bld_rct = self.bld_rct + self.exe_rct
        # sum active power
        self.tot_mtr = self.tot_mtr + self.exe_mtr

        # get fan output meter value if it exists
        if self.fan_mtr_hndl != -1:
            self.fan_mtr = self.api.exchange.get_meter_value(
                state,
                self.fan_mtr_hndl
            )
            # convert to watts
            self.fan_mtr = self.fan_mtr / self.zn_ts_s
        else:
            self.fan_mtr = 0
        # set global, convert to Wh
        self.api.exchange.set_global_value(
            state,
            self.fan_glb_hndl,
            self.fan_mtr * self.zn_ts_h
        )
        # calculate reactive power and sum
        self.fan_rct = self.fan_mtr * math.sin(math.acos(self.fan_pf))
        self.bld_rct = self.bld_rct + self.fan_rct
        # sum active power
        self.tot_mtr = self.tot_mtr + self.fan_mtr

        # get pump output meter value if it exists
        if self.pmp_mtr_hndl != -1:
            self.pmp_mtr = self.api.exchange.get_meter_value(
                state,
                self.pmp_mtr_hndl
            )
            # convert to watts
            self.pmp_mtr = self.pmp_mtr / self.zn_ts_s
        else:
            self.pmp_mtr = 0
        # set global, convert to Wh
        self.api.exchange.set_global_value(
            state,
            self.pmp_glb_hndl,
            self.pmp_mtr * self.zn_ts_h
        )
        # calculate reactive power and sum
        self.pmp_rct = self.pmp_mtr * math.sin(math.acos(self.pmp_pf))
        self.bld_rct = self.bld_rct + self.pmp_rct
        # sum active power
        self.tot_mtr = self.tot_mtr + self.pmp_mtr

        # get heat rejection output meter value if it exists
        if self.hrj_mtr_hndl != -1:
            self.hrj_mtr = self.api.exchange.get_meter_value(
                state,
                self.hrj_mtr_hndl
            )
            # convert to watts
            self.hrj_mtr = self.hrj_mtr / self.zn_ts_s
        else:
            self.hrj_mtr = 0
        # set global, convert to Wh
        self.api.exchange.set_global_value(
            state,
            self.hrj_glb_hndl,
            self.hrj_mtr * self.zn_ts_h
        )
        # calculate reactive power and sum
        self.hrj_rct = self.hrj_mtr * math.sin(math.acos(self.hrj_pf))
        self.bld_rct = self.bld_rct + self.hrj_rct
        # sum active power
        self.tot_mtr = self.tot_mtr + self.hrj_mtr

        # get humidification output meter value if it exists
        if self.hum_mtr_hndl != -1:
            self.hum_mtr = self.api.exchange.get_meter_value(
                state,
                self.hum_mtr_hndl
            )
            # convert to watts
            self.hum_mtr = self.hum_mtr / self.zn_ts_s
        else:
            self.hum_mtr = 0
        # set global, convert to Wh
        self.api.exchange.set_global_value(
            state,
            self.hum_glb_hndl,
            self.hum_mtr * self.zn_ts_h
        )
        # calculate reactive power and sum
        self.hum_rct = self.hum_mtr * math.sin(math.acos(self.hum_pf))
        self.bld_rct = self.bld_rct + self.hum_rct
        # sum active power
        self.tot_mtr = self.tot_mtr + self.hum_mtr

        # get heat recovery output meter value if it exists
        if self.hrc_mtr_hndl != -1:
            self.hrc_mtr = self.api.exchange.get_meter_value(
                state,
                self.hrc_mtr_hndl
            )
            # convert to watts
            self.hrc_mtr = self.hrc_mtr / self.zn_ts_s
        else:
            self.hrc_mtr = 0
        # set global, convert to Wh
        self.api.exchange.set_global_value(
            state,
            self.hrc_glb_hndl,
            self.hrc_mtr * self.zn_ts_h
        )
        # calculate reactive power and sum
        self.hrc_rct = self.hrc_mtr * math.sin(math.acos(self.hrc_pf))
        self.bld_rct = self.bld_rct + self.hrc_rct
        # sum active power
        self.tot_mtr = self.tot_mtr + self.hrc_mtr

        # get service water heating output meter value if it exists
        if self.swh_mtr_hndl != -1:
            self.swh_mtr = self.api.exchange.get_meter_value(
                state,
                self.swh_mtr_hndl
            )
            # convert to watts
            self.swh_mtr = self.swh_mtr / self.zn_ts_s
        else:
            self.swh_mtr = 0
        # set global, convert to Wh
        self.api.exchange.set_global_value(
            state,
            self.swh_glb_hndl,
            self.swh_mtr * self.zn_ts_h
        )
        # calculate reactive power and sum
        self.swh_rct = self.swh_mtr * math.sin(math.acos(self.swh_pf))
        self.bld_rct = self.bld_rct + self.swh_rct
        # sum active power
        self.tot_mtr = self.tot_mtr + self.swh_mtr

        # get refrigeration output meter value if it exists
        if self.ref_mtr_hndl != -1:
            self.ref_mtr = self.api.exchange.get_meter_value(
                state,
                self.ref_mtr_hndl
            )
            # convert to watts
            self.ref_mtr = self.ref_mtr / self.zn_ts_s
        else:
            self.ref_mtr = 0
        # set global, convert to Wh
        self.api.exchange.set_global_value(
            state,
            self.ref_glb_hndl,
            self.ref_mtr * self.zn_ts_h
        )
        # calculate reactive power and sum
        self.ref_rct = self.ref_mtr * math.sin(math.acos(self.ref_pf))
        self.bld_rct = self.bld_rct + self.ref_rct
        # sum active power
        self.tot_mtr = self.tot_mtr + self.ref_mtr

        # get generators output meter value if it exists
        if self.gen_mtr_hndl != -1:
            self.gen_mtr = self.api.exchange.get_meter_value(
                state,
                self.gen_mtr_hndl
            )
            # convert to watts
            self.gen_mtr = self.gen_mtr / self.zn_ts_s
        else:
            self.gen_mtr = 0
        # set global, convert to Wh
        self.api.exchange.set_global_value(
            state,
            self.gen_glb_hndl,
            self.gen_mtr * self.zn_ts_h
        )
        # calculate reactive power and sum
        self.gen_rct = self.gen_mtr * math.sin(math.acos(self.gen_pf))
        self.bld_rct = self.bld_rct + self.gen_rct
        # sum active power
        self.tot_mtr = self.tot_mtr + self.gen_mtr

        # set building active power global
        self.api.exchange.set_global_value(
            state,
            self.tot_mtr_hndl,
            self.tot_mtr
        )

        # set building reactive power global
        self.api.exchange.set_global_value(
            state,
            self.bld_rct_hndl,
            self.bld_rct
        )

        # get battery discharge power output variable value
        if self.dis_pwr_hndl != -1:
            self.dis_pwr = self.api.exchange.get_variable_value(
                state,
                self.dis_pwr_hndl
            )
        else:
            self.dis_pwr = 0

        # get battery total current output variable value
        if self.bat_cur_hndl != -1:
            self.bat_cur = self.api.exchange.get_variable_value(
                state,
                self.bat_cur_hndl
            )
        else:
            self.bat_cur = 0

        # get battery total voltage output variable value
        if self.bat_vlt_hndl != -1:
            self.bat_vlt = self.api.exchange.get_variable_value(
                state,
                self.bat_vlt_hndl
            )
        else:
            self.bat_vlt = 0

        # battery inverter calcs, flip current sign (E+ has diff convention)
        self.bat_pwr = self.bat_cur * -1.0 * self.bat_vlt
        self.bat_ang = math.acos(self.batt_pf)
        self.vlt_grd = 1
        # self.bat_qpu = -2.5 * (self.vlt_grd - 1)
        # if self.bat_pwr != 0:
        #     self.bat_ang = math.asin(self.bat_qpu / self.bat_pwr)
        self.bat_act = self.bat_pwr * math.cos(self.bat_ang)
        self.bat_rct = self.bat_pwr * math.sin(self.bat_ang)

        # actuate battery inverter curve
        if self.inv_crv_hndl != -1:
            self.api.exchange.set_actuator_value(
                state,
                self.inv_crv_hndl,
                self.bat_act
            )

        # set battery power factor global
        self.api.exchange.set_global_value(
            state,
            self.batt_pf_hndl,
            self.batt_pf
        )

        # set battery active power global
        self.api.exchange.set_global_value(
            state,
            self.bat_act_hndl,
            self.bat_act
        )

        # set battery reactive power global
        self.api.exchange.set_global_value(
            state,
            self.bat_rct_hndl,
            self.bat_rct
        )

        # sum building and battery active and reactive power
        self.tot_act = self.tot_mtr + self.bat_act
        self.tot_rct = self.bld_rct + self.bat_rct

        # set total active power global
        self.api.exchange.set_global_value(
            state,
            self.tot_act_hndl,
            self.tot_act
        )

        # set total reactive power global
        self.api.exchange.set_global_value(
            state,
            self.tot_rct_hndl,
            self.tot_rct
        )

        return 0

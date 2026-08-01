class EntityMapping {
  const EntityMapping();

  // Core status
  final String status = 'sensor.kems_status';
  final String phase = 'sensor.kems_phase';
  final String advice = 'sensor.kems_advice';
  final String dataQuality = 'sensor.kems_data_quality';
  final String historySamples = 'sensor.kems_history_samples';
  final String learningConfidence = 'sensor.kems_learning_confidence';
  final String learningReady = 'binary_sensor.kems_learning_ready';

  // Live power and tariff
  final String gridImport = 'sensor.kems_grid_import';
  final String gridExport = 'sensor.kems_grid_export';
  final String gridNetPower = 'sensor.kems_grid_net_power';
  final String gridFlowDirection = 'sensor.kems_grid_flow_direction';
  final String houseLoad = 'sensor.kems_house_load';
  final String solarPower = 'sensor.kems_simulated_solar_power';
  final String batteryPower = 'sensor.kems_battery_power';
  final String batterySoc = 'sensor.kems_battery_state_of_charge';
  final String evPower = 'sensor.kems_ev_charging_power';
  final String evSoc = 'sensor.kems_ev_state_of_charge';
  final String currentRate = 'sensor.kems_current_import_rate';
  final String nextRate = 'sensor.kems_next_import_rate';
  final String nextOffPeakStart = 'sensor.kems_next_off_peak_start';
  final String offPeakEnd = 'sensor.kems_off_peak_end';
  final String predictedEnergyUntilOffPeak = 'sensor.kems_predicted_energy_until_off_peak';

  // Binary state
  final String offPeak = 'binary_sensor.kems_off_peak';
  final String intelligentSlot = 'binary_sensor.kems_intelligent_slot';
  final String cheapPeriodConfirmed = 'binary_sensor.kems_cheap_period_confirmed';
  final String evConnected = 'binary_sensor.kems_ev_connected';
  final String evCharging = 'binary_sensor.kems_ev_charging';
  final String batteryDataAvailable = 'binary_sensor.kems_battery_data_available';
  final String gasDataAvailable = 'binary_sensor.kems_gas_data_available';
  final String gridImportOutsideCheap = 'binary_sensor.kems_grid_import_outside_cheap_period';
  final String simulationReady = 'binary_sensor.kems_simulation_ready';
  final String simulationSaving = 'binary_sensor.kems_simulation_shows_a_saving';
  final String roiReady = 'binary_sensor.kems_roi_prediction_ready';
  final String systemInstalled = 'binary_sensor.kems_system_installed';

  // Today and simulation
  final String observedCostToday = 'sensor.kems_observed_cost_today';
  final String observedGridImportToday = 'sensor.kems_observed_grid_import_today';
  final String observedGridExportToday = 'sensor.kems_observed_grid_export_today';
  final String observedExportIncomeToday = 'sensor.kems_observed_export_income_today';
  final String simulatedCostToday = 'sensor.kems_simulated_kems_cost_today';
  final String simulatedSavingToday = 'sensor.kems_simulated_saving_today';
  final String avoidedDayRateImportToday = 'sensor.kems_avoided_day_rate_import_today';
  final String simulatedBatterySoc = 'sensor.kems_simulated_battery_state_of_charge';
  final String simulatedBatteryPower = 'sensor.kems_simulated_battery_power';
  final String simulatedGridImportPower = 'sensor.kems_simulated_grid_import_power';
  final String simulatedGridExportPower = 'sensor.kems_simulated_grid_export_power';
  final String simulatedSolarPower = 'sensor.kems_simulated_solar_power';

  // Gas and whole-home
  final String gasUsageToday = 'sensor.kems_gas_usage_today';
  final String gasCostToday = 'sensor.kems_gas_cost_today';
  final String gasCurrentRate = 'sensor.kems_gas_current_rate';
  final String wholeHomeCostToday = 'sensor.kems_whole_home_observed_cost_today';
  final String wholeHomeEnergyToday = 'sensor.kems_whole_home_energy_today';
  final String wholeHomeSimulatedSaving = 'sensor.kems_whole_home_simulated_saving_today';

  // Financial and lifetime
  final String roiStatus = 'sensor.kems_roi_status';
  final String systemInvestment = 'sensor.kems_system_investment';
  final String predictedAnnualSaving = 'sensor.kems_predicted_annual_saving';
  final String predictedPayback = 'sensor.kems_predicted_payback';
  final String predictedPaybackDate = 'sensor.kems_predicted_payback_date';
  final String predictedNetValue = 'sensor.kems_predicted_net_value';
  final String roiConfidence = 'sensor.kems_roi_confidence';
  final String lifetimeSystemValue = 'sensor.kems_lifetime_system_value';
  final String lifetimeGridImport = 'sensor.kems_lifetime_grid_import';
  final String lifetimeGridExport = 'sensor.kems_lifetime_grid_export';
  final String lifetimeSolar = 'sensor.kems_lifetime_solar_generation';
  final String lifetimeNetEnergyCost = 'sensor.kems_lifetime_net_energy_cost';
  final String systemProfile = 'sensor.kems_system_profile';

  List<String> get core => [
        status, phase, advice, dataQuality, historySamples,
        learningConfidence, learningReady, gridImport, gridExport,
        gridNetPower, gridFlowDirection, houseLoad, batteryPower,
        batterySoc, evPower, evSoc, currentRate, nextRate,
        nextOffPeakStart, offPeakEnd, predictedEnergyUntilOffPeak,
        offPeak, intelligentSlot, cheapPeriodConfirmed, evConnected,
        evCharging, batteryDataAvailable, gasDataAvailable,
        gridImportOutsideCheap, simulationReady, simulationSaving,
        roiReady, systemInstalled,
      ];
}

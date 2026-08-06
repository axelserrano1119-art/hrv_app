@override
void initState() {
  super.initState();

  _loadData();

  MeasurementEvents.measurementSaved.addListener(
    _loadData,
  );
  @override
void dispose() {

  MeasurementEvents.measurementSaved
      .removeListener(
        _loadData,
      );

  super.dispose();
}
}
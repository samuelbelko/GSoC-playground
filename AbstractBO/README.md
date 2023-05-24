### Example use

1. instantiate a metadata manager `mm`, setup verbose level
2. instantiate a decision support model `dsm` and a compatible policy `plc` (i.e. we can obtain next observation location via `plc(dsm)`), passing configuration parameters to constructors respectively
3. run `initialize(dsm,mm,f)`
4. either use ask-tell interface or call `optimize(dsm, plc, mm, f)`
5. obtain optimizer from `mm` and checkout other metadata

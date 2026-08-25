import 'package:logger/logger.dart';

final logger = Logger(
  filter: ProductionFilter(),
  printer: SimplePrinter(colors: false),
);

import 'package:cw_core/wallet_credentials.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_service.dart';
import 'package:cw_core/transaction_priority.dart';
import 'package:cw_core/unspent_coins_info.dart';
import 'package:cw_core/hardware/hardware_account_data.dart';
import 'package:cake_wallet/view_model/send/output.dart';
import 'package:cw_core/output_info.dart';
import 'package:hive/hive.dart';

import 'package:cw_digibyte/cw_digibyte.dart';

part 'cw_digibyte.dart';

Digibyte? digibyte = CWDigibyte();

abstract class Digibyte {}

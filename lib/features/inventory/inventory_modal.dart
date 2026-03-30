import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import './inventory_item.dart';
import './inventory_service.dart';

void showInventoryModal({
  required BuildContext context,
  required Future<bool> Function(ShopItem, GlobalKey) onItemTap,
  int coins = 0,
}) {
  showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) => _InventoryModal(
      onItemTap: onItemTap,
    ),
  );
}

class _InventoryModal extends StatelessWidget {
  const _InventoryModal({
    required this.onItemTap,
  });

  final Future<bool> Function(ShopItem, GlobalKey) onItemTap;

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final dialogWidth = screenSize.width < 600 ? screenSize.width * 0.9 : 520.0;
    final dialogHeight = screenSize.height < 760 ? screenSize.height * 0.72 : 620.0;

    return Dialog(
      backgroundColor: Colors.transparent,

    );
  }
}
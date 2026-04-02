import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import './inventory_item.dart';
import './inventory_service.dart';

void showInventoryModal({
  required BuildContext context,
}) {
  showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) => const _InventoryModal(),
  );
}

class _InventoryModal extends StatelessWidget {
  const _InventoryModal();

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final dialogWidth = screenSize.width < 600 ? screenSize.width * 0.9 : 520.0;
    final dialogHeight = screenSize.height < 760 ? screenSize.height * 0.72 : 620.0;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: SizedBox(
        width: dialogWidth,
        height: dialogHeight,
        // Im still not entirely comftorable with their future system
        // This pattern was copied from a tutorial but it seems to work :)
        child: FutureBuilder<List<InventoryItem>>(
          future: InventoryService.instance.fetchInventory(),
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Text("No Data!");
            }

            final items = snapshot.data ?? <InventoryItem>[];
            if (items.isEmpty) {
              return const Text("You have no items, go visit the Meowket to buy some!");
            }

            return _InventoryModalCard(items: items);
          },
        ),
      ),
    );
  }
}

/// This actually renders the list items
class _InventoryModalCard extends StatelessWidget {
  const _InventoryModalCard({required this.items});
  final List<InventoryItem> items;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: const BorderRadius.all(Radius.circular(28)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          const _InventoryHeader(),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final inv = items[index];
                // SEE HERE FOR DATA FELLOW GROUP MEMBER 
                return ListTile(
                  dense: true,
                  title: Text(inv.item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("ID: ${inv.item.id} | Tag: ${inv.item.tag}"),
                  trailing: Text("Qty: ${inv.quantity}", style: const TextStyle(color: Colors.blueGrey)),
                  leading: const Icon(FontAwesomeIcons.box, size: 16),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _InventoryHeader extends StatelessWidget {
  const _InventoryHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 14, 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color.fromARGB(255, 73, 20, 220), Color.fromARGB(255, 215, 69, 24)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pawket',
                  style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

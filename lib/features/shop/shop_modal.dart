import 'package:flutter/material.dart';
import './shop_item.dart';
import './shop_service.dart';

void showShopModal({
  required BuildContext context,
  required Function(ShopItem) onItemTap,
}) {
  final screenSize = MediaQuery.of(context).size;

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Meowket'),
      content: SizedBox(
        width: screenSize.width * 0.75,
        height: screenSize.height * 0.65,
        child: FutureBuilder<List<ShopItem>>(
          future: ShopService.loadShopAssets(),
          builder: (context, snapshot) {
            // Loading bar while we wait for json to be parsed
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            
          final items = snapshot.data!;
            return ListView.separated(
              itemCount: items.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final item = items[index];
                return ListTile(
                  title: Text(item.name),
                  subtitle: Text("${item.price} Gold"),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    onItemTap(item);
                    Navigator.pop(context);
                  },
                );
              },
            );
          },
        ),
      ),
    ),
  );
}
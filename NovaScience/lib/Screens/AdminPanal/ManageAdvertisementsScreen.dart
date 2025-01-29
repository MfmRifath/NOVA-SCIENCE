// screens/ManageAdvertisementsScreen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../Modals/Advertisment.dart';
import '../../Service/AdvertisementProvider.dart';
import 'AdvertisementForm.dart';


class ManageAdvertisementsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final advertisementProvider = Provider.of<AdvertisementProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Advertisements'),
      ),
      body: advertisementProvider.isLoading
          ? Center(child: CircularProgressIndicator())
          : advertisementProvider.error != null
          ? Center(
        child: Text(
          'Error: ${advertisementProvider.error}',
          style: TextStyle(color: Colors.red),
        ),
      )
          : ListView.builder(
        itemCount: advertisementProvider.advertisements.length,
        itemBuilder: (context, index) {
          final ad = advertisementProvider.advertisements[index];
          return AdvertisementListItem(advertisement: ad);
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Open the add advertisement form
          showDialog(
            context: context,
            builder: (context) => AdvertisementForm(),
          );
        },
        child: Icon(Icons.add),
        tooltip: 'Add Advertisement',
      ),
    );
  }
}

class AdvertisementListItem extends StatelessWidget {
  final Advertisement advertisement;

  AdvertisementListItem({required this.advertisement});

  @override
  Widget build(BuildContext context) {
    final advertisementProvider = Provider.of<AdvertisementProvider>(context, listen: false);

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
      child: ListTile(
        leading: advertisement.type == AdvertisementType.image
            ? Image.network(
          advertisement.imageUrl,
          width: 60,
          height: 60,
          fit: BoxFit.cover,
        )
            : Icon(Icons.video_library, size: 60, color: Colors.blueAccent),
        title: Text(advertisement.type == AdvertisementType.image ? 'Image Ad' : 'Video Ad'),
        subtitle: Text(advertisement.link.isNotEmpty ? advertisement.link : 'No Link Provided'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.edit, color: Colors.orange),
              tooltip: 'Edit Advertisement',
              onPressed: () {
                // Open the edit advertisement form
                showDialog(
                  context: context,
                  builder: (context) => AdvertisementForm(advertisement: advertisement),
                );
              },
            ),
            IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
              tooltip: 'Delete Advertisement',
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('Delete Advertisement'),
                    content: Text('Are you sure you want to delete this advertisement?'),
                    actions: [
                      TextButton(
                        child: Text('Cancel'),
                        onPressed: () => Navigator.of(context).pop(false),
                      ),
                      TextButton(
                        child: Text('Delete'),
                        onPressed: () => Navigator.of(context).pop(true),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  await advertisementProvider.deleteAdvertisement(advertisement.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Advertisement deleted')),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
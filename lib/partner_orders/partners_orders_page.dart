import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart'; 

class PartnersOrdersPage extends StatelessWidget {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  PartnersOrdersPage({super.key});

  Future<void> _updateOrderStatus(String orderId, String newStatus) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({'orderStatus': newStatus});
      
    } catch (e) {
      // TODO: Show error message to user
      // For now, silently handle the error to avoid crashes
    }
  }

  @override
  Widget build(BuildContext context) {
    final String? partnerId = _auth.currentUser?.uid;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Assigned Orders', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.teal.shade800,
        elevation: 2,
        iconTheme: IconThemeData(color: colorScheme.onPrimary),
        titleTextStyle: TextStyle(color: colorScheme.onPrimary, fontSize: 18),
      ),
      backgroundColor: colorScheme.surface,
      body: partnerId == null
          ? Center(child: Text('Please log in as a partner to see your orders.', style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.7))))
          : StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('orders')
                  .where('partnerId', isEqualTo: partnerId)
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Something went wrong: ${snapshot.error}', style: TextStyle(color: colorScheme.error)));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator(color: Colors.teal.shade800));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text('No orders received yet.', style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.7))));
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final orderDoc = snapshot.data!.docs[index];
                    final orderData = orderDoc.data() as Map<String, dynamic>;
                    final orderId = orderDoc.id;
                    final userId = orderData['userId'] as String?;
                    final orderStatus = orderData['orderStatus'] as String?;
                    final createdAt = (orderData['createdAt'] as Timestamp?)?.toDate();
                    final companyName = orderData['companyName']; 

                    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                      future: _firestore.collection('users').doc(userId).get(),
                      builder: (context, userSnapshot) {
                        final userData = userSnapshot.data?.data();
                        final userName = userData?['name'] as String?;
                        final userLatitude = userData?['latitude'];
                        final userLongitude = userData?['longitude'];

                        if (userLatitude != null && userLongitude != null) {
                        }

                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                spreadRadius: 1,
                                blurRadius: 5,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.notifications_active_outlined, color: Colors.teal.shade700, size: 32),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(userName ?? 'New Order', style: TextStyle(fontWeight: FontWeight.w500, color: colorScheme.onSurface)),
                                          const SizedBox(height: 4),
                                          if (userId != null)
                                            Text('User ID: ${userId.substring(0, 8)}...', style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 12)),
                                          if (createdAt != null)
                                            Text(
                                              'Time: ${DateFormat('MMM d, h:mm a').format(createdAt.toLocal())}',
                                              style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 12),
                                            ),
                                          if (orderStatus != null)
                                            Text('Status: $orderStatus', style: TextStyle(color: _getStatusColor(orderStatus, colorScheme), fontWeight: FontWeight.w400)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    if (orderStatus == 'pending')
                                      ElevatedButton.icon(
                                        onPressed: () => _updateOrderStatus(orderId, 'accepted'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green.shade500,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                        ),
                                        icon: const Icon(Icons.check_circle_outline, size: 20),
                                        label: const Text('Accept'),
                                      ),
                                    const SizedBox(width: 8.0),
                                    if (orderStatus == 'pending')
                                      OutlinedButton.icon(
                                        onPressed: () => _updateOrderStatus(orderId, 'cancelled'),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.red.shade500,
                                          side: BorderSide(color: Colors.red.shade500),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                        ),
                                        icon: const Icon(Icons.cancel_outlined, size: 20),
                                        label: const Text('Cancel'),
                                      ),
                                    const SizedBox(width: 8.0),
                                    IconButton(
                                      icon: const Icon(Icons.info_outline),
                                      color: colorScheme.secondary,
                                      onPressed: () async {
                                        if (userId != null) {
                                          final userDoc = await _firestore.collection('users').doc(userId).get();
                                          final userData = userDoc.data();

                                          String userNameInDialog = userName ?? 'User Info Not Available';
                                          String userPhoneInDialog = userData?['phone'] as String? ?? 'Number not available'; 
                                          String userLocationInDialog = 'Location not available';

                                          if (userData != null) {
                                            final latitude = userData['latitude'];
                                            final longitude = userData['longitude'];

                                            if (latitude != null && longitude != null) {
                                              userLocationInDialog = 'Lat: ${latitude.toStringAsFixed(2)}, Lng: ${longitude.toStringAsFixed(2)}';
                                            }
                                          }

                                          showDialog(
                                            context: context,
                                            builder: (BuildContext dialogContext) {
                                              return AlertDialog(
                                                title: const Text('Order Details'),
                                                content: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Text('User: $userNameInDialog'),
                                                    Text('User ID: ${userId.substring(0, 8)}...'),
                                                    if (companyName != null) Text('Company: $companyName'),
                                                    Text(userLocationInDialog),
                                                    Text('Phone: $userPhoneInDialog'),
                                                    if (orderStatus != null) Text('Status: $orderStatus'),
                                                  ],
                                                ),
                                                actions: <Widget>[
                                                  TextButton(
                                                    child: const Text('Close'),
                                                    onPressed: () {
                                                      Navigator.of(dialogContext).pop();
                                                    },
                                                  ),
                                                ],
                                              );
                                            },
                                          );
                                        } else {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('User information not available.')),
                                          );
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
    );
  }

  Color _getStatusColor(String? status, ColorScheme colorScheme) {
    switch (status?.toLowerCase()) {
      case 'pending':
        return Colors.orange.shade700;
      case 'processing':
        return colorScheme.secondary;
      case 'shipped':
        return Colors.blue.shade700;
      case 'delivered':
        return Colors.green.shade700;
      case 'cancelled':
        return Colors.red.shade700;
      case 'accepted':
        return Colors.green.shade700;
      default:
        return colorScheme.onSurface.withValues(alpha: 0.6);
    }
  }
}
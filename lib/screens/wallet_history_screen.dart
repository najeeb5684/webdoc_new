

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart'; // Import intl for date formatting

import '../models/wallet_history_response.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_styles.dart';
import '../utils/global.dart';

class WalletHistoryScreen extends StatefulWidget {
  final String patientId;

  const WalletHistoryScreen({Key? key, required this.patientId})
      : super(key: key);

  @override
  _WalletHistoryScreenState createState() => _WalletHistoryScreenState();
}

class _WalletHistoryScreenState extends State<WalletHistoryScreen> {
  WalletHistoryResponse? walletHistory;
  bool _isLoading = false;
  final ApiService apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _loadWalletHistory();
  }

  Future<void> _loadWalletHistory() async {
    setState(() {
      _isLoading = true;
    });
    walletHistory = await apiService.getWalletHistory(context, widget.patientId);
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundColor,
        title: Row(
          children: [
            IconButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                icon: const Icon(Icons.arrow_back_ios,
                    color: Colors.black, size: 16)),
            Text('Wallet History',
                style: AppStyles.bodyLarge(context)
                    .copyWith(color: Colors.black, fontWeight: FontWeight.bold)),
          ],
        ),
        automaticallyImplyLeading: false,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: AppColors.primaryColor))
          : walletHistory == null
          ? Center(child: Text('Failed to load wallet history.'))
          : Column(
        children: [
          // Balance Card
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primaryColorLight,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryColor.withOpacity(0.5),
                  spreadRadius: 2,
                  blurRadius: 7,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(
                  FontAwesomeIcons.wallet, // Wallet Icon
                  size: 30,
                  color: AppColors.primaryColor,
                ),
                SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Wallet Balance',
                        style: AppStyles.titleMedium(context)
                            .copyWith(color: AppColors.primaryTextColor)),
                    SizedBox(height: 8),
                    Text(
                        'PKR/-${walletHistory!.payLoad.balance}', // Display balance with currency
                        style: AppStyles.titleMedium(context)
                            .copyWith(color: AppColors.primaryColor)),
                  ],
                ),
              ],
            ),
          ),
          // Transaction History List
          Expanded(
            child: walletHistory!.payLoad.transactions.isEmpty
                ? Center(child: Text('No transactions found.'))
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: walletHistory!.payLoad.transactions.length,
              itemBuilder: (context, index) {
                final transaction =
                walletHistory!.payLoad.transactions[index];
                // Format the date and time
                final parsedDate = DateFormat('dd-MMM-yyyy').parse(transaction.AppointmentDate);
                final formattedDate = DateFormat('MMM dd, yyyy').format(parsedDate); // Format date
                final formattedTime = transaction.AppointmentTime; // Time is already formatted
                final isDebit = transaction.Type == 'Debit';

                return Container(
                  decoration: BoxDecoration(
                    color: AppColors.primaryColorLight,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.primaryColor.withOpacity(0.2),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 3,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          transaction.DoctorName.replaceAll(".", ""),
                          style: AppStyles.titleSmall(context).copyWith(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 8),

                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 14,
                              color: AppColors.secondaryTextColor,
                            ),
                            SizedBox(width: 4),
                            Text(
                              formattedDate, // Display only Date
                              style: AppStyles.bodyMedium(context)
                                  .copyWith(color: AppColors.secondaryTextColor),
                            ),
                          ],
                        ),

                        SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 14,
                              color: AppColors.secondaryTextColor,
                            ),
                            SizedBox(width: 4),
                            Text(
                              formattedTime, // Display only Time
                              style: AppStyles.bodyMedium(context)
                                  .copyWith(color: AppColors.secondaryTextColor),
                            ),
                          ],
                        ),

                        SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Icon(
                                    isDebit ? FontAwesomeIcons.arrowDown : FontAwesomeIcons.arrowUp,
                                    size: 16,
                                    color: isDebit ? Colors.red : Colors.green,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    isDebit ? 'Debit' : 'Credit',
                                    style: AppStyles.bodyMedium(context)
                                        .copyWith(color: AppColors.primaryTextColor, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: isDebit ? Colors.red.withOpacity(0.2) : Colors.green.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(25),
                                border: Border.all(
                                  color: isDebit ? Colors.red : Colors.green,
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                'PKR/-${transaction.Balance}',
                                style: AppStyles.bodySmall(context).copyWith(
                                  color: isDebit ? Colors.red : Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}






import 'package:Webdoc/theme/app_colors.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/profile_model.dart';
import '../services/api_service.dart';
import '../theme/app_styles.dart';
import '../utils/shared_preferences.dart';
import 'package:flutter/services.dart';

class EditProfileScreen extends StatefulWidget {
  final Profile profile;

  EditProfileScreen({Key? key, required this.profile}) : super(key: key);

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController? _nameController;
  TextEditingController? _dobController;
  TextEditingController? _weightController;
  TextEditingController? _heightFeetController;
  TextEditingController? _heightInchController;

  String? _gender;
  String? _maritalStatus;
  int _age = 1;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
        text: widget.profile.payLoad.firstName ?? '');
    _dobController = TextEditingController(
        text: widget.profile.payLoad.dateOfBirth ?? '');
    _weightController = TextEditingController(
        text: (widget.profile.payLoad.weight ?? '0 kg')
            .replaceAll('kg', '')
            .trim());

    String height = widget.profile.payLoad.height ?? '';
    String feet = '', inches = '';

    if (height.isNotEmpty) {
      height = height.replaceAll('ft', '').replaceAll('inch', '').trim();
      List<String> parts = height.split(' ');
      if (parts.isNotEmpty) {
        feet = parts[0];
        inches = parts.length > 1 ? parts[1] : '';
      }
    }

    _heightFeetController = TextEditingController(text: feet);
    _heightInchController = TextEditingController(text: inches);

    _gender = widget.profile.payLoad.gender == 'Male' ||
        widget.profile.payLoad.gender == 'Female'
        ? widget.profile.payLoad.gender
        : null;

    _maritalStatus = widget.profile.payLoad.martialStatus == 'Single' ||
        widget.profile.payLoad.martialStatus == 'Married'
        ? widget.profile.payLoad.martialStatus
        : null;
    _age = int.tryParse(
        (widget.profile.payLoad.age ?? '1 year').replaceAll('year', '').trim()) ??
        1;
  }

  @override
  void dispose() {
    _nameController?.dispose();
    _dobController?.dispose();
    _weightController?.dispose();
    _heightFeetController?.dispose();
    _heightInchController?.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: AppColors.primaryColor,
            colorScheme: ColorScheme.light(primary: AppColors.primaryColor),
            buttonTheme: const ButtonThemeData(textTheme: ButtonTextTheme.primary),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _dobController!.text = DateFormat('MMM dd yyyy').format(picked);
      });
    }
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      setState(() {
        _isSaving = true;
      });

      try {
        final apiService = ApiService();
        final phoneNumber = SharedPreferencesManager.getString('mobileNumber');
        if (phoneNumber != null) {
          final email = SharedPreferencesManager.getString('id') ?? '';
          final updateResponse = await apiService.updatePatientProfile(
            context: context,
            id: email,
            firstName: _nameController!.text,
            gender: _gender!,
            mobileNumber: phoneNumber,
            lastName: ".",
            address: "-",
            city: "-",
            country: "-",
            cnic: "000000000000",
            maritalStatus: _maritalStatus!,
            dateOfBirth: _dobController!.text,
            age: '$_age year',
            weight: '${_weightController!.text}kg',
            height:
            '${_heightFeetController!.text}ft ${_heightInchController!.text}inch',

          );

          if (updateResponse != null) {
            SharedPreferencesManager.putString('name', _nameController!.text);
            Navigator.pop(context, true);
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Profile updated successfully!')));
          } else {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Failed to update profile. Please try again.')));
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Phone number not found. Cannot update profile.')));
        }
      } catch (e) {
        print('Error updating profile: $e');
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('An error occurred. Please try again later.')));
      } finally {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.backgroundColor,
        title:  Row(
          children: [
            IconButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.arrow_back_ios,color: Colors.black,size: 16)),
            Text(
                'Edit Profile',
                style: AppStyles.bodyLarge(context).copyWith(color: Colors.black,fontWeight: FontWeight.bold)
            ),
          ],
        ),
        automaticallyImplyLeading: false,
      ),
      backgroundColor: AppColors.backgroundColor,
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12.0),
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            spreadRadius: 1,
                            blurRadius: 7,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: TextFormField(
                        controller: _nameController,
                        style: AppStyles.bodyMedium(context).copyWith(
                            color: AppColors.primaryTextColor,
                            fontWeight: FontWeight.w500),
                        decoration: InputDecoration(
                          labelText: 'Name',
                          labelStyle: AppStyles.bodyMedium(context).copyWith(
                              color: AppColors.secondaryTextColor,
                              fontWeight: FontWeight.w400),
                          border: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: AppColors.primaryColor, width: 1.0), // Always primary color
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          enabledBorder: OutlineInputBorder(  // Added this
                            borderSide: BorderSide(
                                color: AppColors.primaryColor, width: 1.0),
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: AppColors.primaryColor, width: 1.0),
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          floatingLabelBehavior: FloatingLabelBehavior.always,
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 14.0, horizontal: 16.0),
                          filled: true,
                          fillColor: AppColors
                              .backgroundColor,
                        ),
                        validator: (value) => value == null || value.isEmpty
                            ? 'Please enter your name'
                            : null,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12.0),
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            spreadRadius: 1,
                            blurRadius: 7,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: TextFormField(
                        controller: _dobController,
                        style: AppStyles.bodyMedium(context).copyWith(
                            color: AppColors.primaryTextColor,
                            fontWeight: FontWeight.w500),
                        decoration: InputDecoration(
                          labelText: 'Date of Birth',
                          labelStyle: AppStyles.bodyMedium(context).copyWith(
                              color: AppColors.secondaryTextColor,
                              fontWeight: FontWeight.w400),
                          suffixIcon: Icon(Icons.calendar_today,
                              color: AppColors.iconColor),
                          border: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: AppColors.primaryColor, width: 1.0), // Always primary color
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          enabledBorder: OutlineInputBorder(  // Added this
                            borderSide: BorderSide(
                                color: AppColors.primaryColor, width: 1.0),
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: AppColors.primaryColor, width: 1.0),
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          floatingLabelBehavior: FloatingLabelBehavior.always,
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 14.0, horizontal: 16.0),
                          filled: true,
                          fillColor: AppColors.backgroundColor,
                        ),
                        readOnly: true,
                        onTap: () => _selectDate(context),
                        validator: (value) => value == null || value.isEmpty
                            ? 'Please enter your date of birth'
                            : null,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12.0),
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            spreadRadius: 1,
                            blurRadius: 7,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: DropdownButtonFormField<String>(
                        value: _gender,
                        style: AppStyles.bodyMedium(context).copyWith(
                            color: AppColors.primaryTextColor,
                            fontWeight: FontWeight.w500),
                        decoration: InputDecoration(
                          labelText: 'Gender',
                          labelStyle: AppStyles.bodyMedium(context).copyWith(
                              color: AppColors.secondaryTextColor,
                              fontWeight: FontWeight.w400),
                          border: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: AppColors.primaryColor, width: 1.0), // Always primary color
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          enabledBorder: OutlineInputBorder(  // Added this
                            borderSide: BorderSide(
                                color: AppColors.primaryColor, width: 1.0),
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: AppColors.primaryColor, width: 1.0),
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          floatingLabelBehavior: FloatingLabelBehavior.always,
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 8.0, horizontal: 16.0),
                          filled: true,
                          fillColor: AppColors.backgroundColor,
                        ),
                        items: ['Male', 'Female']
                            .map((label) => DropdownMenuItem(
                          value: label,
                          child: Text(label,
                              style: AppStyles.bodyMedium(context).copyWith(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.primaryTextColor)),
                        ))
                            .toList(),
                        onChanged: (value) => setState(() => _gender = value),
                        validator: (value) => value == null || value.isEmpty
                            ? 'Please select your gender'
                            : null,
                        isExpanded: true,
                        icon: Icon(Icons.arrow_drop_down,
                            color: AppColors.iconColor),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12.0),
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            spreadRadius: 1,
                            blurRadius: 7,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: DropdownButtonFormField<String>(
                        value: _maritalStatus,
                        style: AppStyles.bodyMedium(context).copyWith(
                            color: AppColors.primaryTextColor,
                            fontWeight: FontWeight.w500),
                        decoration: InputDecoration(
                          labelText: 'Marital Status',
                          labelStyle: AppStyles.bodyMedium(context).copyWith(
                              color: AppColors.secondaryTextColor,
                              fontWeight: FontWeight.w400),
                          border: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: AppColors.primaryColor, width: 1.0),  // Always primary color
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          enabledBorder: OutlineInputBorder(  // Added this
                            borderSide: BorderSide(
                                color: AppColors.primaryColor, width: 1.0),
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: AppColors.primaryColor, width: 1.0),
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          floatingLabelBehavior: FloatingLabelBehavior.always,
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 8.0, horizontal: 16.0),
                          filled: true,
                          fillColor: AppColors.backgroundColor,
                        ),
                        items: ['Single', 'Married']
                            .map((label) => DropdownMenuItem(
                          value: label,
                          child: Text(label,
                              style: AppStyles.bodyMedium(context).copyWith(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.primaryTextColor)),
                        ))
                            .toList(),
                        onChanged: (value) =>
                            setState(() => _maritalStatus = value),
                        validator: (value) => value == null || value.isEmpty
                            ? 'Please select your marital status'
                            : null,
                        isExpanded: true,
                        icon: Icon(Icons.arrow_drop_down,
                            color: AppColors.iconColor),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12.0),
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            spreadRadius: 1,
                            blurRadius: 7,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: TextFormField(
                        controller: _weightController,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.done,
                        style: AppStyles.bodyMedium(context).copyWith(
                            color: AppColors.primaryTextColor,
                            fontWeight: FontWeight.w500),
                        decoration: InputDecoration(
                          labelText: 'Weight (kg)',
                          labelStyle: AppStyles.bodyMedium(context).copyWith(
                              color: AppColors.secondaryTextColor,
                              fontWeight: FontWeight.w400),
                          border: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: AppColors.primaryColor, width: 1.0),  // Always primary color
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          enabledBorder: OutlineInputBorder(  // Added this
                            borderSide: BorderSide(
                                color: AppColors.primaryColor, width: 1.0),
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: AppColors.primaryColor, width: 1.0),
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          floatingLabelBehavior: FloatingLabelBehavior.always,
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 14.0, horizontal: 16.0),
                          filled: true,
                          fillColor: AppColors.backgroundColor,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your weight';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Please enter a valid number for weight';
                          }
                          return null;
                        },
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(3),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12.0),
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  spreadRadius: 1,
                                  blurRadius: 7,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: TextFormField(
                              controller: _heightFeetController,
                              keyboardType: TextInputType.number,
                              textInputAction: TextInputAction.done,
                              style: AppStyles.bodyMedium(context).copyWith(
                                  color: AppColors.primaryTextColor,
                                  fontWeight: FontWeight.w500),
                              decoration: InputDecoration(
                                labelText: 'Height (Feet)',
                                labelStyle: AppStyles.bodyMedium(context).copyWith(
                                    color: AppColors.secondaryTextColor,
                                    fontWeight: FontWeight.w400),
                                border: OutlineInputBorder(
                                  borderSide: BorderSide(
                                      color: AppColors.primaryColor, width: 1.0),  // Always primary color
                                  borderRadius: BorderRadius.circular(12.0),
                                ),
                                enabledBorder: OutlineInputBorder(  // Added this
                                  borderSide: BorderSide(
                                      color: AppColors.primaryColor, width: 1.0),
                                  borderRadius: BorderRadius.circular(12.0),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                      color: AppColors.primaryColor, width: 1.0),
                                  borderRadius: BorderRadius.circular(12.0),
                                ),
                                floatingLabelBehavior:
                                FloatingLabelBehavior.always,
                                contentPadding: const EdgeInsets.symmetric(
                                    vertical: 14.0, horizontal: 16.0),
                                filled: true,
                                fillColor: AppColors.backgroundColor,
                              ),
                              validator: (value) => value == null || value.isEmpty
                                  ? 'Please enter feet'
                                  : null,
                              inputFormatters: [
                                LengthLimitingTextInputFormatter(1),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12.0),
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  spreadRadius: 1,
                                  blurRadius: 7,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: TextFormField(
                              controller: _heightInchController,
                              keyboardType: TextInputType.number,
                              textInputAction: TextInputAction.done,
                              style: AppStyles.bodyMedium(context).copyWith(
                                  color: AppColors.primaryTextColor,
                                  fontWeight: FontWeight.w500),
                              decoration: InputDecoration(
                                labelText: 'Height (Inches)',
                                labelStyle: AppStyles.bodyMedium(context).copyWith(
                                    color: AppColors.secondaryTextColor,
                                    fontWeight: FontWeight.w400),
                                border: OutlineInputBorder(
                                  borderSide: BorderSide(
                                      color: AppColors.primaryColor, width: 1.0),  // Always primary color
                                  borderRadius: BorderRadius.circular(12.0),
                                ),
                                enabledBorder: OutlineInputBorder(  // Added this
                                  borderSide: BorderSide(
                                      color: AppColors.primaryColor, width: 1.0),
                                  borderRadius: BorderRadius.circular(12.0),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                      color: AppColors.primaryColor, width: 1.0),
                                  borderRadius: BorderRadius.circular(12.0),
                                ),
                                floatingLabelBehavior:
                                FloatingLabelBehavior.always,
                                contentPadding: const EdgeInsets.symmetric(
                                    vertical: 14.0, horizontal: 16.0),
                                filled: true,
                                fillColor: AppColors.backgroundColor,
                              ),
                              validator: (value) => value == null || value.isEmpty
                                  ? 'Please enter inches'
                                  : null,
                              inputFormatters: [
                                LengthLimitingTextInputFormatter(2),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Age',
                      style: AppStyles.bodyMedium(context).copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.primaryTextColor),
                    ),
                    SizedBox(
                      height: 120,
                      child: CupertinoPicker(
                        itemExtent: 32,
                        onSelectedItemChanged: (index) {
                          setState(() {
                            _age = index + 1;
                          });
                        },
                        scrollController: FixedExtentScrollController(
                            initialItem: _age - 1),
                        children: List.generate(
                            100,
                                (index) =>
                                Center(
                                    child: Text((index + 1).toString(),
                                        style: AppStyles.bodyMedium(context).copyWith(
                                            fontSize: 14,
                                            color: AppColors.primaryTextColor)))),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            if (_isSaving)
              Container(
                color: Colors.black.withOpacity(0.5),
                child: const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.primaryColor),
                  ),
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.only(
          left: 20.0,
          right: 20.0,
          top: 0,
          bottom: 2 + MediaQuery.of(context).padding.bottom, // Add bottom padding
        ),
        decoration: BoxDecoration(
          color: Colors.transparent,
          /* border: Border(
              top: BorderSide(color: Colors.grey[200]!, width: 1.0)),*/
        ),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
              textStyle: AppStyles.bodyLarge(context).copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.white),
            ),
            onPressed: _isSaving ? null : _saveProfile,
            child: _isSaving
                ? const Text('Saving...')
                : const Text('Save Profile'),
          ),
        ),
      ),
    );
  }
}




/*import 'package:Webdoc/theme/app_colors.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/profile_model.dart';
import '../services/api_service.dart';
import '../theme/app_styles.dart';
import '../utils/shared_preferences.dart';
import 'package:flutter/services.dart';

class EditProfileScreen extends StatefulWidget {
  final Profile profile;

  EditProfileScreen({Key? key, required this.profile}) : super(key: key);

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController? _nameController;
  TextEditingController? _dobController;
  TextEditingController? _weightController;
  TextEditingController? _heightFeetController;
  TextEditingController? _heightInchController;

  String? _gender;
  String? _maritalStatus;
  int _age = 1;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
        text: widget.profile.payLoad.firstName ?? '');
    _dobController = TextEditingController(
        text: widget.profile.payLoad.dateOfBirth ?? '');
    _weightController = TextEditingController(
        text: (widget.profile.payLoad.weight ?? '0 kg')
            .replaceAll('kg', '')
            .trim());

    String height = widget.profile.payLoad.height ?? '';
    String feet = '', inches = '';

    if (height.isNotEmpty) {
      height = height.replaceAll('ft', '').replaceAll('inch', '').trim();
      List<String> parts = height.split(' ');
      if (parts.isNotEmpty) {
        feet = parts[0];
        inches = parts.length > 1 ? parts[1] : '';
      }
    }

    _heightFeetController = TextEditingController(text: feet);
    _heightInchController = TextEditingController(text: inches);

    _gender = widget.profile.payLoad.gender == 'Male' ||
        widget.profile.payLoad.gender == 'Female'
        ? widget.profile.payLoad.gender
        : null;

    _maritalStatus = widget.profile.payLoad.martialStatus == 'Single' ||
        widget.profile.payLoad.martialStatus == 'Married'
        ? widget.profile.payLoad.martialStatus
        : null;
    _age = int.tryParse(
        (widget.profile.payLoad.age ?? '1 year').replaceAll('year', '').trim()) ??
        1;
  }

  @override
  void dispose() {
    _nameController?.dispose();
    _dobController?.dispose();
    _weightController?.dispose();
    _heightFeetController?.dispose();
    _heightInchController?.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: AppColors.primaryColor,
            colorScheme: ColorScheme.light(primary: AppColors.primaryColor),
            buttonTheme: const ButtonThemeData(textTheme: ButtonTextTheme.primary),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _dobController!.text = DateFormat('MMM dd yyyy').format(picked);
      });
    }
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      setState(() {
        _isSaving = true;
      });

      try {
        final apiService = ApiService();
        final phoneNumber = SharedPreferencesManager.getString('mobileNumber');
        if (phoneNumber != null) {
          final email = SharedPreferencesManager.getString('id') ?? '';
          final updateResponse = await apiService.updatePatientProfile(
            context: context,
            id: email,
            firstName: _nameController!.text,
            gender: _gender!,
            mobileNumber: phoneNumber,
            lastName: ".",
            address: "-",
            city: "-",
            country: "-",
            cnic: "000000000000",
            maritalStatus: _maritalStatus!,
            dateOfBirth: _dobController!.text,
            age: '$_age year',
            weight: '${_weightController!.text}kg',
            height:
            '${_heightFeetController!.text}ft ${_heightInchController!.text}inch',

          );

          if (updateResponse != null) {
            SharedPreferencesManager.putString('name', _nameController!.text);
            Navigator.pop(context, true);
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Profile updated successfully!')));
          } else {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Failed to update profile. Please try again.')));
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Phone number not found. Cannot update profile.')));
        }
      } catch (e) {
        print('Error updating profile: $e');
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('An error occurred. Please try again later.')));
      } finally {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.backgroundColor,
        title:  Row(
          children: [
            IconButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.arrow_back_ios,color: Colors.black,size: 16)),
            Text(
                'Edit Profile',
                style: AppStyles.bodyLarge(context).copyWith(color: Colors.black,fontWeight: FontWeight.bold)
            ),
          ],
        ),
        automaticallyImplyLeading: false,
      ),
      backgroundColor: AppColors.backgroundColor,
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12.0),
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            spreadRadius: 1,
                            blurRadius: 7,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: TextFormField(
                        controller: _nameController,
                        style: AppStyles.bodyMedium(context).copyWith(
                            color: AppColors.primaryTextColor,
                            fontWeight: FontWeight.w500),
                        decoration: InputDecoration(
                          labelText: 'Name',
                          labelStyle: AppStyles.bodyMedium(context).copyWith(
                              color: AppColors.secondaryTextColor,
                              fontWeight: FontWeight.w400),
                          border: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: AppColors.primaryColor, width: 1.0), // Always primary color
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          enabledBorder: OutlineInputBorder(  // Added this
                            borderSide: BorderSide(
                                color: AppColors.primaryColor, width: 1.0),
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: AppColors.primaryColor, width: 1.0),
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          floatingLabelBehavior: FloatingLabelBehavior.always,
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 14.0, horizontal: 16.0),
                          filled: true,
                          fillColor: AppColors
                              .backgroundColor,
                        ),
                        validator: (value) => value == null || value.isEmpty
                            ? 'Please enter your name'
                            : null,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12.0),
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            spreadRadius: 1,
                            blurRadius: 7,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: TextFormField(
                        controller: _dobController,
                        style: AppStyles.bodyMedium(context).copyWith(
                            color: AppColors.primaryTextColor,
                            fontWeight: FontWeight.w500),
                        decoration: InputDecoration(
                          labelText: 'Date of Birth',
                          labelStyle: AppStyles.bodyMedium(context).copyWith(
                              color: AppColors.secondaryTextColor,
                              fontWeight: FontWeight.w400),
                          suffixIcon: Icon(Icons.calendar_today,
                              color: AppColors.iconColor),
                          border: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: AppColors.primaryColor, width: 1.0), // Always primary color
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          enabledBorder: OutlineInputBorder(  // Added this
                            borderSide: BorderSide(
                                color: AppColors.primaryColor, width: 1.0),
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: AppColors.primaryColor, width: 1.0),
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          floatingLabelBehavior: FloatingLabelBehavior.always,
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 14.0, horizontal: 16.0),
                          filled: true,
                          fillColor: AppColors.backgroundColor,
                        ),
                        readOnly: true,
                        onTap: () => _selectDate(context),
                        validator: (value) => value == null || value.isEmpty
                            ? 'Please enter your date of birth'
                            : null,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12.0),
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            spreadRadius: 1,
                            blurRadius: 7,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: DropdownButtonFormField<String>(
                        value: _gender,
                        style: AppStyles.bodyMedium(context).copyWith(
                            color: AppColors.primaryTextColor,
                            fontWeight: FontWeight.w500),
                        decoration: InputDecoration(
                          labelText: 'Gender',
                          labelStyle: AppStyles.bodyMedium(context).copyWith(
                              color: AppColors.secondaryTextColor,
                              fontWeight: FontWeight.w400),
                          border: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: AppColors.primaryColor, width: 1.0), // Always primary color
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          enabledBorder: OutlineInputBorder(  // Added this
                            borderSide: BorderSide(
                                color: AppColors.primaryColor, width: 1.0),
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: AppColors.primaryColor, width: 1.0),
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          floatingLabelBehavior: FloatingLabelBehavior.always,
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 8.0, horizontal: 16.0),
                          filled: true,
                          fillColor: AppColors.backgroundColor,
                        ),
                        items: ['Male', 'Female']
                            .map((label) => DropdownMenuItem(
                          value: label,
                          child: Text(label,
                              style: AppStyles.bodyMedium(context).copyWith(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.primaryTextColor)),
                        ))
                            .toList(),
                        onChanged: (value) => setState(() => _gender = value),
                        validator: (value) => value == null || value.isEmpty
                            ? 'Please select your gender'
                            : null,
                        isExpanded: true,
                        icon: Icon(Icons.arrow_drop_down,
                            color: AppColors.iconColor),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12.0),
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            spreadRadius: 1,
                            blurRadius: 7,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: DropdownButtonFormField<String>(
                        value: _maritalStatus,
                        style: AppStyles.bodyMedium(context).copyWith(
                            color: AppColors.primaryTextColor,
                            fontWeight: FontWeight.w500),
                        decoration: InputDecoration(
                          labelText: 'Marital Status',
                          labelStyle: AppStyles.bodyMedium(context).copyWith(
                              color: AppColors.secondaryTextColor,
                              fontWeight: FontWeight.w400),
                          border: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: AppColors.primaryColor, width: 1.0),  // Always primary color
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          enabledBorder: OutlineInputBorder(  // Added this
                            borderSide: BorderSide(
                                color: AppColors.primaryColor, width: 1.0),
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: AppColors.primaryColor, width: 1.0),
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          floatingLabelBehavior: FloatingLabelBehavior.always,
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 8.0, horizontal: 16.0),
                          filled: true,
                          fillColor: AppColors.backgroundColor,
                        ),
                        items: ['Single', 'Married']
                            .map((label) => DropdownMenuItem(
                          value: label,
                          child: Text(label,
                              style: AppStyles.bodyMedium(context).copyWith(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.primaryTextColor)),
                        ))
                            .toList(),
                        onChanged: (value) =>
                            setState(() => _maritalStatus = value),
                        validator: (value) => value == null || value.isEmpty
                            ? 'Please select your marital status'
                            : null,
                        isExpanded: true,
                        icon: Icon(Icons.arrow_drop_down,
                            color: AppColors.iconColor),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12.0),
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            spreadRadius: 1,
                            blurRadius: 7,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: TextFormField(
                        controller: _weightController,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.done,
                        style: AppStyles.bodyMedium(context).copyWith(
                            color: AppColors.primaryTextColor,
                            fontWeight: FontWeight.w500),
                        decoration: InputDecoration(
                          labelText: 'Weight (kg)',
                          labelStyle: AppStyles.bodyMedium(context).copyWith(
                              color: AppColors.secondaryTextColor,
                              fontWeight: FontWeight.w400),
                          border: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: AppColors.primaryColor, width: 1.0),  // Always primary color
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          enabledBorder: OutlineInputBorder(  // Added this
                            borderSide: BorderSide(
                                color: AppColors.primaryColor, width: 1.0),
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: AppColors.primaryColor, width: 1.0),
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          floatingLabelBehavior: FloatingLabelBehavior.always,
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 14.0, horizontal: 16.0),
                          filled: true,
                          fillColor: AppColors.backgroundColor,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your weight';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Please enter a valid number for weight';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12.0),
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  spreadRadius: 1,
                                  blurRadius: 7,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: TextFormField(
                              controller: _heightFeetController,
                              keyboardType: TextInputType.number,
                              textInputAction: TextInputAction.done,
                              style: AppStyles.bodyMedium(context).copyWith(
                                  color: AppColors.primaryTextColor,
                                  fontWeight: FontWeight.w500),
                              decoration: InputDecoration(
                                labelText: 'Height (Feet)',
                                labelStyle: AppStyles.bodyMedium(context).copyWith(
                                    color: AppColors.secondaryTextColor,
                                    fontWeight: FontWeight.w400),
                                border: OutlineInputBorder(
                                  borderSide: BorderSide(
                                      color: AppColors.primaryColor, width: 1.0),  // Always primary color
                                  borderRadius: BorderRadius.circular(12.0),
                                ),
                                enabledBorder: OutlineInputBorder(  // Added this
                                  borderSide: BorderSide(
                                      color: AppColors.primaryColor, width: 1.0),
                                  borderRadius: BorderRadius.circular(12.0),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                      color: AppColors.primaryColor, width: 1.0),
                                  borderRadius: BorderRadius.circular(12.0),
                                ),
                                floatingLabelBehavior:
                                FloatingLabelBehavior.always,
                                contentPadding: const EdgeInsets.symmetric(
                                    vertical: 14.0, horizontal: 16.0),
                                filled: true,
                                fillColor: AppColors.backgroundColor,
                              ),
                              validator: (value) => value == null || value.isEmpty
                                  ? 'Please enter feet'
                                  : null,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12.0),
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  spreadRadius: 1,
                                  blurRadius: 7,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: TextFormField(
                              controller: _heightInchController,
                              keyboardType: TextInputType.number,
                              textInputAction: TextInputAction.done,
                              style: AppStyles.bodyMedium(context).copyWith(
                                  color: AppColors.primaryTextColor,
                                  fontWeight: FontWeight.w500),
                              decoration: InputDecoration(
                                labelText: 'Height (Inches)',
                                labelStyle: AppStyles.bodyMedium(context).copyWith(
                                    color: AppColors.secondaryTextColor,
                                    fontWeight: FontWeight.w400),
                                border: OutlineInputBorder(
                                  borderSide: BorderSide(
                                      color: AppColors.primaryColor, width: 1.0),  // Always primary color
                                  borderRadius: BorderRadius.circular(12.0),
                                ),
                                enabledBorder: OutlineInputBorder(  // Added this
                                  borderSide: BorderSide(
                                      color: AppColors.primaryColor, width: 1.0),
                                  borderRadius: BorderRadius.circular(12.0),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                      color: AppColors.primaryColor, width: 1.0),
                                  borderRadius: BorderRadius.circular(12.0),
                                ),
                                floatingLabelBehavior:
                                FloatingLabelBehavior.always,
                                contentPadding: const EdgeInsets.symmetric(
                                    vertical: 14.0, horizontal: 16.0),
                                filled: true,
                                fillColor: AppColors.backgroundColor,
                              ),
                              validator: (value) => value == null || value.isEmpty
                                  ? 'Please enter inches'
                                  : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Age',
                      style: AppStyles.bodyMedium(context).copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.primaryTextColor),
                    ),
                    SizedBox(
                      height: 120,
                      child: CupertinoPicker(
                        itemExtent: 32,
                        onSelectedItemChanged: (index) {
                          setState(() {
                            _age = index + 1;
                          });
                        },
                        scrollController: FixedExtentScrollController(
                            initialItem: _age - 1),
                        children: List.generate(
                            100,
                                (index) =>
                                Center(
                                    child: Text((index + 1).toString(),
                                        style: AppStyles.bodyMedium(context).copyWith(
                                            fontSize: 14,
                                            color: AppColors.primaryTextColor)))),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            if (_isSaving)
              Container(
                color: Colors.black.withOpacity(0.5),
                child: const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.primaryColor),
                  ),
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.only(
          left: 20.0,
          right: 20.0,
          top: 0,
          bottom: 2 + MediaQuery.of(context).padding.bottom, // Add bottom padding
        ),
        decoration: BoxDecoration(
          color: Colors.transparent,
         *//* border: Border(
              top: BorderSide(color: Colors.grey[200]!, width: 1.0)),*//*
        ),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
              textStyle: AppStyles.bodyLarge(context).copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.white),
            ),
            onPressed: _isSaving ? null : _saveProfile,
            child: _isSaving
                ? const Text('Saving...')
                : const Text('Save Profile'),
          ),
        ),
      ),
    );
  }
}*/


/*
import 'package:Webdoc/theme/app_colors.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/profile_model.dart';
import '../services/api_service.dart';
import '../utils/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';

class EditProfileScreen extends StatefulWidget {
  final Profile profile;

  EditProfileScreen({Key? key, required this.profile}) : super(key: key);

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController? _nameController;
  TextEditingController? _dobController;
  TextEditingController? _weightController;
  TextEditingController? _heightFeetController;
  TextEditingController? _heightInchController;

  String? _gender;
  String? _maritalStatus;
  int _age = 1;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile.profileDetails.name ?? '');
    _dobController = TextEditingController(text: widget.profile.profileDetails.dateOfBirth ?? '');
    _weightController = TextEditingController(text: (widget.profile.profileDetails.weight ?? '0 kg').replaceAll('kg', '').trim());

    String height = widget.profile.profileDetails.height ?? '';
    String feet = '', inches = '';

    if (height.isNotEmpty) {
      height = height.replaceAll('ft', '').replaceAll('inch', '').trim();
      List<String> parts = height.split(' ');
      if (parts.isNotEmpty) {
        feet = parts[0];
        inches = parts.length > 1 ? parts[1] : '';
      }
    }

    _heightFeetController = TextEditingController(text: feet);
    _heightInchController = TextEditingController(text: inches);

    _gender = widget.profile.profileDetails.gender == 'Male' || widget.profile.profileDetails.gender == 'Female'
        ? widget.profile.profileDetails.gender
        : null;

    _maritalStatus = widget.profile.profileDetails.martialStatus == 'Single' ||  widget.profile.profileDetails.martialStatus == 'Married'
        ? widget.profile.profileDetails.martialStatus
        : null;
    _age = int.tryParse((widget.profile.profileDetails.age ?? '1 year').replaceAll('year', '').trim()) ?? 1;
  }

  @override
  void dispose() {
    _nameController?.dispose();
    _dobController?.dispose();
    _weightController?.dispose();
    _heightFeetController?.dispose();
    _heightInchController?.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: Colors.black,
            colorScheme: const ColorScheme.light(primary: Colors.black),
            buttonTheme: const ButtonThemeData(textTheme: ButtonTextTheme.primary),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _dobController!.text = DateFormat('MMM dd yyyy').format(picked);
      });
    }
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      setState(() {
        _isSaving = true;
      });

      try {
        final apiService = ApiService();
        final phoneNumber = SharedPreferencesManager.getString('mobileNumber');
        if (phoneNumber != null) {
          final email = '$phoneNumber@webdoc.com.pk';
          final updateResponse = await apiService.updatePatientProfile(
            context: context,
            email: email,
            name: _nameController!.text,
            gender: _gender!,
            mobileNumber: phoneNumber,
            maritalStatus: _maritalStatus!,
            bloodGroup: '-',
            age: '$_age year',
            weight: '${_weightController!.text}kg',
            height: '${_heightFeetController!.text}ft ${_heightInchController!.text}inch',
          );

          if (updateResponse != null) {
            SharedPreferencesManager.putString('name', _nameController!.text);
            Navigator.pop(context, true);
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated successfully!')));
          } else {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to update profile. Please try again.')));
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Phone number not found. Cannot update profile.')));
        }
      } catch (e) {
        print('Error updating profile: $e');
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('An error occurred. Please try again later.')));
      } finally {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Edit Profile", style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.black, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      backgroundColor: Colors.grey[50],
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  Container( // Added Container for Shadow
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12.0),
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          spreadRadius: 1,
                          blurRadius: 7,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: TextFormField(
                      controller: _nameController,
                      style: GoogleFonts.poppins(color: Colors.black87, fontSize: 14, fontWeight: FontWeight.w500),
                      decoration: InputDecoration(
                        labelText: 'Name',
                        labelStyle: GoogleFonts.poppins(color: Colors.black54, fontSize: 14, fontWeight: FontWeight.w400),
                        border: OutlineInputBorder(  // Add a subtle border
                          borderSide: BorderSide(color: Colors.grey[300]!, width: 1.0),
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey[300]!, width: 1.0),
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                        contentPadding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 16.0),
                        filled: true,
                        fillColor: Colors.grey[100], // Very light grey background
                      ),
                      validator: (value) => value == null || value.isEmpty ? 'Please enter your name' : null,
                    ),
                  ),
                  const SizedBox(height: 16),

                  Container( // Added Container for Shadow
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12.0),
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          spreadRadius: 1,
                          blurRadius: 7,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: TextFormField(
                      controller: _dobController,
                      style: GoogleFonts.poppins(color: Colors.black87, fontSize: 14, fontWeight: FontWeight.w500),
                      decoration: InputDecoration(
                        labelText: 'Date of Birth',
                        labelStyle: GoogleFonts.poppins(color: Colors.black54, fontSize: 14, fontWeight: FontWeight.w400),
                        suffixIcon: Icon(Icons.calendar_today, color: Colors.grey[600]),
                        border: OutlineInputBorder( // Add a subtle border
                          borderSide: BorderSide(color: Colors.grey[300]!, width: 1.0),
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey[300]!, width: 1.0),
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                        contentPadding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 16.0),
                        filled: true,
                        fillColor: Colors.grey[100],
                      ),
                      readOnly: true,
                      onTap: () => _selectDate(context),
                      validator: (value) => value == null || value.isEmpty ? 'Please enter your date of birth' : null,
                    ),
                  ),
                  const SizedBox(height: 16),

                  Container( // Added Container for Shadow
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12.0),
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          spreadRadius: 1,
                          blurRadius: 7,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: DropdownButtonFormField<String>(
                      value: _gender,
                      style: GoogleFonts.poppins(color: Colors.black87, fontSize: 14, fontWeight: FontWeight.w500),
                      decoration: InputDecoration(
                        labelText: 'Gender',
                        labelStyle: GoogleFonts.poppins(color: Colors.black54, fontSize: 14, fontWeight: FontWeight.w400),
                        border: OutlineInputBorder( // Add a subtle border
                          borderSide: BorderSide(color: Colors.grey[300]!, width: 1.0),
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey[300]!, width: 1.0),
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                        contentPadding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                        filled: true,
                        fillColor: Colors.grey[100],
                      ),
                      items: ['Male', 'Female']
                          .map((label) => DropdownMenuItem(
                        value: label,
                        child: Text(label, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500)),
                      ))
                          .toList(),
                      onChanged: (value) => setState(() => _gender = value),
                      validator: (value) => value == null || value.isEmpty ? 'Please select your gender' : null,
                      isExpanded: true,
                      icon: Icon(Icons.arrow_drop_down, color: Colors.grey[600]), // Refined icon color
                    ),
                  ),
                  const SizedBox(height: 16),

                  Container( // Added Container for Shadow
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12.0),
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          spreadRadius: 1,
                          blurRadius: 7,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: DropdownButtonFormField<String>(
                      value: _maritalStatus,
                      style: GoogleFonts.poppins(color: Colors.black87, fontSize: 14, fontWeight: FontWeight.w500),
                      decoration: InputDecoration(
                        labelText: 'Marital Status',
                        labelStyle: GoogleFonts.poppins(color: Colors.black54, fontSize: 14, fontWeight: FontWeight.w400),
                        border: OutlineInputBorder( // Add a subtle border
                          borderSide: BorderSide(color: Colors.grey[300]!, width: 1.0),
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey[300]!, width: 1.0),
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                        contentPadding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                        filled: true,
                        fillColor: Colors.grey[100],
                      ),
                      items: ['Single', 'Married']
                          .map((label) => DropdownMenuItem(
                        value: label,
                        child: Text(label, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500)),
                      ))
                          .toList(),
                      onChanged: (value) => setState(() => _maritalStatus = value),
                      validator: (value) => value == null || value.isEmpty ? 'Please select your marital status' : null,
                      isExpanded: true,
                      icon: Icon(Icons.arrow_drop_down, color: Colors.grey[600]), // Refined icon color
                    ),
                  ),
                  const SizedBox(height: 16),

                  Container( // Added Container for Shadow
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12.0),
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          spreadRadius: 1,
                          blurRadius: 7,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: TextFormField(
                      controller: _weightController,
                      keyboardType: TextInputType.number,
                      style: GoogleFonts.poppins(color: Colors.black87, fontSize: 14, fontWeight: FontWeight.w500),
                      decoration: InputDecoration(
                        labelText: 'Weight (kg)',
                        labelStyle: GoogleFonts.poppins(color: Colors.black54, fontSize: 14, fontWeight: FontWeight.w400),
                        border: OutlineInputBorder( // Add a subtle border
                          borderSide: BorderSide(color: Colors.grey[300]!, width: 1.0),
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey[300]!, width: 1.0),
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                        contentPadding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 16.0),
                        filled: true,
                        fillColor: Colors.grey[100],
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your weight';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Please enter a valid number for weight';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: Container( // Added Container for Shadow
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12.0),
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                spreadRadius: 1,
                                blurRadius: 7,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: TextFormField(
                            controller: _heightFeetController,
                            keyboardType: TextInputType.number,
                            style: GoogleFonts.poppins(color: Colors.black87, fontSize: 14, fontWeight: FontWeight.w500),
                            decoration: InputDecoration(
                              labelText: 'Height (Feet)',
                              labelStyle: GoogleFonts.poppins(color: Colors.black54, fontSize: 14, fontWeight: FontWeight.w400),
                              border: OutlineInputBorder( // Add a subtle border
                                borderSide: BorderSide(color: Colors.grey[300]!, width: 1.0),
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.grey[300]!, width: 1.0),
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                              floatingLabelBehavior: FloatingLabelBehavior.always,
                              contentPadding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 16.0),
                              filled: true,
                              fillColor: Colors.grey[100],
                            ),
                            validator: (value) => value == null || value.isEmpty ? 'Please enter feet' : null,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Container( // Added Container for Shadow
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12.0),
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                spreadRadius: 1,
                                blurRadius: 7,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: TextFormField(
                            controller: _heightInchController,
                            keyboardType: TextInputType.number,
                            style: GoogleFonts.poppins(color: Colors.black87, fontSize: 14, fontWeight: FontWeight.w500),
                            decoration: InputDecoration(
                              labelText: 'Height (Inches)',
                              labelStyle: GoogleFonts.poppins(color: Colors.black54, fontSize: 14, fontWeight: FontWeight.w400),
                              border: OutlineInputBorder( // Add a subtle border
                                borderSide: BorderSide(color: Colors.grey[300]!, width: 1.0),
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.grey[300]!, width: 1.0),
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                              floatingLabelBehavior: FloatingLabelBehavior.always,
                              contentPadding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 16.0),
                              filled: true,
                              fillColor: Colors.grey[100],
                            ),
                            validator: (value) => value == null || value.isEmpty ? 'Please enter inches' : null,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  Text(
                    'Age',
                    style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87),
                  ),
                  SizedBox(
                    height: 120,
                    child: CupertinoPicker(
                      itemExtent: 32,
                      onSelectedItemChanged: (index) {
                        setState(() {
                          _age = index + 1;
                        });
                      },
                      scrollController: FixedExtentScrollController(initialItem: _age - 1),
                      children: List.generate(100, (index) => Center(child: Text((index + 1).toString(), style: GoogleFonts.poppins(fontSize: 14)))),
                    ),
                  ),
                  const SizedBox(height: 24),

                ],
              ),
            ),
          ),
          // Loading indicator overlay
          if (_isSaving)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey[200]!, width: 1.0)),
        ),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor, // Keep the button black for emphasis
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
              textStyle: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            onPressed: _isSaving ? null : _saveProfile,
            child: _isSaving ? const Text('Saving...') : const Text('Save Profile'),
          ),
        ),
      ),
    );
  }
}*/

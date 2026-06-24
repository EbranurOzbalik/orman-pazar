import 'package:flutter/material.dart';

import '../constants/app_constants.dart';
import '../models/app_user_model.dart';
import '../models/listing_model.dart';
import '../services/auth_service.dart';
import '../services/listing_service.dart';
import '../services/user_service.dart';

class AddListingScreen extends StatefulWidget {
  const AddListingScreen({super.key});

  @override
  State<AddListingScreen> createState() => _AddListingScreenState();
}

class _AddListingScreenState extends State<AddListingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  final _priceController = TextEditingController();
  final _cityController = TextEditingController();
  final _districtController = TextEditingController();
  final _phoneController = TextEditingController();

  final ListingService _listingService = ListingService();
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();

  String _category = AppConstants.categories.first;
  String _woodType = AppConstants.woodTypes.first;
  String _unit = AppConstants.units.first;
  String _moistureStatus = AppConstants.moistureStatuses.first;
  bool _hasDelivery = false;
  bool _isSaving = false;
  bool _isPrefillingProfile = true;

  @override
  void initState() {
    super.initState();
    _prefillFromProfile();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _amountController.dispose();
    _priceController.dispose();
    _cityController.dispose();
    _districtController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _prefillFromProfile() async {
    final user = _authService.currentUser;
    if (user == null) {
      if (mounted) {
        setState(() => _isPrefillingProfile = false);
      }
      return;
    }

    final profile = await _userService.getUserById(user.uid);

    if (!mounted) {
      return;
    }

    if (profile != null &&
        _phoneController.text.trim().isEmpty &&
        profile.phone.trim().isNotEmpty) {
      _phoneController.text = profile.phone.trim();
    }

    setState(() => _isPrefillingProfile = false);
  }

  Future<void> _saveListing() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final user = _authService.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('İlan eklemek için giriş yapmalısın')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final profile = await _userService.getUserById(user.uid);
    final sellerName = _resolveSellerName(
      userEmail: user.email,
      profile: profile,
    );

    final listing = ListingModel(
      id: '',
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      category: _category,
      woodType: _woodType,
      amount: _parseNumber(_amountController.text),
      unit: _unit,
      price: _parseNumber(_priceController.text),
      city: _cityController.text.trim(),
      district: _districtController.text.trim(),
      moistureStatus: _moistureStatus,
      hasDelivery: _hasDelivery,
      phone: _phoneController.text.trim(),
      sellerId: user.uid,
      sellerName: sellerName,
      createdAt: DateTime.now(),
    );

    try {
      await _listingService.addListing(listing);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('İlan kaydedildi')));
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('İlan kaydedilemedi: $error')));
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  double _parseNumber(String value) {
    return double.tryParse(value.trim().replaceAll(',', '.')) ?? 0;
  }

  String _resolveSellerName({
    required String? userEmail,
    required AppUserModel? profile,
  }) {
    if (profile != null && profile.displayName.trim().isNotEmpty) {
      return profile.displayName.trim();
    }

    final emailPrefix = (userEmail ?? '').split('@').first.trim();
    if (emailPrefix.isNotEmpty) {
      return emailPrefix;
    }

    return 'Kullanici';
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Bu alan zorunlu';
    }
    return null;
  }

  String? _titleValidator(String? value) {
    final requiredError = _requiredValidator(value);
    if (requiredError != null) {
      return requiredError;
    }
    if (value!.trim().length < 3) {
      return 'Başlık en az 3 karakter olmalı';
    }
    return null;
  }

  String? _descriptionValidator(String? value) {
    final requiredError = _requiredValidator(value);
    if (requiredError != null) {
      return requiredError;
    }
    if (value!.trim().length < 10) {
      return 'Açıklama en az 10 karakter olmalı';
    }
    return null;
  }

  String? _cityValidator(String? value) {
    final requiredError = _requiredValidator(value);
    if (requiredError != null) {
      return requiredError;
    }
    if (value!.trim().length < 2) {
      return 'Şehir adını kontrol et';
    }
    return null;
  }

  String? _districtValidator(String? value) {
    final requiredError = _requiredValidator(value);
    if (requiredError != null) {
      return requiredError;
    }
    if (value!.trim().length < 2) {
      return 'İlçe adını kontrol et';
    }
    return null;
  }

  String? _phoneValidator(String? value) {
    final requiredError = _requiredValidator(value);
    if (requiredError != null) {
      return requiredError;
    }
    final digits = value!.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 10) {
      return 'Telefon en az 10 rakam olmalı';
    }
    return null;
  }

  String? _numberValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Bu alan zorunlu';
    }
    final number = double.tryParse(value.trim().replaceAll(',', '.'));
    if (number == null || number <= 0) {
      return 'Geçerli bir sayı gir';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('İlan ekle')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _FormPanel(
                title: 'Ürün bilgileri',
                children: [
                  if (_isPrefillingProfile)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: LinearProgressIndicator(minHeight: 3),
                    ),
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(labelText: 'Başlık'),
                    validator: _titleValidator,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(labelText: 'Açıklama'),
                    minLines: 3,
                    maxLines: 5,
                    validator: _descriptionValidator,
                  ),
                  const SizedBox(height: 12),
                  _DropdownField(
                    label: 'Kategori',
                    value: _category,
                    items: AppConstants.categories,
                    onChanged: (value) => setState(() => _category = value),
                  ),
                  const SizedBox(height: 12),
                  _DropdownField(
                    label: 'Ağaç türü',
                    value: _woodType,
                    items: AppConstants.woodTypes,
                    onChanged: (value) => setState(() => _woodType = value),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _amountController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Miktar',
                          ),
                          validator: _numberValidator,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _DropdownField(
                          label: 'Ölçü birimi',
                          value: _unit,
                          items: AppConstants.units,
                          onChanged: (value) => setState(() => _unit = value),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _priceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Fiyat'),
                    validator: _numberValidator,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _FormPanel(
                title: 'Konum ve satış',
                children: [
                  TextFormField(
                    controller: _cityController,
                    decoration: const InputDecoration(labelText: 'Şehir'),
                    validator: _cityValidator,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _districtController,
                    decoration: const InputDecoration(labelText: 'İlçe'),
                    validator: _districtValidator,
                  ),
                  const SizedBox(height: 12),
                  _DropdownField(
                    label: 'Nem durumu',
                    value: _moistureStatus,
                    items: AppConstants.moistureStatuses,
                    onChanged: (value) =>
                        setState(() => _moistureStatus = value),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    value: _hasDelivery,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Nakliye var mı?'),
                    activeThumbColor: AppConstants.forestGreen,
                    onChanged: (value) => setState(() => _hasDelivery = value),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: 'Telefon'),
                    validator: _phoneValidator,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _isSaving ? null : _saveListing,
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(_isSaving ? 'Kaydediliyor' : 'Kaydet'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FormPanel extends StatelessWidget {
  const _FormPanel({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppConstants.cardBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppConstants.border),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppConstants.forestGreen,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _DropdownField extends StatelessWidget {
  const _DropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<String> items;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(labelText: label),
      items: items.map((item) {
        return DropdownMenuItem(value: item, child: Text(item));
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          onChanged(value);
        }
      },
    );
  }
}

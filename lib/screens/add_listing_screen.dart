import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../constants/app_constants.dart';
import '../models/app_user_model.dart';
import '../models/listing_model.dart';
import '../services/auth_service.dart';
import '../services/listing_service.dart';
import '../services/storage_service.dart';
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
  final _imageUrl1Controller = TextEditingController();
  final _imageUrl2Controller = TextEditingController();
  final _imageUrl3Controller = TextEditingController();
  final _amountController = TextEditingController();
  final _priceController = TextEditingController();
  final _cityController = TextEditingController();
  final _districtController = TextEditingController();
  final _phoneController = TextEditingController();

  final ListingService _listingService = ListingService();
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();
  final StorageService _storageService = StorageService();
  final ImagePicker _imagePicker = ImagePicker();

  String _category = AppConstants.categories.first;
  String _woodType = AppConstants.woodTypes.first;
  String _unit = AppConstants.units.first;
  String _moistureStatus = AppConstants.moistureStatuses.first;
  String _status = AppConstants.activeStatus;
  final List<XFile> _pickedImages = [];
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
    _imageUrl1Controller.dispose();
    _imageUrl2Controller.dispose();
    _imageUrl3Controller.dispose();
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
        const SnackBar(content: Text('Ilan eklemek icin giris yapmalisin')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final profile = await _userService.getUserById(user.uid);
      if (profile != null && profile.userMode == AppConstants.buyerMode) {
        if (!mounted) {
          return;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Ilan eklemek icin hesap modunu Satici ya da Alici ve Satici yapmalisin',
            ),
          ),
        );
        return;
      }

      final sellerName = _resolveSellerName(
        userEmail: user.email,
        profile: profile,
      );
      final imageUrls = await _buildImageUrls(sellerId: user.uid);

      final listing = ListingModel(
        id: '',
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        imageUrls: imageUrls,
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
        status: _status,
        createdAt: DateTime.now(),
      );

      await _listingService.addListing(listing);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Ilan kaydedildi')));
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ilan kaydedilemedi: $error')));
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

  List<String> _collectImageUrls() {
    return [
      _imageUrl1Controller.text.trim(),
      _imageUrl2Controller.text.trim(),
      _imageUrl3Controller.text.trim(),
    ].where((item) => item.isNotEmpty).toList();
  }

  int get _remainingImageSlots {
    return 3 - _collectImageUrls().length - _pickedImages.length;
  }

  Future<void> _pickFromGallery() async {
    if (_remainingImageSlots <= 0) {
      _showImageLimitMessage();
      return;
    }

    final pickedFiles = await _imagePicker.pickMultiImage(imageQuality: 82);
    if (pickedFiles.isEmpty || !mounted) {
      return;
    }

    final allowedFiles = pickedFiles.take(_remainingImageSlots).toList();

    setState(() {
      _pickedImages.addAll(allowedFiles);
    });

    if (pickedFiles.length > allowedFiles.length) {
      _showImageLimitMessage();
    }
  }

  Future<void> _pickFromCamera() async {
    if (_remainingImageSlots <= 0) {
      _showImageLimitMessage();
      return;
    }

    final pickedFile = await _imagePicker.pickImage(
      source: ImageSource.camera,
      imageQuality: 82,
    );

    if (pickedFile == null || !mounted) {
      return;
    }

    setState(() {
      _pickedImages.add(pickedFile);
    });
  }

  Future<List<String>> _buildImageUrls({required String sellerId}) async {
    final manualUrls = _collectImageUrls();
    if (_pickedImages.isEmpty) {
      return manualUrls;
    }

    final uploadableFiles = _pickedImages.take(3 - manualUrls.length).toList();
    final uploadedUrls = await _storageService.uploadListingImages(
      sellerId: sellerId,
      files: uploadableFiles,
    );

    return [...manualUrls, ...uploadedUrls];
  }

  void _removePickedImage(int index) {
    setState(() {
      _pickedImages.removeAt(index);
    });
  }

  void _showImageLimitMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Bir ilan icin en fazla 3 gorsel eklenebilir'),
      ),
    );
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
      return 'Baslik en az 3 karakter olmali';
    }
    return null;
  }

  String? _descriptionValidator(String? value) {
    final requiredError = _requiredValidator(value);
    if (requiredError != null) {
      return requiredError;
    }
    if (value!.trim().length < 10) {
      return 'Aciklama en az 10 karakter olmali';
    }
    return null;
  }

  String? _cityValidator(String? value) {
    final requiredError = _requiredValidator(value);
    if (requiredError != null) {
      return requiredError;
    }
    if (value!.trim().length < 2) {
      return 'Sehir adini kontrol et';
    }
    return null;
  }

  String? _districtValidator(String? value) {
    final requiredError = _requiredValidator(value);
    if (requiredError != null) {
      return requiredError;
    }
    if (value!.trim().length < 2) {
      return 'Ilce adini kontrol et';
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
      return 'Telefon en az 10 rakam olmali';
    }
    return null;
  }

  String? _numberValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Bu alan zorunlu';
    }
    final number = double.tryParse(value.trim().replaceAll(',', '.'));
    if (number == null || number <= 0) {
      return 'Gecerli bir sayi gir';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ilan ekle')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _FormPanel(
                title: 'Urun bilgileri',
                children: [
                  if (_isPrefillingProfile)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: LinearProgressIndicator(minHeight: 3),
                    ),
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(labelText: 'Baslik'),
                    validator: _titleValidator,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(labelText: 'Aciklama'),
                    minLines: 3,
                    maxLines: 5,
                    validator: _descriptionValidator,
                  ),
                  const SizedBox(height: 12),
                  _ImageInputsPreview(
                    imageUrls: _collectImageUrls(),
                    pickedImages: _pickedImages,
                    onPickFromGallery: _pickFromGallery,
                    onPickFromCamera: _pickFromCamera,
                    onRemovePickedImage: _removePickedImage,
                    children: [
                      TextFormField(
                        controller: _imageUrl1Controller,
                        decoration: const InputDecoration(
                          labelText: 'Gorsel URL 1',
                          hintText: 'https://...',
                          prefixIcon: Icon(Icons.image_outlined),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _imageUrl2Controller,
                        decoration: const InputDecoration(
                          labelText: 'Gorsel URL 2',
                          hintText: 'https://...',
                          prefixIcon: Icon(Icons.image_outlined),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _imageUrl3Controller,
                        decoration: const InputDecoration(
                          labelText: 'Gorsel URL 3',
                          hintText: 'https://...',
                          prefixIcon: Icon(Icons.image_outlined),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ],
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
                    label: 'Agac turu',
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
                          label: 'Olcu birimi',
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
                title: 'Konum ve satis',
                children: [
                  _DropdownField(
                    label: 'Ilan durumu',
                    value: _status,
                    items: AppConstants.listingStatuses,
                    onChanged: (value) => setState(() => _status = value),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _cityController,
                    decoration: const InputDecoration(labelText: 'Sehir'),
                    validator: _cityValidator,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _districtController,
                    decoration: const InputDecoration(labelText: 'Ilce'),
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
                    title: const Text('Nakliye var mi?'),
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

class _ImageInputsPreview extends StatelessWidget {
  const _ImageInputsPreview({
    required this.imageUrls,
    required this.pickedImages,
    required this.onPickFromGallery,
    required this.onPickFromCamera,
    required this.onRemovePickedImage,
    required this.children,
  });

  final List<String> imageUrls;
  final List<XFile> pickedImages;
  final Future<void> Function() onPickFromGallery;
  final Future<void> Function() onPickFromCamera;
  final ValueChanged<int> onRemovePickedImage;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onPickFromGallery,
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('Galeriden sec'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onPickFromCamera,
                icon: const Icon(Icons.photo_camera_outlined),
                label: const Text('Kamera'),
              ),
            ),
          ],
        ),
        if (pickedImages.isNotEmpty) ...[
          const SizedBox(height: 12),
          SizedBox(
            height: 86,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: pickedImages.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                return _PickedImageTile(
                  file: pickedImages[index],
                  onRemove: () => onRemovePickedImage(index),
                );
              },
            ),
          ),
        ],
        const SizedBox(height: 12),
        ...children,
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppConstants.cream,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppConstants.border),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppConstants.mossGreen,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.image_outlined,
                  color: AppConstants.forestGreen,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Gorsel alani hazir',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppConstants.deepGreen,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      imageUrls.isEmpty && pickedImages.isEmpty
                          ? 'Su an gorsel eklenmedi. Galeri, kamera veya URL ile ekleyebilirsin.'
                          : '${imageUrls.length + pickedImages.length} gorsel kayit icin hazir.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppConstants.mutedText,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PickedImageTile extends StatelessWidget {
  const _PickedImageTile({required this.file, required this.onRemove});

  final XFile file;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: 92,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppConstants.border),
            color: Colors.white,
          ),
          clipBehavior: Clip.antiAlias,
          child: FutureBuilder(
            future: file.readAsBytes(),
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                );
              }

              if (!snapshot.hasData) {
                return const Center(child: Icon(Icons.broken_image_outlined));
              }

              return Image.memory(
                snapshot.data!,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              );
            },
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: Material(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(999),
            child: InkWell(
              onTap: onRemove,
              borderRadius: BorderRadius.circular(999),
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(Icons.close, size: 14, color: Colors.white),
              ),
            ),
          ),
        ),
      ],
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

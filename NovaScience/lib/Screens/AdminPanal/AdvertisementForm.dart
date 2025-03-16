// widgets/advertisement_form.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'dart:io';

import '../../Modals/Advertisment.dart';
import '../../Service/AdvertisementProvider.dart';


class AdvertisementForm extends StatefulWidget {
  final Advertisement? advertisement; // Null for adding, non-null for editing

  AdvertisementForm({this.advertisement});

  @override
  _AdvertisementFormState createState() => _AdvertisementFormState();
}

class _AdvertisementFormState extends State<AdvertisementForm> {
  final _formKey = GlobalKey<FormState>();
  late AdvertisementType _type;
  String _imageUrl = '';
  String _videoUrl = '';
  String _link = '';
  String _title = '';
  String _description = '';
  late DateTime _startDate;
  late DateTime _endDate;
  bool _isActive = true;

  File? _selectedImage; // To store the selected image file
  bool _isUploading = false; // To track image upload status

  final DateFormat _dateFormat = DateFormat('MMM dd, yyyy');

  @override
  void initState() {
    super.initState();

    // Set default dates
    _startDate = DateTime.now();
    _endDate = DateTime.now().add(Duration(days: 30));

    if (widget.advertisement != null) {
      _type = widget.advertisement!.type;
      _imageUrl = widget.advertisement!.imageUrl;
      _videoUrl = widget.advertisement!.videoUrl;
      _link = widget.advertisement!.link;
      _title = widget.advertisement!.title;
      _description = widget.advertisement!.description;
      _startDate = widget.advertisement!.startDate;
      _endDate = widget.advertisement!.endDate;
      _isActive = widget.advertisement!.isActive;
    } else {
      _type = AdvertisementType.image;
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker _picker = ImagePicker();

    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200, // Increased maximum dimensions for better quality
        maxHeight: 800,
        imageQuality: 90, // High quality
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
          _imageUrl = pickedFile.path; // Temporarily store the local path
        });
      }
    } catch (e) {
      // Handle any errors
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick image: $e')),
      );
    }
  }

  Future<void> _removeImage() async {
    setState(() {
      _selectedImage = null;
      _imageUrl = '';
    });
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime currentDate = isStartDate ? _startDate : _endDate;
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: currentDate,
      firstDate: isStartDate ? DateTime.now() : _startDate,
      lastDate: DateTime.now().add(Duration(days: 365 * 2)),
    );

    if (picked != null && picked != currentDate) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          // If end date is before new start date, adjust it
          if (_endDate.isBefore(_startDate)) {
            _endDate = _startDate.add(Duration(days: 30));
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  // Validate URL format
  bool _isValidUrl(String value) {
    if (value.isEmpty) return true; // Empty is valid as link is optional

    // Basic URL validation
    final urlPattern = RegExp(
      r'^(https?:\/\/)?' + // protocol
          r'((([a-z\d]([a-z\d-]*[a-z\d])*)\.)+[a-z]{2,}|' + // domain name
          r'((\d{1,3}\.){3}\d{1,3}))' + // OR ip (v4) address
          r'(\:\d+)?(\/[-a-z\d%_.~+]*)*' + // port and path
          r'(\?[;&a-z\d%_.~+=-]*)?' + // query string
          r'(\#[-a-z\d_]*)?$', // fragment locator
      caseSensitive: false,
    );

    return urlPattern.hasMatch(value);
  }

  // Validate WhatsApp link or number
  bool _isValidWhatsAppLink(String value) {
    if (value.isEmpty) return false; // WhatsApp link is required

    // Check if it's a phone number
    if (RegExp(r'^\+?[0-9]{8,15}$').hasMatch(value)) {
      return true;
    }

    // Check if it's a wa.me or whatsapp link
    if (value.contains('wa.me') || value.contains('whatsapp.com')) {
      return true;
    }

    return false;
  }

  // Validate Telegram username or link
  bool _isValidTelegramLink(String value) {
    if (value.isEmpty) return false; // Telegram link is required

    // Check if it's a username (with or without @)
    if (RegExp(r'^@?[a-zA-Z0-9_]{5,32}$').hasMatch(value)) {
      return true;
    }

    // Check if it's a t.me link
    if (value.contains('t.me') || value.contains('telegram.me')) {
      return true;
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    final advertisementProvider = Provider.of<AdvertisementProvider>(context, listen: false);

    return Dialog(
        insetPadding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
    child: SingleChildScrollView(
    child: Padding(
    padding: EdgeInsets.all(16.0),
    child: Form(
    key: _formKey,
    child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
    // Form title
    Center(
    child: Text(
    widget.advertisement == null
    ? 'Add New Advertisement'
        : 'Edit Advertisement',
    style: TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    ),
    ),
    ),
    SizedBox(height: 24.0),

    // Title field
    TextFormField(
    initialValue: _title,
    decoration: InputDecoration(
    labelText: 'Title',
    hintText: 'Enter advertisement title',
    border: OutlineInputBorder(),
    ),
    validator: (value) {
    if (value == null || value.isEmpty) {
    return 'Please enter a title';
    }
    return null;
    },
      onSaved: (val) => _title = val ?? '',
    ),
      SizedBox(height: 16.0),

      // Description field
      TextFormField(
        initialValue: _description,
        decoration: InputDecoration(
          labelText: 'Description',
          hintText: 'Enter a short description (optional)',
          border: OutlineInputBorder(),
        ),
        maxLines: 2,
        onSaved: (val) => _description = val ?? '',
      ),
      SizedBox(height: 16.0),

      // Advertisement Type Selection
      Text(
        'Advertisement Type',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      SizedBox(height: 8.0),

      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildTypeButton(AdvertisementType.image, 'Image', Icons.image),
            SizedBox(width: 8),
            _buildTypeButton(AdvertisementType.video, 'Video', Icons.video_library),
            SizedBox(width: 8),
            _buildTypeButton(AdvertisementType.whatsapp, 'WhatsApp', Icons.whatshot),
            SizedBox(width: 8),
            _buildTypeButton(AdvertisementType.telegram, 'Telegram', Icons.send),
          ],
        ),
      ),
      SizedBox(height: 20.0),

      // Advertisement Type Specific Fields
      if (_type == AdvertisementType.image)
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Image Advertisement',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8.0),

            // Image Picker and URL Input
            TextFormField(
              initialValue: _selectedImage == null ? _imageUrl : '',
              decoration: InputDecoration(
                labelText: 'Image URL',
                hintText: 'Select an image or enter URL',
                border: OutlineInputBorder(),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.photo_library),
                      onPressed: _pickImage,
                      tooltip: 'Pick Image from Gallery',
                    ),
                    if (_selectedImage != null || _imageUrl.isNotEmpty)
                      IconButton(
                        icon: Icon(Icons.close),
                        onPressed: _removeImage,
                        tooltip: 'Remove Selected Image',
                      ),
                  ],
                ),
              ),
              validator: (value) {
                if (_selectedImage == null && (value == null || value.isEmpty)) {
                  return 'Please select an image or enter an image URL';
                }
                if (value != null && value.isNotEmpty && !Uri.parse(value).isAbsolute) {
                  return 'Please enter a valid URL';
                }
                return null;
              },
              onSaved: (val) {
                if (_selectedImage != null) {
                  // Keep the local path; will be handled in the provider
                  _imageUrl = _selectedImage!.path;
                } else {
                  _imageUrl = val!;
                }
              },
            ),
            SizedBox(height: 10.0),

            // Image Preview
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: _selectedImage != null
                  ? ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: Image.file(
                  _selectedImage!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
              )
                  : _imageUrl.isNotEmpty
                  ? ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: Image.network(
                  _imageUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  errorBuilder: (context, error, stackTrace) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: Colors.red,
                            size: 48,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Failed to load image',
                            style: TextStyle(color: Colors.red),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              )
                  : Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.image,
                      color: Colors.grey,
                      size: 48,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'No image selected',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          ],
        )
      else if (_type == AdvertisementType.video)
      // Video URL Input
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'YouTube Video Advertisement',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8.0),

            TextFormField(
              initialValue: _videoUrl,
              decoration: InputDecoration(
                labelText: 'YouTube Video URL',
                hintText: 'Enter YouTube Video URL or ID',
                border: OutlineInputBorder(),
                helperText: 'Example: dQw4w9WgXcQ or https://youtu.be/dQw4w9WgXcQ',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a YouTube video URL or ID';
                }
                // Extract the video ID
                final videoId = YoutubePlayer.convertUrlToId(value) ?? value;
                // Validate the video ID length (YouTube video IDs are typically 11 characters)
                if (videoId.length != 11) {
                  return 'Please enter a valid YouTube URL or ID';
                }
                return null;
              },
              onSaved: (val) => _videoUrl = val!,
            ),
            SizedBox(height: 10.0),

            // Video Preview
            if (_videoUrl.isNotEmpty)
              Container(
                margin: EdgeInsets.only(top: 10.0),
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4.0,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: YoutubePlayer(
                    controller: YoutubePlayerController(
                      initialVideoId: YoutubePlayer.convertUrlToId(_videoUrl) ?? '',
                      flags: YoutubePlayerFlags(
                        autoPlay: false,
                        mute: false,
                        loop: false,
                      ),
                    ),
                    showVideoProgressIndicator: true,
                    progressIndicatorColor: Colors.blueAccent,
                    onReady: () {},
                  ),
                ),
              ),
          ],
        )
      else if (_type == AdvertisementType.whatsapp)
        // WhatsApp specific fields
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'WhatsApp Advertisement',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8.0),

              // WhatsApp Link/Number
              TextFormField(
                initialValue: _link,
                decoration: InputDecoration(
                  labelText: 'WhatsApp Phone Number or Link',
                  hintText: 'e.g. +1234567890 or wa.me/1234567890',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone, color: Colors.green),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a WhatsApp number or link';
                  }
                  if (!_isValidWhatsAppLink(value)) {
                    return 'Please enter a valid phone number or WhatsApp link';
                  }
                  return null;
                },
                onSaved: (val) => _link = val!,
              ),
              SizedBox(height: 16.0),

              // Optional Background Image
              Text(
                'Background Image (Optional)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8.0),

              // Image Picker
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickImage,
                      icon: Icon(Icons.add_photo_alternate),
                      label: Text('Select Image'),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  if (_selectedImage != null || _imageUrl.isNotEmpty)
                    SizedBox(width: 8),
                  if (_selectedImage != null || _imageUrl.isNotEmpty)
                    OutlinedButton.icon(
                      onPressed: _removeImage,
                      icon: Icon(Icons.delete_outline, color: Colors.red),
                      label: Text('Remove', style: TextStyle(color: Colors.red)),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                ],
              ),

              // Image Preview
              if (_selectedImage != null || _imageUrl.isNotEmpty)
                Container(
                  margin: EdgeInsets.only(top: 16.0),
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8.0),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: _selectedImage != null
                      ? ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: Image.file(
                      _selectedImage!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                  )
                      : ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: Image.network(
                      _imageUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (context, error, stackTrace) {
                        return Center(
                          child: Text(
                            'Failed to load image',
                            style: TextStyle(color: Colors.red),
                          ),
                        );
                      },
                    ),
                  ),
                ),
            ],
          )
        else if (_type == AdvertisementType.telegram)
          // Telegram specific fields
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Telegram Advertisement',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8.0),

                // Telegram Username or Link
                TextFormField(
                  initialValue: _link,
                  decoration: InputDecoration(
                    labelText: 'Telegram Username or Link',
                    hintText: 'e.g. @username or t.me/username',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.send, color: Colors.blue),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a Telegram username or link';
                    }
                    if (!_isValidTelegramLink(value)) {
                      return 'Please enter a valid Telegram username or link';
                    }
                    return null;
                  },
                  onSaved: (val) => _link = val!,
                ),
                SizedBox(height: 16.0),

                // Optional Background Image
                Text(
                  'Background Image (Optional)',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8.0),

                // Image Picker
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickImage,
                        icon: Icon(Icons.add_photo_alternate),
                        label: Text('Select Image'),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    if (_selectedImage != null || _imageUrl.isNotEmpty)
                      SizedBox(width: 8),
                    if (_selectedImage != null || _imageUrl.isNotEmpty)
                      OutlinedButton.icon(
                        onPressed: _removeImage,
                        icon: Icon(Icons.delete_outline, color: Colors.red),
                        label: Text('Remove', style: TextStyle(color: Colors.red)),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                  ],
                ),

                // Image Preview
                if (_selectedImage != null || _imageUrl.isNotEmpty)
                  Container(
                    margin: EdgeInsets.only(top: 16.0),
                    height: 150,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8.0),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: _selectedImage != null
                        ? ClipRRect(
                      borderRadius: BorderRadius.circular(8.0),
                      child: Image.file(
                        _selectedImage!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                      ),
                    )
                        : ClipRRect(
                      borderRadius: BorderRadius.circular(8.0),
                      child: Image.network(
                        _imageUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorBuilder: (context, error, stackTrace) {
                          return Center(
                            child: Text(
                              'Failed to load image',
                              style: TextStyle(color: Colors.red),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
              ],
            ),

      SizedBox(height: 20.0),

      // Schedule section
      Text(
        'Schedule',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      SizedBox(height: 8.0),

      // Date Range Selector
      Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => _selectDate(context, true),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Start Date',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_dateFormat.format(_startDate)),
                    Icon(Icons.calendar_today, size: 20),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: InkWell(
              onTap: () => _selectDate(context, false),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'End Date',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_dateFormat.format(_endDate)),
                    Icon(Icons.calendar_today, size: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      SizedBox(height: 16),

      // Active Status Switch
      Row(
        children: [
          Expanded(
            child: Text(
              'Advertisement Status',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Switch(
            value: _isActive,
            onChanged: (value) {
              setState(() {
                _isActive = value;
              });
            },
            activeColor: Colors.green,
          ),
          Text(
            _isActive ? 'Active' : 'Inactive',
            style: TextStyle(
              color: _isActive ? Colors.green : Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      SizedBox(height: 30.0),

      // Submit and Cancel Buttons
      Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              child: Text('Cancel'),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: _isUploading
                  ? null
                  : () async {
                if (_formKey.currentState!.validate()) {
                  _formKey.currentState!.save();

                  String imageUrl = _imageUrl;

                  if ((_type == AdvertisementType.image ||
                      _type == AdvertisementType.whatsapp ||
                      _type == AdvertisementType.telegram) &&
                      _selectedImage != null) {
                    // Upload the image and get the download URL
                    setState(() {
                      _isUploading = true;
                    });
                    try {
                      imageUrl = await advertisementProvider.uploadImage(_selectedImage!.path);
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to upload image: $e')),
                      );
                      setState(() {
                        _isUploading = false;
                      });
                      return; // Exit the function if upload fails
                    }
                    setState(() {
                      _isUploading = false;
                    });
                  }

                  final advertisement = Advertisement(
                    id: widget.advertisement?.id ?? '',
                    type: _type,
                    imageUrl: (_type == AdvertisementType.image ||
                        _type == AdvertisementType.whatsapp ||
                        _type == AdvertisementType.telegram) ? imageUrl : '',
                    videoUrl: _type == AdvertisementType.video ? _videoUrl : '',
                    link: _link,
                    title: _title,
                    description: _description,
                    startDate: _startDate,
                    endDate: _endDate,
                    isActive: _isActive,
                  );

                  try {
                    if (widget.advertisement == null) {
                      // Add new advertisement
                      await advertisementProvider.addAdvertisement(
                        advertisement,
                        localImagePath: _selectedImage?.path,
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Advertisement added successfully')),
                      );
                    } else {
                      // Update existing advertisement
                      await advertisementProvider.updateAdvertisement(
                        advertisement,
                        localImagePath: _selectedImage?.path,
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Advertisement updated successfully')),
                      );
                    }

                    Navigator.of(context).pop();
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to save advertisement: $e')),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              child: _isUploading
                  ? SizedBox(
                height: 24.0,
                width: 24.0,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 2.5,
                ),
              )
                  : Text(
                widget.advertisement == null ? 'Add Advertisement' : 'Update Advertisement',
                style: TextStyle(fontSize: 16.0),
              ),
            ),
          ),
        ],
      ),
    ],
    ),
    ),
    ),
    ),
    );
  }

  // Helper method to build type selection buttons
  Widget _buildTypeButton(AdvertisementType type, String label, IconData icon) {
    final isSelected = _type == type;
    return InkWell(
      onTap: () {
        setState(() {
          _type = type;
          // Reset fields when type changes to avoid validation issues
          if (_type == AdvertisementType.image) {
            _videoUrl = '';
          } else if (_type == AdvertisementType.video) {
            _imageUrl = '';
            _selectedImage = null;
          }
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.blue.shade600 : Colors.grey.shade400,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey.shade700,
              size: 20,
            ),
            SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey.shade800,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// widgets/advertisement_form.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:image_picker/image_picker.dart';
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

  File? _selectedImage; // To store the selected image file
  bool _isUploading = false; // To track image upload status

  @override
  void initState() {
    super.initState();
    if (widget.advertisement != null) {
      _type = widget.advertisement!.type;
      _imageUrl = widget.advertisement!.imageUrl;
      _videoUrl = widget.advertisement!.videoUrl;
      _link = widget.advertisement!.link;
    } else {
      _type = AdvertisementType.image;
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker _picker = ImagePicker();

    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 600,
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
              children: [
                // Advertisement Type Selection
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ToggleButtons(
                      borderRadius: BorderRadius.circular(8.0),
                      isSelected: [
                        _type == AdvertisementType.image,
                        _type == AdvertisementType.video,
                      ],
                      onPressed: (int index) {
                        setState(() {
                          _type = AdvertisementType.values[index];
                          // Reset fields when type changes
                          if (_type == AdvertisementType.image) {
                            _videoUrl = '';
                          } else {
                            _imageUrl = '';
                            _selectedImage = null;
                          }
                        });
                      },
                      children: [
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.0),
                          child: Text('Image'),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.0),
                          child: Text('Video'),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 20.0),

                // Advertisement Type Specific Fields
                if (_type == AdvertisementType.image)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image Picker and URL Input
                      TextFormField(
                        initialValue: _selectedImage == null ? _imageUrl : '',
                        decoration: InputDecoration(
                          labelText: 'Image',
                          hintText: 'Select an image from gallery or enter URL',
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
                      if (_selectedImage != null)
                        Container(
                          margin: EdgeInsets.only(top: 10.0),
                          height: 150,
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
                            child: Image.file(
                              _selectedImage!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                            ),
                          ),
                        )
                      else if (_imageUrl.isNotEmpty)
                        Container(
                          margin: EdgeInsets.only(top: 10.0),
                          height: 150,
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
                            child: Image.network(
                              _imageUrl,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey[200],
                                  child: Center(
                                    child: Text(
                                      'Failed to load image',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                    ],
                  )
                else
                // Video URL Input
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        initialValue: _videoUrl,
                        decoration: InputDecoration(
                          labelText: 'YouTube Video',
                          hintText: 'Enter YouTube Video URL or ID',
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
                  ),
                SizedBox(height: 20.0),

                // Link Field
                TextFormField(
                  initialValue: _link,
                  decoration: InputDecoration(
                    labelText: 'Link (Optional)',
                    hintText: 'https://yourwebsite.com',
                  ),
                  validator: (value) {
                    if (value != null && value.isNotEmpty && !Uri.parse(value).isAbsolute) {
                      return 'Please enter a valid URL';
                    }
                    return null;
                  },
                  onSaved: (val) => _link = val!,
                ),
                SizedBox(height: 30.0),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isUploading
                        ? null
                        : () async {
                      if (_formKey.currentState!.validate()) {
                        _formKey.currentState!.save();

                        String imageUrl = _imageUrl;

                        if (_type == AdvertisementType.image && _selectedImage != null) {
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
                          imageUrl: _type == AdvertisementType.image ? imageUrl : '',
                          videoUrl: _type == AdvertisementType.video ? _videoUrl : '',
                          link: _link,
                        );

                        try {
                          if (widget.advertisement == null) {
                            // Add new advertisement
                            await advertisementProvider.addAdvertisement(
                              advertisement,
                              localImagePath: _selectedImage?.path,
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Advertisement added')),
                            );
                          } else {
                            // Update existing advertisement
                            await advertisementProvider.updateAdvertisement(
                              advertisement,
                              localImagePath: _selectedImage?.path,
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Advertisement updated')),
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
          ),
        ),
      ),
    );
  }
}
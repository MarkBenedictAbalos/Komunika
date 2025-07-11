import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:komunika/bloc/bloc_text_to_speech/text_to_speech_bloc.dart';
import 'package:komunika/bloc/bloc_text_to_speech/text_to_speech_event.dart';
import 'package:komunika/bloc/bloc_text_to_speech/text_to_speech_state.dart';
import 'package:komunika/screens/text_to_speech_screen/voice_message_page.dart';
import 'package:komunika/utils/app_localization_translate.dart';
import 'package:komunika/utils/colors.dart';
import 'package:komunika/utils/responsive.dart';
import 'package:komunika/utils/shared_prefs.dart';
import 'package:komunika/utils/snack_bar.dart';
import 'package:komunika/utils/themes.dart';

class TextToSpeechScreen extends StatefulWidget {
  final ThemeProvider themeProvider;
  final TextToSpeechBloc ttsBloc;
  const TextToSpeechScreen({
    super.key,
    required this.themeProvider,
    required this.ttsBloc,
  });

  @override
  State<TextToSpeechScreen> createState() => _TextToSpeechScreenState();
}

class _TextToSpeechScreenState extends State<TextToSpeechScreen> {
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final FlutterTts flutterTts = FlutterTts();
  final ImagePicker _imagePicker = ImagePicker();
  Map<String, String> ttsSettings = {};
  bool _isMaleVoice = false;
  String selectedLangauge = '';
  String selectedVoice = '';
  bool currentlyPlaying = false;
  bool save = false;
  List<XFile> _selectedImages = [];
  int _currentProcessingIndex = 0;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    widget.ttsBloc.add(TextToSpeechLoadingEvent());
    ttsSettings = await PreferencesUtils.getTTSSettings();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: widget.ttsBloc,
      child: Scaffold(
        backgroundColor: widget.themeProvider.themeData.scaffoldBackgroundColor,
        floatingActionButton: FloatingActionButton(
          onPressed: _showImageSourceDialog,
          backgroundColor: widget.themeProvider.themeData.primaryColor,
          tooltip: context.translate("tts_image_processing_title"),
          child: Icon(
            Icons.camera_alt_rounded,
            color: widget.themeProvider.themeData.textTheme.bodySmall?.color,
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        appBar: AppBar(
          title: Padding(
            padding: const EdgeInsets.only(top: 7.0),
            child: Text(
              context.translate("tts_title"),
              style: TextStyle(
                fontSize: ResponsiveUtils.getResponsiveFontSize(context, 16),
              ),
            ),
          ),
          leading: Padding(
            padding: EdgeInsets.only(
              top: ResponsiveUtils.getResponsiveSize(context, 7),
            ),
            child: IconButton(
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: ResponsiveUtils.getResponsiveSize(context, 10),
              ),
              onPressed: () {
                _textController.clear();
                Navigator.pop(context);
              },
            ),
          ),
          actions: [
            Padding(
              padding: EdgeInsets.only(
                top: ResponsiveUtils.getResponsiveSize(context, 7),
                right: ResponsiveUtils.getResponsiveSize(context, 8),
              ),
              child: IconButton(
                icon: Icon(
                  _isMaleVoice ? Icons.male_rounded : Icons.female_rounded,
                  color: _isMaleVoice ? ColorsPalette.blue : ColorsPalette.red,
                  size: ResponsiveUtils.getResponsiveSize(context, 25),
                ),
                onPressed: () async {
                  setState(() {
                    _isMaleVoice = !_isMaleVoice;
                  });

                  selectedVoice = _isMaleVoice
                      ? "fil-ph-x-fie-local"
                      : "fil-ph-x-fic-local";
                  await flutterTts.setLanguage('fil-PH');
                  await flutterTts
                      .setVoice({"name": selectedVoice, "locale": "fil-PH"});
                  print("Selected Voice: $selectedVoice");
                },
              ),
            ),
          ],
        ),
        body: BlocConsumer<TextToSpeechBloc, TextToSpeechState>(
          listener: (context, state) {
            if (state is ImageCroppedState) {
              _extractTextFromImage(state.croppedImagePath);
            }
            if (state is TextExtractionSuccessState) {
              setState(() {
                _textController.text = _textController.text.isNotEmpty
                    ? '${_textController.text}\n\n${state.extractedText}'
                    : state.extractedText;
              });
            }
            if (state is TextToSpeechErrorState) {
              showCustomSnackBar(
                  context, "Error, Please try again", ColorsPalette.red);
            }
            if (state is AudioPlaybackCompletedState) {
              setState(() {
                currentlyPlaying = false;
              });
            }
          },
          builder: (context, state) {
            if (state is TextToSpeechLoadingState) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is TextToSpeechLoadedSuccessState) {
              return _buildContent(widget.themeProvider);
            } else if (state is TextToSpeechErrorState) {
              return const Text('Error processing text to speech!');
            } else {
              return _buildContent(widget.themeProvider);
            }
          },
        ),
      ),
    );
  }

  Widget _buildContent(ThemeProvider themeProvider) {
    final double phoneHeight = MediaQuery.of(context).size.height * 0.7;
    final double phoneWidth = MediaQuery.of(context).size.width * 1.0;
    return RefreshIndicator.adaptive(
      onRefresh: _initialize,
      child: Padding(
        padding: EdgeInsets.all(
          ResponsiveUtils.getResponsiveSize(context, 16),
        ),
        child: ListView(
          children: [
            SizedBox(
              width: phoneWidth,
              height: phoneHeight,
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: themeProvider.themeData.cardColor,
                      borderRadius: BorderRadius.circular(
                        ResponsiveUtils.getResponsiveSize(context, 12),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        TextField(
                          readOnly: false,
                          controller: _textController,
                          style: TextStyle(
                            color: themeProvider
                                .themeData.textTheme.bodyMedium?.color,
                            fontSize: ResponsiveUtils.getResponsiveFontSize(
                                context, 20),
                          ),
                          decoration: InputDecoration(
                            hintText: context.translate("tts_hint2"),
                            hintStyle: TextStyle(
                              color: Colors.grey,
                              fontSize: ResponsiveUtils.getResponsiveFontSize(
                                  context, 16),
                            ),
                            border: InputBorder.none,
                            fillColor: Colors.transparent,
                            filled: true,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: ResponsiveUtils.getResponsiveSize(
                                  context, 12),
                              vertical: ResponsiveUtils.getResponsiveSize(
                                  context, 16),
                            ),
                          ),
                          textAlignVertical: TextAlignVertical.center,
                          maxLines: 17,
                          keyboardType: TextInputType.multiline,
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(width: 8),
                              Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: ColorsPalette.grey.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: IconButton(
                                  icon: const Icon(Icons.expand_outlined,
                                      size: 15, color: Colors.grey),
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      barrierDismissible: false,
                                      builder: (context) {
                                        return Dialog(
                                          insetPadding: EdgeInsets.zero,
                                          backgroundColor: widget
                                              .themeProvider
                                              .themeData
                                              .scaffoldBackgroundColor,
                                          child: Column(
                                            children: [
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 16,
                                                        vertical: 12),
                                                alignment:
                                                    Alignment.centerRight,
                                                child: IconButton(
                                                  icon: const Icon(
                                                      Icons.expand_less,
                                                      color: Colors.grey),
                                                  onPressed: () =>
                                                      Navigator.pop(context),
                                                ),
                                              ),
                                              Expanded(
                                                child: Padding(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 16,
                                                      vertical: 8),
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      color: widget
                                                          .themeProvider
                                                          .themeData
                                                          .cardColor,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              12),
                                                    ),
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 12),
                                                    child: TextField(
                                                      controller:
                                                          _textController,
                                                      expands: true,
                                                      maxLines: null,
                                                      minLines: null,
                                                      keyboardType:
                                                          TextInputType
                                                              .multiline,
                                                      style: widget
                                                          .themeProvider
                                                          .themeData
                                                          .textTheme
                                                          .bodyLarge,
                                                      decoration:
                                                          const InputDecoration(
                                                        border:
                                                            InputBorder.none,
                                                        hintText:
                                                            "Type your text here...",
                                                        hintStyle: TextStyle(
                                                            color: Colors.grey),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          bottom: 8,
                          right: 8,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(width: 8),
                              Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: ColorsPalette.grey.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: IconButton(
                                  icon: const Icon(Icons.clear,
                                      size: 15, color: Colors.grey),
                                  onPressed: () {
                                    _textController.clear();
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => VoiceMessagePage(
                              themeProvider: widget.themeProvider,
                              textToSpeechBloc: widget.ttsBloc),
                        ),
                      );
                    },
                    child: Container(
                      width: ResponsiveUtils.getResponsiveSize(context, 50),
                      height: ResponsiveUtils.getResponsiveSize(context, 50),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: themeProvider.themeData.primaryColor,
                      ),
                      child: Icon(
                        Icons.list_rounded,
                        color:
                            themeProvider.themeData.textTheme.bodySmall?.color,
                        size: ResponsiveUtils.getResponsiveSize(context, 40),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: ResponsiveUtils.getResponsiveSize(context, 20)),
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: GestureDetector(
                    onTap: currentlyPlaying
                        ? null
                        : () {
                            _titleController.text.trim();
                            final text = _textController.text.trim();
                            if (text.isNotEmpty) {
                              setState(() {
                                currentlyPlaying = true;
                              });
                              widget.ttsBloc.add(FlutterTTSEvent(
                                  text: text,
                                  language: ttsSettings['language'].toString(),
                                  voice: ttsSettings['voice'].toString()));
                            } else {
                              showCustomSnackBar(
                                context,
                                "Text field is empty!",
                                ColorsPalette.red,
                              );
                            }
                          },
                    child: Container(
                      width: ResponsiveUtils.getResponsiveSize(context, 80),
                      height: ResponsiveUtils.getResponsiveSize(context, 80),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: themeProvider.themeData.primaryColor,
                      ),
                      child: currentlyPlaying
                          ? Icon(
                              Icons.pause_outlined,
                              color: themeProvider
                                  .themeData.textTheme.bodySmall?.color,
                              size: ResponsiveUtils.getResponsiveSize(
                                  context, 60),
                            )
                          : Icon(
                              Icons.play_arrow_rounded,
                              color: themeProvider
                                  .themeData.textTheme.bodySmall?.color,
                              size: ResponsiveUtils.getResponsiveSize(
                                  context, 60),
                            ),
                    ),
                  ),
                ),
                SizedBox(width: ResponsiveUtils.getResponsiveSize(context, 20)),
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: GestureDetector(
                    onTap: () async {
                      final text = _textController.text.trim();
                      if (text.isNotEmpty) {
                        final enteredTitle = await showDialog<String>(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              backgroundColor:
                                  themeProvider.themeData.primaryColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              title: Text(
                                "Enter Title",
                                style: TextStyle(
                                  color: themeProvider
                                      .themeData.textTheme.bodySmall?.color,
                                  fontSize:
                                      ResponsiveUtils.getResponsiveFontSize(
                                          context, 20),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              content: Container(
                                decoration: BoxDecoration(
                                  color:
                                      widget.themeProvider.themeData.cardColor,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                                child: TextField(
                                  controller: _titleController,
                                  style: widget.themeProvider.themeData
                                      .textTheme.bodyLarge,
                                  decoration: InputDecoration(
                                    hintText: "Enter title here",
                                    hintStyle: TextStyle(
                                      color: Colors.grey.shade600,
                                    ),
                                    border: InputBorder.none,
                                  ),
                                ),
                              ),
                              actions: [
                                FilledButton(
                                  onPressed: () {
                                    _titleController.clear();
                                    save = false;
                                    Navigator.pop(context);
                                  },
                                  style: FilledButton.styleFrom(
                                    backgroundColor: ColorsPalette.red,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 8),
                                  ),
                                  child: Text(
                                    context.translate("tts_cancel"),
                                    style: TextStyle(
                                      color: widget.themeProvider.themeData
                                          .textTheme.bodySmall?.color,
                                      fontSize:
                                          ResponsiveUtils.getResponsiveFontSize(
                                              context, 14),
                                    ),
                                  ),
                                ),
                                FilledButton(
                                  onPressed: () {
                                    _titleController.clear();
                                    save = true;
                                    Navigator.pop(
                                        context, _titleController.text.trim());
                                  },
                                  style: FilledButton.styleFrom(
                                    backgroundColor: ColorsPalette.green,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 8),
                                  ),
                                  child: Text(
                                    context.translate("tts_proceed"),
                                    style: TextStyle(
                                      color: widget.themeProvider.themeData
                                          .textTheme.bodySmall?.color,
                                      fontSize:
                                          ResponsiveUtils.getResponsiveFontSize(
                                              context, 14),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        );
                        if (save != false) {
                          if (enteredTitle != null && enteredTitle.isNotEmpty) {
                            widget.ttsBloc.add(
                              CreateTextToSpeechEvent(
                                text: text,
                                title: enteredTitle,
                                save: true,
                              ),
                            );
                            _textController.clear();
                            showCustomSnackBar(
                                context, "Saved!", ColorsPalette.green);
                          } else {
                            showCustomSnackBar(context,
                                "Error, Please try again!", ColorsPalette.red);
                          }
                        } else {}
                      } else {
                        showCustomSnackBar(
                            context, "Text field is empty!", ColorsPalette.red);
                      }
                    },
                    child: Container(
                      width: ResponsiveUtils.getResponsiveSize(context, 50),
                      height: ResponsiveUtils.getResponsiveSize(context, 50),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: themeProvider.themeData.primaryColor,
                      ),
                      child: Icon(
                        Icons.save_alt_rounded,
                        color:
                            themeProvider.themeData.textTheme.bodySmall?.color,
                        size: ResponsiveUtils.getResponsiveSize(context, 35),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showImageSourceDialog() async {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: widget.themeProvider.themeData.primaryColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                context.translate("tts_select_source"),
                style: TextStyle(
                  color:
                      widget.themeProvider.themeData.textTheme.bodySmall?.color,
                  fontWeight: FontWeight.bold,
                  fontSize: ResponsiveUtils.getResponsiveFontSize(context, 20),
                ),
              ),
              const SizedBox(height: 24),
              ListTile(
                leading: Icon(
                  Icons.camera_alt_rounded,
                  color: widget.themeProvider.themeData.primaryColor,
                ),
                title: Text(
                  context.translate("tts_camera"),
                  style: widget.themeProvider.themeData.textTheme.bodyMedium,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                tileColor: widget.themeProvider.themeData.cardColor,
                onTap: () {
                  Navigator.pop(context);
                  widget.ttsBloc.add(
                    CaptureImageEvent(source: ImageSource.camera),
                  );
                },
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: Icon(
                  Icons.photo_library_rounded,
                  color: widget.themeProvider.themeData.primaryColor,
                ),
                title: Text(
                  context.translate("tts_gallery"),
                  style: widget.themeProvider.themeData.textTheme.bodyLarge,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                tileColor: widget.themeProvider.themeData.cardColor,
                onTap: () {
                  Navigator.pop(context);
                  _pickMultipleImages();
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickMultipleImages() async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage(
        imageQuality: 70,
      );

      if (images.isNotEmpty) {
        setState(() {
          _selectedImages = images;
        });
        _showBatchProcessingDialog();
      }
    } catch (e) {
      showCustomSnackBar(context, "Error: ${e.toString()}", ColorsPalette.red);
    }
  }

  Future<void> _extractTextFromImage(String imagePath) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                context.translate("tts_processing_image"),
                style: TextStyle(
                  color: widget
                      .themeProvider.themeData.textTheme.bodyMedium?.color,
                  fontWeight: FontWeight.bold,
                  fontSize: ResponsiveUtils.getResponsiveFontSize(context, 20),
                ),
              ),
              const SizedBox(height: 24),
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                context.translate("tts_extracting_text"),
                style: TextStyle(
                  color: widget
                      .themeProvider.themeData.textTheme.bodyMedium?.color,
                  fontWeight: FontWeight.bold,
                  fontSize: ResponsiveUtils.getResponsiveFontSize(context, 20),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      widget.ttsBloc.add(
        ExtractTextFromImageEvent(imagePath: imagePath),
      );
      Navigator.pop(context);
    } catch (e) {
      if (mounted) Navigator.of(context).pop();
      showCustomSnackBar(
        context,
        "Error processing image: ${e.toString()}",
        ColorsPalette.red,
      );
    }
  }

  Future<void> _showBatchProcessingDialog() async {
    bool confirmBatch = false;

    await showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: widget.themeProvider.themeData.primaryColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                context.translate("tts_batch_process_title"),
                style: TextStyle(
                  color:
                      widget.themeProvider.themeData.textTheme.bodySmall?.color,
                  fontWeight: FontWeight.bold,
                  fontSize: ResponsiveUtils.getResponsiveFontSize(context, 20),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                context
                    .translate("tts_batch_process_message")
                    .replaceAll("{count}", _selectedImages.length.toString()),
                style: TextStyle(
                  color:
                      widget.themeProvider.themeData.textTheme.bodySmall?.color,
                  fontSize: ResponsiveUtils.getResponsiveFontSize(context, 14),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  FilledButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: ColorsPalette.red,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 8),
                    ),
                    child: Text(
                      context.translate("tts_cancel"),
                      style: TextStyle(
                        color: widget
                            .themeProvider.themeData.textTheme.bodySmall?.color,
                        fontSize:
                            ResponsiveUtils.getResponsiveFontSize(context, 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () {
                      confirmBatch = true;
                      Navigator.pop(context);
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: ColorsPalette.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 8),
                    ),
                    child: Text(
                      context.translate("tts_proceed"),
                      style: TextStyle(
                        color: widget
                            .themeProvider.themeData.textTheme.bodySmall?.color,
                        fontSize:
                            ResponsiveUtils.getResponsiveFontSize(context, 14),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmBatch && mounted) {
      setState(() {
        _currentProcessingIndex = 0;
      });
      await _processBatchImages();
    }
  }

  Future<void> _processBatchImages() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    context.translate("tts_processing_batch"),
                    style: TextStyle(
                      color: widget
                          .themeProvider.themeData.textTheme.bodyMedium?.color,
                      fontWeight: FontWeight.bold,
                      fontSize:
                          ResponsiveUtils.getResponsiveFontSize(context, 20),
                    ),
                  ),
                  const SizedBox(height: 24),
                  LinearProgressIndicator(
                    value: _currentProcessingIndex / _selectedImages.length,
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    context
                        .translate("tts_processing_image_count")
                        .replaceAll("{current}",
                            (_currentProcessingIndex + 1).toString())
                        .replaceAll(
                            "{total}", _selectedImages.length.toString()),
                    style: TextStyle(
                      color: widget
                          .themeProvider.themeData.textTheme.bodyMedium?.color,
                      fontSize:
                          ResponsiveUtils.getResponsiveFontSize(context, 14),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    String combinedText = _textController.text;

    widget.ttsBloc.add(
      BatchExtractTextEvent(
          imagePaths: _selectedImages.map((e) => e.path).toList()),
    );

    if (mounted) {
      Navigator.of(context).pop();
      setState(() {
        _textController.text = combinedText;
        _selectedImages.clear();
      });
    }
  }
}

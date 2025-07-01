import 'dart:io';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Script to upload default pet images to Supabase storage
///
/// Usage: dart run scripts/upload_default_pet_images.dart
///
/// This script:
/// 1. Connects to Supabase
/// 2. Uploads default pet stage images to the pet-images bucket
/// 3. Creates default image URLs for each pet stage
/// 4. Updates families table with default pet stage images

void main() async {
  print('🚀 Starting pet image upload...');

  // Initialize Supabase (replace with your actual project URL and anon key)
  const supabaseUrl = 'https://your-project-id.supabase.co';
  const supabaseAnonKey = 'your-anon-key-here';

  try {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );

    final supabase = Supabase.instance.client;

    print('✅ Connected to Supabase');

    // Define default pet images
    final petStages = {
      'egg': 'assets/images/pet_egg.png',
      'baby': 'assets/images/pet_baby.png',
      'child': 'assets/images/pet_child.png',
      'teen': 'assets/images/pet_teen.png',
      'adult': 'assets/images/pet_adult.png',
    };

    Map<String, String> defaultStageUrls = {};

    // Upload each default pet image
    for (final entry in petStages.entries) {
      final stage = entry.key;
      final assetPath = entry.value;

      print('📤 Uploading $stage image...');

      try {
        // Read the asset file
        final file = File(assetPath);
        if (!file.existsSync()) {
          print('⚠️  Warning: $assetPath not found, skipping...');
          continue;
        }

        final fileBytes = await file.readAsBytes();
        final fileName = 'default_pet_$stage.png';
        final storagePath = 'defaults/$fileName';

        // Upload to pet-images bucket
        await supabase.storage
            .from('pet-images')
            .uploadBinary(storagePath, fileBytes,
                fileOptions: const FileOptions(
                  cacheControl: '3600',
                  upsert: true, // Allow overwriting existing files
                ));

        // Get public URL
        final publicUrl =
            supabase.storage.from('pet-images').getPublicUrl(storagePath);

        defaultStageUrls[stage] = publicUrl;
        print('✅ Uploaded $stage: $publicUrl');
      } catch (e) {
        print('❌ Failed to upload $stage: $e');
      }
    }

    if (defaultStageUrls.isNotEmpty) {
      print('📊 Default stage URLs created:');
      defaultStageUrls.forEach((stage, url) {
        print('  $stage: $url');
      });

      // Optionally update existing families without pet stage images
      print('🔄 Updating families without pet stage images...');

      try {
        final result = await supabase
            .from('families')
            .update({
              'pet_stage_images': defaultStageUrls,
            })
            .isFilter('pet_stage_images', null)
            .select('id');

        print('✅ Updated ${result.length} families with default pet images');
      } catch (e) {
        print('⚠️  Warning: Could not update families: $e');
      }
    }

    print('🎉 Pet image upload completed!');
  } catch (e) {
    print('❌ Error: $e');
    exit(1);
  }
}

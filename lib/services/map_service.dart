import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class MapService {
  static Future<void> launchMapByQuery({
    required String query,
    required BuildContext context,
  }) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bu etkinlik için konum bilgisi bulunmuyor.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    final encodedQuery = Uri.encodeComponent(cleanQuery);

    try {
      if (kIsWeb) {
        final webUrl =
            'https://www.google.com/maps/search/?api=1&query=$encodedQuery';
        if (await launchUrl(Uri.parse(webUrl))) {
          return;
        }
      } else if (Platform.isIOS) {
        final appleMaps = Uri.parse('https://maps.apple.com/?q=$encodedQuery');
        if (await canLaunchUrl(appleMaps)) {
          if (await launchUrl(
            appleMaps,
            mode: LaunchMode.externalApplication,
          )) {
            return;
          }
        }

        final googleMapsIos = Uri.parse('comgooglemaps://?q=$encodedQuery');
        if (await canLaunchUrl(googleMapsIos)) {
          if (await launchUrl(
            googleMapsIos,
            mode: LaunchMode.externalApplication,
          )) {
            return;
          }
        }
      } else if (Platform.isAndroid) {
        final androidUrls = [
          'google.navigation:q=$encodedQuery&mode=w',
          'geo:0,0?q=$encodedQuery',
          'https://www.google.com/maps/search/?api=1&query=$encodedQuery',
        ];

        for (final url in androidUrls) {
          final uri = Uri.parse(url);
          try {
            if (await launchUrl(uri, mode: LaunchMode.externalApplication)) {
              return;
            }
          } catch (_) {
            continue;
          }
        }
      }

      final fallback = Uri.parse(
          'https://www.google.com/maps/search/?api=1&query=$encodedQuery');
      if (!await launchUrl(fallback, mode: LaunchMode.externalApplication)) {
        await launchUrl(fallback, mode: LaunchMode.inAppWebView);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Harita uygulaması açılamadı: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  static Future<void> launchMap({
    required double? latitude,
    required double? longitude,
    required String locationName,
    required BuildContext context,
  }) async {
    if (latitude == null || longitude == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bu mekan için konum bilgisi bulunmuyor.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    // Encode the location name properly for all URLs
    final encodedName = Uri.encodeComponent(locationName);

    try {
      // Web platform handling
      if (kIsWeb) {
        final webUrl =
            'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';
        if (await launchUrl(Uri.parse(webUrl))) {
          return;
        }
      }
      // iOS platform handling
      else if (Platform.isIOS) {
        // First try Apple Maps
        final appleUrl =
            'https://maps.apple.com/?q=$encodedName&ll=$latitude,$longitude';
        final appleUri = Uri.parse(appleUrl);

        if (await canLaunchUrl(appleUri)) {
          if (await launchUrl(
            appleUri,
            mode: LaunchMode.externalApplication,
          )) {
            return;
          }
        }

        // If Apple Maps fails, try Google Maps app on iOS
        final googleIosUrl =
            'comgooglemaps://?q=$latitude,$longitude&query=$encodedName';
        final googleIosUri = Uri.parse(googleIosUrl);

        if (await canLaunchUrl(googleIosUri)) {
          if (await launchUrl(
            googleIosUri,
            mode: LaunchMode.externalApplication,
          )) {
            return;
          }
        }
      }
      // Android platform handling
      else if (Platform.isAndroid) {
        // Try several different formats for Google Maps on Android with walking mode
        final List<String> androidUrls = [
          // Standard Google Maps intent with walking mode
          'google.navigation:q=$latitude,$longitude&mode=w',
          // Alternative format with walking mode
          'https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude&travelmode=walking',
          // Geo format as fallback
          'geo:$latitude,$longitude?q=$latitude,$longitude($encodedName)',
        ];

        for (String urlString in androidUrls) {
          final uri = Uri.parse(urlString);
          try {
            // On Android, directly try to launch without checking canLaunchUrl
            // as it can give false negatives on some devices
            if (await launchUrl(
              uri,
              mode: LaunchMode.externalApplication,
            )) {
              return;
            }
          } catch (e) {
            debugPrint('Failed to launch $urlString: $e');
            // Continue to next URL
          }
        }
      }

      // Universal fallback to web URL for any platform if above methods fail
      final webFallbackUrl =
          'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';
      final webUri = Uri.parse(webFallbackUrl);

      await launchUrl(
        webUri,
        mode: LaunchMode.externalNonBrowserApplication,
      ).catchError((e) async {
        // If external app fails, try browser mode
        debugPrint('Failed to launch in app mode, trying browser mode');
        return await launchUrl(
          webUri,
          mode: LaunchMode.inAppWebView,
        );
      }).catchError((e) {
        // Final fallback
        debugPrint('All URL launch attempts failed: $e');
        throw e; // Re-throw to trigger the error message
      });
    } catch (e) {
      debugPrint('Error launching map: $e');

      // Show error message if all attempts failed
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Harita uygulaması açılamadı: ${e.toString()}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}

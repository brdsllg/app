import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Shows the first-launch disclaimer flow if not yet accepted.
/// Returns true if the user accepted (or had already accepted).
Future<bool> checkAndShowDisclaimers(BuildContext context) async {
  // ignore: use_build_context_synchronously
  final navigator = Navigator.of(context);
  final prefs = await SharedPreferences.getInstance();
  final accepted = prefs.getBool('disclaimers_accepted') ?? false;
  if (accepted) return true;

  // Show 3 sequential disclaimer dialogs, force accept
  await _showDisclaimerPage(
    // ignore: use_build_context_synchronously
    navigator.context,
    'Notice — Zmanim Accuracy',
    'Please add at least 2 minutes to these zmanim l\'chumrah, since '
        'Calculated zmanim are inherently approximate due to factors such as '
        'atmospheric conditions (including temperature and barometric pressure), '
        'clock inaccuracies (including smartphones), rounding, differences in '
        'halachic opinions, and other variables.',
    1,
    2,
  );

  await _showDisclaimerPage(
    // ignore: use_build_context_synchronously
    navigator.context,
    'Notice — Location Permissions',
    'These zmanim use exact coordinates. Please ensure that you allow '
        'exact location permissions.',
    2,
    2,
  );

  // All disclaimers accepted — persist
  await prefs.setBool('disclaimers_accepted', true);
  return true;
}

Future<void> _showDisclaimerPage(
  BuildContext context,
  String title,
  String body,
  int page,
  int totalPages,
) async {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return PopScope(
        canPop: false,
        child: AlertDialog(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title),
              const SizedBox(height: 4),
              Text(
                'Page $page of $totalPages',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Text(
              body,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    },
  );
}
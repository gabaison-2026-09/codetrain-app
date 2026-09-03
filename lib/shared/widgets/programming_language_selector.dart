import 'package:flutter/material.dart';

import 'programming_language_icon.dart';

class ProgrammingLanguageSelector extends StatelessWidget {
  const ProgrammingLanguageSelector({
    super.key,
    required this.languages,
    required this.selectedLanguage,
    required this.onChanged,
    this.keyPrefix = 'programming-language',
    this.semanticsLabel = 'プログラミング言語',
    this.labelBuilder,
  });

  final List<String> languages;
  final String selectedLanguage;
  final ValueChanged<String> onChanged;
  final String keyPrefix;
  final String semanticsLabel;
  final String Function(String language)? labelBuilder;

  @override
  Widget build(BuildContext context) {
    final uniqueLanguages = <String>[];
    final seenKeys = <String>{};
    for (final language in languages) {
      final key = language.toLowerCase();
      if (key.isNotEmpty && seenKeys.add(key)) {
        uniqueLanguages.add(language);
      }
    }
    if (uniqueLanguages.isEmpty) return const SizedBox.shrink();

    return Semantics(
      container: true,
      label: semanticsLabel,
      child: SizedBox(
        height: 82,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final language in uniqueLanguages) ...[
                _ProgrammingLanguageButton(
                  language: language,
                  label: labelBuilder?.call(language) ?? language,
                  isSelected: language.toLowerCase() ==
                      selectedLanguage.toLowerCase(),
                  keyPrefix: keyPrefix,
                  onTap: () => onChanged(language),
                ),
                const SizedBox(width: 12),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ProgrammingLanguageButton extends StatelessWidget {
  const _ProgrammingLanguageButton({
    required this.language,
    required this.label,
    required this.isSelected,
    required this.keyPrefix,
    required this.onTap,
  });

  final String language;
  final String label;
  final bool isSelected;
  final String keyPrefix;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: isSelected,
      button: true,
      label: label,
      child: InkWell(
        key: ValueKey('$keyPrefix-${language.toLowerCase()}'),
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: SizedBox(
          width: 64,
          child: Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 44,
                height: 44,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xff6263d9)
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: ProgrammingLanguageIcon(
                  language: language,
                  size: 38,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isSelected
                      ? const Color(0xff6263d9)
                      : const Color(0xff55555e),
                  fontFamily: 'Noto Sans Japanese',
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

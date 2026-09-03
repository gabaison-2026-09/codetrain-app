import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ProgrammingLanguageIcon extends StatelessWidget {
  const ProgrammingLanguageIcon({
    super.key,
    required this.language,
    this.size = 44,
  });

  final String language;
  final double size;

  static const _assetByLanguage = <String, String>{
    'c': 'assets/icons/programming_languages/c.svg',
    'c++': 'assets/icons/programming_languages/cpp.svg',
    'cpp': 'assets/icons/programming_languages/cpp.svg',
    'c#': 'assets/icons/programming_languages/csharp.svg',
    'csharp': 'assets/icons/programming_languages/csharp.svg',
    'dart': 'assets/icons/programming_languages/dart.svg',
    'go': 'assets/icons/programming_languages/go.svg',
    'java': 'assets/icons/programming_languages/java.svg',
    'javascript': 'assets/icons/programming_languages/javascript.svg',
    'js': 'assets/icons/programming_languages/javascript.svg',
    'kotlin': 'assets/icons/programming_languages/kotlin.svg',
    'php': 'assets/icons/programming_languages/php.svg',
    'python': 'assets/icons/programming_languages/python.svg',
    'ruby': 'assets/icons/programming_languages/ruby.svg',
    'rust': 'assets/icons/programming_languages/rust.svg',
    'swift': 'assets/icons/programming_languages/swift.svg',
    'typescript': 'assets/icons/programming_languages/typescript.svg',
    'ts': 'assets/icons/programming_languages/typescript.svg',
  };

  @override
  Widget build(BuildContext context) {
    final normalizedLanguage = language.trim().toLowerCase();
    final assetPath = _assetByLanguage[normalizedLanguage];
    if (assetPath == null) {
      return _FallbackLanguageIcon(language: language, size: size);
    }

    return SvgPicture.asset(
      assetPath,
      width: size,
      height: size,
      fit: BoxFit.contain,
      semanticsLabel: language,
    );
  }
}

class _FallbackLanguageIcon extends StatelessWidget {
  const _FallbackLanguageIcon({required this.language, required this.size});

  final String language;
  final double size;

  @override
  Widget build(BuildContext context) {
    final label = language.trim().isEmpty
        ? '?'
        : language.trim().length > 3
        ? language.trim().substring(0, 2)
        : language.trim();

    return Semantics(
      label: language,
      image: true,
      child: SizedBox.square(
        dimension: size,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xffe3e3e9),
            borderRadius: BorderRadius.circular(size * 0.2),
            border: Border.all(color: const Color(0xffb7b7c2)),
          ),
          child: Center(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.clip,
              style: TextStyle(
                color: const Color(0xff4c4c55),
                fontFamily: 'Russo One',
                fontSize: size * 0.28,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

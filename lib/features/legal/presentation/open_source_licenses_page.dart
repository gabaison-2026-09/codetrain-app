import 'package:flutter/material.dart';

class OpenSourceLicensesPage extends StatelessWidget {
  const OpenSourceLicensesPage({super.key});

  static const _textColor = Color(0xff222229);
  static const _mutedColor = Color(0xff707078);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: _textColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'オープンソースライセンス',
          style: TextStyle(
            fontFamily: 'Noto Sans Japanese',
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: SelectionArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
            children: const [
              Text(
                'CodeYomelでは、プログラミング言語を示すアイコンにオープンソースの素材を使用しています。',
                style: TextStyle(
                  color: _textColor,
                  fontFamily: 'Noto Sans Japanese',
                  fontSize: 14,
                  height: 1.8,
                ),
              ),
              SizedBox(height: 24),
              _LicenseSection(
                title: 'Devicon',
                subtitle: 'プログラミング言語アイコンの出典',
                body: _deviconNotice,
              ),
              SizedBox(height: 20),
              _LicenseSection(
                title: '追加のライセンス表示',
                subtitle: 'ロゴごとに適用される追加条件',
                body: _additionalNotice,
              ),
              SizedBox(height: 20),
              _LicenseSection(
                title: '商標・非提携に関する注意',
                body: _trademarkNotice,
              ),
              SizedBox(height: 24),
              Text(
                '各アイコンの取得元一覧は、アプリのソースコードに含まれる THIRD_PARTY_NOTICES.md と assets/icons/programming_languages/SOURCE.md にも記載しています。',
                style: TextStyle(
                  color: _mutedColor,
                  fontFamily: 'Noto Sans Japanese',
                  fontSize: 12,
                  height: 1.7,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LicenseSection extends StatelessWidget {
  const _LicenseSection({
    required this.title,
    required this.body,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: OpenSourceLicensesPage._textColor,
              fontFamily: 'Noto Sans Japanese',
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 3),
            Text(
              subtitle!,
              style: const TextStyle(
                color: OpenSourceLicensesPage._mutedColor,
                fontFamily: 'Noto Sans Japanese',
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Text(
            body,
            style: const TextStyle(
              color: OpenSourceLicensesPage._textColor,
              fontFamily: 'Noto Sans Japanese',
              fontSize: 12,
              height: 1.65,
            ),
          ),
        ],
      ),
    );
  }
}

const _deviconNotice = '''
アイコンの取得元
Devicon
https://github.com/devicons/devicon

ライセンス
The MIT License (MIT)

Copyright (c) 2015 konpa

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
the Software, and to permit persons to whom the Software is furnished to do so,
subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.''';

const _additionalNotice = '''
PHP logo
Copyright Colin Viebrock
Creative Commons Attribution-ShareAlike 4.0 International (CC BY-SA 4.0)
https://creativecommons.org/licenses/by-sa/4.0/

Ruby logo
Copyright Yukihiro Matsumoto
Creative Commons Attribution-ShareAlike 2.5 (CC BY-SA 2.5)
https://creativecommons.org/licenses/by-sa/2.5/

Rust logo
Rust Foundation
Creative Commons Attribution 4.0 International (CC BY 4.0)
https://creativecommons.org/licenses/by/4.0/

これらのライセンスでは、著作権者の表示、ライセンスへのリンク、変更の有無の表示が求められます。将来アイコンを変更・改変する場合は、ShareAlikeまたはAttributionの条件を維持します。''';

const _trademarkNotice = '''
Python、Dart、Rust、Swift、C++、Go、Java、Kotlin、TypeScript、JavaScript、C#、PHPなどの名称・ロゴは、それぞれの権利者に帰属します。

CodeYomelでの使用は、学習対象の言語を示すための参照目的です。CodeYomelが各プロジェクトから承認・後援されていること、または各プロジェクトと提携していることを示すものではありません。''';

import 'package:flutter/material.dart';

import '../../domain/learn_content.dart';

class LearnSelectionView extends StatelessWidget {
  const LearnSelectionView({
    super.key,
    required this.catalog,
    required this.selectedNodeId,
    required this.isLoading,
    required this.errorMessage,
    required this.contentPadding,
    required this.onNodeSelected,
    required this.onStart,
  });

  final LearnCatalog catalog;
  final String? selectedNodeId;
  final bool isLoading;
  final String? errorMessage;
  final EdgeInsets contentPadding;
  final ValueChanged<String> onNodeSelected;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.white,
      child: SingleChildScrollView(
        padding: contentPadding,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _SelectionHeader(),
                const SizedBox(height: 26),
                for (var index = 0; index < catalog.skills.length; index++) ...[
                  _SkillSection(
                    skill: catalog.skills[index],
                    selectedNodeId: selectedNodeId,
                    onNodeSelected: onNodeSelected,
                  ),
                  if (index < catalog.skills.length - 1)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 22),
                      child: Divider(height: 1, color: Color(0xffe2e2e7)),
                    ),
                ],
                if (errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xffc34949),
                      fontFamily: 'Noto Sans Japanese',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 26),
                SizedBox(
                  height: 58,
                  child: FilledButton(
                    key: const ValueKey('learn-start-button'),
                    onPressed: selectedNodeId == null || isLoading
                        ? null
                        : onStart,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xff111116),
                      disabledBackgroundColor: const Color(0xffd8d8df),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: isLoading
                        ? const SizedBox.square(
                            dimension: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'この内容で始める',
                                style: TextStyle(
                                  fontFamily: 'Noto Sans Japanese',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              SizedBox(width: 10),
                              Icon(Icons.arrow_forward_rounded, size: 22),
                            ],
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

class _SelectionHeader extends StatelessWidget {
  const _SelectionHeader();

  @override
  Widget build(BuildContext context) {
    return const Text(
      '何を学習する？',
      style: TextStyle(
        color: Color(0xff111116),
        fontFamily: 'Noto Sans Japanese',
        fontSize: 27,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.5,
      ),
    );
  }
}

class _SkillSection extends StatelessWidget {
  const _SkillSection({
    required this.skill,
    required this.selectedNodeId,
    required this.onNodeSelected,
  });

  final LearnSkill skill;
  final String? selectedNodeId;
  final ValueChanged<String> onNodeSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          skill.name,
          style: const TextStyle(
            color: Color(0xff18181d),
            fontFamily: 'Noto Sans Japanese',
            fontSize: 19,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          skill.description,
          style: const TextStyle(
            color: Color(0xff777781),
            fontFamily: 'Noto Sans Japanese',
            fontSize: 13,
            height: 1.65,
          ),
        ),
        const SizedBox(height: 10),
        for (final node in skill.nodes)
          _NodeButton(
            node: node,
            isSelected: node.id == selectedNodeId,
            onTap: () => onNodeSelected(node.id),
          ),
      ],
    );
  }
}

class _NodeButton extends StatelessWidget {
  const _NodeButton({
    required this.node,
    required this.isSelected,
    required this.onTap,
  });

  final LearnSkillNode node;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: isSelected,
      button: true,
      child: InkWell(
        key: ValueKey('learn-node-${node.id}'),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Color(0xffededf0))),
          ),
          child: Row(
            children: [
              Icon(
                isSelected ? Icons.check_circle_rounded : Icons.circle_outlined,
                color: isSelected
                    ? const Color(0xff6263d9)
                    : const Color(0xffb2b2bb),
                size: 18,
              ),
              const SizedBox(width: 7),
              Text(
                node.name,
                style: TextStyle(
                  color: isSelected
                      ? const Color(0xff6263d9)
                      : const Color(0xff4e4e57),
                  fontFamily: 'Noto Sans Japanese',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              const SizedBox(width: 8),
              Text(
                'Lv.${node.difficulty}',
                style: TextStyle(
                  color: isSelected
                      ? const Color(0xff6263d9)
                      : const Color(0xff9b9ba4),
                  fontFamily: 'Russo One',
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

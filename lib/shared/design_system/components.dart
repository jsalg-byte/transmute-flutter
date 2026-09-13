import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/transmute_palette.dart';
import 'design_tokens.dart';

/// A themed surface. Insets can be omitted for ListTile and other padded content.
class TransmutePanel extends StatelessWidget {
  const TransmutePanel({
    super.key,
    required this.child,
    this.padding,
    this.margin,
  });
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) => Card(
    margin: margin,
    child: Padding(
      padding: padding ?? EdgeInsets.all(DesignTokens.of(context).panelPadding),
      child: child,
    ),
  );
}

enum TransmuteButtonKind { primary, secondary, quiet, destructive }

class TransmuteButton extends StatelessWidget {
  const TransmuteButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.kind = TransmuteButtonKind.primary,
    this.icon,
    this.loading = false,
  });
  final String label;
  final VoidCallback? onPressed;
  final TransmuteButtonKind kind;
  final IconData? icon;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTokens.of(context);
    final palette = TransmutePalette.of(context);
    final content = Stack(
      alignment: Alignment.center,
      children: [
        // Retain the label's layout while the request is pending.
        Opacity(
          opacity: loading ? 0 : 1,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18),
                const SizedBox(width: DesignSpace.sm),
              ],
              Flexible(child: Text(label, textAlign: TextAlign.center)),
            ],
          ),
        ),
        if (loading)
          const SizedBox.square(
            dimension: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
      ],
    );
    final action = loading ? null : onPressed;
    final style = ButtonStyle(
      minimumSize: WidgetStatePropertyAll(
        Size(tokens.controlHeight, tokens.controlHeight),
      ),
      shape: WidgetStatePropertyAll(tokens.shape()),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(
          horizontal: DesignSpace.lg,
          vertical: DesignSpace.sm,
        ),
      ),
    );
    final button = switch (kind) {
      TransmuteButtonKind.primary => ElevatedButton(
        style: style,
        onPressed: action,
        child: content,
      ),
      TransmuteButtonKind.secondary => OutlinedButton(
        style: style,
        onPressed: action,
        child: content,
      ),
      TransmuteButtonKind.quiet => TextButton(
        style: style,
        onPressed: action,
        child: content,
      ),
      TransmuteButtonKind.destructive => TextButton(
        style: style.copyWith(
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) =>
                states.contains(WidgetState.disabled) ? null : palette.rest,
          ),
        ),
        onPressed: action,
        child: content,
      ),
    };
    return Semantics(
      label: loading ? '$label, Saving' : null,
      liveRegion: loading,
      child: button,
    );
  }
}

enum TransmuteFieldKind { outlined, ledger }

/// A controlled input. Parsing, validation, and controller lifetime belong to
/// the feature; this widget only owns presentation and accessible labelling.
class TransmuteTextField extends StatelessWidget {
  const TransmuteTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.error,
    this.semanticLabel,
    this.enabled = true,
    this.kind = TransmuteFieldKind.outlined,
    this.keyboardType,
    this.onChanged,
    this.inputFormatters,
  });
  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final String? error;
  final String? semanticLabel;
  final bool enabled;
  final TransmuteFieldKind kind;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    final ledger = kind == TransmuteFieldKind.ledger;
    final compact = MediaQuery.sizeOf(context).width < 600;
    return Semantics(
      label: semanticLabel,
      child: TextField(
        controller: controller,
        enabled: enabled,
        keyboardType: keyboardType,
        onChanged: onChanged,
        inputFormatters: inputFormatters,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          errorText: error,
          border: ledger ? const UnderlineInputBorder() : null,
          isDense: ledger && compact,
          contentPadding: ledger && compact
              ? const EdgeInsets.symmetric(vertical: 7)
              : null,
        ),
      ),
    );
  }
}

/// One selected step, full title, and explicit previous/next navigation.
/// The feature owns selection and any optional action below the indicators.
class TransmuteStepper extends StatelessWidget {
  const TransmuteStepper({
    super.key,
    required this.title,
    required this.currentIndex,
    required this.stepCount,
    this.onPrevious,
    this.onNext,
    this.onStepSelected,
    this.footer,
    this.previousLabel = 'Previous Step',
    this.nextLabel = 'Next Step',
  }) : assert(stepCount > 0),
       assert(currentIndex >= 0 && currentIndex < stepCount);
  final String title;
  final int currentIndex;
  final int stepCount;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final ValueChanged<int>? onStepSelected;
  final String previousLabel;
  final String nextLabel;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 600;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconButton(
              tooltip: previousLabel,
              onPressed: onPrevious,
              icon: const Icon(Icons.chevron_left),
            ),
            Expanded(
              child: Semantics(
                header: true,
                label: 'Step ${currentIndex + 1} of $stepCount: $title',
                excludeSemantics: true,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    title,
                    maxLines: 1,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontSize: compact ? 24 : null,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
            IconButton(
              tooltip: nextLabel,
              onPressed: onNext,
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
        SizedBox(height: compact ? 6 : 12),
        Row(
          children: [
            for (var index = 0; index < stepCount; index++) ...[
              if (index > 0) SizedBox(width: compact ? 6 : 8),
              Expanded(
                child: _StepperIndicator(
                  index: index,
                  selected: index == currentIndex,
                  height: compact ? 4 : 6,
                  onSelected: onStepSelected,
                ),
              ),
            ],
          ],
        ),
        if (footer != null) ...[SizedBox(height: compact ? 4 : 12), footer!],
      ],
    );
  }
}

class _StepperIndicator extends StatelessWidget {
  const _StepperIndicator({
    required this.index,
    required this.selected,
    required this.height,
    required this.onSelected,
  });

  final int index;
  final bool selected;
  final double height;
  final ValueChanged<int>? onSelected;

  @override
  Widget build(BuildContext context) {
    final bar = Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(DesignTokens.of(context).radius),
        color: selected
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).dividerColor,
      ),
    );
    if (onSelected == null) return ExcludeSemantics(child: bar);
    return Semantics(
      button: true,
      selected: selected,
      label: 'Step ${index + 1}',
      child: Tooltip(
        message: 'Go to step ${index + 1}',
        child: InkWell(
          onTap: () => onSelected!(index),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: (44 - height) / 2),
            child: ExcludeSemantics(child: bar),
          ),
        ),
      ),
    );
  }
}
